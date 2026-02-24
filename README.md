# Giretra

Documentation and community website for [Giretra](https://play.giretra.com), an open-source Malagasy trick-taking card game for 4 players in 2 teams.

The site covers game rules, bot development guides, and contribution guidelines — available in English, French, and Malagasy.

## Build

```bash
npm install
npm run dev      # dev server on localhost:4321
npm run build    # production build to ./dist/
```

## Translations

Content lives in `src/content/docs/`:

```
src/content/docs/
├── *.md(x)      # English (default)
├── fr/          # French
└── mg/          # Malagasy
```

UI strings are in `src/content/i18n/{en,fr,mg}.json`.

## Links

- Play: https://play.giretra.com
- Game engine: https://github.com/giretra/giretra
