---
title: Publish Your Bot
description: Submit your bot to the Giretra repository and make it playable on play.giretra.com.
---

Your bot beats `Kialasoa` without breaking a sweat. It holds its own against `Razavavy`. Maybe it even gives `Eva` a hard time. Time to put it online and let real people play against it.

Publishing your bot means opening a pull request on the [giretra/giretra](https://github.com/giretra/giretra) repository. Once merged, your bot becomes available on [play.giretra.com](https://play.giretra.com), the online multiplayer platform where humans and bots compete in ranked matches.

## Pre-flight checklist

Before you open a PR, run these three commands from the root of your Giretra clone. They are your best friends.

### Validate

```bash
./giretra-manage.sh validate my-bot
```

This is the **minimum requirement**. Validation plays your bot through 100 matches against `Kialasoa` and checks for rule violations, crashes, and response time issues. Your target: **zero violations, zero crashes**.

Go further with these flags:

| Flag | What it does |
|------|-------------|
| `-n 500` | Run more matches for higher confidence |
| `-o Razavavy` | Test against a smarter opponent |
| `-d` | Determinism check: runs twice with the same seed and verifies identical decisions |
| `-v` | Verbose mode: shows every violation in detail |
| `--timeout 200` | Flag any response slower than 200ms as a violation |

A solid validation run looks like this:

```bash
./giretra-manage.sh validate my-bot -n 500 -o Razavavy -d -v
```

### Benchmark

```bash
./giretra-manage.sh benchmark my-bot Razavavy -n 500
```

Benchmark gives you win rates with 95% confidence intervals, ELO ratings, and statistical significance over 1000 matches by default. Use it to measure exactly how your bot stacks up.

Test against all three built-in opponents:

```bash
./giretra-manage.sh benchmark my-bot Kialasoa
./giretra-manage.sh benchmark my-bot Razavavy
./giretra-manage.sh benchmark my-bot Eva
```

If your bot can't consistently beat `Kialasoa`, it's not ready. If it loses every game against `Razavavy`, you probably want to iterate before publishing.

### Swiss tournament

```bash
./giretra-manage.sh swiss
```

This discovers all bots (built-in and external) and runs a full Swiss-system tournament. You get a final leaderboard with ELO ratings, win/loss records, and pairwise results. This is the closest thing to what your bot will face on the platform.

You can also limit participants:

```bash
./giretra-manage.sh swiss my-bot Kialasoa Razavavy Eva
```

### Test in the browser

Before submitting, it's worth seeing your bot in action in the real web interface. You can run [play.giretra.com](https://play.giretra.com) locally with mocked authentication. First, install the frontend dependencies:

```bash
cd src/Giretra.Web/ClientApp/giretra-web
npm install
```

Then start the app from the repository root:

```bash
dotnet run --project src/Giretra.Web -- --offline
```

The `--offline` flag runs the ASP.NET backend and the Angular frontend without needing any external services. Open [http://localhost:4200](http://localhost:4200) to access the app, find your bot, and play a match against it.

**Watch the console output carefully.** When the app starts, it discovers and launches all external bots. If your bot fails to load (missing dependencies, build errors in your `init` script, port conflicts), the error will appear in stdout. This is the best way to catch issues that the CLI tools won't surface, like broken startup sequences or UI-facing problems.

## Preparing your pull request

### What to include

Your PR should contain **only your bot folder** inside `external-bots/`. That means:

```
external-bots/
  my-bot/
    bot.meta.json
    bot.py (or bot.ts, Bot.cs, bot.go, Bot.java)
    ... (any other files your bot needs)
```

Do not modify files outside your bot folder. Do not touch other bots, the engine, or the CLI tools.

### PR title format

Your pull request title **must** follow this syntax:

```
[Bot:my-bot] Short description
```

Where `my-bot` is exactly the name of your folder inside `external-bots/`. Examples:

- `[Bot:clever-fox] Add card-counting bot in Python`
- `[Bot:rush-player] TypeScript bot with void detection`
- `[Bot:la-machine] First submission of Go bot`

This naming convention is how the CI pipeline identifies bot submissions.

### Double-check `bot.meta.json`

Make sure your metadata is complete and accurate:

```json
{
  "name": "my-bot",
  "displayName": "My Awesome Bot",
  "pun": "I never bluff... except when I do",
  "author": "Your Name",
  "authorGithub": "your-github-username"
}
```

- `name` must match your folder name exactly
- `displayName` is what players see on the platform
- `authorGithub` must be your actual GitHub username

### What reviewers look for

- **Zero rule violations** when running `validate`
- **No crashes** over a reasonable number of matches
- **Reasonable response times** (see Performance below)
- **Self-contained**: no calls to external APIs, no network requests during play
- **Clean folder structure**: only your bot's files, no leftover junk

## Performance

There is no strict speed requirement, but keep in mind: **a single game can generate over a thousand calls to your bot's API**. Between cuts, negotiations, card plays, and observation events, the engine talks to your bot constantly.

A bot that takes 500ms per decision will make games painfully slow for the human waiting on the other side. Aim for:

| Metric | Recommended |
|--------|-------------|
| Average response time | Under 50ms |
| P95 response time | Under 100ms |
| P99 response time | Under 200ms |

Use `validate` with `--timeout` to catch outliers:

```bash
./giretra-manage.sh validate my-bot --timeout 200
```

Tips for keeping your bot fast:

- **Avoid heavy computation on every call.** Precompute what you can during observation events or at the start of a deal.
- **Keep memory allocation minimal.** Creating large data structures per decision adds up over thousands of calls.
- **Profile locally.** If your language has a profiler, use it. A bottleneck that adds 10ms per call becomes 10 seconds over a game.
- **Watch your startup time.** The `init` script runs once, so heavy setup (compiling, loading models) belongs there, not in the decision methods.

## Bot conventions

A few things to keep in mind so your bot plays well with the platform:

- **Stateless between matches.** Your bot gets a fresh instance per match. Don't rely on data from previous matches.
- **Determinism is a plus.** If your bot uses randomness, consider supporting a seed for reproducibility. The `validate -d` flag tests this. Deterministic bots are easier to debug and reproduce issues with.
- **Handle all game modes.** Your bot will face all six game modes in ranked play. Make sure it doesn't crash or behave strangely in any of them. The validate report shows game mode coverage.
- **Don't hardcode assumptions.** Card order, dealing patterns, and opponent behavior will vary. Your bot should make decisions based on what the engine tells it, not on expected sequences.

## Debugging a failing submission

If your PR fails CI or reviewers flag issues:

1. **Read the validation report.** It tells you exactly what went wrong: which match, which decision, what was expected vs. what your bot did.
2. **Run locally with `-v`.** Verbose mode shows every violation in detail.
3. **Test with a fixed seed.** Use `-s 42` (or any number) to reproduce the exact same game sequence. This makes debugging deterministic.
4. **Check your `init` script.** If your bot fails to start, the issue is often a missing dependency or a build error in the init step.
5. **Try different opponents.** Some bugs only surface against certain strategies. `Razavavy` is particularly good at exposing edge cases because it plays more varied openings.

## After your bot is merged

Once your PR is merged:

- Your bot appears on [play.giretra.com](https://play.giretra.com) and is available for ranked matches
- Players can challenge it or get matched against it
- Your bot's ELO rating starts at 1200 and adjusts based on match results
- You can submit updates to your bot with new PRs following the same process

Want to improve your bot? Clone, iterate, validate, benchmark, PR. The cycle is the same every time.

## Further reading

- [Getting Started](/build-your-bot/) — Build your bot from a template in 5 steps
- [Build from Scratch](/build-your-bot-custom/) — Understand the protocol and build a bot in any language
- [How to Contribute](/contribute/) — Contribute to the Giretra project beyond bots
