# DeliveryPlanner – Teknisk spesifikasjon

## 1. Dokumentinformasjon

| Felt | Verdi |
|---|---|
| Kunde | [AVKLARES: kundenavn] |
| App-navn | DeliveryPlanner |
| Publisher | Knowit Insight Business Solution AS |
| Versjon | 1.0.0.0 [AVKLARES: versjonsnummer for denne leveransen, app.json er ikke oppdatert] |
| ID-range | 78900–78950 (app), 70000–70049 (testapp) |
| BC-versjon | Application 28.0.0.0, runtime 17.0 |
| Utarbeidet av | Knowit Insight Business Solutions [AVKLARES: navn på ansvarlig konsulent] |
| Dato | 2026-10-15 |
| Status | Utkast |

## 2. Formål og bakgrunn

Kunden forsyner butikker fra ett hovedlager. Påfyllingen skal skje hver natt, bygge på faktisk salg, treffe butikkenes faste leveringsdager og ta hensyn til hyllekapasitet.

Standard BC dekker ikke dette fullt ut:

- **Planlegging (Calculate Plan)** i **Rekvisisjonskladd (Req. Worksheet)** bruker faste parametere på **Lagerføringsenhet (Stockkeeping Unit)**. Den beregner ikke lagermål fra salgshistorikk.
- Salgshistorikk i standard BC skiller ikke mellom dager uten etterspørsel og dager der varen var utsolgt.
- Standard planlegging kan overstige **Makslager (Maximum Inventory)** gjennom ordremodifikatorer.
- Standard BC fordeler ikke knapp beholdning på hovedlageret etter hvilken butikk som går tom først. Den som planlegges først, får varene.
- Standard BC har ingen leveringsplan per butikk, ingen avviksoppfølging og ingen godkjenning av unormalt store overføringsordrer.

DeliveryPlanner beregner et salgsbasert lagermål per vare, variant og butikk, frem til butikkens neste levering. Utvidelsen bruker standard planmotor til å lage forslagene, begrenser dem til makslager og fordeler hovedlagerets ledige beholdning slik at butikkene får like mange dagers dekning. Resultatet er **Overføringsordrer (Transfer Order)** som frigis, eller som venter på godkjenning når de er unormalt store.

## 3. Funksjonell beskrivelse

1. Brukeren setter opp hovedlager, analyseperiode, varsling, godkjenning og en dedikert rekvisisjonskladd i **DeliveryPlanner-oppsett**.
2. Butikker (lokasjoner) aktiveres og får butikkategori og leveringsdager. Det kan gjøres enkeltvis på **Lokasjonskort (Location Card)** eller for mange lokasjoner samtidig fra **Lokasjoner (Location List)**.
3. På **Varekort (Item Card)** angis makslager per butikkstørrelse i fanen **Delivery planner**. «Opprett standardoppsett» overfører verdiene til lagerføringsenhetene i aktive butikker.
4. Lagerføringsenheter som skal forsynes, aktiveres per vare, variant og butikk.
5. **Beregn DeliveryPlanner** fyller den dedikerte kladden med forslag. Ingen ordrer opprettes.
6. **Kjør DeliveryPlanner** beregner på nytt, oppretter overføringsordrer og frigir dem. Unormalt store ordrer blir stående åpne til de godkjennes.
7. En nattjobb i **Jobbkø (Job Queue)** utfører steg 6 automatisk og sender e-post ved feil, manglende salg eller ordrer til godkjenning.
8. Hver kjøring logges med beregningsgrunnlag, forslag, tildeling, begrunnelse, avvik og kobling til opprettede ordrelinjer.
9. **DeliveryPlanner-avvik**, **DeliveryPlanner-nøkkeltall** og en kø-del i **Lagerleders rollesenter (Inventory Manager, side 9008 «Whse. Basic Role Center»)** viser resultatet av siste kjøring.

Den dedikerte kladden er skrivebeskyttet. Linjene kan bare endres gjennom DeliveryPlanner-handlingene.

## 4. Omfang og avgrensning

**Inkludert:**

- Salgstakt per dag på lager, med minste antall dager som nevner.
- Leveringsdager per butikk og transporttid fra overføringsrutens speditørtjeneste.
- Lagermål som dekker salget frem til neste mulige levering.
- Hardt tak på makslager for mengder DeliveryPlanner oppretter.
- Fordeling av knapp beholdning etter dager med dekning.
- Avrunding til ordremultippel eller basisenhetens antallspresisjon.
- Opprettelse og frigivelse av overføringsordrer via standard «Utfør handlingsmeldinger».
- Godkjenning av ordrer som er mye større enn snittet av butikkens siste ordrer.
- Avviksliste, nøkkeltall per butikk og kategori, og kø-felt i lagerleders rollesenter.
- E-postvarsel og telemetri.
- Kontroll av at gårsdagens salg er bokført.
- Automatisk sletting av gamle kjøringslogger.
- Makslager per butikkstørrelse fra varekortet.
- Masseoppdatering av aktivering og butikkategori på lokasjoner.
- Skrivebeskyttelse av den dedikerte rekvisisjonskladden.

**Ikke inkludert:**

- Forsyning fra flere hovedlagre. Det finnes ett hovedlager i oppsettet.
- Innkjøpsplanlegging for hovedlageret.
- Forsyning ved innkjøp eller produksjon. Kun overføring støttes.
- Utlevering, mottak og bokføring av overføringsordrene. Dette skjer i ordinær lagerflyt.
- Prognoser, sesong, kampanjer, vektet salgstakt og dynamisk sikkerhetslager (forslag 3, 4 og 9 i forslagsdokumentet).
- Unntak fra leveringsdager, som helligdager og ekstra leveringer.
- Omfordeling mellom butikker, minste ordre per butikk og avrunding opp (forslag 6–8).
- Bruk av **Bestillingspunkt (Reorder Point)** som utløser.
- Oppdeling av kjøringen i flere transaksjoner. Kjøringen er bevisst én transaksjon, fordi fordelingen krever alle butikker samtidig.
- Varesporing (serie-/lotnummer) i beregningen. [AVKLARES: om kunden bruker varesporing på aktiverte varer]

## 5. Objektoversikt

| Type | ID | Navn | Utvider | Beskrivelse |
|---|---|---|---|---|
| Table | 78900 | DP Setup KBS | – | Oppsett (én post) |
| Table | 78901 | DP Store Category KBS | – | Butikkategorier med dekningsdager og vekt |
| Table | 78902 | DP Run KBS | – | Kjøringslogg (hode), med salgskontroll, tidsmåling og ordretall |
| Table | 78903 | DP Run Line KBS | – | Beregningsgrunnlag per vare/variant/butikk, med avvik |
| Table | 78904 | DP Proposal Log KBS | – | Kladdforslag og kobling til overføringslinje |
| Table | 78905 | DP Allocation Buffer KBS | – | Midlertidig tabell for fordelingsalgoritmen |
| Table | 78906 | DP KPI Buffer KBS | – | Midlertidig tabell for nøkkeltall per butikk og kategori |
| Table | 78907 | DP Store Order KBS | – | Historikk over opprettede ordrer per butikk, grunnlag for godkjenning |
| TableExtension | 78900 | DP Location KBS | Location | Aktivering, butikkategori og leveringsdager |
| TableExtension | 78901 | DP SKU KBS | Stockkeeping Unit | Aktivering per lagerføringsenhet |
| TableExtension | 78902 | DP Req Line KBS | Requisition Line | Kjørings-ID, mål, vekt, forslag, begrunnelse |
| TableExtension | 78903 | DP Transfer Header KBS | Transfer Header | Kjørings-ID og godkjenningsstatus |
| TableExtension | 78904 | DP Item KBS | Item | Makslager per butikkstørrelse |
| Page | 78900 | DP Setup KBS | – | Oppsettskort med handlinger |
| Page | 78901 | DP Store Categories KBS | – | Liste over butikkategorier |
| Page | 78902 | DP Assortment KBS | – | Butikksortiment (lagerføringsenheter) |
| Page | 78903 | DP Runs KBS | – | Kjøringslogg |
| Page | 78904 | DP Run Lines KBS | – | Beregningsgrunnlag |
| Page | 78905 | DP Proposal Log KBS | – | Forslag og ordre |
| Page | 78906 | DP Location Batch Update KBS | – | Dialog for masseoppdatering av lokasjoner (StandardDialog) |
| Page | 78907 | DP Exceptions KBS | – | Avviksliste for siste eller valgt kjøring |
| Page | 78908 | DP KPI Activities KBS | – | Kø-del (CardPart) for rollesenteret |
| Page | 78909 | DP KPIs KBS | – | Nøkkeltall per butikk og kategori |
| Page | 78910 | DP Store Orders KBS | – | Butikkordrer med snitt og godkjenningsstatus |
| Page (API) | 78911 | DP API Runs KBS | – | `knowit/deliveryPlanner/v1.0/deliveryRuns` |
| Page (API) | 78912 | DP API Run Lines KBS | – | `knowit/deliveryPlanner/v1.0/deliveryRunLines` |
| Page (API) | 78913 | DP API Store Orders KBS | – | `knowit/deliveryPlanner/v1.0/deliveryStoreOrders` |
| Page (API) | 78914 | DP API Stores KBS | – | `knowit/deliveryPlanner/v1.0/deliveryStores` (Location, ikke transitt) |
| Page (API) | 78915 | DP API Store Categories KBS | – | `knowit/deliveryPlanner/v1.0/deliveryStoreCategories` |
| PageExtension | 78900 | DP Location Card KBS | Location Card | Fanen DeliveryPlanner med leveringsdager, og sortimentshandling |
| PageExtension | 78901 | DP SKU Card KBS | Stockkeeping Unit Card | Aktiveringsfelt |
| PageExtension | 78902 | DP Req Worksheet KBS | Req. Worksheet | Skrivebeskyttelse, DP-felt og -handlinger |
| PageExtension | 78903 | DP Transfer Order KBS | Transfer Order | Kjørings-ID, godkjenningsstatus og navigering til kjøring |
| PageExtension | 78904 | DP Item Card KBS | Item Card | Fanen Delivery planner med makslager per butikkstørrelse |
| PageExtension | 78905 | DP Location List KBS | Location List | Kolonner og handlingen «Angi DeliveryPlanner» |
| PageExtension | 78906 | DP Inventory Manager RC KBS | Whse. Basic Role Center | Kø-delen DeliveryPlanner i Inventory Manager-rollen |
| Codeunit | 78900 | DP Management KBS | – | Inngangspunkt: oppsett, beregn, kjør, nattjobb, opprydding, telemetri |
| Codeunit | 78901 | DP Worker KBS | – | Hele kjøringen i én transaksjon |
| Codeunit | 78902 | DP Job Queue KBS | – | Jobbkø-inngang (TableNo = Job Queue Entry) |
| Codeunit | 78903 | DP Planning Adapter KBS | – | Manuelle event subscribers mot standard planmotor, ordreopprettelse og godkjenning |
| Codeunit | 78904 | DP Worksheet Guard KBS | – | Sperre mot manuelle endringer i kladden |
| Codeunit | 78905 | DP Inventory KBS | – | Salgstakt, beholdning, inngående, utgående, kapasitet |
| Codeunit | 78906 | DP Allocation KBS | – | Fordeling etter dager med dekning, og avrunding |
| Codeunit | 78907 | DP Upgrade KBS | – | Upgrade codeunit med upgrade tag |
| Codeunit | 78908 | DP Delivery Schedule KBS | – | Mottaksdato, leveringsdag og dekningsperiode per butikk |
| Codeunit | 78909 | DP Setup Check KBS | – | Kontroll av butikk- og SKU-oppsett per linje |
| Codeunit | 78910 | DP KPI Mgt KBS | – | Siste kjøring og beregning av nøkkeltall |
| Codeunit | 78911 | DP Notification KBS | – | Tekst og mottaker for e-postvarsler |
| Codeunit | 78912 | DP Send Email KBS | – | Sender én e-post. Kalles med Codeunit.Run for å fange feil |
| Codeunit | 78913 | DP Approval KBS | – | Ordresnitt, godkjenningsgrense og godkjenning ved frigivelse |
| Query | 78900 | DP Daily Item Movement KBS | – | Varebevegelse per bokføringsdato og posttype |
| Enum | 78900 | DP Run Status KBS | – | Kjører, Beregnet, Fullført, Mislykket |
| Enum | 78901 | DP Exception KBS | – | Avvikstyper for beregningslinjer |
| Enum | 78902 | DP Approval Status KBS | – | Blank, Venter på godkjenning, Godkjent |
| EnumExtension | 78900 | DP Email Scenario KBS | Email Scenario | E-postscenarioet DeliveryPlanner |
| PermissionSet | 78907 | DP ADMIN KBS | – | Full tilgang til DeliveryPlanner |
| PermissionSet | 78908 | DP RUN KBS | – | Kjøring og oppfølging |
| PermissionSet | 78909 | DP API KBS | – | Lesetilgang for Power BI og andre API-klienter |

Testappen (DeliveryPlanner Tests, 70000–70049) ligger i `Tests/` med filendelse `.al.test`:

| Type | ID | Navn | Dekker |
|---|---|---|---|
| Codeunit | 70001 | DP Allocation Tests KBS | Fordeling, metning, avrunding, dager med dekning |
| Codeunit | 70002 | DP Inventory Tests KBS | Salgstakt, utsolgte dager, inngående, utgående, reservasjoner |
| Codeunit | 70003 | DP Workflow Tests KBS | Skrivebeskyttet kladd |
| Codeunit | 70004 | DP Item Maximum Tests KBS | Makslager fra varekortet |
| Codeunit | 70005 | DP Location Settings Tests KBS | Masseoppdatering av lokasjoner |
| Codeunit | 70006 | DP Delivery Schedule Tests KBS | Leveringsdager og transporttid |
| Codeunit | 70007 | DP Exception Tests KBS | Avvikstyper og oppsettskontroll |
| Codeunit | 70008 | DP Monitoring Tests KBS | Godkjenning, nøkkeltall og sletting av logger |
| Codeunit / Page | 70010 | DP Test Data KBS | Testdata for manuell test i sandkasse |

`scripts/Build.ps1 -Tests` bygger app og testapp. Skriptet finner ikke kompilatoren i AL-utvidelse 18.1, som har `alc.exe` og analysatorene direkte i `bin`. På ARM64 må kompilatoren kjøres som `dotnet alc.dll`. [AVKLARES: om byggeskriptet skal oppdateres]

## 6. Datamodell og feltendringer

### 6.1 DP Setup KBS (78900)

AllowInCustomizations = AsReadWrite.

| Navn | Datatype | Standardverdi | Formål |
|---|---|---|---|
| Primary Key | Code[10] | '' | Primærnøkkel |
| Enabled | Boolean | false | Må være sann for at ordrer kan opprettes |
| Hub Location Code | Code[10] | – | Hovedlager. Kan ikke være transittlokasjon eller aktivert butikk |
| Worksheet Template Name | Code[10] | 'DELIVERY' (via «Opprett standardoppsett») | Ikke-gjentakende rekvisisjonsmal |
| Worksheet Batch Name | Code[10] | 'AUTO' (via «Opprett standardoppsett») | Dedikert kladd. Nullstilles når malen endres |
| Sales History Days | Integer | 56 | Antall avsluttede kalenderdager i salgsgrunnlaget. MinValue 1 |
| Job Start Time | Time | 02:00:00 | Starttid for nattjobben ved opprettelse |
| Min. Days In Stock | Integer | 14 | Minste nevner i salgstakten. MinValue 1 |
| Notification Email | Text[250] | – | Mottaker av e-postvarsler. Flere adresser skilles med semikolon |
| Sales Alert % | Decimal | 50 | Varsle når en større andel butikker mangler salg for i går. 0 slår av |
| Log Retention Days | Integer | 90 | Kjøringer eldre enn dette slettes. 0 beholder alt |
| Approval Factor | Decimal | 2 | Ordre over faktor × snitt venter på godkjenning. 0 slår av |
| Approval History Orders | Integer | 4 | Antall tidligere ordrer i snittet. MinValue 1 |

### 6.2 DP Store Category KBS (78901)

| Navn | Datatype | Standardverdi | Formål |
|---|---|---|---|
| Code | Code[10] | – | Kategorikode |
| Description | Text[100] | – | Beskrivelse |
| Coverage Days | Integer | 7 | Dekningsdager for butikker uten leveringsdager. MinValue 1 |
| Allocation Weight | Decimal | 1 | Avgjør bare ved likhet i fordelingen. Må være > 0 |

«Opprett standardoppsett» lager SMALL (7/1), MEDIUM (14/2) og LARGE (21/3). Kodene er låst i koden for makslager fra varekortet.

### 6.3 DP Run KBS (78902)

AllowInCustomizations = AsReadOnly.

| Navn | Datatype | Standardverdi | Formål |
|---|---|---|---|
| Run ID | Guid | CreateGuid() | Primærnøkkel |
| Started At | DateTime | – | Starttidspunkt |
| Finished At | DateTime | – | Sluttidspunkt |
| Planning Date | Date | Today() | Beregningsdato |
| Create Orders | Boolean | – | Sann for «Kjør» og nattjobb, usann for «Beregn» |
| Status | Enum DP Run Status KBS | Running | Kjører / Beregnet / Fullført / Mislykket |
| User ID | Code[50] | UserId() | Bruker som startet kjøringen |
| Error Text | Text[2048] | – | Feilmelding ved mislykket kjøring |
| Sales History Days | Integer | – | Analyseperioden brukt i kjøringen |
| Line Count | Integer | – | Antall beregnede linjer uten oppsettsfeil |
| Snapshot Duration | Duration | – | Tid for beregningsgrunnlag og salgskontroll |
| Planning Duration | Duration | – | Tid for standard planberegning og fordeling |
| Order Duration | Duration | – | Tid for ordreopprettelse og frigivelse |
| Orders Created | Integer | – | Antall opprettede overføringsordrer |
| Orders Awaiting Approval | Integer | – | Antall ordrer som venter på godkjenning |
| Stores Checked | Integer | – | Butikker med minst én beregnet linje |
| Stores Without Sales | Integer | – | Butikker uten salg på noen aktiv vare dagen før planleggingsdatoen |
| Sales Warning | Boolean | – | Andelen butikker uten salg var over Sales Alert % |

### 6.4 DP Run Line KBS (78903)

AllowInCustomizations = AsReadOnly. Nøkler: Run ID, Entry No. (primær), og ByException (Run ID, Exception, Location Code, Item No.). Én linje per aktivert lagerføringsenhet i aktiv butikk, også når oppsettet er feil.

| Navn | Datatype | Standardverdi | Formål |
|---|---|---|---|
| Item No. / Variant Code / Location Code | Code | – | Vare, variant, butikk |
| Category Code | Code[10] | – | Butikkategori ved beregning |
| Sold Quantity | Decimal | – | Netto salg i analyseperioden |
| Days In Stock | Integer | – | Dager med beholdning eller salg i analyseperioden |
| Sold Last Day | Boolean | – | Salg bokført dagen før planleggingsdatoen |
| Daily Sales | Decimal | – | Salgstakt per dag på lager |
| Days of Cover | Decimal | – | Lagerposisjon / daglig salg før tildeling. Blank når daglig salg er 0 |
| Ships Now | Boolean | – | Ordre fra kjøringen kommer frem på en leveringsdag |
| Receipt Date | Date | – | Mottaksdato for ordre sendt på planleggingsdatoen |
| Next Receipt Date | Date | – | Neste mulige mottak på en leveringsdag |
| Coverage Days | Integer | – | Dager lagermålet dekker |
| Target Quantity | Decimal | – | Lagermål |
| Maximum Inventory | Decimal | – | Makslager på lagerføringsenheten ved beregning |
| Inventory | Decimal | – | Bokført beholdning |
| Incoming Quantity | Decimal | – | Utestående innkjøp og overføringer inn |
| Outgoing Quantity | Decimal | – | Bundne utgående mengder og reservasjoner |
| Capacity Quantity | Decimal | – | Ledig plass under makslager |
| Need Quantity | Decimal | – | Påfyllingsbehov |
| Suggested Quantity | Decimal | – | Sum av standardforslag |
| Allocated Quantity | Decimal | – | Endelig tildeling |
| Unmet Quantity | Decimal | – | Behov som ikke ble dekket av hovedlageret |
| Quantity Precision | Decimal | – | Basisenhetens antallspresisjon (fallback 0,00001) |
| Order Multiple | Decimal | – | Ordremultippel fra lagerføringsenheten |
| Allocation Weight | Decimal | – | Kategorivekt |
| Exception | Enum DP Exception KBS | None | Viktigste avvik for linjen |
| Reason | Text[250] | – | Begrunnelse for begrensning, utelatelse eller oppsettsfeil |
| Item Description | Text[100] (FlowField) | – | Varebeskrivelse |
| Planning Date | Date | – | Kjøringens planleggingsdato. Nøkkel ByPlanningDate (Planning Date, Location Code, Item No.) for filtrering i API |

Prosedyren `UpdateException` setter avviket i prioritert rekkefølge: Mangler oppsett beholdes. Deretter kommer Tom – udekket behov (beholdning ≤ 0 og udekket > 0), Udekket behov, Tom i butikk og Over makslager (beholdning + inngående > makslager > 0). «Venter på godkjenning» settes etter ordreopprettelse på linjer uten annet avvik.

### 6.5 DP Proposal Log KBS (78904)

Nøkkel: Run ID, Entry No. Sekundærnøkkel: Run ID, Run Line Entry No., Due Date, Entry No.

| Navn | Datatype | Standardverdi | Formål |
|---|---|---|---|
| Run Line Entry No. | Integer | – | Kobling til beregningslinje |
| Worksheet Line No. | Integer | – | Kladdelinje ved beregning |
| Item No. / Variant Code / Location Code | Code | – | Vare, variant, butikk |
| Due Date | Date | – | Standardmotorens behovsdato |
| Suggested Quantity | Decimal | – | Standardforslag (basis) |
| Allocated Quantity | Decimal | – | Tildelt antall (basis) |
| Transfer Order No. / Transfer Line No. | Code[20] / Integer | – | Opprettet overføringslinje |

### 6.6 DP Allocation Buffer KBS (78905)

TableType = Temporary. Felt: Location Code (nøkkel), Need, Weight, Increment, Allocation, Ideal Allocation, Run Line Entry No., Position (lagerposisjon), Daily Rate (daglig forbruk).

### 6.7 DP KPI Buffer KBS (78906)

TableType = Temporary. Nøkkel: Group Type (Butikk/Kategori), Code. Felt: Description, Line Count, Service Level %, Avg. Days of Cover, Out of Stock, Over Maximum, Overstock Quantity, Unmet Quantity, Exception Count, og hjelpesummer for beregningen.

### 6.8 DP Store Order KBS (78907)

AllowInCustomizations = AsReadOnly. Nøkler: Entry No. (AutoIncrement), ByStore (Location Code, Planning Date), ByOrder (Transfer Order No.). Slettes ikke av loggoppryddingen.

| Navn | Datatype | Standardverdi | Formål |
|---|---|---|---|
| Entry No. | Integer | AutoIncrement | Primærnøkkel |
| Run ID | Guid | – | Kjøringen som opprettet ordren |
| Location Code | Code[10] | – | Butikk |
| Transfer Order No. | Code[20] | – | Overføringsordre |
| Planning Date | Date | – | Planleggingsdato |
| Quantity | Decimal | – | Sum Quantity (Base) på opprinnelige ordrelinjer |
| Average Quantity | Decimal | – | Snittet ordren ble sammenlignet med. 0 = for få tidligere ordrer |
| Approval Status | Enum DP Approval Status KBS | None | Frigitt direkte (blank), venter eller godkjent |

### 6.9 Tabellutvidelser

| Tabell | Felt (ID) | Datatype | Standardverdi | Formål |
|---|---|---|---|---|
| Location | DP Enabled KBS (78900) | Boolean | false | Butikken forsynes av DeliveryPlanner. Ikke tillatt for transitt eller hovedlager |
| Location | DP Category Code KBS (78901) | Code[10] | – | Butikkategori |
| Location | DP Delivery Monday KBS … DP Delivery Sunday KBS (78902–78908) | Boolean | false | Ukedager varer kommer frem til butikken |
| Stockkeeping Unit | DP Enabled KBS (78900) | Boolean | false | Lagerføringsenheten inngår i påfyllingen |
| Item | DP Max. Inv. Small KBS (78900) | Decimal | 0 | Makslager for kategori SMALL |
| Item | DP Max. Inv. Medium KBS (78901) | Decimal | 0 | Makslager for kategori MEDIUM |
| Item | DP Max. Inv. Large KBS (78902) | Decimal | 0 | Makslager for kategori LARGE |
| Requisition Line | DP Run ID KBS (78900) | Guid | – | Eierskap til kjøring |
| Requisition Line | DP Run Line No. KBS (78901) | Integer | – | Beregningslinje |
| Requisition Line | DP Proposal No. KBS (78902) | Integer | – | Linje i forslagsloggen |
| Requisition Line | DP Target Qty. KBS (78903) | Decimal | – | Lagermål |
| Requisition Line | DP Weight KBS (78904) | Decimal | – | Fordelingsvekt |
| Requisition Line | DP Suggested Qty. KBS (78905) | Decimal | – | Standardforslag før fordeling |
| Requisition Line | DP Reason KBS (78906) | Text[250] | – | Begrunnelse |
| Transfer Header | DP Run ID KBS (78900) | Guid | – | Kjøringen som opprettet ordren. Nøkkel DPRunKBS |
| Transfer Header | DP Approval Status KBS (78901) | Enum DP Approval Status KBS | None | Godkjenningsstatus. Nøkkel DPApprovalKBS |

Location har prosedyrene `DPHasDeliveryPlanKBS` og `DPIsDeliveryDayKBS(Date)`. Ukedagen bestemmes med `Date2DWY(Date, 1)`.

AllowInCustomizations er satt på objektnivå: AsReadWrite for Location, Item og Stockkeeping Unit. AsReadOnly for Requisition Line og Transfer Header. Never for de midlertidige tabellene.

## 7. Forretningslogikk og prosessflyt

### 7.1 Inngang

- **Beregn DeliveryPlanner** → `DP Management KBS.Calculate()` → `Execute(false)` → åpner kladden.
- **Kjør DeliveryPlanner** → `RunPlanner()` → `Execute(true)` → åpner kjøringsloggen.
- **Nattjobb** → `DP Job Queue KBS.OnRun` → `Execute(true)`.

`Execute`:

1. `DeleteOldRuns` sletter kjøringer eldre enn Log Retention Days, med linjer og forslag. Kjøringer med status Kjører slettes aldri.
2. Oppretter `DP Run KBS` med status Kjører og gjør `Commit`.
3. Kaller `Codeunit.Run(Codeunit::"DP Worker KBS", RunRecord)`.
4. **Ved feil:** Status settes til Mislykket, feilteksten lagres, og det gjøres `Commit`. Telemetri `DP0002` sendes. Når `GuiAllowed` er usann (nattjobb), sendes e-post med `SendRunFailure`. Feilen kastes videre, slik at Jobbkø registrerer den og prøver på nytt.
5. **Ved suksess:** `Commit`, telemetri `DP0001`. Når `GuiAllowed` er usann, sendes `SendRunSummary` hvis det er salgsvarsel eller ordrer til godkjenning.

### 7.2 Worker (én transaksjon)

`DP Worker KBS.ExecuteWorker` har `[CommitBehavior(CommitBehavior::Error)]`. En `Commit` underveis gir feil. Alle endringer rulles tilbake ved feil.

1. `Setup.LockTable()` serialiserer samtidige kjøringer.
2. **ValidateSetup:** Aktivert (kun ved ordreopprettelse), hovedlager, mal, kladd, analyseperiode ≥ 1 og minste dager på lager ≥ 1. Hovedlager er ikke transitt og ikke aktivert butikk. Malen er type Req., ikke gjentakende og uten «Increment Batch Name». Feil her stopper kjøringen.
3. **ValidateWorksheet:** Alle eksisterende linjer i kladden må tilhøre en kjent kjøring.
4. **ValidateAssortment:** Minst én aktivert lagerføringsenhet i en aktiv butikk.
5. `BindSubscription(Adapter)` aktiverer de manuelle subscriberne.
6. **DeletePreviousProposals:** Sletter alle linjer i den dedikerte kladden.
7. **BuildSnapshots:** For hver aktivert lagerføringsenhet i aktiv butikk:
   - Butikkens oppsett kontrolleres én gang med `DP Setup Check KBS.GetStoreProblem`, og leveringsplanen hentes med `DP Delivery Schedule KBS.GetSchedule`. Begge mellomlagres per butikk.
   - Lagerføringsenheten kontrolleres med `GetSKUProblem`.
   - **Oppsettsfeil:** Linjen lagres med Exception = Mangler oppsett, beholdning og begrunnelse. Behovet settes til 0.
   - **Ellers:** `DP Inventory KBS.BuildRunLine` med butikkens dekningsdager. Blokkert vare eller variant gir behov 0. Butikk uten levering fra kjøringen gir behov 0 og begrunnelsen «Ingen levering fra denne kjøringen. Neste levering …». Hovedlagerets fordelbare mengde beregnes én gang per vare/variant.
8. **CheckSalesImport:** Teller butikker med beregnede linjer, og butikker der ingen linje har Sold Last Day. Sales Warning settes når andelen uten salg er over Sales Alert %. Kjøringen fortsetter uansett.
9. **CalculateStandardPlan:** For linjer med behov > 0 kalles `Inventory Profile Offsetting.CalculatePlanFromWorksheet` for én lagerføringsenhet om gangen. Planperiode: planleggingsdato til planleggingsdato + dekningsdager − 1.
10. **CaptureProposals:** Hver kladdelinje kontrolleres (Transfer, New, riktig vare/butikk/fra-kode, positiv mengde) og logges i `DP Proposal Log KBS`. «Accept Action Message» settes til usann.
11. **AllocateStock:** Per vare/variant fylles bufferen for linjer uten oppsettsfeil, med behov (min av behov og avrundet standardforslag), vekt, antallstrinn, lagerposisjon og daglig forbruk. `DP Allocation KBS.Allocate` fordeler. Udekket antall = behov − tildeling.
12. **ApplyAllocations:** Tildelingen fordeles på forslagslinjene i rekkefølge etter forfallsdato. Linjer med 0 slettes. Øvrige får ny mengde og «Accept Action Message» = sann. `UpdateException` setter avviket.
13. **Ved ordreopprettelse:** `CarryOutAndRelease` kaller `Req. Wksh.-Make Order.CarryOutBatchAction` med `SetSuppressCommit(true)`. For hver ny overføringsordre med kjørings-ID:
    - Ordremengden (sum Quantity (Base) på linjer med Derived From Line No. = 0) sammenlignes med `DP Approval KBS.GetAverageQuantity`.
    - Er mengden større enn Approval Factor × snitt, settes DP Approval Status KBS = Venter på godkjenning, og ordren forblir åpen.
    - Ellers frigis ordren med `Release Transfer Document`.
    - Ordren registreres i `DP Store Order KBS`.
14. **MarkAwaitingApproval:** Linjer med tildeling > 0 og uten avvik for butikker med ventende ordre får Exception = Venter på godkjenning.
15. Tidsbruk, ordretall og status lagres. Status settes til Fullført (kjør) eller Beregnet (beregn).

### 7.3 Beregningsformler (DP Inventory KBS)

Alle mengder er i basisenhet, per vare/variant/lokasjon. Analyseperioden er planleggingsdato − Dager til planleggingsdato − 1.

```text
Åpningsbeholdning = Σ Item Ledger Entry.Quantity før analyseperioden
Per dag (query DP Daily Item Movement KBS, gruppert på bokføringsdato og posttype):
  På lager        = åpning > 0  eller  slutt > 0  eller  salgspost denne dagen
Solgt antall      = maks(0, −Σ Quantity der Entry Type = Sale i perioden)
Dager på lager    = antall dager som er På lager
Daglig salg       = Solgt antall / maks(Dager på lager, min(Minste dager på lager, Dager))
Solgt i går       = salgspost på planleggingsdato − 1

Dekningsdager     = Neste mottaksdato − planleggingsdato   (butikk med leveringsdager)
                  = kategoriens dekningsdager              (butikk uten leveringsdager)
Lagermål          = maks(0, min(Makslager, maks(Sikkerhetslager, Daglig salg × Dekningsdager)))
Beholdning        = Σ Item Ledger Entry.Quantity (alle datoer)
Inngående         = Utestående innkjøpsordrelinjer (Outstanding Qty. (Base), ikke direkte levering)
                  + Σ maks(0, Quantity (Base) − Qty. Received (Base)) på opprinnelige
                    overføringslinjer til lokasjonen (Derived From Line No. = 0)
Utgående          = Utestående salgsordrelinjer (ikke direkte levering)
                  + Utestående overføringslinjer fra lokasjonen
                  + reservasjoner mot beholdning som ikke allerede er telt i ordrene
Lagerposisjon     = Beholdning + Inngående − Utgående
Dager med dekning = maks(0, Lagerposisjon) / Daglig salg     (blank når Daglig salg = 0)
Ledig plass       = maks(0, Makslager − maks(0, Beholdning) − Inngående)
Behov             = min(Ledig plass, maks(0, Lagermål − Lagerposisjon))
Hovedlager        = maks(0, Beholdning − Utgående − Sikkerhetslager på hovedlagerets SKU)
```

Spørringen leses sekvensielt med en mellomlagret radidato. AL evaluerer begge operandene i `and`, så kolonneverdier leses aldri etter siste `Read`.

### 7.4 Leveringsplan (DP Delivery Schedule KBS)

1. **CalcReceiptDate** speiler datoberegningen på overføringsordren. Den bruker `Transfer Route.GetTransferRoute`, `GetShippingTime` og `CalcReceiptDate` med hovedlagerets Outbound Whse. Handling Time og butikkens Inbound Whse. Handling Time. Basiskalendere for lokasjoner og speditørtjeneste brukes av standard `CalendarMgmt`.
2. **GetSchedule:**
   - Mottaksdato = CalcReceiptDate(planleggingsdato).
   - Butikk uten leveringsdager: Ships Now = sann, dekning = kategoriens dekningsdager.
   - Ellers er Ships Now = sann når mottaksdatoen er en leveringsdag. Neste mottaksdato finnes ved å prøve sendedatoer fra planleggingsdato + 1 til og med + 28, og velge første mottaksdato etter dagens som er en leveringsdag.
   - Dekning = neste mottaksdato − planleggingsdato.
   - Finnes ingen leveringsdag innen 28 dager, returneres usann. Linjen får da Mangler oppsett.
3. **GetFirstDeliveryDate** gir første mottaksdato på en leveringsdag, til begrunnelsen for butikker som ikke får levering fra kjøringen.

### 7.5 Fordelingsalgoritme (DP Allocation KBS)

Butikkene fylles opp til et felles nivå T i dager med dekning: tildeling_i = min(behov_i, maks(0, T × forbruk_i − posisjon_i)).

1. Behov avrundes ned til antallstrinn (ordremultippel, ellers antallspresisjon). Forbruk må være > 0 når behovet er > 0.
2. Tilgjengelig mengde = min(hovedlager, sum behov). Er alt tilgjengelig, får alle sitt behov.
3. Ellers finnes T med halveringssøk mellom laveste posisjon/forbruk og høyeste (posisjon + behov)/forbruk, slik at sum tildeling ≤ tilgjengelig.
4. `SolveLevelInSegment` løser T eksakt i det siste lineære segmentet. Dermed blir like avrundingsrester faktisk like, og vekten avgjør likhet.
5. Tildeling avrundes ned til antallstrinn.
6. Restmengden fordeles i hele trinn. Prioritet: størst relativ avrundingsrest, deretter høyest vekt, deretter lavest lokasjonskode. Fulle runder fordeles samlet, slik at kjøretiden ikke avhenger av antall enheter.

Daglig forbruk i fordelingen er Daglig salg. For varer uten salg brukes lagermål / dekningsdager, og ellers behov / dekningsdager. Tildeling overstiger aldri behov, tilgjengelig mengde eller makslager.

### 7.6 Godkjenning (DP Approval KBS)

- **GetAverageQuantity:** Snitt av de siste N ordrene til butikken med status blank eller Godkjent. Ordrer som venter eller er slettet før godkjenning, telles ikke. Returnerer 0 når butikken har færre enn N ordrer.
- **NeedsApproval:** Mengde > Approval Factor × snitt. Faktor 0 eller snitt 0 gir aldri godkjenning.
- En ventende ordre er en åpen overføringsordre. Den telles som inngående for butikken og utgående for hovedlageret i neste kjøring.
- Godkjenning skjer med standard **Frigi**. Subscriberen på `OnAfterReleaseTransferDoc` setter status Godkjent på ordren og i `DP Store Order KBS`. Avvisning er å slette ordren.

### 7.7 Nøkkeltall (DP KPI Mgt KBS)

- **GetLatestRun:** Siste kjøring med status Fullført eller Beregnet. Brukes av avvikslisten, nøkkeltallssiden og kø-delen.
- **FillBuffer:** Én linje per butikk og per kategori. Linjer med oppsettsfeil telles som avvik, men holdes utenfor de andre tallene.
  - Servicegrad = Σ Dager på lager / (antall linjer × analysedager) × 100
  - Snitt dager med dekning = gjennomsnitt over linjer med salg
  - Tomme varer = linjer med beholdning ≤ 0
  - Overlager = Σ (beholdning + inngående − makslager) når summen er over makslager
- **CountAwaitingApproval** teller åpne overføringsordrer med status Venter på godkjenning, uavhengig av kjøring.

### 7.8 Varsling og telemetri

- E-post sendes med `Email.Send` og scenarioet DeliveryPlanner, via `DP Send Email KBS` og `Codeunit.Run`. Feil i sendingen stopper ikke kjøringen, og gir telemetri `DP0003`.
- Det sendes ingen e-post når Notification Email er tom.
- Jobbkøen prøver tre ganger. En feil som gjentar seg, gir derfor opptil tre e-poster.
- Telemetri sendes med `Session.LogMessage` og `TelemetryScope::ExtensionPublisher`. Dimensjoner: RunId, Status, CreateOrders, LineCount, SnapshotMs, PlanningMs, OrderMs, OrdersCreated, OrdersAwaitingApproval og SalesWarning.

### 7.9 Makslager fra varekortet og masseoppdatering av lokasjoner

- `DP Management KBS.CreateDefaults` kaller `ApplyItemMaximums` etter at kategoriene er opprettet:
  - For lokasjoner med DP Enabled KBS og kategori SMALL, MEDIUM eller LARGE hentes tilsvarende felt på varer av type Inventory der verdien er > 0.
  - Varer med varianter får verdien per variant.
  - Finnes lagerføringsenheten, valideres Maximum Inventory. Andre felt endres ikke.
  - Finnes den ikke, opprettes den med `Validate("Item No.")`, `Validate("Location Code")` og `Insert(true)`. Deretter valideres Transfer-from Code = hovedlager, Replenishment System = Transfer og Maximum Inventory. Transfer-from Code valideres etter `Insert`, fordi standardvalideringen kaller `Modify`.
  - DP Enabled KBS settes ikke.
- `SetStoreSettings` validerer DP Category Code KBS og DP Enabled KBS for alle lokasjoner i utvalget. Er bare én linje merket i Location List, brukes sidens filter. Kategori er påkrevd ved aktivering. Ugyldige lokasjoner gir feil, og hele oppdateringen rulles tilbake.

### 7.10 Event subscribers

**DP Planning Adapter KBS (EventSubscriberInstance = Manual, kun aktiv under kjøring):**

| Publisher | Event | Formål |
|---|---|---|
| Codeunit Planning-Get Parameters | OnAfterAdjustInvalidSettings | Overstyrer planparametere i minnet: Maximum Qty. (Lot-for-Lot når målet er 0), makslager = lagermål, bestillingspunkt = mål − presisjon, nuller min/maks ordreantall, lotstørrelse og dempere, tidsbøtte 1D. Lagerføringsenheten endres ikke i databasen |
| Codeunit Inventory Profile Offsetting | OnFindCombinationOnBeforeSKUFindSet | Begrenser planleggingen til gjeldende lagerføringsenhet |
| Codeunit Inventory Profile Offsetting | OnPlanItemOnBeforeTempSKUFind | Samme begrensning på midlertidig SKU-tabell |
| Codeunit Inventory Profile Offsetting | OnCalculatePlanFromWorksheetOnBeforeUnfoldItemTracking | Setter Planning Flexibility = None på eksisterende forsyning, slik at eksisterende ordrer ikke endres |
| Codeunit Req. Wksh.-Make Order | OnCodeOnBeforeInitProgressWindow | Skjuler fremdriftsvindu |
| Codeunit Carry Out Action | OnInsertTransHeaderOnBeforeTransHeaderInsert | Setter kjørings-ID og bokføringsdato på overføringshodet |
| Codeunit Carry Out Action | OnAfterInsertTransLine | Kobler forslagsloggen til overføringslinjen |
| Codeunit DP Worksheet Guard KBS | OnCheckAccess | Gir skrivetilgang til den dedikerte kladden mens kjøringen pågår |

**DP Worksheet Guard KBS (statisk):**

| Publisher | Event | Formål |
|---|---|---|
| Table Requisition Line | OnBeforeInsertEvent / OnBeforeModifyEvent / OnBeforeDeleteEvent / OnBeforeRenameEvent | Stopper endringer i den dedikerte kladden utenfor kjøring |
| Codeunit Req. Wksh.-Make Order | OnBeforeCarryOutBatchActionCode / OnBeforeOnRun | Stopper manuell «Utfør handlingsmeldinger» |
| Codeunit Carry Out Action | OnBeforeInsertTransHeader / OnInsertTransLineOnAfterTransLineInit | Stopper ordreopprettelse fra kladden utenfor kjøring |

**DP Approval KBS (statisk):**

| Publisher | Event | Formål |
|---|---|---|
| Codeunit Release Transfer Document | OnAfterReleaseTransferDoc | Setter ventende ordre til Godkjent i Transfer Header og DP Store Order KBS |

**DP Upgrade KBS:**

| Publisher | Event | Formål |
|---|---|---|
| Codeunit Upgrade Tag | OnGetPerCompanyUpgradeTags | Registrerer upgrade tag, slik at nye installasjoner ikke får standardverdiene satt på nytt ved første oppgradering |

Sperren publiserer `OnCheckAccess` (IntegrationEvent). Den manuelt bundne adapteren svarer bare så lenge den er bundet. En feil avbinder instansen, så tilgangen lekker ikke til senere arbeid.

### 7.11 Sideutvidelser

- **Req. Worksheet:** For den dedikerte kladden er repeateren skrivebeskyttet, og en informasjonstekst vises. Disse standardhandlingene er deaktivert: Beregn plan, Utfør handlingsmeldinger, Slett alle, Reserver, Dimensjoner, Varesporingslinjer, Hent salgsordrer, Salgsordre, Action53, Action75 og Rediger i Excel. Gruppen «DeliveryPlanner» viser Beregn, Kjør og Kjøringslogg.
- **Location Card:** Gruppen DeliveryPlanner legges etter General, med undergruppen Leveringsdager.
- **Whse. Basic Role Center (Inventory Manager):** Kø-delen legges etter `Control1906245608` (Whse Ship & Receive Activities).
- **Transfer Order:** DP Approval Status KBS vises med Importance = Promoted og rød stil når ordren venter.
- **Proposal Log:** Handlingen Overføringsordre er deaktivert uten ordrenummer, og forklarer hvorfor ordren mangler.

## 8. Oppsett og konfigurasjon

| Side | Felt | Verdi | Kommentar |
|---|---|---|---|
| DeliveryPlanner-oppsett | Handling «Opprett standardoppsett» | – | Lager mal DELIVERY, kladd AUTO og kategoriene SMALL/MEDIUM/LARGE. Overfører makslager fra varekortet |
| DeliveryPlanner-oppsett | Hovedlager | [AVKLARES: lokasjonskode] | Ikke transitt, ikke aktivert butikk |
| DeliveryPlanner-oppsett | Dager med salgshistorikk / Minste antall dager på lager | 56 / 14 | – |
| DeliveryPlanner-oppsett | Starttid for nattjobb | 02:00 | Må ligge etter salgsimporten [AVKLARES: tidspunkt for salgsimport] |
| DeliveryPlanner-oppsett | Behold kjøringslogg (dager) | 90 | 0 beholder alt |
| DeliveryPlanner-oppsett | Varsel til e-post | [AVKLARES: mottakeradresse] | Tom adresse = ingen e-post |
| DeliveryPlanner-oppsett | Varsle ved manglende salg (%) | 50 | 0 slår av kontrollen |
| DeliveryPlanner-oppsett | Godkjenning over faktor / Ordrer i snittet | 2 / 4 | Faktor 0 slår av godkjenning |
| E-postkontoer og E-postscenarioer | Scenario DeliveryPlanner | E-postkonto | Påkrevd for e-postvarsler |
| DeliveryPlanner-butikkategorier | Dekningsdager / Fordelingsvekt | 7/1, 14/2, 21/3 | Dekningsdager gjelder bare butikker uten leveringsdager |
| Lokasjonskort | DeliveryPlanner aktivert / butikkategori / leveringsdager | Per butikk | Kan også settes fra Lokasjoner med «Angi DeliveryPlanner» |
| Speditører (Shipping Agents) | Speditørtjenester med Transporttid (Shipping Time) | [AVKLARES: tjenester og transporttid per region] | Gir transporttiden, for eksempel lengre for nord enn for sør |
| Overføringsruter (Transfer Routes) | Transittkode, speditør, speditørtjeneste | Per butikk | Uten speditørtjeneste regnes transporttiden som 0 dager pluss lagerhåndteringstid |
| Lokasjonskort | Utgående/Inngående lagerhåndteringstid | Valgfritt | Inngår i mottaksdatoen |
| Varekort, fanen Delivery planner | Makslager liten/mellomstor/stor butikk | Per vare | 0 endrer ingenting |
| DeliveryPlanner-butikksortiment | Aktivert, makslager, sikkerhetslager, ordremultippel, etterforsyningssystem, overfør fra-kode | Per vare/variant/butikk | Makslager > 0. Overføring fra hovedlager |
| Lagerføringsenhet på hovedlager | Sikkerhetslager | Valgfritt | Holdes tilbake fra fordeling |
| DeliveryPlanner-oppsett | Handling «Opprett nattjobb» | – | Jobbkøposten opprettes med status «På vent» (On Hold) og må settes til «Klar» |
| DeliveryPlanner-oppsett | Aktivert | Ja | Påkrevd for «Kjør» og nattjobb |

Nattjobben opprettes med jobbkøkategori DELIVERY, alle ukedager, maks 3 forsøk og 300 sekunders forsinkelse mellom forsøk. Starttiden tolkes i tidssonen til brukeren som kjører jobben. Ordre lages bare natten der ordren kommer frem på en leveringsdag, så jobben må kjøre hver natt.

## 9. Tillatelser

| Permission set | Innhold | Rolle |
|---|---|---|
| DP ADMIN KBS («DeliveryPlanner - Administrasjon») | RIMD på alle DP-tabeller. Kjøretilgang til alle DP-sider, codeunits og query | Innkjøps-/logistikkansvarlig som vedlikeholder oppsett og sortiment |
| DP API KBS («DeliveryPlanner - Rapportering») | Les på kjøring, beregningslinjer, butikkordrer, kategorier og Location. Kjøretilgang til de fem API-sidene | Power BI-kontoen. Trenger i tillegg lesetilgang til varer, for eksempel D365 READ |
| DP RUN KBS («DeliveryPlanner - Kjøring») | Les på oppsett og kategorier. RIMD på kjøring, beregningslinjer, forslagslogg, butikkordrer og buffere. Kjøretilgang til kjøringslogg, beregningsgrunnlag, forslag, avvik, nøkkeltall, kø-del, butikkordrer, alle DP-codeunits og query | Jobbkøbrukeren og brukere som kjører og følger opp |

Begge settene gir bare tilgang til DeliveryPlanner-objekter. Brukeren trenger i tillegg standard tilganger til vare, lagerføringsenhet, lokasjon, overføringsrute, speditør, rekvisisjonskladd, planlegging, overføringsordre, reservasjoner og e-post. [AVKLARES: hvilke standard permission sets som tildeles jobbkøbrukeren]

DP RUN KBS gir ikke kjøretilgang til DP Setup KBS, DP Assortment KBS eller DP Location Batch Update KBS. Handlingene på oppsettssiden og masseoppdatering av lokasjoner krever derfor DP ADMIN KBS. Fra rekvisisjonskladden er Beregn og Kjør tilgjengelige med DP RUN KBS.

## 10. Avhengigheter og integrasjoner

- Ingen appavhengigheter i `app.json` utover Base Application og System Application.
- Bruker standard BC-objekter:
  - planlegging og ordreopprettelse: Inventory Profile Offsetting, Planning-Get Parameters, Req. Wksh.-Make Order, Carry Out Action og Release Transfer Document
  - ruteberegning: Transfer Route
  - drift: Job Queue
  - System Application: Email, Email Message, Email Scenario og Upgrade Tag
- Salgshistorikk leses fra varepostene. Butikksalget kommer som enkelttransaksjoner, og må være bokført som vareposter av typen Salg før nattjobben kjører. [AVKLARES: hvilken løsning importerer butikksalget, og når er den ferdig]
- E-post krever en konfigurert e-postkonto i BC, tildelt scenarioet DeliveryPlanner.
- Telemetri sendes til Application Insights når miljøet eller appen har en tilkoblingsstreng. `app.json` har ingen `applicationInsightsConnectionString`. [AVKLARES: om produksjonsstrengen fra AL-retningslinjene skal legges inn]
- Ingen eksterne systemer eller tredjepartsløsninger.

## 11. Oppgradering og kompatibilitet

- **DP Upgrade KBS (Subtype = Upgrade):**
  - Setter Min. Days In Stock = 14 når verdien er 0.
  - Setter Sales Alert % = 50, Log Retention Days = 90, Approval Factor = 2 og Approval History Orders = 4 én gang per selskap, styrt av tagen `KBS-DELIVERYPLANNER-MONITORING-DEFAULTS-20261016`.
  - Fyller Planning Date på eksisterende beregningslinjer fra kjøringen, styrt av tagen `KBS-DELIVERYPLANNER-RUNLINE-PLANNINGDATE-20261016`.
  - Tagene registreres via `OnGetPerCompanyUpgradeTags`, så nye installasjoner beholder egne valg.
- **Atferdsendring ved oppgradering fra første versjon:**
  - Oppsettsfeil på enkeltvarer eller butikker stopper ikke lenger kjøringen.
  - Vektfordeling er erstattet av fordeling etter dager med dekning.
  - Salgstakten deles på dager på lager i stedet for alle dager.
- Ingen objekter eller felt er merket obsolete.
- **Risiko:** Utvidelsen abonnerer på interne events i `Inventory Profile Offsetting`, `Planning-Get Parameters`, `Req. Wksh.-Make Order`, `Carry Out Action` og `Release Transfer Document`. Endrede signaturer eller fjernede events i en ny BC-versjon gir kompileringsfeil. Test hver hovedversjon i sandkasse før oppgradering.
- **Risiko:** Sideutvidelsene refererer til kontrollnavnene `Control1`, `Control120`, `Action53` og `Action75` i Req. Worksheet, og `Control1906245608` i Whse. Basic Role Center. Microsoft kan endre disse.
- **Ytelse:** Salgstakten leser én query-rad per dag og posttype per lagerføringsenhet. Salgskontrollen bruker de samme dataene og gjør ingen ekstra spørring mot alle vareposter. Leveringsplanen beregnes én gang per butikk. Tid per steg logges i kjøringen og i telemetrien.
- Ressurseksponering: debugging, nedlasting av kildekode og kildekode i symbolfil er tillatt.

## 12. Testscenarier

Automatiserte tester dekker beregningene bak scenariene 1–9, 11–15, 17 og 19–24. For scenario 17 gjelder det snitt og grense, ikke selve ordreopprettelsen. Scenario 10, 16, 18, 25 og 26 testes manuelt i sandkasse med `DP Test Data KBS`.

| Nr | Scenario | Forutsetning | Steg | Forventet resultat |
|---|---|---|---|---|
| 1 | Butikken som går tom først | A: salg 2/dag, tom. B: salg 6/dag, 30 på lager. Tilgjengelig 12 | Kjør fordeling | A 10, B 2 |
| 2 | Like posisjoner | Behov 100 og 20, forbruk 2 og 1, tilgjengelig 30 | Kjør fordeling | 20 og 10 |
| 3 | Negativ posisjon | A: posisjon −5. B: posisjon 10. Tilgjengelig 5 | Kjør fordeling | A 5, B 0 |
| 4 | Metning | Én butikk når behovsgrensen | Kjør fordeling | Resten går til øvrige butikker |
| 5 | Kolli | Behov 11, ordremultippel 6 | Kjør fordeling | Høyst 6 |
| 6 | Store kolli | Stor uoppnåelig pakke og mange små enheter | Kjør fordeling | Fullføres uten å iterere per enhet |
| 7 | Utsolgte dager | På lager 17 av 56 dager, solgt 18 | Beregn | Daglig salg 18/17 |
| 8 | Minste dager på lager | På lager 3 dager, solgt 6 | Beregn | Daglig salg 6/14 |
| 9 | Kapasitet | Beholdning 90, makslager 100, åpne salg 30 | Beregn | Høyst 10 nye enheter |
| 10 | Varer underveis | Overføring 20, sendt 12, mottatt 5 | Beregn | 8 utestående fra hovedlager, 15 inngående til butikk |
| 11 | Leveringsdag | Mottaksdato er en leveringsdag | Beregn | Leveres nå. Dekning til neste levering |
| 12 | Ikke leveringsdag | Mottaksdato er ikke en leveringsdag | Beregn | Behov 0. Begrunnelse med neste levering |
| 13 | Uten leveringsdager | Ingen dager avkrysset | Beregn | Leveres hver natt med kategoriens dekningsdager |
| 14 | Transporttid | Speditørtjeneste 2D på ruten | Beregn | Mottaksdato ≥ planleggingsdato + 2 |
| 15 | Oppsettsfeil | Makslager 0, manglende rute eller kategori | Kjør | Linjen får Mangler oppsett. Øvrige butikker får ordre |
| 16 | Salgsimport mangler | Ingen salg i går i over 50 % av butikkene | Kjør nattjobb | Salgsvarsel i kjøringen, rollesenteret og e-post |
| 17 | Godkjenning | Ordre over 2 × snittet av fire siste | Kjør | Ordren er åpen, Venter på godkjenning, e-post sendt |
| 18 | Godkjent ved frigivelse | Ventende ordre | Frigi | Status Godkjent på ordre og i butikkordrer |
| 19 | For få ordrer | Butikk med færre enn fire ordrer | Kjør | Ordren frigis uten sammenligning |
| 20 | Nøkkeltall | Kjøring med kjente linjer | Åpne nøkkeltall | Servicegrad, tomme varer og overlager per butikk og kategori |
| 21 | Logg-opprydding | Kjøring eldre enn 90 dager | Kjør | Gammel kjøring med linjer slettes. Kjøring som pågår, beholdes |
| 22 | Makslager fra varekortet | Vare med liten 10, mellomstor 0, stor 30 | Opprett standardoppsett | SKU for liten (10) og stor (30). Ingen for mellomstor |
| 23 | Masseoppdatering | Tre lokasjoner, to merket | Angi DeliveryPlanner | Bare de merkede endres |
| 24 | Skrivebeskyttet kladd | Dedikert kladd åpnet | Endre, sett inn eller slett linje | Feilmelding. Vanlige kladder kan fortsatt redigeres |
| 25 | Frigivelsesfeil | Feil på siste butikk | Kjør | Alle nye ordrer rulles tilbake. Status Mislykket og e-post fra nattjobben |
| 26 | Gjenkjøring | Fullført kjøring samme dag | Kjør på nytt | Eksisterende ordrer telles som inngående. Ingen dobbeltbestilling |

## 13. Kjente begrensninger

- Ett hovedlager per selskap.
- Salgstakten er et gjennomsnitt over dager på lager. Trend og sesong fanges ikke.
- Leveringsdager er faste ukedager uten unntakskalender. Basiskalendere påvirker bare mottaksdatoen.
- Feiler nattjobben natten før en leveringsdag, får butikken ingen ordre før neste leveringsdag med mindre noen kjører manuelt.
- Godkjenning vurderer hele ordren per butikk, ikke enkeltlinjer. Butikker med færre enn N tidligere ordrer vurderes ikke.
- Avvikslisten og nøkkeltallene viser siste fullførte eller beregnede kjøring. En manuell beregning etter nattjobben erstatter nattens tall i visningen.
- Makslager fra varekortet er knyttet til kategorikodene SMALL, MEDIUM og LARGE.
- Den dedikerte kladden kan ikke redigeres manuelt. Justering skjer via oppsettet.
- Beholdning beregnes fra alle vareposter uten datofilter.
- Hele kjøringen er én transaksjon med tabellås på oppsettet. Store sortimenter gir lang låsetid. [AVKLARES: forventet antall aktive lagerføringsenheter]
- Små butikker kan få 0 når mengden ikke rekker til ett kolli.
- Testene er kompilert, men ikke kjørt i et BC-miljø. [AVKLARES: testkjøring i sandkasse]

## 14. Endringslogg

| Versjon | Dato | Endring | Av |
|---|---|---|---|
| 1.0.0.0 | 2026-10-14 | Første versjon av dokumentet | Knowit Insight Business Solutions |
| [AVKLARES: versjon] | 2026-10-15 | Lagt til: makslager fra varekortet, masseoppdatering av lokasjoner, salgstakt uten utsolgte dager, leveringsdager med transporttid fra rute, fordeling etter dager med dekning, avviksliste, oppsettsfeil per linje, nøkkeltall og rollesenter, e-postvarsel og salgskontroll, logg-opprydding, tidsmåling og telemetri, godkjenning av store ordrer, upgrade codeunit | Knowit Insight Business Solutions |
| [AVKLARES: versjon] | [AVKLARES: dato] | API-sider for Power BI (78911–78915), rettighetssett DP API KBS, Planning Date på beregningslinjen. Rapportspesifikasjon i `Docs/PowerBI/` | Knowit Insight Business Solutions |
