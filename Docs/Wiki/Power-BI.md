# Power BI

DeliveryPlanner har API-sider for rapportering. Rapporten har tre faner: **Ledelse**, **Innkjøp** og **Lager og logistikk**.

Den fullstendige spesifikasjonen, med datamodell, Power Query, DAX-mål og innhold i fanene, står i `Docs/PowerBI/DeliveryPlanner - Power BI-rapport.md`.

## API

Publisher `knowit`, gruppe `deliveryPlanner`, versjon `v1.0`:

| Entitetssett | Innhold |
|---|---|
| `deliveryRuns` | Kjøringer: status, tidsbruk, ordretall, salgskontroll |
| `deliveryRunLines` | Beregningsgrunnlag per vare, variant og butikk per kjøring. Filtrer på `planningDate` |
| `deliveryStoreOrders` | Opprettede ordrer med snitt og godkjenningsstatus |
| `deliveryStores` | Butikker med kategori og leveringsdager |
| `deliveryStoreCategories` | Kategorier |

```text
https://api.businesscentral.dynamics.com/v2.0/<tenant>/<miljø>/api/knowit/deliveryPlanner/v1.0/companies(<firma-id>)/deliveryRunLines?$filter=planningDate ge 2026-10-01
```

## Tilgang

Gi kontoen Power BI bruker rettighetssettet **DP API KBS** («DeliveryPlanner - Rapportering») og lesetilgang til varer, for eksempel **D365 READ**.

## Viktig å vite

- **Øyeblikksbilde per natt:** Beregningslinjene viser tilstanden hver natt. Summer aldri beholdning eller tomme varer over flere datoer. Bruk siste natt, eller snitt per natt.
- **Én kjøring per dato:** Bruk bare den siste fullførte kjøringen med ordreopprettelse per dato, slik at manuelle «Beregn»-kjøringer ikke telles.
- **Historikk:** BC sletter kjøringer etter «Behold kjøringslogg (dager)». Bruk inkrementell oppdatering i Power BI for å beholde historikken.
