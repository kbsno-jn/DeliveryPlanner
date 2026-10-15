namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;

pageextension 78901 "DP SKU Card KBS" extends "Stockkeeping Unit Card"
{
    layout
    {
        addlast(General)
        {
            field(DPEnabledKBS; Rec."DP Enabled KBS") { ApplicationArea = All; }
        }
    }
}
