---
title: Créer de zéro
description: Le protocole HTTP brut pour créer un bot Giretra dans n'importe quel langage.
---

Les templates gèrent le HTTP à votre place, mais si vous voulez tout construire vous-même en Rust, Haskell ou autre, voici comment ça fonctionne sous le capot. Du HTTP basique, du JSON basique. Si votre langage sait servir du HTTP et parser du JSON, vous pouvez créer un bot.

## Architecture

Le moteur contrôle tout. Votre bot se contente de répondre.

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

         Le moteur démarre votre bot, lui envoie des requêtes HTTP,
         et votre bot répond en JSON. C'est tout le protocole.
```

Votre bot est un serveur HTTP. Le moteur le démarre, lui envoie des requêtes et lit les réponses. Vous n'initiez jamais la communication. Vous répondez quand on vous le demande, point.

## L'API HTTP

Tous les endpoints sont sous `/api/sessions/{sessionId}/`. Le moteur crée une session au début de chaque match et y rattache toutes les requêtes suivantes.

### Gestion des sessions

| Méthode | Chemin | Description |
|---------|--------|-------------|
| `GET` | `/health` | Vérification de vie. Renvoyez `200 OK`. |
| `POST` | `/api/sessions` | Crée une nouvelle instance de bot pour un match. Reçoit `{ "matchId": "..." }`, renvoyez `{ "sessionId": "..." }`. |
| `DELETE` | `/api/sessions/{sessionId}` | Nettoyage en fin de match. Renvoyez `200 OK`. |

### Endpoints de décision

Ce sont les trois endpoints où votre bot fait réellement ses choix.

| Méthode | Chemin | Description |
|---------|--------|-------------|
| `POST` | `/api/sessions/{sessionId}/choose-cut` | Choisir où couper le jeu. |
| `POST` | `/api/sessions/{sessionId}/choose-negotiation-action` | Choisir une action d'enchère. |
| `POST` | `/api/sessions/{sessionId}/choose-card` | Choisir une carte à jouer. |

### Endpoints de notification (optionnel)

Si votre `bot.meta.json` contient un tableau `notifications`, le moteur fera des POST vers ceux-ci :

| Méthode | Chemin | Description |
|---------|--------|-------------|
| `POST` | `/api/sessions/{sessionId}/notify/deal-started` | Une nouvelle donne commence. |
| `POST` | `/api/sessions/{sessionId}/notify/card-played` | Une carte a été jouée par n'importe quel joueur. |
| `POST` | `/api/sessions/{sessionId}/notify/trick-completed` | Un pli vient de se terminer. |
| `POST` | `/api/sessions/{sessionId}/notify/deal-ended` | La donne est terminée, voici les résultats. |
| `POST` | `/api/sessions/{sessionId}/notify/match-ended` | Le match est terminé. |

Les endpoints de notification doivent renvoyer `200 OK`. Ils fonctionnent en fire-and-forget : le moteur n'utilise pas le corps de la réponse.

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

`position` doit être compris entre 6 et 26.

### Choisir l'action d'enchère

C'est la phase de négociation. Le moteur vous transmet votre main et la liste des actions possibles.

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

**Réponse :** renvoyez un des objets de `validActions` :

```json
{ "type": "Announce", "gameMode": "ColourHearts" }
```

### Choisir une carte

La décision centrale. Le moteur vous fournit le contexte complet de la partie et la liste des cartes jouables.

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

**Réponse :** renvoyez une carte parmi `validPlays` :

```json
{ "rank": "Ace", "suit": "Hearts" }
```

## `bot.meta.json` pour les bots custom

Sans template, c'est à vous d'écrire ce fichier. Voici la référence complète :

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
| `pun` | Non | Une petite phrase en guise de tagline. |
| `author` | Non | Votre nom. |
| `authorGithub` | Non | Votre pseudo GitHub. |
| `notifications` | Non | Tableau de types d'événements auxquels s'abonner. Options : `deal-started`, `card-played`, `trick-completed`, `deal-ended`, `match-ended`. |
| `init.command` | Non | Programme à exécuter pour la mise en place (installer les dépendances, compiler). |
| `init.arguments` | Non | Arguments de la commande init. |
| `launch.fileName` | Oui | Programme pour démarrer votre serveur. |
| `launch.arguments` | Non | Arguments de la commande de lancement. |
| `launch.startupTimeout` | Non | Délai en secondes avant que le bot soit considéré comme non-fonctionnel (défaut : 15). |
| `launch.healthEndpoint` | Oui | Chemin pour le health check (en général `"health"`). |

## Référence du format réseau

Toutes les valeurs sont en JSON. Voici les structures que votre bot enverra et recevra.

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

Valeurs possibles : `Bottom`, `Left`, `Top`, `Right`

Votre bot est toujours `Bottom`. `Left` et `Right` sont les adversaires. `Top` est votre partenaire.

### Team

```json
"Team1"
```

Valeurs possibles : `Team1`, `Team2`

`Team1` = Bottom + Top. `Team2` = Left + Right.

### GameMode

```json
"ColourHearts"
```

Valeurs possibles : `ColourClubs`, `ColourDiamonds`, `ColourHearts`, `ColourSpades`, `NoTrumps`, `AllTrumps`

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

Voici la séquence complète des appels que le moteur effectue au cours d'un match. Un match se compose de plusieurs donnes, chacune avec une phase d'enchères suivie du jeu de cartes.

```
1. POST /api/sessions                     → Créer la session
2. Pour chaque donne :
   a. POST .../notify/deal-started        → (si abonné)
   b. POST .../choose-cut                 → Couper le jeu
   c. Phase d'enchères :
      - POST .../choose-negotiation-action  (répété jusqu'à résolution)
   d. Phase de jeu :
      - POST .../choose-card              → Jouer une carte (votre tour)
      - POST .../notify/card-played       → (si abonné, pour chaque carte)
      - POST .../notify/trick-completed   → (si abonné, après chaque pli)
   e. POST .../notify/deal-ended          → (si abonné)
3. POST .../notify/match-ended            → (si abonné)
4. DELETE /api/sessions/{sessionId}       → Nettoyage
```

Le moteur n'appelle vos endpoints de décision que quand c'est à vous de jouer. Vous ne recevrez jamais de requête `choose-card` quand c'est le tour d'un autre joueur. Les endpoints de notification, eux, se déclenchent pour les actions de tous les joueurs (si vous y êtes abonné).

## Détails techniques

### Allocation de port

Le moteur définit une variable d'environnement `PORT` avant de démarrer votre bot. Votre serveur doit lire cette variable et écouter sur ce port. Ne codez jamais un port en dur.

```
PORT=12345 ./my-bot
```

### Health check

Après le démarrage de votre bot, le moteur interroge `GET /health` en boucle jusqu'à recevoir un `200 OK` ou atteindre le `startupTimeout`. Assurez-vous que votre endpoint health répond dès que le serveur écoute.

### Isolation des sessions

Chaque match a sa propre session via `POST /api/sessions`. Le moteur peut lancer plusieurs matchs en parallèle, donc votre bot peut avoir plusieurs sessions actives simultanément. Gardez l'état de chaque session bien cloisonné. Pas d'état mutable partagé entre les sessions.

### Timeouts

Le moteur attend une réponse dans un délai raisonnable. Si votre bot met trop de temps, le moteur joue un coup par défaut à sa place. Visez des temps de réponse inférieurs à 100ms. Le seuil P99 de la validation est fixé à 500ms.

### Résilience

Si votre bot plante ou renvoie une réponse invalide, le moteur lui substitue un coup de repli (en général un jeu légal aléatoire) et continue le match. Ça ne vous disqualifie pas, mais ça plombera votre taux de victoire. La commande `validate` signale tous ces coups de repli pour que vous puissiez les corriger.
