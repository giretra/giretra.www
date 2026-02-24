---
title: Publier ny Bot-nao
description: Alefaso ny bot-nao ao amin'ny dépôt Giretra ary ataovy azo lalaoina amin'ny play.giretra.com.
---

Ny bot-nao maharesy `RandomPlayer` tsy mila mikofoka. Mahatohitra `CalculatingPlayer` izy. Angamba aza mampijaly `DeterministicPlayer` izy. Fotoana izao hametrahana azy amin'ny internet sy hampiady azy amin'ny mpilalao tena izy.

Ny famoahana ny bot-nao dia midika fanokafana pull request amin'ny dépôt [giretra/giretra](https://github.com/giretra/giretra). Rehefa merged, ny bot-nao dia ho hita amin'ny [play.giretra.com](https://play.giretra.com), ny plateforme multijoueur amin'ny internet izay ifanandrinan'ny olombelona sy bot amin'ny matchs classés.

## Lisitra fanamarinana alohan'ny fandefasana

Alohan'ny hanokafanao PR, alefaso ireto baiko telo ireto avy amin'ny fototry ny clone Giretra anao. Ireo no namana tsara indrindra anao.

### Fanamarinana

```bash
./giretra-manage.sh validate my-bot
```

Ity no **fepetra farany ambany**. Ny fanamarinana dia mampilalao ny bot-nao amin'ny match 100 amin'ny `RandomPlayer` ary manamarina raha misy fandikana fitsipika, crash, sy olana amin'ny fotoana famaliana. Ny tanjonao : **tsy misy fandikana, tsy misy crash**.

Mandrosoa kokoa amin'ireto option ireto :

| Option | Izay ataony |
|--------|------------|
| `-n 500` | Mampitombo ny isan'ny match ho an'ny confiance ambony kokoa |
| `-o CalculatingPlayer` | Mitsapa amin'ny mpifanandrina maranitra kokoa |
| `-d` | Fitsapana déterminisme : milalao indroa amin'ny graine mitovy ary manamarina fa mitovy ny fanapahan-kevitra |
| `-v` | Mode verbeux : mampiseho ny fandikana tsirairay amin'ny antsipiriany |
| `--timeout 200` | Manamarika ny valin-teny mihoatra ny 200ms ho fandikana |

Ny run de validation mafy orina dia toy izao :

```bash
./giretra-manage.sh validate my-bot -n 500 -o CalculatingPlayer -d -v
```

### Benchmark

```bash
./giretra-manage.sh benchmark my-bot CalculatingPlayer -n 500
```

Ny benchmark manome anao ny taha-pandresena miaraka amin'ny intervalle de confiance 95%, ny classement ELO ary ny signification statistique amin'ny match 1000 amin'ny ankapobeny. Ampiasao izy handrefesana tsara ny toeran'ny bot-nao.

Tsapao amin'ny mpifanandrina voarafitra telo :

```bash
./giretra-manage.sh benchmark my-bot RandomPlayer
./giretra-manage.sh benchmark my-bot CalculatingPlayer
./giretra-manage.sh benchmark my-bot DeterministicPlayer
```

Raha tsy maharesy `RandomPlayer` tsy tapaka ny bot-nao, tsy vonona izy. Raha very daholo ny match amin'ny `CalculatingPlayer`, tsara raha manatsara alohan'ny famoahana.

### Tournoi suisse

```bash
./giretra-manage.sh swiss
```

Io baiko io mahita ny bot rehetra (voarafitra sy externe) ary mandefa tournoi au format suisse feno. Mahazo classement farany ianao miaraka amin'ny classement ELO, ny tantaran'ny fandresena/faharesena ary ny vokatra isaky ny paire. Izay no manakaiky indrindra izay hatrehin'ny bot-nao amin'ny plateforme.

Afaka mametra ny mpandray anjara koa ianao :

```bash
./giretra-manage.sh swiss my-bot RandomPlayer CalculatingPlayer DeterministicPlayer
```

### Andramo ao amin'ny navigateur

Alohan'ny fandefasana, tsara ny mahita ny bot-nao miasa ao amin'ny tena interface web. Afaka alefanao eo an-toerana ny [play.giretra.com](https://play.giretra.com) miaraka amin'ny authentification simulée. Voalohany, apetraho ny dépendances frontend :

```bash
cd src/Giretra.Web/ClientApp/giretra-web
npm install
```

Avy eo alefaso ny application avy amin'ny fototry ny dépôt :

```bash
dotnet run --project src/Giretra.Web -- --offline
```

Ny flag `--offline` dia mandefa ny backend ASP.NET sy ny frontend Angular tsy mila service externe. Sokafy ny [http://localhost:4200](http://localhost:4200) mba hidirana ny application, hitadiavana ny bot-nao ary hilalaovana match aminy.

**Araho tsara ny sortie console.** Rehefa manomboka ny application, mahita sy mandefa ny bot externe rehetra izy. Raha tsy mipoitra ny bot-nao (dépendances tsy ampy, erreur de build ao amin'ny script `init`, conflit de port), ny erreur dia hiseho ao amin'ny stdout. Izay ny fomba tsara indrindra hahitana olana izay tsy asetrin'ny fitaovana CLI, toy ny séquence fanombohana simba na olana hita amin'ny interface.

## Fanomanana ny pull request anao

### Inona no tokony ho ao

Ny PR anao dia tokony hisy ny **dossier bot-nao ihany** ao amin'ny `external-bots/`. Izany hoe :

```
external-bots/
  my-bot/
    bot.meta.json
    bot.py (na bot.ts, Bot.cs, bot.go, Bot.java)
    ... (rakitra hafa rehetra ilain'ny bot-nao)
```

Aza manova rakitra ivelan'ny dossier bot-nao. Aza mikitika ny bot hafa, ny moteur, na ny fitaovana CLI.

### Endriky ny lohateny PR

Ny lohateny-n'ny pull request anao **tsy maintsy** manaraka ity syntaxe ity :

```
[Bot:my-bot] Fanazavana fohy
```

Ny `my-bot` dia ny anaran'ny dossier-nao ao amin'ny `external-bots/` tsy misy miova. Ohatra :

- `[Bot:clever-fox] Add card-counting bot in Python`
- `[Bot:rush-player] TypeScript bot with void detection`
- `[Bot:la-machine] First submission of Go bot`

Io convention de nommage io no ampiasain'ny pipeline CI hamantarana ny soumission bot.

### Hamarino ny `bot.meta.json`

Ataovy azo antoka fa feno sy marina ny metadata anao :

```json
{
  "name": "my-bot",
  "displayName": "My Awesome Bot",
  "pun": "I never bluff... except when I do",
  "author": "Anaranao",
  "authorGithub": "github-username-nao"
}
```

- `name` dia tsy maintsy mitovy amin'ny anaran'ny dossier-nao
- `displayName` dia izay hitan'ny mpilalao amin'ny plateforme
- `authorGithub` dia tsy maintsy ny tena GitHub username anao

### Izay jerena amin'ny review

- **Tsy misy fandikana fitsipika** rehefa alefa ny `validate`
- **Tsy misy crash** amin'ny match ampy isa
- **Fotoana famaliana mety** (jereo ny Performance eto ambany)
- **Autonome** : tsy misy appel amin'ny API externe, tsy misy requête réseau mandritra ny lalao
- **Structure dossier madio** : ny rakitry ny bot-nao ihany, tsy misy fako

## Performance

Tsy misy fepetra hentitra momba ny hafainganam-pandeha, fa tadidio : **partie tokana dia afaka mamokatra appel mihoatra ny arivo amin'ny API-n'ny bot-nao**. Eo anelanelan'ny coupe, ny fifampiraharahana, ny karatra alalaovina ary ny événement d'observation, ny moteur miresaka amin'ny bot-nao tsy an-kijanona.

Bot mandany 500ms isaky ny fanapahan-kevitra dia hahatonga ny partie ho mafy loatra ho an'ny olombelona miandry eo andaniny. Kendreo :

| Metrika | Soso-kevitra |
|---------|-------------|
| Fotoana famaliana moy | Latsaky ny 50ms |
| Fotoana famaliana P95 | Latsaky ny 100ms |
| Fotoana famaliana P99 | Latsaky ny 200ms |

Ampiasao `validate` miaraka amin'ny `--timeout` hahitana valeur mihoatra :

```bash
./giretra-manage.sh validate my-bot --timeout 200
```

Torohevitra mba hahatonga ny bot-nao haingana :

- **Ialao ny kajy mavesatra isaky ny appel.** Kajy mialoha izay azo atao mandritra ny événement d'observation na amin'ny fanombohan'ny donne.
- **Ataovy kely ny allocation mémoire.** Ny fanaovana structure de données lehibe isaky ny fanapahan-kevitra dia mitombo amin'ny appel an'arivony.
- **Profilez eo an-toerana.** Raha misy profiler ny fiteny-nao, ampiasao. Goulot d'étranglement manampy 10ms isaky ny appel dia lasa 10 segondra amin'ny partie iray.
- **Tandremo ny fotoana fanombohana.** Ny script `init` dia atao indray mandeha, ka ny asa mavesatra (compilation, chargement modèles) dia ao, fa tsy ao amin'ny méthode de décision.

## Convention ho an'ny bot

Zavatra vitsivitsy tadidina mba hifandraisan'ny bot-nao tsara amin'ny plateforme :

- **Tsy misy état eo anelanelan'ny match.** Ny bot-nao dia mahazo instance vaovao isaky ny match. Aza miankina amin'ny données avy amin'ny match teo aloha.
- **Ny déterminisme dia tombony.** Raha mampiasa hasard ny bot-nao, eritrereto ny fanohanan'ny graine ho an'ny reproductibilité. Ny option `validate -d` no mitsapa izany. Ny bot déterministe dia mora kokoa debuggena sy averina.
- **Tantano ny fomba filalaovana rehetra.** Ny bot-nao dia hiatrika ny fomba filalaovana enina rehetra amin'ny partie classée. Ataovy azo antoka fa tsy crash izy ary tsy mitondra tena hafahafa amin'ny iray amin'ireo. Ny tatitra fanamarinana dia mampiseho ny firakofana ny fomba filalaovana.
- **Aza manao hypothèse an-tsaina.** Ny filaharan'ny karatra, ny fomba fizarana ary ny fitondran-tenan'ny mpifanandrina dia miovaova. Ny bot-nao dia tokony handray fanapahan-kevitra araka izay lazain'ny moteur aminy, fa tsy araka ny séquence andrasana.

## Debugging soumission tsy mandeha

Raha tsy mandeha ny PR anao amin'ny CI na raha misy olana hitan'ny reviewers :

1. **Vakio ny tatitry ny fanamarinana.** Milaza aminao ny tena olana : inona no match, inona no fanapahan-kevitra, inona no nantenaina vs. izay nataon'ny bot-nao.
2. **Alefaso eo an-toerana amin'ny `-v`.** Ny mode verbeux mampiseho ny fandikana tsirairay amin'ny antsipiriany.
3. **Tsapao amin'ny graine voafaritra.** Ampiasao `-s 42` (na isa hafa) hamerenana ny tena séquence lalao mitovy. Mahatonga ny debugging ho déterministe izany.
4. **Hamarino ny script `init` anao.** Raha tsy manomboka ny bot-nao, ny olana matetika dia dépendance tsy ampy na erreur de build amin'ny étape init.
5. **Andramo mpifanandrina samihafa.** Misy bug tsy mipoitra afa-tsy amin'ny stratégie sasany. `CalculatingPlayer` dia tena mahomby amin'ny fampisehoana cas limites satria milalao ouverture maro samihafa izy.

## Aorian'ny fusion ny bot-nao

Rehefa merged ny PR anao :

- Ny bot-nao miseho amin'ny [play.giretra.com](https://play.giretra.com) ary azo atao match classé
- Ny mpilalao afaka mihaika azy na atao match aminy
- Ny classement ELO ny bot-nao manomboka amin'ny 1200 ary miova araka ny vokatra
- Afaka mandefa mise à jour ny bot-nao ianao amin'ny PR vaovao manaraka ny fizotrana mitovy

Te hanatsara ny bot-nao ? Clone, amboary, tsapao, benchmark, PR. Mitovy foana ny fizotrana isaky ny mandeha.

## Hamaky bebe kokoa

- [Manao ny Bot-nao](/mg/build-your-bot/) — Manaova bot avy amin'ny template amin'ny dingana 5
- [Manao avy amin'ny tsy misy](/build-your-bot-custom/) — Fantaro ny protocole ary manaova bot amin'ny fiteny rehetra
- [Fomba fandraisana anjara](/mg/contribute/) — Mandraisa anjara amin'ny projet Giretra ankoatra ny bot
