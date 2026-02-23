---
title: Build from Scratch
description: The raw HTTP protocol for building a Giretra bot in any language.
---

The templates handle HTTP for you, but if you want to roll your own in Rust, Haskell, or whatever, here's how it works under the hood. Plain HTTP, plain JSON. If your language can serve HTTP and parse JSON, you can build a bot.

## Architecture

The engine controls everything. Your bot just responds.

```
┌─────────────────────┐                     ┌─────────────────────┐
│                     │   POST /choose-card  │                     │
│   Giretra Engine    │ ──────────────────►  │      Your Bot       │
│                     │                      │                     │
│  • manages state    │  ◄────────────────── │  • makes decisions  │
│  • enforces rules   │    JSON response     │  • stateless or     │
│  • tracks scores    │                      │    stateful         │
│                     │                      │                     │
└─────────────────────┘                      └─────────────────────┘

         The engine starts your bot, sends HTTP requests,
         and your bot responds with JSON. That's the whole protocol.
```

Your bot is an HTTP server. The engine starts it, sends it requests, and reads the responses. You don't initiate any communication. You just answer when asked.

## The HTTP API

All endpoints are under `/api/sessions/{sessionId}/`. The engine creates a session at the start of each match and sends all subsequent requests scoped to that session.

### Session management

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Liveness check. Return `200 OK`. |
| `POST` | `/api/sessions` | Create a new bot instance for a match. Receives `{ "matchId": "..." }`, return `{ "sessionId": "..." }`. |
| `DELETE` | `/api/sessions/{sessionId}` | Cleanup after match ends. Return `200 OK`. |

### Decision endpoints

These are the three endpoints where your bot actually makes choices.

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/sessions/{sessionId}/choose-cut` | Pick where to cut the deck. |
| `POST` | `/api/sessions/{sessionId}/choose-negotiation-action` | Pick a bidding action. |
| `POST` | `/api/sessions/{sessionId}/choose-card` | Pick a card to play. |

### Notification endpoints (optional)

If your `bot.meta.json` includes a `notifications` array, the engine will POST to these:

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/sessions/{sessionId}/notify/deal-started` | A new deal is beginning. |
| `POST` | `/api/sessions/{sessionId}/notify/card-played` | A card was played by any player. |
| `POST` | `/api/sessions/{sessionId}/notify/trick-completed` | A trick just finished. |
| `POST` | `/api/sessions/{sessionId}/notify/deal-ended` | The deal is over, here are the results. |
| `POST` | `/api/sessions/{sessionId}/notify/match-ended` | The match is over. |

Notification endpoints should return `200 OK`. They're fire-and-forget. The engine doesn't use the response body.

## The 3 decisions

### Choose cut

The engine asks where to cut the deck before each deal.

**Request:**

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

**Response:**

```json
{
  "position": 16,
  "fromTop": true
}
```

`position` must be between 6 and 26.

### Choose negotiation action

The bidding phase. The engine gives you your hand and a list of valid actions.

**Request:**

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

**Response:** return one of the objects from `validActions`:

```json
{ "type": "Announce", "gameMode": "ColourHearts" }
```

### Choose card

The core decision. The engine gives you the full game context and a list of legal cards.

**Request:**

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

**Response:** return one card from `validPlays`:

```json
{ "rank": "Ace", "suit": "Hearts" }
```

## `bot.meta.json` for custom bots

When you're not using a template, you write this from scratch. Here's the full field reference:

```json
{
  "name": "my-custom-bot",
  "displayName": "My Custom Bot",
  "pun": "Handcrafted with love",
  "author": "Your Name",
  "authorGithub": "your-github-username",
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

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier. Lowercase, no spaces. Must match your folder name. |
| `displayName` | Yes | Human-readable name for leaderboards. |
| `pun` | No | A one-liner tagline. |
| `author` | No | Your name. |
| `authorGithub` | No | Your GitHub username. |
| `notifications` | No | Array of event types to subscribe to. Options: `deal-started`, `card-played`, `trick-completed`, `deal-ended`, `match-ended`. |
| `init.command` | No | Program to run for setup (install deps, compile). |
| `init.arguments` | No | Arguments for the init command. |
| `launch.fileName` | Yes | Program to start your server. |
| `launch.arguments` | No | Arguments for the launch command. |
| `launch.startupTimeout` | No | Seconds to wait for your bot to become healthy (default: 15). |
| `launch.healthEndpoint` | Yes | Path for the health check (typically `"health"`). |

## Wire format reference

All values are JSON. Here are the shapes your bot will send and receive.

### Card

```json
{ "rank": "Ace", "suit": "Hearts" }
```

**Ranks:** `Seven`, `Eight`, `Nine`, `Ten`, `Jack`, `Queen`, `King`, `Ace`

**Suits:** `Clubs`, `Diamonds`, `Hearts`, `Spades`

### PlayerPosition

```json
"Bottom"
```

One of: `Bottom`, `Left`, `Top`, `Right`

Your bot is always `Bottom`. `Left` and `Right` are opponents. `Top` is your partner.

### Team

```json
"Team1"
```

One of: `Team1`, `Team2`

`Team1` = Bottom + Top. `Team2` = Left + Right.

### GameMode

```json
"ColourHearts"
```

One of: `ColourClubs`, `ColourDiamonds`, `ColourHearts`, `ColourSpades`, `NoTrumps`, `AllTrumps`

### NegotiationAction

```json
{ "type": "Announce", "gameMode": "ColourHearts" }
```

Action types: `Announce` (with `gameMode`), `Accept`, `Pass`, `Double`, `Redouble`

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

## Match lifecycle

Here's the full sequence of calls the engine makes over a match. A match consists of multiple deals, and each deal has a negotiation phase followed by card play.

```
1. POST /api/sessions                     → Create session
2. For each deal:
   a. POST .../notify/deal-started        → (if subscribed)
   b. POST .../choose-cut                 → Cut the deck
   c. Negotiation phase:
      - POST .../choose-negotiation-action  (repeated until resolved)
   d. Card play phase:
      - POST .../choose-card              → Play a card (your turn)
      - POST .../notify/card-played       → (if subscribed, for every card)
      - POST .../notify/trick-completed   → (if subscribed, after each trick)
   e. POST .../notify/deal-ended          → (if subscribed)
3. POST .../notify/match-ended            → (if subscribed)
4. DELETE /api/sessions/{sessionId}       → Cleanup
```

The engine only calls your decision endpoints when it's your turn. You'll never receive a `choose-card` request when it's someone else's turn. Notification endpoints fire for all players' actions (if subscribed).

## Technical details

### Port allocation

The engine sets a `PORT` environment variable before starting your bot. Your server must read this variable and listen on that port. Do not hardcode a port.

```
PORT=12345 ./my-bot
```

### Health check

After starting your bot, the engine polls `GET /health` until it receives a `200 OK` response or the `startupTimeout` expires. Make sure your health endpoint is available as soon as your server starts listening.

### Session isolation

Each match gets its own session via `POST /api/sessions`. The engine can run multiple concurrent matches, so your bot may have multiple active sessions. Keep session state isolated. Don't share mutable state between sessions.

### Timeouts

The engine expects responses within a reasonable time. If your bot takes too long, the engine will make a default move on your behalf. Aim for sub-100ms response times. The P99 validation threshold is 500ms.

### Resilience

If your bot crashes or returns an invalid response, the engine substitutes a fallback move (typically a random legal play) and continues the match. This won't disqualify you, but it will tank your win rate. The `validate` command reports all fallback events so you can fix them.
