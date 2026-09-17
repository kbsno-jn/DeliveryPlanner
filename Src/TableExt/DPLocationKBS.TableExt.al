namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;

tableextension 62100 "DP Location KBS" extends Location
{
    fields
    {
        field(62100; "DP Enabled KBS"; Boolean)
        {
            Caption = 'DeliveryPlanner aktivert';
            DataClassification = CustomerContent;
            ToolTip = 'Angir om lokasjonen er en butikk som skal forsynes av DeliveryPlanner. Aktiver også ønskede lagerføringsenheter.';

            trigger OnValidate()
            var
                Setup: Record "DP Setup KBS";
            begin
                if not "DP Enabled KBS" then
                    exit;
                TestField("Use As In-Transit", false);
                if Setup.Get('') then
                    if Code = Setup."Hub Location Code" then
                        Error(HubCannotBeStoreErr);
            end;
        }
        field(62101; "DP Category Code KBS"; Code[10])
        {
            Caption = 'DeliveryPlanner-butikkategori';
            DataClassification = CustomerContent;
            TableRelation = "DP Store Category KBS".Code;
            ToolTip = 'Angir butikkens dekningsdager og vekt ved fordeling av knapp beholdning.';
        }
    }
    var
        HubCannotBeStoreErr: Label 'Hovedlageret kan ikke aktiveres som butikk i DeliveryPlanner.';
}
