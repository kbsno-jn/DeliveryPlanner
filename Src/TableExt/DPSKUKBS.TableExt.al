namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;

tableextension 62101 "DP SKU KBS" extends "Stockkeeping Unit"
{
    fields
    {
        field(62100; "DP Enabled KBS"; Boolean)
        {
            Caption = 'DeliveryPlanner aktivert';
            DataClassification = CustomerContent;
            ToolTip = 'Angir om denne kombinasjonen av vare, variant og butikk skal inngå i automatisk påfylling.';
        }
    }
}
