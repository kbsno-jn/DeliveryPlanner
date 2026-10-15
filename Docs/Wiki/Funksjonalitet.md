# Funksjonalitet

Alle mengder er i basisenhet og beregnes per vare, variant og butikk. Bare lagerføringsenheter med **DeliveryPlanner aktivert**, i butikker med **DeliveryPlanner aktivert**, er med.

## Tre måter å kjøre på

| Handling | Hva skjer | Ordrer |
|---|---|---|
| **Beregn DeliveryPlanner** | Fyller den dedikerte rekvisisjonskladden med forslag | Nei |
| **Kjør DeliveryPlanner** | Beregner på nytt, oppretter og frigir overføringsordrer | Ja |
| **Nattjobb** (Job Queue) | Som «Kjør», og sender e-post ved feil eller når noe må følges opp | Ja |

Den dedikerte kladden er låst. Linjene endres bare gjennom disse handlingene.

## 1. Salgstakt uten utsolgte dager

Analyseperioden er «Dager med salgshistorikk» (standard 56) avsluttede kalenderdager, til og med i går.

```text
På lager (per dag) = beholdning ved start > 0  eller  ved slutt > 0  eller  salg den dagen
Daglig salg        = netto solgt / maks(dager på lager, min(Minste dager på lager, analysedager))
```

- Dager uten beholdning ser ellers ut som dager uten etterspørsel. Varen får da for lite og blir utsolgt igjen.
- «Minste antall dager på lager» (standard 14) hindrer at noen få dager med salg gir en urealistisk høy salgstakt.
- 56 er 8 hele uker, så alle ukedager teller like mye. Velg et tall som er delelig med 7 hvis du endrer det.

## 2. Leveringsdager og dekning

- Lokasjonskortet har sju avkrysningsfelt for dagene varer **kommer frem** til butikken.
- Mottaksdatoen regnes ut slik BC regner den på overføringsordren: lagerhåndteringstid på hovedlageret, transporttid fra speditørtjenesten på overføringsruten og lagerhåndteringstid i butikken. Basiskalendere tas med.
- **Leveres nå:** Ordren kommer frem på en leveringsdag. Bare da får butikken ordre fra kjøringen.
- **Dekningsdager:** Antall dager fra planleggingsdatoen til neste mulige mottak på en leveringsdag (søker inntil 28 dager frem).
- Butikker **uten** leveringsdager fylles hver natt med kategoriens dekningsdager, som i første versjon.

```text
Lagermål = min(Makslager, maks(Sikkerhetslager, Daglig salg × Dekningsdager))
Behov    = min(Ledig plass under makslager, maks(0, Lagermål − (Beholdning + Inngående − Utgående)))
```

Makslager er et absolutt tak. Utgående ordrer reduserer lagerposisjonen, men gir ikke ledig plass før varene er bokført ut.

## 3. Fordeling ved mangel

Har hovedlageret mindre enn butikkene trenger, fylles butikkene opp til et felles nivå T i dager med dekning:

```text
tildeling = min(behov, maks(0, T × daglig forbruk − lagerposisjon))
```

- **Eksempel:** Hovedlageret har 12. Butikk A selger 2 per dag og er tom. Butikk B selger 6 per dag og har 30 på lager (5 dagers dekning). Da får A 10 og B 2.
- Varer uten salg bruker lagermål / dekningsdager som forbruk, så de også er med i fordelingen.
- Resultatet rundes ned til ordremultippel. Restmengden fordeles i hele kolli etter størst avrundingsrest, deretter kategorivekt, deretter lokasjonskode.
- Kategoriens **fordelingsvekt** avgjør altså bare når butikker står likt.

## 4. Avvik

Hver beregningslinje får det viktigste avviket. Siden **DeliveryPlanner-avvik** viser bare linjer med avvik fra siste kjøring.

| Avvik | Når |
|---|---|
| Mangler oppsett | Butikken eller lagerføringsenheten er feil satt opp. Linjen hoppes over, mens resten av kjøringen går som normalt |
| Tom – udekket behov | Tom i butikken, og hovedlageret hadde for lite |
| Udekket behov | Butikken fikk mindre enn behovet fordi hovedlageret hadde for lite |
| Tom i butikk | Beholdning ≤ 0 da kjøringen startet |
| Over makslager | Beholdning + inngående er større enn makslageret |
| Venter på godkjenning | Butikkens ordre er holdt tilbake (se 7) |

Feil i hovedoppsettet stopper fortsatt hele kjøringen. Det gjelder for eksempel manglende hovedlager, feil kladd eller ingen aktive varer.

## 5. Nøkkeltall

- **DeliveryPlanner-nøkkeltall** viser én linje per butikk og per kategori: servicegrad, snitt dager med dekning, tomme varer, over makslager, overlager, udekket antall og avvik.
- **Servicegrad** = sum dager på lager / (antall linjer × analysedager).
- Kø-delen **DeliveryPlanner** i Inventory Manager-rollen viser servicegrad, dekning, tomme varer, avvik, ordrer til godkjenning og status for salgsimporten.
- Både avvikslisten og nøkkeltallene viser siste kjøring med status Fullført eller Beregnet.

## 6. Varsling og salgskontroll

- **Salgskontroll:** Kjøringen teller butikker der ingen aktiv vare ble solgt i går. Er andelen over «Varsle ved manglende salg (%)» (standard 50), settes salgsvarsel. Planen beregnes uansett.
- **E-post** sendes bare fra nattjobben, til «Varsel til e-post», med e-postscenarioet **DeliveryPlanner**:
  - når kjøringen feiler, opptil tre ganger fordi jobbkøen prøver tre ganger
  - når salg mangler eller ordrer venter på godkjenning
- Feil i e-postsendingen stopper aldri kjøringen.

## 7. Godkjenning av store ordrer

- Hver ny ordre sammenlignes med snittet av butikkens siste 4 frigitte eller godkjente ordrer.
- Er den mer enn 2 ganger snittet, blir den liggende **åpen** med status Venter på godkjenning.
- **Godkjenne:** Frigi ordren med standard **Frigi**. **Avvise:** Slett ordren.
- En åpen ordre teller som varer på vei neste natt, så butikken får ikke dobbelt opp.
- Butikker med færre enn 4 tidligere ordrer blir ikke vurdert.
- Faktor og antall ordrer kan endres i oppsettet. Faktor 0 slår av godkjenningen.

## 8. Makslager fra varekortet

- Varekortet har fanen **Delivery planner** med makslager for liten, mellomstor og stor butikk.
- «Opprett standardoppsett» overfører verdiene til lagerføringsenhetene i aktive butikker med kategori **SMALL**, **MEDIUM** eller **LARGE**. Kodene er låst.
- Lagerføringsenheter som mangler, opprettes med overføring fra hovedlageret. De aktiveres ikke automatisk.

## 9. Masseoppdatering av butikker

- **Lokasjoner → Angi DeliveryPlanner** setter aktivering og butikkategori på de merkede lokasjonene.
- Er bare én linje merket, gjelder endringen alle lokasjonene i filteret. Dialogen viser antallet før du trykker OK.

## 10. Opprydding

Kjøringer eldre enn «Behold kjøringslogg (dager)» (standard 90) slettes ved neste kjøring, sammen med beregningslinjer og forslag. Butikkordrene beholdes, fordi godkjenningen bruker dem.
