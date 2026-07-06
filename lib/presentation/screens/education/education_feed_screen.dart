import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/education_post_model.dart';
import '../../../data/services/education_feed_service.dart';
import '../../../data/services/education_sync_service.dart';

const List<String> _kReactionEmojis = ['👍', '❤️', '😮', '😢'];

/// 📰 FLUX ÉDUCATIF SANTÉ RESPIRATOIRE
///
/// Actualités OMS Afrique, synchronisées depuis l'app à l'ouverture de cet
/// écran (au plus une fois toutes les 30 min, voir EducationSyncService) —
/// lecture seule + réactions emoji. Ne remplace pas les écrans TB/pneumonie
/// spécifiques à RespiraBox — c'est un contenu de sensibilisation plus large.
class EducationFeedScreen extends ConsumerStatefulWidget {
  const EducationFeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EducationFeedScreen> createState() => _EducationFeedScreenState();
}

class _EducationFeedScreenState extends ConsumerState<EducationFeedScreen> {
  final EducationFeedService _service = EducationFeedService();
  String _selectedCategory = EducationCategory.all;

  @override
  void initState() {
    super.initState();
    EducationSyncService.syncIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Éducation santé respiratoire'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<EducationPostModel>>(
        // Un seul flux non filtré : sert à la fois à afficher les articles
        // et à ne proposer que les onglets de catégorie qui ont vraiment du
        // contenu (pas de vide, réapparaît automatiquement si l'OMS publie
        // un jour un article tuberculose/pneumonie/asthme/qualité de l'air).
        stream: _service.watchPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur de chargement: ${snapshot.error}'));
          }

          final allPosts = snapshot.data ?? [];
          final availableCategories = <String>{
            for (final post in allPosts) post.category,
          };
          if (!availableCategories.contains(_selectedCategory) &&
              _selectedCategory != EducationCategory.all) {
            _selectedCategory = EducationCategory.all;
          }

          final displayedPosts = _selectedCategory == EducationCategory.all
              ? allPosts
              : allPosts.where((p) => p.category == _selectedCategory).toList();

          return Column(
            children: [
              _buildCategoryTabs(availableCategories),
              Expanded(child: _buildFeed(displayedPosts)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs(Set<String> availableCategories) {
    final tabs = [EducationCategory.all, ...availableCategories];
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final category = tabs[index];
          final selected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(EducationCategory.label(category)),
              selected: selected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.textDark,
                fontSize: 12,
              ),
              onSelected: (_) => setState(() => _selectedCategory = category),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeed(List<EducationPostModel> posts) {
    if (posts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun article disponible pour l\'instant. '
            'Le flux se synchronise à l\'ouverture de cet écran, réessayez dans quelques instants.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      itemBuilder: (context, index) => _PostCard(post: posts[index], service: _service)
          .animate()
          .fadeIn(delay: (60 * index).ms, duration: 350.ms)
          .slideY(begin: 0.06, end: 0),
    );
  }
}

class _PostCard extends ConsumerStatefulWidget {
  final EducationPostModel post;
  final EducationFeedService service;

  const _PostCard({required this.post, required this.service});

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  String? _myReaction;

  @override
  void initState() {
    super.initState();
    _loadMyReaction();
  }

  Future<void> _loadMyReaction() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final reaction = await widget.service.getUserReaction(widget.post.id, user.id);
    if (mounted) setState(() => _myReaction = reaction);
  }

  Future<void> _onReact(String emoji) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => _myReaction = _myReaction == emoji ? null : emoji);
    await widget.service.setReaction(postId: widget.post.id, userId: user.id, emoji: emoji);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(post.sourceUrl), mode: LaunchMode.externalApplication),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.imageUrl != null)
              Image.network(
                post.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          EducationCategory.label(post.category),
                          style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd MMM yyyy', 'fr_FR').format(post.publishedAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    post.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 4),
                  Text(post.sourceName, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                  const Divider(height: 20),
                  _buildReactionRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionRow() {
    return Wrap(
      spacing: 8,
      children: _kReactionEmojis.map((emoji) {
        final count = widget.post.reactionCounts[emoji] ?? 0;
        final selected = _myReaction == emoji;
        return InkWell(
          onTap: () => _onReact(emoji),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withOpacity(0.15) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: selected ? Border.all(color: AppColors.primary) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 15))
                    .animate(target: selected ? 1 : 0)
                    .scaleXY(begin: 1, end: 1.25, curve: Curves.easeOutBack, duration: 250.ms),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Text('$count', style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
