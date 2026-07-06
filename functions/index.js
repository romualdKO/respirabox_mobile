/**
 * Cloud Function planifiée — synchronise le flux éducatif santé
 * respiratoire depuis les flux RSS officiels OMS Afrique (afro.who.int) et
 * notifie les utilisateurs (topic FCM `education_updates`) des nouveaux
 * articles. Voir ml/README.md et lib/data/services/education_feed_service.dart
 * pour le contexte côté app.
 *
 * Écrit exclusivement dans la collection Firestore `education_posts` —
 * les règles de sécurité (firestore.rules) interdisent au client d'écrire
 * le contenu éditorial, seule cette fonction (Admin SDK) le peut.
 *
 * Déploiement : voir functions/README.md
 */
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {XMLParser} = require("fast-xml-parser");
const crypto = require("crypto");

initializeApp();
const db = getFirestore();

const FEEDS = [
  {url: "https://www.afro.who.int/rss/featured-news.xml", sourceName: "OMS Afrique"},
  {url: "https://www.afro.who.int/rss/emergencies.xml", sourceName: "OMS Afrique - Urgences"},
];

const CATEGORY_KEYWORDS = {
  tuberculosis: ["tuberculosis", "tuberculose"],
  pneumonia: ["pneumonia", "pneumonie"],
  asthma: ["asthma", "asthme"],
  air_quality: ["air quality", "qualité de l'air", "pollution"],
  emergency: ["outbreak", "épidémie", "emergency", "urgence", "ebola", "cholera", "choléra"],
};

function detectCategory(text) {
  const lower = text.toLowerCase();
  for (const [category, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
    if (keywords.some((kw) => lower.includes(kw))) return category;
  }
  return "general";
}

function decodeHtmlEntities(text) {
  return text
      .replace(/&nbsp;/g, " ")
      .replace(/&amp;/g, "&")
      .replace(/&quot;/g, "\"")
      .replace(/&#39;/g, "'")
      .replace(/&rsquo;/g, "'");
}

function stripHtml(html) {
  if (!html) return "";
  return decodeHtmlEntities(
      html
          .replace(/<[^>]*>/g, " ")
          // WHO tronque parfois lui-même l'email auteur en "nom@…" (ellipse
          // littérale dans le flux, pas une vraie adresse complète)
          .replace(/\S+@…/g, "")
          .replace(/\S+@\S+\.\S+/g, "") // adresses email complètes (byline auteur)
          .replace(/\s+/g, " ")
          .trim(),
  );
}

function extractImage(html) {
  if (!html) return null;
  const match = html.match(/<img[^>]+src="([^"]+)"/);
  return match ? match[1] : null;
}

// La balise <description> du flux AFRO ne contient pas toujours d'extrait de
// texte réel (le flux "featured-news" ne fournit que titre + image + email
// auteur + date, sans corps de texte). On nettoie les préfixes de date/CTA
// répétitifs ; si le résultat est trop court pour être un vrai résumé, on
// affiche un texte d'invite à cliquer plutôt qu'une bribe de date orpheline.
function buildSummary(title, rawDescription) {
  let text = stripHtml(rawDescription);
  if (text.startsWith(title)) {
    text = text.slice(title.length).trim();
  }
  text = text
      .replace(/^[A-Za-z]{3}, \d{2}\/\d{2}\/\d{4} - \d{2}:\d{2}\s*/, "")
      .replace(/^\d{1,2} (January|February|March|April|May|June|July|August|September|October|November|December) \d{4}\s*/, "")
      .replace(/^Read more about .*?\s(?=[A-Z])/, "")
      .trim();

  if (text.length < 20) {
    return "Cliquez pour lire l'article complet sur le site de l'OMS.";
  }
  return text.slice(0, 300);
}

async function fetchAndParseFeed(feed) {
  const response = await fetch(feed.url, {signal: AbortSignal.timeout(15000)});
  if (!response.ok) throw new Error(`HTTP ${response.status} pour ${feed.url}`);
  const xml = await response.text();

  const parser = new XMLParser({ignoreAttributes: false});
  const data = parser.parse(xml);
  const items = data?.rss?.channel?.item;
  if (!items) return [];

  return (Array.isArray(items) ? items : [items]).map((item) => {
    const link = String(item.link || "").trim();
    const rawDescription = typeof item.description === "string" ? item.description : "";
    const title = stripHtml(String(item.title || ""));
    return {
      id: crypto.createHash("sha256").update(link).digest("hex"),
      title: title,
      summary: buildSummary(title, rawDescription),
      imageUrl: extractImage(rawDescription),
      sourceUrl: link,
      sourceName: feed.sourceName,
      publishedAt: item.pubDate ? new Date(item.pubDate) : new Date(),
      category: detectCategory(`${item.title} ${rawDescription}`),
    };
  });
}

exports.syncEducationFeed = onSchedule(
    {schedule: "every 30 minutes", region: "europe-west1"},
    async () => {
      const newPostTitles = [];

      for (const feed of FEEDS) {
        let posts;
        try {
          posts = await fetchAndParseFeed(feed);
        } catch (e) {
          console.error(`Échec récupération ${feed.url}:`, e);
          continue;
        }

        for (const post of posts) {
          const ref = db.collection("education_posts").doc(post.id);
          const existing = await ref.get();
          const isNew = !existing.exists;

          await ref.set({
            title: post.title,
            summary: post.summary,
            imageUrl: post.imageUrl,
            sourceUrl: post.sourceUrl,
            sourceName: post.sourceName,
            publishedAt: post.publishedAt,
            category: post.category,
            reactionCounts: existing.exists ? (existing.data().reactionCounts || {}) : {},
          }, {merge: true});

          if (isNew) newPostTitles.push(post.title);
        }
      }

      if (newPostTitles.length > 0) {
        const body = newPostTitles.length === 1 ?
          newPostTitles[0] :
          `${newPostTitles.length} nouveaux articles disponibles`;

        await getMessaging().send({
          topic: "education_updates",
          notification: {
            title: "📰 Nouvelle actualité santé respiratoire",
            body,
          },
        });
        console.log(`Notifié ${newPostTitles.length} nouveau(x) post(s)`);
      }
    },
);
