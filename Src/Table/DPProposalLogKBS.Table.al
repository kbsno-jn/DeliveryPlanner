namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

table 62104 "DP Proposal Log KBS"
{
    Caption = 'DeliveryPlanner-forslagslogg';
    DataClassification = CustomerContent;
    DataCaptionFields = "Item No.", "Variant Code", "Location Code", "Due Date";
    LookupPageId = "DP Proposal Log KBS";
    DrillDownPageId = "DP Proposal Log KBS";
    fields
    {
        field(1; "Run ID"; Guid)
        {
            Caption = 'Kjørings-ID';
            ToolTip = 'Angir kjøringen som forslaget tilhører.';
            TableRelation = "DP Run KBS"."Run ID";
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Løpenummer';
            ToolTip = 'Angir nummeret på forslagslinjen.';
        }
        field(3; "Run Line Entry No."; Integer)
        {
            Caption = 'Beregningslinjenr.';
            ToolTip = 'Angir beregningslinjen for butikken, varen og varianten.';
            TableRelation = "DP Run Line KBS"."Entry No." where("Run ID" = field("Run ID"));
        }
        field(4; "Worksheet Line No."; Integer)
        {
            Caption = 'Kladdelinjenr.';
            ToolTip = 'Angir linjenummeret i rekvisisjonskladden da forslaget ble beregnet.';
        }
        field(5; "Item No."; Code[20])
        {
            Caption = 'Varenr.';
            ToolTip = 'Angir varen i forslaget.';
            TableRelation = Item."No.";
        }
        field(6; "Variant Code"; Code[10])
        {
            Caption = 'Variantkode';
            ToolTip = 'Angir varevarianten i forslaget.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Butikklokasjon';
            ToolTip = 'Angir mottakende butikklokasjon.';
            TableRelation = Location.Code;
        }
        field(8; "Due Date"; Date)
        {
            Caption = 'Forfallsdato';
            ToolTip = 'Angir standardmotorens behovsdato for forslaget.';
        }
        field(9; "Suggested Quantity"; Decimal)
        {
            Caption = 'Standardforslag';
            ToolTip = 'Angir opprinnelig foreslått antall i basisenheter.';
            DecimalPlaces = 0 : 5;
        }
        field(10; "Allocated Quantity"; Decimal)
        {
            Caption = 'Tildelt antall';
            ToolTip = 'Angir endelig tildelt antall i basisenheter.';
            DecimalPlaces = 0 : 5;
        }
        field(11; "Transfer Order No."; Code[20])
        {
            Caption = 'Overføringsordrenr.';
            ToolTip = 'Angir overføringsordren som ble opprettet fra forslaget.';
        }
        field(12; "Transfer Line No."; Integer)
        {
            Caption = 'Overføringslinjenr.';
            ToolTip = 'Angir linjen på den opprettede overføringsordren.';
        }
    }
    keys
    {
        key(PK; "Run ID", "Entry No.") { Clustered = true; }
        key(ByRunLineDate; "Run ID", "Run Line Entry No.", "Due Date", "Entry No.") { }
    }
}
