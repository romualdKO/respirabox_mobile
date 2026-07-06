import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

/// 📰 SYNCHRONISATION CÔTÉ APP DU FLUX ÉDUCATIF SANTÉ RESPIRATOIRE
///
/// Alternative à la Cloud Function planifiée (voir functions/README.md) —
/// utilisée ici car le plan Firebase Blaze n'est pas activé sur le projet.
///
/// ⚠️ Compromis assumé : contrairement à la Cloud Function (Admin SDK), le
/// client doit avoir le droit d'écrire dans `education_posts` pour que
/// cette synchronisation fonctionne (voir firestore.rules — la règle exige
/// que `sourceUrl` pointe vers afro.who.int, ce qui limite mais n'élimine
/// pas complètement le risque qu'un client modifié injecte du faux contenu).
/// Si le plan Blaze est activé plus tard, migrer vers `functions/index.js`
/// qui a exactement la même logique côté serveur, en lecture seule pour
/// l'app — bien plus sûr.
///
/// Autre limite : pas de vraie notification push (nécessiterait un serveur
/// pour déclencher l'envoi FCM) — la synchronisation ne se déclenche que
/// quand un utilisateur ouvre l'écran Éducation, pas en tâche de fond.
class EducationSyncService {
  static const String _collection = 'education_posts';
  static const String _lastSyncKey = 'education_last_sync';
  static const Duration _syncInterval = Duration(minutes: 30);

  static const List<Map<String, String>> _feeds = [
    {
      'url': 'https://www.afro.who.int/rss/featured-news.xml',
      'sourceName': 'OMS Afrique',
    },
    {
      'url': 'https://www.afro.who.int/rss/emergencies.xml',
      'sourceName': 'OMS Afrique - Urgences',
    },
  ];

  static const Map<String, List<String>> _categoryKeywords = {
    'tuberculosis': ['tuberculosis', 'tuberculose'],
    'pneumonia': ['pneumonia', 'pneumonie'],
    'asthma': ['asthma', 'asthme'],
    'air_quality': ["air quality", "qualité de l'air", 'pollution'],
    'emergency': ['outbreak', 'épidémie', 'emergency', 'urgence', 'ebola', 'cholera', 'choléra'],
  };

  /// Synchronise uniquement si la dernière synchro date de plus de 30 min
  /// (évite de solliciter le flux RSS à chaque ouverture d'écran).
  static Future<void> syncIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncMillis = prefs.getInt(_lastSyncKey);
    final now = DateTime.now();

    if (lastSyncMillis != null) {
      final elapsed = now.difference(DateTime.fromMillisecondsSinceEpoch(lastSyncMillis));
      if (elapsed < _syncInterval) return;
    }

    try {
      await _syncNow();
      await prefs.setInt(_lastSyncKey, now.millisecondsSinceEpoch);
    } catch (e) {
      print('⚠️ Synchronisation flux éducatif échouée (non bloquant): $e');
    }
  }

  static Future<void> _syncNow() async {
    final firestore = FirebaseFirestore.instance;

    for (final feed in _feeds) {
      List<Map<String, dynamic>> posts;
      try {
        posts = await _fetchAndParseFeed(feed['url']!, feed['sourceName']!);
      } catch (e) {
        print('⚠️ Échec récupération ${feed['url']}: $e');
        continue;
      }

      for (final post in posts) {
        final ref = firestore.collection(_collection).doc(post['id'] as String);
        final existing = await ref.get();

        await ref.set({
          'title': post['title'],
          'summary': post['summary'],
          'imageUrl': post['imageUrl'],
          'sourceUrl': post['sourceUrl'],
          'sourceName': post['sourceName'],
          'publishedAt': post['publishedAt'],
          'category': post['category'],
          'reactionCounts': existing.exists
              ? (existing.data()?['reactionCounts'] ?? {})
              : <String, dynamic>{},
        }, SetOptions(merge: true));
      }
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchAndParseFeed(
      String url, String sourceName) async {
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final document = XmlDocument.parse(response.body);
    final items = document.findAllElements('item');

    return items.map((item) {
      final link = item.findElements('link').firstOrNull?.innerText.trim() ?? '';
      final rawDescription = item.findElements('description').firstOrNull?.innerText ?? '';
      final rawTitle = item.findElements('title').firstOrNull?.innerText ?? '';
      final pubDateStr = item.findElements('pubDate').firstOrNull?.innerText;

      final title = _stripHtml(rawTitle);
      final id = sha256.convert(utf8.encode(link)).toString();

      DateTime publishedAt;
      try {
        publishedAt = pubDateStr != null ? _parseRfc822Date(pubDateStr) : DateTime.now();
      } catch (_) {
        publishedAt = DateTime.now();
      }

      return {
        'id': id,
        'title': title,
        'summary': _buildSummary(title, rawDescription),
        'imageUrl': _extractImage(rawDescription),
        'sourceUrl': link,
        'sourceName': sourceName,
        'publishedAt': Timestamp.fromDate(publishedAt),
        'category': _detectCategory('$title $rawDescription'),
      };
    }).toList();
  }

  static String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&rsquo;', "'");
  }

  static String _stripHtml(String html) {
    if (html.isEmpty) return '';
    final noTags = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    // WHO tronque parfois lui-même l'email auteur en "nom@…" (ellipse
    // littérale dans le flux, pas une vraie adresse email complète) —
    // il faut un motif dédié en plus du regex email standard.
    final noTruncatedEmails = noTags.replaceAll(RegExp(r'\S+@…'), '');
    final noEmails = noTruncatedEmails.replaceAll(RegExp(r'\S+@\S+\.\S+'), '');
    final collapsed = noEmails.replaceAll(RegExp(r'\s+'), ' ').trim();
    return _decodeHtmlEntities(collapsed);
  }

  static String? _extractImage(String html) {
    final match = RegExp(r'<img[^>]+src="([^"]+)"').firstMatch(html);
    return match?.group(1);
  }

  /// Idem `buildSummary()` dans functions/index.js — voir ce fichier pour
  /// le contexte (le flux "featured-news" n'a pas de vrai extrait de texte).
  static String _buildSummary(String title, String rawDescription) {
    var text = _stripHtml(rawDescription);
    if (text.startsWith(title)) {
      text = text.substring(title.length).trim();
    }
    text = text
        .replaceAll(RegExp(r'^[A-Za-z]{3}, \d{2}/\d{2}/\d{4} - \d{2}:\d{2}\s*'), '')
        .replaceAll(
            RegExp(r'^\d{1,2} (January|February|March|April|May|June|July|August|September|October|November|December) \d{4}\s*'),
            '')
        .replaceAll(RegExp(r'^Read more about .*?\s(?=[A-Z])'), '')
        .trim();

    if (text.length < 20) {
      return "Cliquez pour lire l'article complet sur le site de l'OMS.";
    }
    return text.length > 300 ? text.substring(0, 300) : text;
  }

  static String _detectCategory(String text) {
    final lower = text.toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      if (entry.value.any((kw) => lower.contains(kw))) return entry.key;
    }
    return 'general';
  }

  static DateTime _parseRfc822Date(String rfc822) {
    // Format RSS standard: "Thu, 02 Jul 2026 15:48:10 +0000"
    return HttpDate.parse(rfc822);
  }
}

/// Parseur minimal de date RFC 822/1123 (format des flux RSS), sans
/// dépendance supplémentaire — couvre le format utilisé par afro.who.int.
class HttpDate {
  static DateTime parse(String input) {
    final cleaned = input.trim();
    final parts = cleaned.split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).toList();
    // ["Thu", "02", "Jul", "2026", "15:48:10", "+0000"]
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final day = int.parse(parts[1]);
    final month = months[parts[2]] ?? 1;
    final year = int.parse(parts[3]);
    final timeParts = parts[4].split(':');
    return DateTime.utc(
      year, month, day,
      int.parse(timeParts[0]), int.parse(timeParts[1]), int.parse(timeParts[2]),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
