namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Transfer;

pageextension 78903 "DP Transfer Order KBS" extends "Transfer Order"
{
    layout
    {
        addlast(General)
        {
            field(DPRunIDKBS; Rec."DP Run ID KBS") { ApplicationArea = All; Importance = Additional; }
            field(DPApprovalStatusKBS; Rec."DP Approval Status KBS") { ApplicationArea = All; Importance = Promoted; StyleExpr = ApprovalStyle; }
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

    trigger OnAfterGetCurrRecord()
    begin
        if Rec."DP Approval Status KBS" = Rec."DP Approval Status KBS"::"Awaiting Approval" then
            ApprovalStyle := 'Unfavorable'
        else
            ApprovalStyle := 'Standard';
    end;

    var
        ApprovalStyle: Text;
}
