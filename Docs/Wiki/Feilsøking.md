# Feilsøking

## Kjøringen

| Symptom | Årsak | Løsning |
|---|---|---|
| Kjøringen har status **Mislykket** | Feil i hovedoppsettet: hovedlager, kladd, analyseperiode eller ingen aktive varer | Les **Feilmelding** i kjøringsloggen. Ingen ordrer fra kjøringen er lagret |
| «Kladden … inneholder linje … som ikke eies av DeliveryPlanner» | Noen har lagt linjer i den dedikerte kladden utenom DeliveryPlanner | Slett linjene, eller velg en annen kladd i oppsettet |
| «Du har ikke hentet en datarad for denne spørringen ennå» | Feil i eldre versjon av salgstakten, når en vare ikke hadde vareposter i perioden | Oppgrader til versjonen fra `new_feature` |
| En butikk får ingen ordre | Ordren ville ikke kommet frem på en leveringsdag | Se begrunnelsen «Ingen levering fra denne kjøringen. Neste levering …». Dette er forventet |
| Linje med **Mangler oppsett** | Feil i oppsettet av butikken eller lagerføringsenheten | Les begrunnelsen. Resten av kjøringen går som normalt |
| «Ingen leveringsdag innen 28 dager» | Leveringsdagene og transporttiden passer ikke sammen | Kontroller leveringsdagene og speditørtjenesten på ruten |
| «Har forslag i kladden …» | En annen rekvisisjonskladd har linjer for samme vare og butikk | Behandle eller slett linjene i den andre kladden |
| Lavere påfylling enn forventet etter natten | Salget var ikke bokført da jobben kjørte | Se **Salgsvarsel** i kjøringen. Flytt starttiden, eller kjør manuelt |
| Mange tomme butikker og udekket behov | Hovedlageret har for lite | Følg opp innkjøp til hovedlageret. DeliveryPlanner planlegger ikke innkjøp |

## Oppfølging

| Symptom | Årsak | Løsning |
|---|---|---|
| Kø-delen vises ikke | Brukeren har ikke Inventory Manager-rollen, eller profilen er deaktivert | Aktiver profilen under **Profiler (roller)**, eller åpne sidene fra søk |
| Avvikslisten viser ikke nattens resultat | Noen har kjørt **Beregn** etter nattjobben | Listen viser siste kjøring. Åpne avvik fra riktig kjøring i kjøringsloggen |
| Ingen e-post | Mangler adresse, konto, eller jobben kjører i forgrunnen | Fyll ut «Varsel til e-post» og velg en konto for scenarioet DeliveryPlanner. Manuelle kjøringer sender ikke e-post |
| Tre like e-poster om feil | Jobbkøen prøver tre ganger | Forventet |
| «Overføringsordre» i forslagsloggen er grå | Forslaget ble aldri en ordre: Beregn, eller tildelt 0 | Forventet |
| Ordre står med **Venter på godkjenning** | Ordren er mer enn faktoren × snittet av butikkens siste ordrer | Frigi for å godkjenne, eller slett ordren |

## Oppsett

| Symptom | Årsak | Løsning |
|---|---|---|
| Butikkategorier som LITEN og STOR i tillegg til SMALL og LARGE | Lagt inn for hånd | Behold SMALL, MEDIUM og LARGE. Flytt butikkene over, og slett de andre etterpå |
| Makslager fra varekortet kommer ikke på lagerføringsenhetene | Butikken har en annen kategori enn SMALL, MEDIUM eller LARGE, eller verdien på varekortet er 0 | Rett kategorien, og velg **Opprett standardoppsett** på nytt |
| «Angi hovedlager før lagerføringsenheter kan opprettes …» | Hovedlager mangler i oppsettet | Fyll ut Hovedlager |
| Alle lokasjoner ble endret med Angi DeliveryPlanner | Bare én linje var merket, så hele filteret ble endret | Merk flere linjer, eller filtrer listen først |

## Utvikling

| Symptom | Årsak | Løsning |
|---|---|---|
| VS Code viser feil som ikke stemmer | AL-språktjenesten har ikke lest filene på nytt | **Developer: Reload Window** |
| «Table 62100 er allerede i bruk» ved publisering | Gammelt ID-område | Bruk versjonen med 78900–78950 |
| Publisering feiler etter at ID-området er endret | Gammel versjon er installert | Avinstaller med sletting av data |
| `Build.ps1`: «alc.exe is not recognized» | Endret mappestruktur i AL-utvidelse 18.1, eller ARM64 | Kompiler med `dotnet alc.dll`, se [Utvikling](Utvikling) |
