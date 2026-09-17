namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Transfer;

page 62105 "DP Proposal Log KBS"
{
    Caption = 'DeliveryPlanner-forslag og ordre';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "DP Proposal Log KBS";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Proposals)
            {
                field(Field1; Rec."Run ID") { ApplicationArea = All; Visible = false; }
                field(Field2; Rec."Entry No.") { ApplicationArea = All; Visible = false; }
                field(Field3; Rec."Run Line Entry No.") { ApplicationArea = All; Visible = false; }
                field(Field4; Rec."Worksheet Line No.") { ApplicationArea = All; }
                field(Field5; Rec."Item No.") { ApplicationArea = All; }
                field(Field6; Rec."Variant Code") { ApplicationArea = All; }
                field(Field7; Rec."Location Code") { ApplicationArea = All; }
                field(Field8; Rec."Due Date") { ApplicationArea = All; }
                field(Field9; Rec."Suggested Quantity") { ApplicationArea = All; }
                field(Field10; Rec."Allocated Quantity") { ApplicationArea = All; }
                field(Field11; Rec."Transfer Order No.") { ApplicationArea = All; }
                field(Field12; Rec."Transfer Line No.") { ApplicationArea = All; }
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
                ToolTip = 'Åpner den opprettede overføringsordren dersom den fortsatt finnes som åpen ordre.';

                trigger OnAction()
                var
                    TransferHeader: Record "Transfer Header";
                begin
                    Rec.TestField("Transfer Order No.");
                    TransferHeader.Get(Rec."Transfer Order No.");
                    Page.Run(Page::"Transfer Order", TransferHeader);
                end;
            }
        }
    }
}
