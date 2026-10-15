namespace Knowit.DeliveryPlanner;

table 78902 "DP Run KBS"
{
    AllowInCustomizations = AsReadOnly;
    Caption = 'DeliveryPlanner-kjøring';
    DataClassification = CustomerContent;
    DataCaptionFields = "Planning Date", "Started At", Status;
    LookupPageId = "DP Runs KBS";
    DrillDownPageId = "DP Runs KBS";

    fields
    {
        field(1; "Run ID"; Guid) { Caption = 'Kjørings-ID'; ToolTip = 'Angir den unike identifikatoren for kjøringen.'; }
        field(2; "Started At"; DateTime) { Caption = 'Startet'; ToolTip = 'Angir når kjøringen startet.'; }
        field(3; "Finished At"; DateTime) { Caption = 'Avsluttet'; ToolTip = 'Angir når kjøringen ble avsluttet.'; }
        field(4; "Planning Date"; Date) { Caption = 'Planleggingsdato'; ToolTip = 'Angir den faktiske datoen som behovet ble beregnet for.'; }
        field(5; "Create Orders"; Boolean) { Caption = 'Opprett ordrer'; ToolTip = 'Angir om kjøringen utfører handlingsmeldingene og frigir overføringsordrene.'; }
        field(6; Status; Enum "DP Run Status KBS") { Caption = 'Status'; ToolTip = 'Angir om kjøringen pågår, er beregnet, er fullført eller har feilet.'; }
        field(7; "User ID"; Code[50]) { Caption = 'Bruker-ID'; DataClassification = EndUserIdentifiableInformation; ToolTip = 'Angir brukeren som startet kjøringen.'; }
        field(8; "Error Text"; Text[2048]) { Caption = 'Feilmelding'; ToolTip = 'Angir årsaken til at kjøringen mislyktes. Ingen nye ordre beholdes etter en feil.'; }
        field(9; "Sales History Days"; Integer) { Caption = 'Dager med salgshistorikk'; ToolTip = 'Angir analyseperioden som ble brukt i kjøringen.'; }
        field(10; "Line Count"; Integer) { Caption = 'Antall linjer'; ToolTip = 'Angir hvor mange kombinasjoner av vare og butikk som ble beregnet.'; }
        field(11; "Snapshot Duration"; Duration) { Caption = 'Tid for beregningsgrunnlag'; ToolTip = 'Angir hvor lang tid det tok å lese salg, beholdning og leveringsplan.'; }
        field(12; "Planning Duration"; Duration) { Caption = 'Tid for planlegging'; ToolTip = 'Angir hvor lang tid standard planberegning og fordeling tok.'; }
        field(13; "Order Duration"; Duration) { Caption = 'Tid for ordreopprettelse'; ToolTip = 'Angir hvor lang tid opprettelse og frigivelse av overføringsordrer tok.'; }
        field(14; "Orders Created"; Integer) { Caption = 'Ordrer opprettet'; ToolTip = 'Angir hvor mange overføringsordrer kjøringen opprettet.'; }
        field(15; "Orders Awaiting Approval"; Integer) { Caption = 'Ordrer til godkjenning'; ToolTip = 'Angir hvor mange av ordrene som ble liggende åpne fordi de var mye større enn butikkens vanlige ordrer.'; }
        field(16; "Stores Checked"; Integer) { Caption = 'Butikker kontrollert for salg'; ToolTip = 'Angir hvor mange butikker salgskontrollen omfattet.'; }
        field(17; "Stores Without Sales"; Integer) { Caption = 'Butikker uten salg i går'; ToolTip = 'Angir hvor mange butikker som ikke hadde bokført salg på noen aktiv vare dagen før planleggingsdatoen.'; }
        field(18; "Sales Warning"; Boolean) { Caption = 'Salgsvarsel'; ToolTip = 'Angir at for mange butikker manglet salg for i går. Salgsimporten var trolig ikke ferdig da kjøringen startet.'; }
    }
    keys
    {
        key(PK; "Run ID") { Clustered = true; }
        key(Started; "Started At") { }
    }
}
