namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Requisition;

tableextension 62102 "DP Req Line KBS" extends "Requisition Line"
{
    fields
    {
        field(62100; "DP Run ID KBS"; Guid)
        {
            Caption = 'DeliveryPlanner-kjørings-ID';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Angir kjøringen som opprettet denne systemstyrte linjen.';
        }
        field(62101; "DP Run Line No. KBS"; Integer)
        {
            Caption = 'DeliveryPlanner-beregningslinje';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Angir beregningslinjen for varen, varianten og butikken.';
        }
        field(62102; "DP Proposal No. KBS"; Integer)
        {
            Caption = 'DeliveryPlanner-forslagsnr.';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Angir linjen i forslagsloggen som bevares etter ordreopprettelse.';
        }
        field(62103; "DP Target Qty. KBS"; Decimal)
        {
            Caption = 'DeliveryPlanner-lagermål';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
            ToolTip = 'Angir målet for butikkens beholdning i basisenheter.';
        }
        field(62104; "DP Weight KBS"; Decimal)
        {
            Caption = 'DeliveryPlanner-vekt';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
            ToolTip = 'Angir butikkens relative fordelingsvekt ved knapp beholdning.';
        }
        field(62105; "DP Suggested Qty. KBS"; Decimal)
        {
            Caption = 'DeliveryPlanner-standardforslag';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
            ToolTip = 'Angir standardmotorens forslag i basisenheter før kapasitetskontroll og vektet fordeling.';
        }
        field(62106; "DP Reason KBS"; Text[250])
        {
            Caption = 'DeliveryPlanner-begrunnelse';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Angir årsaken til eventuelle begrensninger i det tildelte antallet.';
        }
    }
    keys
    {
        key(DPRunKBS; "DP Run ID KBS", "DP Run Line No. KBS") { }
    }
}
