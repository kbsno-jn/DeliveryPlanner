# Oppsett og drift

## Installasjon

1. Publiser og installer appen i sandkassen først.
2. Er en tidligere versjon med ID-område 62100–62149 installert, må den **avinstalleres med sletting av data**. Objekt-ID-ene er endret, og BC regner dem som nye objekter.
3. Appen kan ikke installeres i samme miljø som **RolleSenter**. Begge bruker page 78900 og pageextension 78901–78902.
4. Når appen oppgraderes fra en versjon uten varsling og godkjenning, får oppsettet standardverdier én gang. Det styres av upgrade tagen `KBS-DELIVERYPLANNER-MONITORING-DEFAULTS-20261016`.

## Sjekkliste for kundens oppsett

| # | Hvor | Hva |
|---|---|---|
| 1 | DeliveryPlanner-oppsett | **Opprett standardoppsett**. Lager kladden DELIVERY/AUTO og kategoriene SMALL, MEDIUM og LARGE |
| 2 | DeliveryPlanner-oppsett | Hovedlager, analyseperiode (56) og minste antall dager på lager (14) |
| 3 | Speditører | Speditørtjenester med transporttid, for eksempel én for nord og én for sør |
| 4 | Overføringsruter | Rute fra hovedlageret til hver butikk, med transittlokasjon og speditørtjeneste |
| 5 | Lokasjoner | Aktiver butikkene, sett kategori (**Angi DeliveryPlanner**), og kryss av leveringsdager på lokasjonskortet |
| 6 | Varekort / Butikksortiment | Makslager, sikkerhetslager og ordremultippel. Aktiver lagerføringsenhetene |
| 7 | E-postkontoer / E-postscenarioer | Velg en konto for scenarioet **DeliveryPlanner** |
| 8 | DeliveryPlanner-oppsett | Varsel til e-post, salgsvarsel (%), godkjenningsfaktor, ordrer i snittet og logglagring |
| 9 | Profiler (roller) | Profilen for Inventory Manager (`SHIPPING AND RECEIVING`) må være aktivert for at kø-delen skal vises |
| 10 | DeliveryPlanner-oppsett | **Beregn DeliveryPlanner** og kontroller avvikslisten |
| 11 | DeliveryPlanner-oppsett | **Opprett nattjobb**, og sett jobbkøposten til **Klar**. Den opprettes som På vent |
| 12 | DeliveryPlanner-oppsett | **Aktivert** = Ja |

## Nattjobben

- Jobbkøkategori DELIVERY. Kjører alle dager kl. 02:00 i tidssonen til jobbkøbrukeren. Maks 3 forsøk, med 300 sekunder mellom forsøkene.
- Jobben **må kjøre hver natt**. Ordre lages bare natten før en leveringsdag. Feiler den natten, får butikken ingen ordre før neste leveringsdag, med mindre noen kjører DeliveryPlanner manuelt.
- Starttiden må ligge etter at salgsimporten er ferdig. Ellers får du salgsvarsel, og påfyllingen kan bli for lav.

## Rettigheter

| Rettighetssett | For |
|---|---|
| **DP ADMIN KBS** (DeliveryPlanner - Administrasjon) | De som vedlikeholder oppsett, sortiment og butikker |
| **DP RUN KBS** (DeliveryPlanner - Kjøring) | Jobbkøbrukeren og de som følger opp: kjøringslogg, avvik, nøkkeltall og butikkordrer |

- Begge settene dekker bare DeliveryPlanner-objekter. Brukerne trenger i tillegg standard tilganger til vare, lagerføringsenhet, lokasjon, rute, speditør, rekvisisjonskladd, planlegging, overføringsordre, reservasjoner og e-post.
- DP RUN KBS gir ikke tilgang til oppsettssiden, butikksortimentet eller dialogen for masseoppdatering av lokasjoner.

## Daglig oppfølging

1. Kø-delen **DeliveryPlanner** i Inventory Manager-rollen: servicegrad, tomme varer, avvik, ordrer til godkjenning og salgsimport.
2. **DeliveryPlanner-avvik**: rett «Mangler oppsett» og følg opp udekket behov.
3. **Ordrer til godkjenning**: frigi eller slett.
4. **DeliveryPlanner-nøkkeltall**: butikker eller kategorier med lav servicegrad over tid.

## Logger

- **DeliveryPlanner-kjøringslogg** viser alle kjøringer med status, tidsbruk, ordretall, salgsvarsel og feilmelding.
- Fra en kjøring kommer du videre til beregningsgrunnlag, forslag og ordre, og avvik.
- Gamle kjøringer slettes etter «Behold kjøringslogg (dager)». 0 beholder alt.
