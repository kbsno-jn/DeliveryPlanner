# DeliveryPlanner – Demoguide

Demodatasettet lages av testappen («DeliveryPlanner Tests»), codeunit 70011 `DP Demo Data KBS`. Det er laget for et CRONUS-selskap eller et annet selskap med standard bokføringsoppsett. Bruk en sandkasse: bokførte poster kan ikke slettes igjen.

## Opprette datasettet

1. Installer DeliveryPlanner og DeliveryPlanner Tests i sandkassen.
2. Søk etter **DeliveryPlanner testdata** og velg **Opprett demodatasett (stort)**.
3. Jobben kjører i bakgrunnen i 30–60 minutter. Følg med under **Jobbkøposter**. Ved feil står feilmeldingen i jobbkøloggen.
4. Velg **Klargjør demo for i dag** den dagen du skal vise løsningen.

Krav:
- Brukeren må ha lov til å bokføre 113 dager tilbake i tid. Se «Tillat bokføring fra» i Finansoppsett og Brukeroppsett.
- Selskapet må ha minst én lagervare med bokføringsgrupper. Den brukes som mal.

## Hva som lages

| Område | Innhold |
|---|---|
| Lokasjoner | Hovedlager `DP-HOVED`, transitt `DP-TRANSIT`, 15 butikker `DP-…` |
| Transport | Speditør `DPDEMO` med tjenestene `SOR1D` (1 dag) og `NORD3D` (3 dager), og overføringsruter til alle butikker |
| Butikker | 5 store (LARGE), 5 mellomstore (MEDIUM), 5 små (SMALL). Sør: Oslo, Bergen, Stavanger, Drammen, Kristiansand, Fredrikstad, Hamar, Gjøvik. Nord: Trondheim, Tromsø, Bodø, Narvik, Harstad, Alta, Mo i Rana |
| Leveringsdager | Ulike per butikk. Fredrikstad og Mo i Rana har ingen leveringsdager og fylles hver natt |
| Varer | 80 varer `DPV-001` til `DPV-080` i fem kategorier: mat, drikke, hus, hage og sesong. Kollistørrelse 1, 6 eller 12. Varene 035, 040 og 046 har variantene S, M og L |
| Sortiment | Satt via makslagerfeltene på varekortet og **Opprett standardoppsett**. Små butikker har 30 varer, mellomstore 55 og store alle 80 |
| Salg | 56 dager bokført som enkelttransaksjoner, med mottak på leveringsdagene. Varene går tomme når forsyningen ikke strekker til |
| Salgsmønstre | Stabile, stigende (007, 023, 041, 058), synkende (012, 033, 061), kampanje (015, 047), nye varer (070, 075) og sesongtopp de siste 14 dagene for sesongvarene |
| Historikk | 56 simulerte nattkjøringer med beregningslinjer og butikkordrer, merket med bruker `DEMO`. Tilgjengeligheten bedres de siste fire ukene |

## Scenarioer å vise

| Scenario | Hvor | Hva du ser |
|---|---|---|
| **Salgstakt uten utsolgte dager** | Beregningsgrunnlag, varer med mangel (003, 009, 018, 027, 036, 052) | Dager på lager er lavere enn 56. Daglig salg er høyere enn et flatt snitt ville gitt |
| **Leveringsdager og transport** | Beregningsgrunnlag, kolonnene Leveres nå, Mottaksdato og Neste mottaksdato | Nordbutikker får 3 dagers transport. Butikker uten levering i dag får begrunnelsen «Ingen levering fra denne kjøringen» |
| **Fordeling ved mangel** | Varene 003, 009, 018, 027, 036 og 052 har lite på hovedlageret. 044 og 066 har ingenting | Butikkene fylles opp til like mange dagers dekning. Avvik: Udekket behov og Tom – udekket behov |
| **Godkjenning** | Bodø har fått fire ganger så høyt makslager på de 15 mest solgte varene | Ordren til Bodø blir liggende med «Venter på godkjenning». Frigi den for å godkjenne |
| **Over makslager** | Hamar, varene 002, 004 og 006 | Avvik: Over makslager |
| **Mangler oppsett** | Alta, vare 010 (makslager 0) | Avvik: Mangler oppsett. Resten av kjøringen går som normalt |
| **Blokkert vare** | Vare 078 | Begrunnelse: «Varen eller varianten er blokkert» |
| **Salgsvarsel** | Gjøvik, Narvik og Alta har ikke salg i går | Sett **Varsle ved manglende salg (%)** til 15 og kjør på nytt. Kjøringen får salgsvarsel |
| **Nøkkeltall og trender** | Kø-delen i Inventory Manager, DeliveryPlanner-nøkkeltall, Power BI | 8 uker historikk per butikk og kategori |

## Forslag til demo (20 minutter)

1. **Utgangspunkt:** Vis rollesenteret og nøkkeltallene. Tilgjengeligheten har steget de siste ukene.
2. **Oppsett:** Lokasjonskortet for Tromsø (kategori, leveringsdager), overføringsruten med speditørtjenesten, og varekortet for DPV-001 med makslager per butikkstørrelse.
3. **Beregn:** Velg **Beregn DeliveryPlanner** og vis kladden og beregningsgrunnlaget for en vare med mangel. Vis dager på lager, daglig salg, dekningsdager og fordelingen mellom butikkene.
4. **Kjør:** Velg **Kjør DeliveryPlanner**. Vis butikkordrene, ordren til Bodø som venter på godkjenning, og frigi den.
5. **Avvik:** Gå gjennom avvikslisten: Hamar over makslager, Alta mangler oppsett, og varer med udekket behov.
6. **Power BI:** Vis fanene Ledelse, Innkjøp og Lager og logistikk.

## Merknader

- **Historikken er simulert.** Kjøringene i historikken har ingen ekte overføringsordrer. Ordrenumrene `DEMO-…` finnes ikke i BC.
- **Første ekte kjøring** bruker de bokførte varepostene og lager ekte overføringsordrer fra hovedlageret.
- **Godkjenningsscenarioet er dagsavhengig.** Det virker den dagen du har valgt **Klargjør demo for i dag**. Kjører du **Opprett standardoppsett** etterpå, settes makslageret i Bodø tilbake til verdiene fra varekortet.
