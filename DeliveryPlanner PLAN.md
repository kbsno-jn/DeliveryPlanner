# DeliveryPlanner for Business Central

## Formål

Bygge en AL-utvidelse som hver natt beregner butikkbehov og oppretter **frigjorte overføringsordrer fra hovedlageret**. Fordelingen bygger på salgshistorikk, butikkategori og standard makslager per vare, variant og butikklokasjon.

Ved knapp beholdning brukes kategoriens vekt fra første enhet, slik du valgte. Behov på 100 og 20, vekt 2 og 1 og tilgjengelig mengde 30 gir dermed **20 og 10**.

## Oppsett og brukerflater

- **DeliveryPlanner-oppsett:** Hovedlager, analyseperiode, aktivering og handling for å opprette nattjobben. Standardforslag: 56 avsluttede kalenderdager med salgshistorikk og kjøring kl. 02.00 etter salgsimport, i jobbbrukerens norske tidssone.
- **Butikkategorier:** Redigerbare dekningsdager og fordelingsvekt. Startforslag: liten 7 dager/vekt 1, mellomstor 14 dager/vekt 2 og stor 21 dager/vekt 3.
- **Lokasjoner:** Utvides med butikkategori og aktivering for DeliveryPlanner. Hovedlager og transittlokasjoner kan ikke aktiveres som butikker.
- **Lagerføringsenheter/SKU:** Eget aktiveringsfelt per vare, variant og butikk, avslått som standard. Gjenbruk `Maximum Inventory`, `Safety Stock Quantity`, `Order Multiple`, `Replenishment System` og `Transfer-from Code`. Aktive SKU-er skal forsynes ved overføring fra valgt hovedlager.
- **Sortimentsoversikt:** Redigerbar liste over SKU-aktivering og standard lagergrenser, med filtrering på butikk og kategori.
- **Forhåndsvisning og kjøringslogg:** Vis salgstakt, beholdning, inngående mengder, mål, behov, tildeling, begrensninger og tilhørende ordre. Forhåndsvisningen bruker samme beregningsmotor som nattjobben.

Makslager håndheves som et hardt tak for mengder DeliveryPlanner oppretter. Standard BC-planlegging kan ellers overstige dette feltet gjennom ordremodifikatorer. [Microsofts planleggingsregler](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-handling-reordering-policies).

## Behov og fordelingsregler

Alle beregninger gjøres separat per vare og variant, i basisenheter.

```text
Daglig salg = maks(0, netto bokført salg i analyseperioden) / antall dager

Mål = min(makslager,
          maks(sikkerhetslager, daglig salg × kategoriens dekningsdager))

Lagerposisjon = beholdning + inngående mengder − bundne utgående mengder

Ledig plass = maks(0, makslager − maks(0, beholdning) − inngående mengder)

Behov = min(ledig plass, maks(0, mål − lagerposisjon))
```

- Salg beregnes fra vareposter av typen salg, inklusive returer, til og med gårsdagen. Uten salgshistorikk brukes sikkerhetslager som mål.
- Inngående mengder inkluderer utestående innkjøpsordre og overføringer, også varer underveis, uavhengig av forventet mottaksdato. Hver mengde telles én gang.
- Bundne utgående mengder omfatter åpne salgsordre og overføringer samt øvrige reservasjoner mot fysisk beholdning. Reservasjoner som allerede inngår i ordremengdene trekkes ikke fra på nytt.
- Åpne utgående ordre frigjør først fysisk kapasitet når varene er bokført ut. Forventet salg skal derfor ikke gjøre det mulig å overskride makslageret.
- Hovedlagerets fordelbare mengde er fysisk beholdning minus eksisterende forpliktelser og sikkerhetslager fra hovedlagerets SKU. Fremtidige mottak finansierer ikke nye overføringsordrer.
- Når beholdningen er tilstrekkelig, dekkes beregnet behov. Ved mangel fordeles mengden etter kategorivekt, begrenset av hver butikks behov. Andeler som ikke kan brukes, fordeles videre.
- Behov og tildeling avrundes ned til SKU-ens ordremultippel, ellers basisenhetens antallspresisjon. Restmengder fordeles i gyldige trinn etter størst relativ avrundingsrest, deretter høyeste vekt og lokasjonskode. Behov, tilgjengelig beholdning og makslager skal aldri overskrides.
- Påfylling beregnes hver natt mot målet; `Reorder Point` brukes ikke som utløser. Små butikker kan få null ved svært knapp beholdning eller utilstrekkelig mengde til ett kolli.

## Nattjobb og teknisk gjennomføring

- Lag én overføringsordre per butikk med positiv tildeling, med én linje per vare/variant. Eksisterende ordre inngår i behovsberegningen.
- Bruk standard nummerserie, feltvalideringer, overføringsruter og transittlokasjon. Sett faktisk kjøringsdato og la BC beregne transportdatoene.
- Frigi med standardcodeunit `Release Transfer Document`. Forsendelse og mottak behandles videre i ordinær lagerflyt. [Standard overføringsflyt](https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-transfer-between-locations).
- Bruk standard gjentakende Job Queue for nattkjøring, rettigheter, feilregistrering og nye forsøk. [Job Queue](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-job-queue).
- Serialiser automatiske og manuelle planner-kjøringer med en låst kontrollpost. Beregning, ordreopprettelse, frigivelse og vellykket kjøringsstatus gjennomføres i én transaksjon. Feil ruller alle nye ordre tilbake; feilloggen beholdes.
- Valider aktivt oppsett før ordreopprettelse: positivt makslager, sikkerhetslager innenfor maksimum, gyldig kategori, forsyningskilde, rute og mengdemultippel. Blokkerte varer/varianter utelates med begrunnelse i loggen.
- Tilføy oppsetts-, kategori- og loggtabeller samt utvidelser av Location, SKU og Transfer Header. Ordrene merkes med kjørings-ID for sporbarhet. Beregningsmotoren holdes adskilt fra dokumentopprettelsen.
- Følg `claude.md`: `Src/<objekttype>`, `KBS`-suffiks, objektområde 62100–62149, publisher `Knowit Insight Business Solution AS` og CodeCop/UICop/PerTenantExtensionCop. Behold appens ID og BC 28/runtime 17. Legg til norske tekster og rettighetssett for oppsett og kjøring.

## Tester og innføring

- **Fordeling:** Verifiser 20/10-eksempelet og omfordeling når én butikk når behovsgrensen.
- **Kapasitet:** Beholdning 90, maksimum 100 og åpne salg på 30 tillater høyst 10 nye enheter.
- **Kolli:** Behov 11 og multippel 6 gir høyst 6.
- **Underveis:** Overføring på 20, sendt 12 og mottatt 5 gir 8 utestående fra hovedlageret og 15 inngående til butikken.
- **Reservasjoner:** Beholdning 100 og salgsordre 30, hvorav 20 reservert, gir 70 tilgjengelig før sikkerhetslager.
- **Datavarianter:** Test returer, manglende salgshistorikk, null makslager, varianter, enheter og blokkerte varer.
- **Drift:** Test gjenkjøring uten dobbeltbestilling, samtidige kjøringer og frigivelsesfeil på siste butikk. Ingen delvis opprettede ordre skal bli stående ved feil.
- Kompiler mot tilgjengelige BC 28.4-symboler med analysatorene, og kjør automatiserte AL-tester. Verifiser deretter forhåndsvisning, frigivelse og lagerflyt i sandkassen med et begrenset sortiment før nattjobben aktiveres.
