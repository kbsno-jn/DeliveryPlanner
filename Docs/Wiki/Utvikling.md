# Utvikling

## Repo-struktur

```text
app.json                  Appen (78900–78950)
Src/<Objekttype>/         AL-kode, én mappe per objekttype
Tests/app.json            Testappen (70000–70049)
Tests/*.al.test           Testkode. Filendelsen gjør at hovedappen ikke kompilerer den
scripts/Build.ps1         Bygger app og testapp med analysatorer
Docs/                     Spesifikasjon, brukerveiledning, forslag og wiki-kilde
```

## Konvensjoner

- Følger AL-Development-Guidelines: `KBS`-suffiks på alle objekter, `Src/<Objekttype>/<Navn>.<Type>.al`, og CodeCop, UICop og PerTenantExtensionCop aktive.
- Navnerom `Knowit.DeliveryPlanner`.
- Brukertekster (Caption, ToolTip, Label) skrives på norsk bokmål. Telemetritekster og tagger er engelske og har `Locked = true`.
- `AllowInCustomizations` settes på objektnivå: AsReadWrite for oppsett, AsReadOnly for logger og Never for midlertidige tabeller.
- Nye felt på eksisterende oppsett, som ikke kan bruke `InitValue`, får standardverdi i `DP Upgrade KBS` bak en upgrade tag.

## Bygge

Fra VS Code: **AL: Package** med analysatorene aktive (se `.vscode/settings.json`).

Fra kommandolinjen:

```powershell
.\scripts\Build.ps1          # app
.\scripts\Build.ps1 -Tests   # app og testapp
```

`Build.ps1` finner ikke kompilatoren i AL-utvidelse 18.1, fordi `alc.exe` og analysatorene nå ligger direkte i `bin`. På Windows ARM64 starter heller ikke x64-versjonen av `alc.exe`. Kompiler da slik:

```powershell
$bin = "$env:USERPROFILE\.vscode\extensions\ms-dynamics-smb.al-<versjon>\bin"
dotnet "$bin\alc.dll" /project:<kopi av app> /packagecachepath:.alpackages /out:DeliveryPlanner.app `
  "/analyzer:$bin\Microsoft.Dynamics.Nav.CodeCop.dll" `
  "/analyzer:$bin\Microsoft.Dynamics.Nav.UICop.dll" `
  "/analyzer:$bin\Microsoft.Dynamics.Nav.PerTenantExtensionCop.dll"
```

Testappen kompileres på samme måte. Kopier `Tests/*.al.test` til `.al`-filer i en midlertidig mappe sammen med `Tests/app.json`, og bruk en pakkemappe som inneholder den bygde DeliveryPlanner.app.

## Tester

| Codeunit | Dekker |
|---|---|
| 70001 DP Allocation Tests KBS | Fordeling, metning, kolli, dager med dekning |
| 70002 DP Inventory Tests KBS | Salgstakt, utsolgte dager, inngående, utgående, reservasjoner |
| 70003 DP Workflow Tests KBS | Låst kladd |
| 70004 DP Item Maximum Tests KBS | Makslager fra varekortet |
| 70005 DP Location Settings Tests KBS | Masseoppdatering av lokasjoner |
| 70006 DP Delivery Schedule Tests KBS | Leveringsdager og transporttid |
| 70007 DP Exception Tests KBS | Avvikstyper og oppsettskontroll |
| 70008 DP Monitoring Tests KBS | Godkjenning, nøkkeltall og sletting av logger |
| 70010 DP Test Data KBS (codeunit og side) | Testdata for manuell test i sandkasse |

Testene bruker `TransactionModel::AutoRollback`. Kode som testes, kan derfor ikke kalle `Commit`. Det er grunnen til at `DeleteOldRuns` ikke gjør `Commit` selv, men overlater det til `Execute`.

Testene for leveringsplan regner forventet mottaksdato med samme rutefunksjon. Grunnen er at selskapets basiskalender kan flytte datoer i testmiljøet.

## Fallgruver i AL

- **`and` og `or` kortslutter ikke.** I `while HasRow and (Query.Posting_Date = Day)` leses kolonnen også når `HasRow` er usann, og det gir kjøretidsfeil. Mellomlagre verdien, eller bruk nøstede `if`.
- **Validering kan kalle `Modify`.** `Transfer-from Code` på Stockkeeping Unit kaller `Modify(true)` i `OnValidate`. Sett derfor inn posten før du validerer feltet.
- **`Codeunit.Run` med returverdi** krever at det ikke finnes en åpen skrivetransaksjon. Gjør `Commit` før e-post sendes.
- **Ikke `Commit` i worker.** `CommitBehavior::Error` gjør at det feiler med en gang.
- **AL-språktjenesten i VS Code** viser ofte gamle feil etter at filer er endret utenfor editoren. Kjør **Developer: Reload Window** før du stoler på problemlisten.

## ID-område

- Appen bruker **78900–78950**. Området ble flyttet fra 62100–62149 fordi tabell 62100 var i bruk av en annen app i kundens miljø.
- **Kjent konflikt med RolleSenter** (78900–78949): page 78900 og pageextension 78901–78902. Appene kan ikke installeres i samme miljø.
- Hverken DeliveryPlanner eller RolleSenter står i listen over delte apper i AL-Development-Guidelines. Listen bør oppdateres.

## Pull requests

- Lag en branch fra `main`, og opprett pull request mot `main`.
- Ta med `AB#<arbeidsoppgave>` i tittel eller beskrivelse, slik at den kobles til DevOps.
- Kompiler app og testapp uten advarsler, og kjør testappen i sandkasse før merge.
- Ikke commit Word-låsefiler (`~$*.docx`).
