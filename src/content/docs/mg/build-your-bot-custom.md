---
title: Manao avy amin'ny tsy misy
description: Ny protocole HTTP mivantana hanaovana bot Giretra amin'ny fiteny rehetra.
---

Ny template no mitantana ny HTTP ho anao, fa raha te hanao ny anao manokana amin'ny Rust, Haskell, na inona na inona, dia toy izao ny fomba fiasany ao ambadika. HTTP tsotra, JSON tsotra. Raha ny fiteny-nao afaka manompo HTTP sy mamaky JSON, dia afaka manao bot ianao.

## Architecture

Ny moteur no mifehy ny zava-drehetra. Ny bot-nao dia mamaly fotsiny.

```
┌─────────────────────┐                      ┌─────────────────────┐
│                     │   POST /choose-card  │                     │
│   Moteur Giretra    │ ──────────────────►  │     Ny Bot-nao      │
│                     │                      │                     │
│  • mitantana état   │  ◄────────────────── │  • mandray          │
│  • mampihatra       │    valiny JSON       │    fanapahan-kevitra│
│    fitsipika        │                      │  • misy na tsy misy │
│  • manara-maso isa  │                      │    état             │
│                     │                      │                     │
└─────────────────────┘                      └─────────────────────┘

         Ny moteur manomboka ny bot-nao, mandefa requête HTTP,
         ary ny bot-nao mamaly amin'ny JSON. Izay ihany ny protocole.
```

Ny bot-nao dia serveur HTTP. Ny moteur manomboka azy, mandefa requête aminy ary mamaky ny valiny. Tsy ianao no manomboka ny fifandraisana. Mamaly rehefa anontaniana fotsiny ianao.

## Ny API HTTP

Ny endpoint rehetra dia ao amin'ny `/api/sessions/{sessionId}/`. Ny moteur mamorona session amin'ny fanombohan'ny match tsirairay ary mandefa ny requête manaraka rehetra ao anatin'io session io.

### Fitantanana ny session

| Méthode | Lalana | Fanazavana |
|---------|--------|------------|
| `GET` | `/health` | Fitsapana fahasalamana. Avereno `200 OK`. |
| `POST` | `/api/sessions` | Mamorona instance bot vaovao ho an'ny match iray. Mandray `{ "matchId": "..." }`, avereno `{ "sessionId": "..." }`. |
| `DELETE` | `/api/sessions/{sessionId}` | Fanadiovana aorian'ny match. Avereno `200 OK`. |

### Endpoint fanapahan-kevitra

Ireto ny endpoint telo izay tena andraisana fanapahan-kevitra ny bot-nao.

| Méthode | Lalana | Fanazavana |
|---------|--------|------------|
| `POST` | `/api/sessions/{sessionId}/choose-cut` | Misafidiana izay hanapahana ny karatra. |
| `POST` | `/api/sessions/{sessionId}/choose-negotiation-action` | Misafidiana action enchère. |
| `POST` | `/api/sessions/{sessionId}/choose-card` | Misafidiana karatra hilalaovana. |

### Endpoint notification (tsy voatery)

Raha ny `bot.meta.json` anao dia misy tableau `notifications`, ny moteur dia hanao POST amin'ireto :

| Méthode | Lalana | Fanazavana |
|---------|--------|------------|
| `POST` | `/api/sessions/{sessionId}/notify/deal-started` | Donne vaovao manomboka. |
| `POST` | `/api/sessions/{sessionId}/notify/card-played` | Karatra nolalaovina na iza na iza mpilalao. |
| `POST` | `/api/sessions/{sessionId}/notify/trick-completed` | Pli iray vao vita. |
| `POST` | `/api/sessions/{sessionId}/notify/deal-ended` | Vita ny donne, indreto ny vokatra. |
| `POST` | `/api/sessions/{sessionId}/notify/match-ended` | Vita ny match. |

Ny endpoint notification dia tokony hamerina `200 OK`. Fire-and-forget izy ireo. Tsy ampiasain'ny moteur ny vatan'ny valiny.

## Ny fanapahan-kevitra 3

### Misafidiana ny fanapahana

Ny moteur manontany izay hanapahana ny karatra alohan'ny donne tsirairay.

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

**Valiny :**

```json
{
  "position": 16,
  "fromTop": true
}
```

`position` dia tsy maintsy eo anelanelan'ny 6 sy 26.

### Misafidiana ny action fifampiraharahana

Ny fizotran'ny enchère. Ny moteur manome anao ny karatra eny an-tananao sy ny lisitry ny action azo atao.

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

**Valiny :** avereno ny iray amin'ny objet ao amin'ny `validActions` :

```json
{ "type": "Announce", "gameMode": "ColourHearts" }
```

### Misafidiana karatra

Ny fanapahan-kevitra fototra. Ny moteur manome anao ny contexte feno ny lalao sy ny lisitry ny karatra ara-dalàna.

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

**Valiny :** avereno karatra iray avy ao amin'ny `validPlays` :

```json
{ "rank": "Ace", "suit": "Hearts" }
```

## `bot.meta.json` ho an'ny bot custom

Rehefa tsy mampiasa template ianao, soratanao avy amin'ny tsy misy ity rakitra ity. Ity ny tondro feno ho an'ny champs :

```json
{
  "name": "my-custom-bot",
  "displayName": "My Custom Bot",
  "pun": "Handcrafted with love",
  "author": "Anaranao",
  "authorGithub": "github-username-nao",
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

| Champ | Ilaina | Fanazavana |
|-------|--------|------------|
| `name` | Eny | Anarana tokana. Litera kely, tsy misy espace. Tsy maintsy mitovy amin'ny anaran'ny dossier-nao. |
| `displayName` | Eny | Anarana ho an'ny classement. |
| `pun` | Tsia | Teny kely mahafinaritra ho tagline. |
| `author` | Tsia | Ny anaranao. |
| `authorGithub` | Tsia | Ny GitHub username anao. |
| `notifications` | Tsia | Tableau karazana événement iray arahina. Safidy : `deal-started`, `card-played`, `trick-completed`, `deal-ended`, `match-ended`. |
| `init.command` | Tsia | Programme atao ho an'ny fanomanana (mametraka deps, manangona). |
| `init.arguments` | Tsia | Arguments ho an'ny baiko init. |
| `launch.fileName` | Eny | Programme hanombohana ny serveur-nao. |
| `launch.arguments` | Tsia | Arguments ho an'ny baiko de lancement. |
| `launch.startupTimeout` | Tsia | Segondra iandrasana ny bot-nao ho salama (défaut : 15). |
| `launch.healthEndpoint` | Eny | Lalana ho an'ny health check (matetika `"health"`). |

## Tondro ho an'ny format réseau

Ny valeur rehetra dia JSON. Ireto ny endrika halefan'ny bot-nao sy horaisiny.

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

Iray amin'ireto : `Bottom`, `Left`, `Top`, `Right`

Ny bot-nao dia `Bottom` mandrakariva. `Left` sy `Right` dia mpifanandrina. `Top` dia ny mpiara-milalao aminao.

### Team

```json
"Team1"
```

Iray amin'ireto : `Team1`, `Team2`

`Team1` = Bottom + Top. `Team2` = Left + Right.

### GameMode

```json
"ColourHearts"
```

Iray amin'ireto : `ColourClubs`, `ColourDiamonds`, `ColourHearts`, `ColourSpades`, `NoTrumps`, `AllTrumps`

### NegotiationAction

```json
{ "type": "Announce", "gameMode": "ColourHearts" }
```

Karazana action : `Announce` (miaraka amin'ny `gameMode`), `Accept`, `Pass`, `Double`, `Redouble`

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

## Fiainanan'ny match

Ity ny fizotry ny appel rehetra ataon'ny moteur mandritra ny match. Ny match dia misy donne maromaro, ary ny donne tsirairay dia misy fizotram-pifampiraharahana arahina filalaovana karatra.

```
1. POST /api/sessions                     → Mamorona session
2. Ho an'ny donne tsirairay :
   a. POST .../notify/deal-started        → (raha abonné)
   b. POST .../choose-cut                 → Manapaka ny karatra
   c. Fizotram-pifampiraharahana :
      - POST .../choose-negotiation-action  (averina hatramin'ny fahatapiny)
   d. Fizotry ny filalaovana :
      - POST .../choose-card              → Milalao karatra (ny anjaranao)
      - POST .../notify/card-played       → (raha abonné, isaky ny karatra)
      - POST .../notify/trick-completed   → (raha abonné, aorian'ny pli tsirairay)
   e. POST .../notify/deal-ended          → (raha abonné)
3. POST .../notify/match-ended            → (raha abonné)
4. DELETE /api/sessions/{sessionId}       → Fanadiovana
```

Ny moteur dia miantso ny endpoint fanapahan-kevitra rehefa anjaranao ihany. Tsy handray requête `choose-card` mihitsy ianao rehefa anjaran'ny hafa ny milalao. Ny endpoint notification dia mipoaka ho an'ny action-n'ny mpilalao rehetra (raha abonné).

## Antsipiriany teknika

### Fanomezana port

Ny moteur mametraka variable d'environnement `PORT` alohan'ny fanombohana ny bot-nao. Ny serveur-nao dia tsy maintsy mamaky io variable io sy mihaino amin'io port io. Aza manoratra port an-tsaina.

```
PORT=12345 ./my-bot
```

### Health check

Aorian'ny fanombohana ny bot-nao, ny moteur manontany `GET /health` hatramin'ny fahazoana valiny `200 OK` na hatramin'ny fahatapahan'ny `startupTimeout`. Ataovy azo antoka fa ny endpoint health dia vonona raha vao manomboka mihaino ny serveur-nao.

### Fiavahana ny session

Ny match tsirairay dia mahazo session manokana amin'ny `POST /api/sessions`. Ny moteur dia afaka mandefa match maromaro miaraka, ka ny bot-nao dia mety manana session mavitrika maromaro. Avaho tsara ny état-n'ny session tsirairay. Aza mizara état miovaova eo anelanelan'ny session.

### Timeouts

Ny moteur miandry valiny ao anatin'ny fotoana mety. Raha ela loatra ny bot-nao, ny moteur dia hanao coup défaut ho azy. Kendreo fotoana famaliana latsaky ny 100ms. Ny seuil de validation P99 dia 500ms.

### Faharetana

Raha crash ny bot-nao na mamerina valiny tsy mety, ny moteur dia manolo amin'ny coup de repli (matetika filalaovana ara-dalàna kisendrasendra) ary manohy ny match. Tsy hanitsakitsahana anao izany, fa hanadinana ny taha-pandresen'ny bot-nao. Ny baiko `validate` dia milaza ny événement de repli rehetra mba ahafahan'nao manamboatra azy.
