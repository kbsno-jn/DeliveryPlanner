namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Transfer;

pageextension 62103 "DP Transfer Order KBS" extends "Transfer Order"
{
    layout
    {
        addlast(General)
        {
            field(DPRunIDKBS; Rec."DP Run ID KBS") { ApplicationArea = All; Importance = Additional; }
        }
    }
    actions
    {
        addlast(Navigation)
        {
            action(DPRunKBS)
            {
                Caption = 'DeliveryPlanner-kjøring';
                ApplicationArea = All;
                Image = Log;
                ToolTip = 'Viser DeliveryPlanner-kjøringen som opprettet denne overføringsordren.';
                RunObject = page "DP Runs KBS";
                RunPageLink = "Run ID" = field("DP Run ID KBS");
            }
        }
    }
}
