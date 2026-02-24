---
title: Créer de zéro
description: Le protocole HTTP brut pour créer un bot Giretra dans n'importe quel langage.
---

Les templates gèrent le HTTP pour vous, mais si vous voulez faire le vôtre en Rust, Haskell, ou autre, voici comment ça marche sous le capot. Du HTTP simple, du JSON simple. Si votre langage peut servir du HTTP et parser du JSON, vous pouvez créer un bot.

## Architecture

Le moteur contrôle tout. Votre bot ne fait que répondre.

```
┌─────────────────────┐                     ┌─────────────────────┐
│                     │   POST /choose-card  │                     │
│   Moteur Giretra    │ ──────────────────►  │     Votre Bot       │
│                     │                      │                     │
│  • gère l'état      │  ◄────────────────── │  • prend des        │
│  • applique les     │    réponse JSON      │    décisions        │
│    règles           │                      │  • avec ou sans     │
│  • suit les scores  │                      │    état             │
│                     │                      │                     │
└─────────────────────┘                      └─────────────────────┘

         Le moteur démarre votre bot, envoie des requêtes HTTP,
         et votre bot répond en JSON. C'est tout le protocole.
```

Votre bot est un serveur HTTP. Le moteur le démarre, lui envoie des requêtes et lit les réponses. Vous n'initiez aucune communication. Vous répondez quand on vous le demande.

## L'API HTTP

Tous les endpoints se trouvent sous `/api/sessions/{sessionId}/`. Le moteur crée une session au début de chaque match et envoie toutes les requêtes suivantes dans le cadre de cette session.

### Gestion des sessions

| Méthode | Chemin | Description |
|---------|--------|-------------|
| `GET` | `/health` | Vérification de vie. Retournez `200 OK`. |
| `POST` | `/api/sessions` | Crée une nouvelle instance de bot pour un match. Reçoit `{ "matchId": "..." }`, retourne `{ "sessionId": "..." }`. |
| `DELETE` | `/api/sessions/{sessionId}` | Nettoyage après la fin du match. Retournez `200 OK`. |

### Endpoints de décision

Ce sont les trois endpoints où votre bot fait réellement ses choix.

| Méthode | Chemin | Description |
|---------|--------|-------------|
| `POST` | `/api/sessions/{sessionId}/choose-cut` | Choisir où couper le jeu. |
| `POST` | `/api/sessions/{sessionId}/choose-negotiation-action` | Choisir une action d'enchère. |
| `POST` | `/api/sessions/{sessionId}/choose-card` | Choisir une carte à jouer. |

### Endpoints de notification (optionnel)

Si votre `bot.meta.json` inclut un tableau `notifications`, le moteur fera des POST vers ceux-ci :

| Méthode | Chemin | Description |
|---------|--------|-------------|
| `POST` | `/api/sessions/{sessionId}/notify/deal-started` | Une nouvelle donne commence. |
| `POST` | `/api/sessions/{sessionId}/notify/card-played` | Une carte a été jouée par n'importe quel joueur. |
| `POST` | `/api/sessions/{sessionId}/notify/trick-completed` | Un pli vient de se terminer. |
| `POST` | `/api/sessions/{sessionId}/notify/deal-ended` | La donne est terminée, voici les résultats. |
| `POST` | `/api/sessions/{sessionId}/notify/match-ended` | Le match est terminé. |

Les endpoints de notification doivent retourner `200 OK`. Ils fonctionnent en mode fire-and-forget. Le moteur n'utilise pas le corps de la réponse.

## Les 3 décisions

### Choisir la coupe

Le moteur demande où couper le jeu avant chaque donne.

**Requête :**

```json
{
  "hand": [
    { "rank": "Ace", "suit": "Hearts" },
    { "rank": "Ten", "suit": "Clubs" },
    { "rank": "Jack", "suit": "Spades" }
  ],
  "matchState": {
    "score": { "team1": 0, "team2": 0 },
    "dealer": "Bottom",
    "targetScore": 501
  }
}
```

**Réponse :**

```json
{
  "position": 16,
  "fromTop": true
}
```

`position` doit être entre 6 et 26.

### Choisir l'action de négociation

La phase d'enchères. Le moteur vous donne votre main et la liste des actions valides.

**Requête :**

```json
{
  "hand": [
    { "rank": "Ace", "suit": "Hearts" },
    { "rank": "King", "suit": "Hearts" },
    { "rank": "Queen", "suit": "Hearts" },
    { "rank": "Jack", "suit": "Spades" },
    { "rank": "Nine", "suit": "Clubs" }
  ],
  "validActions": [
    { "type": "Announce", "gameMode": "ColourHearts" },
    { "type": "Announce", "gameMode": "AllTrumps" },
    { "type": "Accept" },
    { "type": "Pass" }
  ],
  "negotiationState": {
    "actions": [
      { "player": "Left", "action": { "type": "Announce", "gameMode": "ColourClubs" } }
    ]
  },
  "matchState": {
    "score": { "team1": 150, "team2": 200 },
    "dealer": "Right",
    "targetScore": 501
  }
}
```

**Réponse :** retournez un des objets de `validActions` :

```json
{ "type": "Announce", "gameMode": "ColourHearts" }
```

### Choisir une carte

La décision centrale. Le moteur vous donne le contexte complet du jeu et la liste des cartes légales.

**Requête :**

```json
{
  "hand": [
    { "rank": "Ace", "suit": "Hearts" },
    { "rank": "King", "suit": "Hearts" },
    { "rank": "Seven", "suit": "Clubs" }
  ],
  "validPlays": [
    { "rank": "Ace", "suit": "Hearts" },
    { "rank": "King", "suit": "Hearts" }
  ],
  "handState": {
    "gameMode": "ColourHearts",
    "currentTrick": {
      "leader": "Left",
      "cards": [
        { "card": { "rank": "Ten", "suit": "Hearts" }, "player": "Left" }
      ]
    },
    "completedTricks": [],
    "scores": { "team1": 0, "team2": 0 },
    "multiplier": "None"
  },
  "matchState": {
    "score": { "team1": 150, "team2": 200 },
    "dealer": "Right",
    "targetScore": 501
  }
}
```

**Réponse :** retournez une carte de `validPlays` :

```json
{ "rank": "Ace", "suit": "Hearts" }
```

## `bot.meta.json` pour les bots custom

Quand vous n'utilisez pas de template, vous écrivez ce fichier de zéro. Voici la référence complète des champs :

```json
{
  "name": "my-custom-bot",
  "displayName": "My Custom Bot",
  "pun": "Handcrafted with love",
  "author": "Votre Nom",
  "authorGithub": "votre-pseudo-github",
  "notifications": ["card-played", "trick-completed", "deal-ended"],
  "init": {
    "command": "cargo",
    "arguments": "build --release"
  },
  "launch": {
    "fileName": "./target/release/my-bot",
    "arguments": "",
    "startupTimeout": 10,
    "healthEndpoint": "health"
  }
}
```

| Champ | Requis | Description |
|-------|--------|-------------|
| `name` | Oui | Identifiant unique. Minuscules, sans espaces. Doit correspondre au nom de votre dossier. |
| `displayName` | Oui | Nom lisible pour les classements. |
| `pun` | Non | Un mot d'esprit en guise de tagline. |
| `author` | Non | Votre nom. |
| `authorGithub` | Non | Votre pseudo GitHub. |
| `notifications` | Non | Tableau de types d'événements auxquels s'abonner. Options : `deal-started`, `card-played`, `trick-completed`, `deal-ended`, `match-ended`. |
| `init.command` | Non | Programme à exécuter pour la mise en place (installer les deps, compiler). |
| `init.arguments` | Non | Arguments pour la commande init. |
| `launch.fileName` | Oui | Programme pour démarrer votre serveur. |
| `launch.arguments` | Non | Arguments pour la commande de lancement. |
| `launch.startupTimeout` | Non | Secondes à attendre avant que votre bot soit considéré comme sain (défaut : 15). |
| `launch.healthEndpoint` | Oui | Chemin pour le health check (typiquement `"health"`). |

## Référence du format réseau

Toutes les valeurs sont en JSON. Voici les formes que votre bot enverra et recevra.

### Card

```json
{ "rank": "Ace", "suit": "Hearts" }
```

**Ranks :** `Seven`, `Eight`, `Nine`, `Ten`, `Jack`, `Queen`, `King`, `Ace`

**Suits :** `Clubs`, `Diamonds`, `Hearts`, `Spades`

### PlayerPosition

```json
"Bottom"
```

Une valeur parmi : `Bottom`, `Left`, `Top`, `Right`

Votre bot est toujours `Bottom`. `Left` et `Right` sont les adversaires. `Top` est votre partenaire.

### Team

```json
"Team1"
```

Une valeur parmi : `Team1`, `Team2`

`Team1` = Bottom + Top. `Team2` = Left + Right.

### GameMode

```json
"ColourHearts"
```

Une valeur parmi : `ColourClubs`, `ColourDiamonds`, `ColourHearts`, `ColourSpades`, `NoTrumps`, `AllTrumps`

### NegotiationAction

```json
{ "type": "Announce", "gameMode": "ColourHearts" }
```

Types d'action : `Announce` (avec `gameMode`), `Accept`, `Pass`, `Double`, `Redouble`

### MatchState

```json
{
  "score": { "team1": 150, "team2": 200 },
  "dealer": "Right",
  "targetScore": 501
}
```

### HandState

```json
{
  "gameMode": "ColourHearts",
  "currentTrick": {
    "leader": "Left",
    "cards": [
      { "card": { "rank": "Ten", "suit": "Hearts" }, "player": "Left" }
    ]
  },
  "completedTricks": [],
  "scores": { "team1": 0, "team2": 0 },
  "multiplier": "None"
}
```

### NegotiationState

```json
{
  "actions": [
    { "player": "Left", "action": { "type": "Announce", "gameMode": "ColourClubs" } },
    { "player": "Bottom", "action": { "type": "Pass" } }
  ]
}
```

## Cycle de vie d'un match

Voici la séquence complète des appels que le moteur effectue au cours d'un match. Un match se compose de plusieurs donnes, et chaque donne a une phase de négociation suivie du jeu de cartes.

```
1. POST /api/sessions                     → Créer la session
2. Pour chaque donne :
   a. POST .../notify/deal-started        → (si abonné)
   b. POST .../choose-cut                 → Couper le jeu
   c. Phase de négociation :
      - POST .../choose-negotiation-action  (répété jusqu'à résolution)
   d. Phase de jeu :
      - POST .../choose-card              → Jouer une carte (votre tour)
      - POST .../notify/card-played       → (si abonné, pour chaque carte)
      - POST .../notify/trick-completed   → (si abonné, après chaque pli)
   e. POST .../notify/deal-ended          → (si abonné)
3. POST .../notify/match-ended            → (si abonné)
4. DELETE /api/sessions/{sessionId}       → Nettoyage
```

Le moteur n'appelle vos endpoints de décision que quand c'est votre tour. Vous ne recevrez jamais une requête `choose-card` quand c'est le tour d'un autre joueur. Les endpoints de notification se déclenchent pour les actions de tous les joueurs (si abonné).

## Détails techniques

### Allocation de port

Le moteur définit une variable d'environnement `PORT` avant de démarrer votre bot. Votre serveur doit lire cette variable et écouter sur ce port. Ne codez pas un port en dur.

```
PORT=12345 ./my-bot
```

### Health check

Après avoir démarré votre bot, le moteur interroge `GET /health` jusqu'à recevoir une réponse `200 OK` ou que le `startupTimeout` expire. Assurez-vous que votre endpoint health est disponible dès que votre serveur commence à écouter.

### Isolation des sessions

Chaque match obtient sa propre session via `POST /api/sessions`. Le moteur peut exécuter plusieurs matchs en parallèle, donc votre bot peut avoir plusieurs sessions actives. Gardez l'état de chaque session isolé. Ne partagez pas d'état mutable entre les sessions.

### Timeouts

Le moteur attend des réponses dans un délai raisonnable. Si votre bot met trop de temps, le moteur jouera un coup par défaut à sa place. Visez des temps de réponse inférieurs à 100ms. Le seuil de validation P99 est de 500ms.

### Résilience

Si votre bot plante ou retourne une réponse invalide, le moteur substitue un coup de repli (typiquement un jeu légal aléatoire) et continue le match. Ça ne vous disqualifiera pas, mais ça plombera votre taux de victoire. La commande `validate` signale tous les événements de repli pour que vous puissiez les corriger.
