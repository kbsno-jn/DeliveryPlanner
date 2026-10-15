# DeliveryPlanner

DeliveryPlanner er en per-tenant-utvidelse (PTE) for Business Central. Den fyller opp butikker fra ett hovedlager hver natt med frigitte overføringsordrer. Målet er riktig beholdning i hver butikk til riktig tid.

> Wikien beskriver appen slik den er etter at branchen `new_feature` er merget. `main` har fortsatt ID-område 62100–62149 og mangler leveringsdager, avviksliste, nøkkeltall, varsling og godkjenning.

## Kort fortalt

- **Salgstakt:** Salg per dag varen var på lager i butikken, ikke per kalenderdag. Dager varen var utsolgt, holdes utenfor.
- **Når:** Butikken får ordre bare når ordren kommer frem på en av butikkens leveringsdager. Transporttiden hentes fra overføringsruten.
- **Hvor mye:** Nok til neste mulige levering, aldri mer enn makslageret.
- **Ved mangel:** Butikken som går tom først, får først. Butikkene fylles opp til like mange dagers dekning.
- **Oppfølging:** Avviksliste, nøkkeltall per butikk og kategori, kø-del i Inventory Manager-rollen, e-postvarsel og godkjenning av unormalt store ordrer.

## Nøkkeltall om appen

| | |
|---|---|
| App-navn | DeliveryPlanner |
| App-ID | `34afd6a6-5218-47cc-b199-c6fb441adda8` |
| Publisher | Knowit Insight Business Solution AS |
| ID-område | 78900–78950 |
| Testapp | DeliveryPlanner Tests, 70000–70049 |
| Business Central | Application 28.0.0.0, runtime 17.0 |
| Avhengigheter | Bare Base Application og System Application |
| Navnerom | `Knowit.DeliveryPlanner` |
| Objektsuffiks | `KBS` |

## Sider i wikien

- [Funksjonalitet](Funksjonalitet) – hva appen gjør, og hvordan den regner
- [Arkitektur](Arkitektur) – objekter, kjøringsflyt, transaksjoner og event subscribers
- [Oppsett og drift](Oppsett-og-drift) – installasjon, kundens oppsett, rettigheter og nattjobb
- [Utvikling](Utvikling) – bygging, tester, konvensjoner og fallgruver
- [Feilsøking](Feilsøking) – vanlige feil og hva de betyr

## Dokumenter i repoet

| Fil | Innhold | Målgruppe |
|---|---|---|
| `Docs/DeliveryPlanner - Teknisk spesifikasjon.md` | Full objektoversikt, datamodell, formler og testscenarier | Utviklere |
| `Docs/DeliveryPlanner - Brukerveiledning.docx` | Steg-for-steg-veiledning med plassholdere for skjermbilder | Kundens brukere |
| `Docs/DeliveryPlanner - Forslag til videreutvikling.docx` | 16 forslag i fire faser, der 1, 2, 5 og 12–16 er implementert | Kunde og prosjekt |
| `DeliveryPlanner PLAN.md` | Den opprinnelige planen for versjon 1 | Historikk |
