namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;

tableextension 78901 "DP SKU KBS" extends "Stockkeeping Unit"
{
    AllowInCustomizations = AsReadWrite;
    fields
    {
        field(78900; "DP Enabled KBS"; Boolean)
        {
            Caption = 'DeliveryPlanner aktivert';
            DataClassification = CustomerContent;
            ToolTip = 'Angir om denne kombinasjonen av vare, variant og butikk skal inngå i automatisk påfylling.';
        }
    }
}
