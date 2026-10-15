namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;

table 78907 "DP Store Order KBS"
{
    AllowInCustomizations = AsReadOnly;
    Caption = 'DeliveryPlanner-butikkordre';
    DataClassification = CustomerContent;
    LookupPageId = "DP Store Orders KBS";
    DrillDownPageId = "DP Store Orders KBS";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Løpenummer';
            AutoIncrement = true;
            ToolTip = 'Angir løpenummeret for ordren.';
        }
        field(2; "Run ID"; Guid)
        {
            Caption = 'Kjørings-ID';
            TableRelation = "DP Run KBS"."Run ID";
            ToolTip = 'Angir kjøringen som opprettet ordren.';
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Butikklokasjon';
            TableRelation = Location.Code;
            ToolTip = 'Angir butikken ordren går til.';
        }
        field(4; "Transfer Order No."; Code[20])
        {
            Caption = 'Overføringsordrenr.';
            ToolTip = 'Angir overføringsordren.';
        }
        field(5; "Planning Date"; Date)
        {
            Caption = 'Planleggingsdato';
            ToolTip = 'Angir datoen ordren ble beregnet for.';
        }
        field(6; Quantity; Decimal)
        {
            Caption = 'Antall (basis)';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Angir summen av ordrelinjene i basisenheter.';
        }
        field(7; "Average Quantity"; Decimal)
        {
            Caption = 'Snitt siste ordrer';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Angir snittet av butikkens siste frigitte ordrer da ordren ble opprettet. 0 betyr at butikken hadde for få tidligere ordrer til å sammenligne.';
        }
        field(8; "Approval Status"; Enum "DP Approval Status KBS")
        {
            Caption = 'Godkjenning';
            ToolTip = 'Angir om ordren ble frigitt direkte, venter på godkjenning eller er godkjent.';
        }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByStore; "Location Code", "Planning Date") { }
        key(ByOrder; "Transfer Order No.") { }
    }
}
