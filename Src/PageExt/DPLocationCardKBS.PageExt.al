namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;

pageextension 62100 "DP Location Card KBS" extends "Location Card"
{
    layout
    {
        addlast(General)
        {
            field(DPEnabledKBS; Rec."DP Enabled KBS") { ApplicationArea = All; }
            field(DPCategoryCodeKBS; Rec."DP Category Code KBS") { ApplicationArea = All; }
        }
    }
    actions
    {
        addlast(Navigation)
        {
            action(DPAssortmentKBS)
            {
                Caption = 'DeliveryPlanner-sortiment';
                ApplicationArea = All;
                Image = ItemAvailability;
                ToolTip = 'Åpner lagerføringsenhetene for denne lokasjonen slik at du kan velge sortiment og makslager.';
                RunObject = page "DP Assortment KBS";
                RunPageLink = "Location Code" = field(Code);
            }
        }
    }
}
