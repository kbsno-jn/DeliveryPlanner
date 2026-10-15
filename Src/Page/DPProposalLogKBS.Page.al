namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Transfer;

page 78905 "DP Proposal Log KBS"
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
                Enabled = HasTransferOrder;

                trigger OnAction()
                var
                    TransferHeader: Record "Transfer Header";
                    RunRecord: Record "DP Run KBS";
                begin
                    if Rec."Transfer Order No." = '' then begin
                        if RunRecord.Get(Rec."Run ID") then
                            if not RunRecord."Create Orders" then
                                Error(CalculationOnlyErr);
                        Error(NoOrderErr);
                    end;
                    if not TransferHeader.Get(Rec."Transfer Order No.") then
                        Error(OrderGoneErr, Rec."Transfer Order No.");
                    Page.Run(Page::"Transfer Order", TransferHeader);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        HasTransferOrder := Rec."Transfer Order No." <> '';
    end;

    var
        HasTransferOrder: Boolean;
        CalculationOnlyErr: Label 'Forslaget er fra Beregn DeliveryPlanner, som ikke oppretter ordrer. Bruk Kjør DeliveryPlanner eller vent på nattjobben.';
        NoOrderErr: Label 'Forslaget ble ikke til en overføringsordre fordi tildelt antall er 0. Se begrunnelsen i beregningsgrunnlaget.';
        OrderGoneErr: Label 'Overføringsordre %1 finnes ikke lenger som åpen ordre. Den er trolig ferdig mottatt. Se bokførte overføringer.', Comment = '%1 = transfer order number';
}
