# Cloud Function — Flux éducatif santé respiratoire (upgrade optionnelle, non déployée)

⚠️ **Non active actuellement.** Le plan Firebase Blaze n'a pas été activé
sur `respirabox-production`, donc l'app synchronise le flux RSS elle-même
(`lib/data/services/education_sync_service.dart`) plutôt que via cette
fonction planifiée. Ce code reste ici prêt à déployer si le plan Blaze est
activé plus tard — voir plus bas pourquoi ce serait préférable.

Une fois déployée, cette fonction synchroniserait toutes les 30 minutes le
flux RSS OMS Afrique (`afro.who.int/rss/featured-news.xml` +
`emergencies.xml`) vers Firestore (`education_posts`), et notifierait les
utilisateurs abonnés au topic FCM `education_updates` quand de nouveaux
articles apparaissent (vraie notification push, y compris app fermée —
chose impossible avec la synchronisation côté app actuelle).

## Pourquoi ce serait mieux qu'une synchronisation côté app

Actuellement, `firestore.rules` autorise un client authentifié à écrire
dans `education_posts` (avec un garde-fou : `sourceUrl` doit pointer vers
afro.who.int) pour que la synchro côté app fonctionne. Avec cette Cloud
Function (Admin SDK, contourne les règles), on pourrait revenir à des
règles strictement lecture-seule côté client — plus robuste face à un
client modifié qui tenterait d'injecter du faux contenu.

## Prérequis (à faire une seule fois, de ton côté)

1. **Activer le plan Blaze** sur le projet Firebase `respirabox-production`
   (console.firebase.google.com → Paramètres du projet → Utilisation et
   facturation). Les Cloud Functions planifiées nécessitent ce plan, mais à
   ce volume d'usage (1 fonction, 48 exécutions/jour, quelques appels HTTP
   et lectures Firestore), le coût réel devrait rester à 0 FCFA ou presque
   (largement dans le quota gratuit mensuel).
2. Installer le CLI Firebase si ce n'est pas déjà fait :
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

## Déploiement

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

## Vérifier que ça tourne

```bash
firebase functions:log
```

Tu devrais voir un log toutes les 30 minutes, et de nouveaux documents
apparaître dans la collection Firestore `education_posts` (console Firebase
→ Firestore Database).

## Modifier la fréquence ou les flux RSS

Tout est dans `index.js` :
- `FEEDS` : liste des flux RSS à synchroniser (ajouter une source ici si tu
  en trouves une autre avec un flux RSS réel — voir la conversation
  précédente sur pourquoi le scraping HTML n'est pas fait ici)
- `CATEGORY_KEYWORDS` : mots-clés qui déterminent la catégorie affichée
  dans l'app (onglets de filtre)
- `"every 30 minutes"` : fréquence de synchronisation (syntaxe cron
  App Engine, voir [doc Firebase](https://firebase.google.com/docs/functions/schedule-functions))
