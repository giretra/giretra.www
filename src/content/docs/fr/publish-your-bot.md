---
title: Publier votre Bot
description: Soumettez votre bot au dépôt Giretra et rendez-le jouable sur play.giretra.com.
---

Votre bot écrase `RandomPlayer` sans effort. Il tient tête à `CalculatingPlayer`. Peut-être même qu'il donne du fil à retordre à `DeterministicPlayer`. Il est temps de le mettre en ligne et de laisser de vrais joueurs l'affronter.

Publier votre bot signifie ouvrir une pull request sur le dépôt [giretra/giretra](https://github.com/giretra/giretra). Une fois fusionnée, votre bot devient disponible sur [play.giretra.com](https://play.giretra.com), la plateforme multijoueur en ligne où humains et bots s'affrontent en matchs classés.

## Liste de vérification avant décollage

Avant d'ouvrir une PR, lancez ces trois commandes depuis la racine de votre clone Giretra. Ce sont vos meilleurs alliés.

### Valider

```bash
./giretra-manage.sh validate my-bot
```

C'est le **minimum requis**. La validation fait jouer votre bot pendant 100 matchs contre `RandomPlayer` et vérifie les violations de règles, les crashs et les problèmes de temps de réponse. Votre objectif : **zéro violation, zéro crash**.

Allez plus loin avec ces options :

| Option | Ce qu'elle fait |
|--------|----------------|
| `-n 500` | Lance plus de matchs pour une confiance accrue |
| `-o CalculatingPlayer` | Teste contre un adversaire plus intelligent |
| `-d` | Test de déterminisme : joue deux fois avec la même graine et vérifie des décisions identiques |
| `-v` | Mode verbeux : affiche chaque violation en détail |
| `--timeout 200` | Signale toute réponse dépassant 200ms comme violation |

Un run de validation solide ressemble à ça :

```bash
./giretra-manage.sh validate my-bot -n 500 -o CalculatingPlayer -d -v
```

### Benchmark

```bash
./giretra-manage.sh benchmark my-bot CalculatingPlayer -n 500
```

Le benchmark vous donne les taux de victoire avec intervalles de confiance à 95%, les classements ELO et la significativité statistique sur 1000 matchs par défaut. Utilisez-le pour mesurer précisément comment votre bot se compare.

Testez contre les trois adversaires intégrés :

```bash
./giretra-manage.sh benchmark my-bot RandomPlayer
./giretra-manage.sh benchmark my-bot CalculatingPlayer
./giretra-manage.sh benchmark my-bot DeterministicPlayer
```

Si votre bot ne bat pas `RandomPlayer` de façon régulière, il n'est pas prêt. S'il perd tous ses matchs contre `CalculatingPlayer`, vous voudrez probablement itérer avant de publier.

### Tournoi suisse

```bash
./giretra-manage.sh swiss
```

Cette commande découvre tous les bots (intégrés et externes) et lance un tournoi au format suisse complet. Vous obtenez un classement final avec les classements ELO, les bilans victoires/défaites et les résultats par paire. C'est ce qui se rapproche le plus de ce que votre bot affrontera sur la plateforme.

Vous pouvez aussi limiter les participants :

```bash
./giretra-manage.sh swiss my-bot RandomPlayer CalculatingPlayer DeterministicPlayer
```

### Essayez dans le navigateur

Avant de soumettre, ça vaut le coup de voir votre bot en action dans la vraie interface web. Vous pouvez lancer [play.giretra.com](https://play.giretra.com) en local avec une authentification simulée. D'abord, installez les dépendances frontend :

```bash
cd src/Giretra.Web/ClientApp/giretra-web
npm install
```

Puis lancez l'application depuis la racine du dépôt :

```bash
dotnet run --project src/Giretra.Web -- --offline
```

Le flag `--offline` lance le backend ASP.NET et le frontend Angular sans aucun service externe. Ouvrez [http://localhost:4200](http://localhost:4200) pour accéder à l'application, trouver votre bot et jouer un match contre lui.

**Surveillez attentivement la sortie console.** Au démarrage, l'application découvre et lance tous les bots externes. Si votre bot ne se charge pas (dépendances manquantes, erreurs de build dans votre script `init`, conflits de port), l'erreur apparaîtra dans stdout. C'est le meilleur moyen de repérer les problèmes que les outils CLI ne font pas remonter, comme des séquences de démarrage cassées ou des soucis visibles côté interface.

## Préparer votre pull request

### Quoi inclure

Votre PR ne doit contenir **que votre dossier bot** dans `external-bots/`. C'est à dire :

```
external-bots/
  my-bot/
    bot.meta.json
    bot.py (ou bot.ts, Bot.cs, bot.go, Bot.java)
    ... (tout autre fichier nécessaire à votre bot)
```

Ne modifiez pas de fichiers en dehors de votre dossier bot. Ne touchez pas aux autres bots, au moteur, ni aux outils CLI.

### Format du titre de PR

Le titre de votre pull request **doit** suivre cette syntaxe :

```
[Bot:my-bot] Description courte
```

Où `my-bot` est exactement le nom de votre dossier dans `external-bots/`. Exemples :

- `[Bot:clever-fox] Add card-counting bot in Python`
- `[Bot:rush-player] TypeScript bot with void detection`
- `[Bot:la-machine] First submission of Go bot`

C'est cette convention de nommage qui permet au pipeline CI d'identifier les soumissions de bots.

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

- **Zéro violation de règles** lors de l'exécution de `validate`
- **Pas de crashs** sur un nombre raisonnable de matchs
- **Temps de réponse raisonnables** (voir Performance ci-dessous)
- **Autonome** : pas d'appels à des API externes, pas de requêtes réseau pendant le jeu
- **Structure de dossier propre** : uniquement les fichiers de votre bot, pas de résidus

## Performance

Il n'y a pas d'exigence stricte de vitesse, mais gardez en tête : **une seule partie peut générer plus d'un millier d'appels à l'API de votre bot**. Entre les coupes, les négociations, les cartes jouées et les événements d'observation, le moteur communique constamment avec votre bot.

Un bot qui prend 500ms par décision rendra les parties péniblement lentes pour l'humain qui attend de l'autre côté. Visez :

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

- **Évitez les calculs lourds à chaque appel.** Précalculez ce que vous pouvez pendant les événements d'observation ou au début d'une donne.
- **Minimisez les allocations mémoire.** Créer de grandes structures de données à chaque décision s'accumule sur des milliers d'appels.
- **Profilez en local.** Si votre langage a un profiler, utilisez-le. Un goulot d'étranglement qui ajoute 10ms par appel devient 10 secondes sur une partie.
- **Surveillez votre temps de démarrage.** Le script `init` ne s'exécute qu'une fois, donc les opérations lourdes (compilation, chargement de modèles) vont là, pas dans les méthodes de décision.

## Conventions pour les bots

Quelques points à garder en tête pour que votre bot s'intègre bien à la plateforme :

- **Sans état entre les matchs.** Votre bot reçoit une instance neuve par match. Ne comptez pas sur les données des matchs précédents.
- **Le déterminisme est un plus.** Si votre bot utilise du hasard, envisagez de supporter une graine pour la reproductibilité. L'option `validate -d` teste ça. Les bots déterministes sont plus faciles à déboguer et à reproduire.
- **Gérez tous les modes de jeu.** Votre bot affrontera les six modes de jeu en partie classée. Assurez-vous qu'il ne crashe pas et ne se comporte pas bizarrement dans aucun d'entre eux. Le rapport de validation montre la couverture des modes de jeu.
- **Ne codez pas d'hypothèses en dur.** L'ordre des cartes, les schémas de distribution et le comportement des adversaires varient. Votre bot doit prendre ses décisions en fonction de ce que le moteur lui dit, pas de séquences attendues.

## Déboguer une soumission qui échoue

Si votre PR échoue en CI ou si les reviewers signalent des problèmes :

1. **Lisez le rapport de validation.** Il vous dit exactement ce qui a mal tourné : quel match, quelle décision, ce qui était attendu vs. ce que votre bot a fait.
2. **Lancez en local avec `-v`.** Le mode verbeux affiche chaque violation en détail.
3. **Testez avec une graine fixe.** Utilisez `-s 42` (ou n'importe quel nombre) pour reproduire exactement la même séquence de jeu. Ça rend le débogage déterministe.
4. **Vérifiez votre script `init`.** Si votre bot ne démarre pas, le problème est souvent une dépendance manquante ou une erreur de build dans l'étape init.
5. **Essayez différents adversaires.** Certains bugs ne se révèlent que contre certaines stratégies. `CalculatingPlayer` est particulièrement efficace pour exposer les cas limites parce qu'il joue des ouvertures plus variées.

## Après la fusion de votre bot

Une fois votre PR fusionnée :

- Votre bot apparaît sur [play.giretra.com](https://play.giretra.com) et est disponible pour les matchs classés
- Les joueurs peuvent le défier ou être matchés contre lui
- Le classement ELO de votre bot démarre à 1200 et s'ajuste en fonction des résultats
- Vous pouvez soumettre des mises à jour de votre bot avec de nouvelles PR en suivant le même processus

Envie d'améliorer votre bot ? Clonez, itérez, validez, benchmarkez, PR. Le cycle est le même à chaque fois.

## Pour aller plus loin

- [Créer votre Bot](/fr/build-your-bot/) — Créez votre bot à partir d'un template en 5 étapes
- [Créer de zéro](/build-your-bot-custom/) — Comprenez le protocole et créez un bot dans n'importe quel langage
- [Comment contribuer](/fr/contribute/) — Contribuez au projet Giretra au-delà des bots
