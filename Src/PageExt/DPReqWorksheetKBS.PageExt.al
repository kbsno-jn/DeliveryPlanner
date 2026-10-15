namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Requisition;

pageextension 78902 "DP Req Worksheet KBS" extends "Req. Worksheet"
{
    layout
    {
        modify(Control1)
        {
            Editable = not ManagedWorksheet;
        }
        addafter(Control120)
        {
            group(DPInformationKBS)
            {
                ShowCaption = false;
                Visible = ManagedWorksheet;
                field(DPManagedInformationKBS; ManagedInformationLbl)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    ToolTip = 'DeliveryPlanner beregner linjene på nytt før ordreopprettelse. Endre butikkategori eller SKU-oppsett for å justere påfyllingen.';
                }
            }
        }
        addafter(Quantity)
        {
            field(DPSuggestedQtyKBS; Rec."DP Suggested Qty. KBS") { ApplicationArea = All; Visible = ManagedWorksheet; }
            field(DPAllocatedQtyKBS; Rec."Quantity (Base)")
            {
                Caption = 'DeliveryPlanner-tildeling (basis)';
                ApplicationArea = All;
                Editable = false;
                Visible = ManagedWorksheet;
                ToolTip = 'Angir det tildelte antallet i basisenheter etter kapasitetskontroll og vektet fordeling.';
            }
            field(DPTargetQtyKBS; Rec."DP Target Qty. KBS") { ApplicationArea = All; Visible = ManagedWorksheet; }
            field(DPWeightKBS; Rec."DP Weight KBS") { ApplicationArea = All; Visible = ManagedWorksheet; }
            field(DPReasonKBS; Rec."DP Reason KBS") { ApplicationArea = All; Visible = ManagedWorksheet; }
            field(DPRunIDKBS; Rec."DP Run ID KBS") { ApplicationArea = All; Visible = false; }
        }
    }
    actions
    {
        modify(CalculatePlan) { Enabled = not ManagedWorksheet; }
        modify(CarryOutActionMessage) { Enabled = not ManagedWorksheet; }
        modify("Delete All") { Enabled = not ManagedWorksheet; }
        modify(Reserve) { Enabled = not ManagedWorksheet; }
        modify(Dimensions) { Enabled = not ManagedWorksheet; }
        modify("Item &Tracking Lines") { Enabled = not ManagedWorksheet; }
        modify("Get &Sales Orders") { Enabled = not ManagedWorksheet; }
        modify("Sales &Order") { Enabled = not ManagedWorksheet; }
        modify(Action53) { Enabled = not ManagedWorksheet; }
        modify(Action75) { Enabled = not ManagedWorksheet; }
        modify(EditInExcel) { Enabled = not ManagedWorksheet; }

        addlast(Processing)
        {
            group(DeliveryPlannerKBS)
            {
                Caption = 'DeliveryPlanner';
                Visible = ManagedWorksheet;
                action(DPCalculateKBS)
                {
                    Caption = 'Beregn DeliveryPlanner';
                    ApplicationArea = All;
                    Image = CalculatePlan;
                    ToolTip = 'Beregner standardforslagene på nytt og oppdaterer kapasitet og vektet tildeling i kladden.';

                    trigger OnAction()
                    var
                        Management: Codeunit "DP Management KBS";
                    begin
                        Management.Calculate();
                        CurrPage.Update(false);
                    end;
                }
                action(DPRunKBS)
                {
                    Caption = 'Kjør DeliveryPlanner';
                    ApplicationArea = All;
                    Image = CarryOutActionMessage;
                    ToolTip = 'Beregner forslagene på nytt, utfører handlingsmeldingene og frigir overføringsordrene.';

                    trigger OnAction()
                    var
                        Management: Codeunit "DP Management KBS";
                    begin
                        Management.RunPlanner();
                        CurrPage.Update(false);
                    end;
                }
                action(DPHistoryKBS)
                {
                    Caption = 'DeliveryPlanner-kjøringslogg';
                    ApplicationArea = All;
                    Image = Log;
                    ToolTip = 'Viser kjøringer med beregningsgrunnlag, opprettede ordre og eventuelle feil.';
                    RunObject = page "DP Runs KBS";
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetManagedWorksheet();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetManagedWorksheet();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetManagedWorksheet();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CheckManualChange();
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CheckManualChange();
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CheckManualChange();
        exit(true);
    end;

    var
        ManagedWorksheet: Boolean;
        ManagedInformationLbl: Label 'Systemstyrt kladd. Bruk Beregn DeliveryPlanner eller Kjør DeliveryPlanner.';
        ManagedWorksheetErr: Label 'DeliveryPlanner-linjer kan bare endres gjennom Beregn DeliveryPlanner eller Kjør DeliveryPlanner.';

    local procedure SetManagedWorksheet()
    var
        Setup: Record "DP Setup KBS";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        ManagedWorksheet := not IsNullGuid(Rec."DP Run ID KBS");
        if ManagedWorksheet then
            exit;
        if not Setup.Get('') then
            exit;
        if (Setup."Worksheet Template Name" = '') or (Setup."Worksheet Batch Name" = '') then
            exit;
        TemplateName := Rec."Worksheet Template Name";
        BatchName := Rec."Journal Batch Name";
        if (TemplateName = '') and (Rec.GetFilter("Worksheet Template Name") <> '') then
            TemplateName := Rec.GetRangeMin("Worksheet Template Name");
        if (BatchName = '') and (Rec.GetFilter("Journal Batch Name") <> '') then
            BatchName := Rec.GetRangeMin("Journal Batch Name");
        ManagedWorksheet := (TemplateName = Setup."Worksheet Template Name") and (BatchName = Setup."Worksheet Batch Name");
    end;

    local procedure CheckManualChange()
    begin
        SetManagedWorksheet();
        if ManagedWorksheet then
            Error(ManagedWorksheetErr);
    end;
}
