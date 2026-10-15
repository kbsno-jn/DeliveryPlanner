namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Transfer;

page 78910 "DP Store Orders KBS"
{
    Caption = 'DeliveryPlanner-butikkordrer';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "DP Store Order KBS";
    SourceTableView = sorting("Location Code", "Planning Date") order(descending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Orders)
            {
                field(PlanningDate; Rec."Planning Date") { ApplicationArea = All; }
                field(LocationCode; Rec."Location Code") { ApplicationArea = All; }
                field(TransferOrderNo; Rec."Transfer Order No.") { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field(AverageQuantity; Rec."Average Quantity") { ApplicationArea = All; }
                field(ApprovalStatus; Rec."Approval Status") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(TransferOrder)
            {
                Caption = 'Overføringsordre';
                ApplicationArea = All;
                Image = TransferOrder;
                ToolTip = 'Åpner overføringsordren dersom den fortsatt finnes som åpen ordre.';

                trigger OnAction()
                var
                    TransferHeader: Record "Transfer Header";
                begin
                    if not TransferHeader.Get(Rec."Transfer Order No.") then
                        Error(OrderGoneErr, Rec."Transfer Order No.");
                    Page.Run(Page::"Transfer Order", TransferHeader);
                end;
            }
        }
        area(Promoted)
        {
            actionref(TransferOrderPromoted; TransferOrder) { }
        }
    }

    var
        OrderGoneErr: Label 'Overføringsordre %1 finnes ikke lenger som åpen ordre. Den er ferdig mottatt eller slettet.', Comment = '%1 = transfer order number';
}
