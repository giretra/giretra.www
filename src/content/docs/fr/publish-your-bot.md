---
title: Publier votre Bot
description: Soumettez votre bot au dépôt Giretra et rendez-le jouable sur play.giretra.com.
---

Votre bot écrase `Kialasoa` sans forcer. Il tient tête à `Razavavy`. Peut-être même qu'il donne du fil à retordre à `Eva`. Il est temps de le mettre en ligne et de le confronter à de vrais joueurs.

Publier votre bot, c'est ouvrir une pull request sur le dépôt [giretra/giretra](https://github.com/giretra/giretra). Une fois fusionnée, votre bot devient disponible sur [play.giretra.com](https://play.giretra.com), la plateforme multijoueur en ligne où humains et bots s'affrontent en matchs classés.

## Checklist avant soumission

Avant d'ouvrir une PR, lancez ces trois commandes depuis la racine de votre clone Giretra. Ce sont vos meilleurs alliés.

### Valider

```bash
./giretra-manage.sh validate my-bot
```

C'est le **strict minimum**. La validation fait tourner votre bot pendant 100 matchs contre `Kialasoa` et vérifie les violations de règles, les crashs et les temps de réponse. Objectif : **zéro violation, zéro crash**.

Pour aller plus loin :

| Option | Ce qu'elle fait |
|--------|----------------|
| `-n 500` | Lance plus de matchs pour gagner en fiabilité |
| `-o Razavavy` | Teste contre un adversaire plus malin |
| `-d` | Test de déterminisme : rejoue avec la même graine et vérifie que les décisions sont identiques |
| `-v` | Mode verbeux : affiche chaque violation en détail |
| `--timeout 200` | Signale toute réponse au-delà de 200ms comme violation |

Un bon passage de validation ressemble à ça :

```bash
./giretra-manage.sh validate my-bot -n 500 -o Razavavy -d -v
```

### Benchmark

```bash
./giretra-manage.sh benchmark my-bot Razavavy -n 500
```

Le benchmark vous donne les taux de victoire avec intervalles de confiance à 95%, les classements ELO et les tests de significativité sur 1000 matchs par défaut. Idéal pour mesurer précisément où se situe votre bot.

Testez contre les trois adversaires intégrés :

```bash
./giretra-manage.sh benchmark my-bot Kialasoa
./giretra-manage.sh benchmark my-bot Razavavy
./giretra-manage.sh benchmark my-bot Eva
```

Si votre bot ne bat pas `Kialasoa` régulièrement, il n'est pas prêt. S'il perd systématiquement contre `Razavavy`, mieux vaut itérer avant de publier.

### Tournoi suisse

```bash
./giretra-manage.sh swiss
```

Cette commande détecte tous les bots (intégrés et externes) et lance un tournoi au format suisse complet. Vous obtenez un classement final avec les classements ELO, les bilans victoires/défaites et les résultats par paire. C'est ce qui ressemble le plus aux conditions réelles de la plateforme.

Vous pouvez aussi restreindre les participants :

```bash
./giretra-manage.sh swiss my-bot Kialasoa Razavavy Eva
```

### Essayez dans le navigateur

Avant de soumettre, ça vaut le coup de voir votre bot en action dans la vraie interface web. Vous pouvez lancer [play.giretra.com](https://play.giretra.com) en local avec une authentification simulée. Commencez par installer les dépendances frontend :

```bash
cd src/Giretra.Web/ClientApp/giretra-web
npm install
```

Puis lancez l'application depuis la racine du dépôt :

```bash
dotnet run --project src/Giretra.Web -- --offline
```

Le flag `--offline` lance le backend ASP.NET et le frontend Angular sans dépendance externe. Ouvrez [http://localhost:4200](http://localhost:4200) pour accéder à l'application, trouver votre bot et jouer un match contre lui.

**Gardez un œil sur la sortie console.** Au démarrage, l'application découvre et lance tous les bots externes. Si votre bot ne se charge pas (dépendances manquantes, erreurs de build dans votre script `init`, conflits de port), l'erreur apparaîtra dans stdout. C'est le meilleur moyen de repérer les problèmes que les outils CLI ne détectent pas — séquences de démarrage cassées, soucis visibles côté interface, etc.

## Préparer votre pull request

### Quoi inclure

Votre PR ne doit contenir **que votre dossier bot** dans `external-bots/`. Concrètement :

```
external-bots/
  my-bot/
    bot.meta.json
    bot.py (ou bot.ts, Bot.cs, bot.go, Bot.java)
    ... (tout autre fichier nécessaire à votre bot)
```

Ne modifiez rien en dehors de votre dossier. Ne touchez pas aux autres bots, au moteur, ni aux outils CLI.

### Format du titre de PR

Le titre de votre pull request **doit** suivre cette syntaxe :

```
[Bot:my-bot] Description courte
```

Où `my-bot` correspond exactement au nom de votre dossier dans `external-bots/`. Exemples :

- `[Bot:clever-fox] Add card-counting bot in Python`
- `[Bot:rush-player] TypeScript bot with void detection`
- `[Bot:la-machine] First submission of Go bot`

C'est grâce à cette convention que le pipeline CI identifie les soumissions de bots.

### Vérifiez `bot.meta.json`

Assurez-vous que vos métadonnées sont complètes et exactes :

```json
{
  "name": "my-bot",
  "displayName": "My Awesome Bot",
  "pun": "I never bluff... except when I do",
  "author": "Votre Nom",
  "authorGithub": "votre-pseudo-github"
}
```

- `name` doit correspondre exactement au nom de votre dossier
- `displayName` est ce que les joueurs voient sur la plateforme
- `authorGithub` doit être votre vrai pseudo GitHub

### Ce que les reviewers vérifient

- **Zéro violation de règles** lors de la validation
- **Aucun crash** sur un nombre raisonnable de matchs
- **Des temps de réponse corrects** (voir Performance ci-dessous)
- **Autonomie complète** : pas d'appels à des API externes, pas de requêtes réseau en cours de partie
- **Un dossier propre** : uniquement les fichiers de votre bot, pas de fichiers inutiles

## Performance

Il n'y a pas d'exigence stricte de vitesse, mais gardez en tête : **une seule partie peut générer plus d'un millier d'appels à l'API de votre bot**. Entre les coupes, les enchères, les cartes jouées et les événements d'observation, le moteur communique en permanence avec votre bot.

Un bot qui prend 500ms par décision rendra les parties insupportablement lentes pour l'humain qui attend en face. Visez :

| Métrique | Recommandé |
|----------|------------|
| Temps de réponse moyen | Moins de 50ms |
| Temps de réponse P95 | Moins de 100ms |
| Temps de réponse P99 | Moins de 200ms |

Utilisez `validate` avec `--timeout` pour repérer les valeurs aberrantes :

```bash
./giretra-manage.sh validate my-bot --timeout 200
```

Conseils pour garder votre bot rapide :

- **Évitez les calculs lourds à chaque appel.** Précalculez autant que possible lors des événements d'observation ou en début de donne.
- **Limitez les allocations mémoire.** Recréer de grosses structures de données à chaque décision, ça finit par peser sur des milliers d'appels.
- **Profilez en local.** Si votre langage dispose d'un profiler, servez-vous-en. Un goulot d'étranglement de 10ms par appel, c'est 10 secondes de perdu sur une partie.
- **Attention au temps de démarrage.** Le script `init` ne tourne qu'une fois : c'est là que vont la compilation, le chargement de modèles et toute opération lourde. Pas dans les méthodes de décision.

## Conventions pour les bots

Quelques points à retenir pour que votre bot s'intègre bien à la plateforme :

- **Pas d'état entre les matchs.** Votre bot reçoit une instance neuve à chaque match. Ne comptez pas sur les données des matchs précédents.
- **Le déterminisme est un plus.** Si votre bot utilise du hasard, pensez à gérer une graine pour la reproductibilité. L'option `validate -d` teste justement ça. Un bot déterministe est bien plus facile à déboguer.
- **Gérez tous les modes de jeu.** En partie classée, votre bot sera confronté aux six modes. Assurez-vous qu'il ne crashe pas et ne se comporte pas bizarrement dans aucun d'entre eux. Le rapport de validation montre la couverture des modes.
- **Pas d'hypothèses en dur.** L'ordre des cartes, la distribution et le comportement des adversaires changent à chaque partie. Votre bot doit se fier à ce que le moteur lui transmet, pas à des séquences prédéfinies.

## Déboguer une soumission qui échoue

Si votre PR échoue en CI ou si les reviewers signalent des problèmes :

1. **Lisez le rapport de validation.** Il indique précisément ce qui a posé problème : quel match, quelle décision, ce qui était attendu et ce que votre bot a fait.
2. **Relancez en local avec `-v`.** Le mode verbeux détaille chaque violation.
3. **Testez avec une graine fixe.** Utilisez `-s 42` (ou n'importe quel nombre) pour reproduire exactement la même séquence de jeu. Le débogage devient déterministe.
4. **Vérifiez votre script `init`.** Si votre bot refuse de démarrer, le problème vient souvent d'une dépendance manquante ou d'une erreur de build dans l'étape init.
5. **Variez les adversaires.** Certains bugs ne se manifestent que face à certaines stratégies. `Razavavy` est particulièrement efficace pour révéler les cas limites grâce à ses ouvertures variées.

## Après la fusion de votre bot

Une fois votre PR fusionnée :

- Votre bot apparaît sur [play.giretra.com](https://play.giretra.com) et devient disponible pour les matchs classés
- Les joueurs peuvent le défier ou tomber contre lui en matchmaking
- Son classement ELO démarre à 1200 et évolue selon les résultats
- Vous pouvez soumettre des mises à jour via de nouvelles PR en suivant le même processus

Envie d'améliorer votre bot ? Clonez, itérez, validez, benchmarkez, PR. Le cycle est toujours le même.

## Pour aller plus loin

- [Créer votre Bot](/fr/build-your-bot/) — Créez votre bot à partir d'un template en 5 étapes
- [Créer de zéro](/build-your-bot-custom/) — Comprenez le protocole et créez un bot dans n'importe quel langage
- [Comment contribuer](/fr/contribute/) — Contribuez au projet Giretra au-delà des bots
