namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Item;

pageextension 78904 "DP Item Card KBS" extends "Item Card"
{
    layout
    {
        addafter(Planning)
        {
            group(DeliveryPlannerKBS)
            {
                Caption = 'Delivery planner';

                field(DPMaxInvSmallKBS; Rec."DP Max. Inv. Small KBS") { ApplicationArea = All; }
                field(DPMaxInvMediumKBS; Rec."DP Max. Inv. Medium KBS") { ApplicationArea = All; }
                field(DPMaxInvLargeKBS; Rec."DP Max. Inv. Large KBS") { ApplicationArea = All; }
            }
        }
    }
}
