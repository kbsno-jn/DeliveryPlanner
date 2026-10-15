# DeliveryPlanner – Power BI-prosjekt

Power BI-prosjekt (PBIP) med datamodell (TMDL) og rapport (PBIR) for DeliveryPlanner. Rapporten har tre faner:

| Fane | Innhold |
|---|---|
| **Ledelse** | Tilgjengelighet, endring mot forrige 28 dager, overlager og udekket behov i kroner, trend per uke, butikker og uker, tapte salgsdager per varekategori |
| **Innkjøp** | Mangel på hovedlageret, varer som ofte er tomme, overlager per vare og butikk, avvik siste natt |
| **Lager og logistikk** | Enheter sendt, ordrer til godkjenning, nattjobb, enheter per ukedag og butikk, siste natt per butikk, butikkordrer |

Spesifikasjonen med begrunnelser står i `Docs/PowerBI/DeliveryPlanner - Power BI-rapport.md`.

## Forutsetninger

- DeliveryPlanner med API-sidene (publisher `knowit`, gruppe `deliveryPlanner`, `v1.0`) er installert i BC.
- Kontoen du logger på med har rettighetssettet **DP API KBS** og lesetilgang til varer, for eksempel **D365 READ**.
- Power BI Desktop er av nyere versjon. Prosjektet er laget og validert mot versjon 2.158.

## Slik åpner du rapporten

1. Åpne `DeliveryPlanner.pbip` i Power BI Desktop.
2. Velg **Transformer data → Rediger parametere** og fyll inn:
   - **Tenant**: kundens tenant-ID (GUID)
   - **Miljo**: navnet på BC-miljøet, for eksempel `Production`
   - **FirmaId**: ID-en (GUID) til firmaet
   - **RangeStart** og **RangeEnd**: la stå. De brukes av inkrementell oppdatering.
3. Velg **Organisasjonskonto** og logg inn når Power BI ber om det. Bruk kontoen som har tilgang hos kunden, også om det er en Knowit-konto.
4. Velg **Oppdater**.

## Finne tenant, miljø og firma-ID

Kildene er adresser mot `https://api.businesscentral.dynamics.com/v2.0/<Tenant>/<Miljo>/api/...`. Fordi kundens tenant står i adressen, kan du logge inn med en Knowit-konto og likevel lese kundens data. Business Central-koblingen i Power BI kobler seg derimot alltid til kontoens egen tenant.

| Verdi | Hvor du finner den |
|---|---|
| **Tenant** | Logg inn i kundens BC. Adressen er `https://businesscentral.dynamics.com/<tenant-ID>/<miljø>/…`. Står det et domenenavn i stedet for en GUID, finner du ID-en under **?** → **Hjelp og støtte** → **Feilsøking** (Entra-tenant-ID) |
| **Miljo** | Del to av samme adresse, eller miljønavnet i **Business Central Admin Center** |
| **FirmaId** | I Power BI Desktop: **Hent data → OData-feed** med `https://api.businesscentral.dynamics.com/v2.0/<Tenant>/<Miljo>/api/v2.0/companies`. Logg inn med **Organisasjonskonto**, og kopier `id` for riktig firma. Adressen kan ikke åpnes direkte i nettleseren, fordi API-et krever token |

### Tilgang med Knowit-konto

- **Gjestebruker:** Knowit-kontoen må være lagt til som bruker i kundens BC, med lisens og rettighetssettene **DP API KBS** og **D365 READ**. Det fungerer for API-er og Power BI.
- **Delegert administrator (GDAP):** Delegerte administratorer har begrensninger i BC. Tilgang via API og Power BI er ikke sikker. Får du 401 eller 403 selv om du kommer inn i BC i nettleseren, må kunden legge deg til som gjestebruker, eller opprette en egen bruker for rapporten. [AVKLARES: tilgangstype mot kunden]
- **Planlagt oppdatering i Power BI-tjenesten** bruker legitimasjonen som er satt på datasettet. Bruk en konto som blir værende, ikke en personlig konto som slutter. Publiser helst rapporten i kundens Power BI-tenant.

## Kontroller ved første oppdatering

- **Avvik:** Tabellen `Avvik` mapper enum-verdiene fra API-et (for eksempel `Missing_x0020_Setup`) til norsk tekst. Vises avvik som tomme i rapporten, sammenlign kolonnen Avvikskode i `Beregning` med `Avvik`, og rett mappingen i Power Query.
- **Status og godkjenning:** `Kjøring[Statuskode]` og `Butikkordre[Godkjenningskode]` brukes i målene. Verdiene skal være `Completed` og `Awaiting_x0020_Approval`.
- **Datatabell:** Tabellen `Dato` starter 1.1.2025 og slutter ved utgangen av inneværende år. Endre `Start` i Power Query hvis dere har eldre data.

## Publisering

1. **Publiser** til ønsket arbeidsområde. [AVKLARES: arbeidsområde]
2. Sett opp **inkrementell oppdatering** på tabellene `Beregning` og `Butikkordre`, filtrert på `Planleggingsdato`. Anbefalt: lagre 2 år og oppdater siste 7 dager for `Beregning`, og siste 30 dager for `Butikkordre`.
3. Sett **planlagt oppdatering** én gang i døgnet, etter nattjobben, for eksempel kl. 06:00.
4. Del rapporten, eller lag en Power BI-app med én fane per målgruppe.

BC sletter kjøringer eldre enn «Behold kjøringslogg (dager)», standard 90. Inkrementell oppdatering beholder historikken i Power BI.

## Datamodell

| Tabell | Innhold |
|---|---|
| `Beregning` | Én rad per vare, variant og butikk per natt, fra nattens siste fullførte kjøring |
| `Butikkordre` | Opprettede overføringsordrer |
| `Kjøring` | Alle kjøringer, til oppfølging av driften |
| `Dato`, `Butikk`, `Kategori`, `Vare`, `Avvik` | Dimensjoner |
| `_Mål` | 34 DAX-mål i mappene Grunnlag, Tilgjengelighet, Tomme varer, Mangel, Lager, Avvik, Ordrer og Drift |

Beregningen er et øyeblikksbilde per natt. Beholdning, tomme varer og overlager summeres derfor aldri over flere netter. Målene merket «siste natt» bruker siste dato i utvalget.

## Endringer

Prosjektet er generert. Etter at det er åpnet og lagret i Power BI Desktop, er filene i mappen kilden. Gjør endringer i Desktop, og commit mappen. `.pbi/localSettings.json` og `.pbi/cache.abf` holdes utenfor git.
