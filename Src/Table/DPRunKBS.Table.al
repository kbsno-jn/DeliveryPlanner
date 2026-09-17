namespace Knowit.DeliveryPlanner;

table 62102 "DP Run KBS"
{
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
    }
    keys
    {
        key(PK; "Run ID") { Clustered = true; }
        key(Started; "Started At") { }
    }
}
