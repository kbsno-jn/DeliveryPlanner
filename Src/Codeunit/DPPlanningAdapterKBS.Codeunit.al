namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;

codeunit 62103 "DP Planning Adapter KBS"
{
    EventSubscriberInstance = Manual;

    var
        PlannerSetup: Record "DP Setup KBS";
        PlannerRun: Record "DP Run KBS";
        CurrentSKU: Record "Stockkeeping Unit";
        CurrentRunLine: Record "DP Run Line KBS";
        Configured: Boolean;
        Calculating: Boolean;
        CarryingOut: Boolean;
        UnexpectedProposalErr: Label 'Standardplanleggingen opprettet et uventet forslag for vare %1, variant %2 og lokasjon %3. DeliveryPlanner-kjøringen er rullet tilbake.', Comment = '%1 = item number, %2 = variant code, %3 = location code';
        MissingProposalErr: Label 'DeliveryPlanner-forslag %1 mangler loggpost. Beregn DeliveryPlanner på nytt.', Comment = '%1 = proposal number';
        RemainingProposalErr: Label 'Standardbehandlingen utførte ikke alle DeliveryPlanner-forslag. Kjøringen er rullet tilbake.';

    procedure Configure(Setup: Record "DP Setup KBS"; RunRecord: Record "DP Run KBS")
    begin
        PlannerSetup := Setup;
        PlannerRun := RunRecord;
        Configured := true;
    end;

    procedure CalculateSKU(SKU: Record "Stockkeeping Unit"; RunLine: Record "DP Run Line KBS")
    var
        Item: Record Item;
        InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting";
        WorksheetType: Option Requisition,Planning;
    begin
        CurrentSKU := SKU;
        CurrentRunLine := RunLine;
        Calculating := true;
        Item.Get(SKU."Item No.");
        Item.SetRange("No.", SKU."Item No.");
        Item.SetRange("Location Filter", SKU."Location Code");
        Item.SetRange("Variant Filter", SKU."Variant Code");
        InventoryProfileOffsetting.SetParm('', 0D, WorksheetType::Requisition);
        // Resiliency is deliberately left off: all proposals form one transaction.
        InventoryProfileOffsetting.CalculatePlanFromWorksheet(
            Item, PlannerSetup."Worksheet Template Name", PlannerSetup."Worksheet Batch Name",
            PlannerRun."Planning Date", PlannerRun."Planning Date" + RunLine."Coverage Days" - 1, true, false);
        TagProposals();
        Calculating := false;
    end;

    procedure CarryOutAndRelease()
    var
        RequisitionLine: Record "Requisition Line";
        TransferHeader: Record "Transfer Header";
        MakeOrder: Codeunit "Req. Wksh.-Make Order";
        ReleaseTransfer: Codeunit "Release Transfer Document";
    begin
        SetOwnedLineFilters(RequisitionLine);
        RequisitionLine.SetRange("Accept Action Message", true);
        RequisitionLine.SetRange("Replenishment System", RequisitionLine."Replenishment System"::Transfer);
        RequisitionLine.SetRange("Action Message", RequisitionLine."Action Message"::New);
        if not RequisitionLine.FindFirst() then
            exit;

        CarryingOut := true;
        MakeOrder.SetSuppressCommit(true);
        MakeOrder.CarryOutBatchAction(RequisitionLine);
        RequisitionLine.Reset();
        SetOwnedLineFilters(RequisitionLine);
        if not RequisitionLine.IsEmpty() then
            Error(RemainingProposalErr);

        TransferHeader.SetRange("DP Run ID KBS", PlannerRun."Run ID");
        if TransferHeader.FindSet(true) then
            repeat
                ReleaseTransfer.Release(TransferHeader);
                TransferHeader.TestField(Status, TransferHeader.Status::Released);
            until TransferHeader.Next() = 0;
        CarryingOut := false;
    end;

    local procedure SetOwnedLineFilters(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.SetRange("Worksheet Template Name", PlannerSetup."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", PlannerSetup."Worksheet Batch Name");
        RequisitionLine.SetRange("DP Run ID KBS", PlannerRun."Run ID");
    end;

    local procedure TagProposals()
    var
        RequisitionLine: Record "Requisition Line";
        EmptyGuid: Guid;
    begin
        RequisitionLine.SetRange("Worksheet Template Name", PlannerSetup."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", PlannerSetup."Worksheet Batch Name");
        RequisitionLine.SetRange("DP Run ID KBS", EmptyGuid);
        if RequisitionLine.FindSet(true) then
            repeat
                if (RequisitionLine.Type <> RequisitionLine.Type::Item) or
                   (RequisitionLine."No." <> CurrentSKU."Item No.") or
                   (RequisitionLine."Variant Code" <> CurrentSKU."Variant Code") or
                   (RequisitionLine."Location Code" <> CurrentSKU."Location Code") or
                   (RequisitionLine."Transfer-from Code" <> PlannerSetup."Hub Location Code") or
                   (RequisitionLine."Replenishment System" <> RequisitionLine."Replenishment System"::Transfer) or
                   (RequisitionLine."Action Message" <> RequisitionLine."Action Message"::New)
                then
                    Error(UnexpectedProposalErr, RequisitionLine."No.", RequisitionLine."Variant Code", RequisitionLine."Location Code");
                RequisitionLine."DP Run ID KBS" := PlannerRun."Run ID";
                RequisitionLine."DP Run Line No. KBS" := CurrentRunLine."Entry No.";
                RequisitionLine."DP Target Qty. KBS" := CurrentRunLine."Target Quantity";
                RequisitionLine."DP Weight KBS" := CurrentRunLine."Allocation Weight";
                RequisitionLine."DP Suggested Qty. KBS" := RequisitionLine."Quantity (Base)";
                // Only the allocation pass may approve the resulting quantity.
                RequisitionLine.Validate("Accept Action Message", false);
                RequisitionLine.Modify(true);
            until RequisitionLine.Next() = 0;
    end;

    local procedure IsCurrentSKU(SKU: Record "Stockkeeping Unit"): Boolean
    begin
        exit(Calculating and (SKU."Item No." = CurrentSKU."Item No.") and
            (SKU."Location Code" = CurrentSKU."Location Code") and
            (SKU."Variant Code" = CurrentSKU."Variant Code"));
    end;

    local procedure IsOwnedLine(RequisitionLine: Record "Requisition Line"): Boolean
    begin
        exit(Configured and (RequisitionLine."Worksheet Template Name" = PlannerSetup."Worksheet Template Name") and
            (RequisitionLine."Journal Batch Name" = PlannerSetup."Worksheet Batch Name") and
            (RequisitionLine."DP Run ID KBS" = PlannerRun."Run ID"));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Planning-Get Parameters", 'OnAfterAdjustInvalidSettings', '', false, false)]
    local procedure OverlayPlanningParameters(var StockkeepingUnit: Record "Stockkeeping Unit"; var PlanningParameters: Record "Planning Parameters")
    begin
        if not IsCurrentSKU(StockkeepingUnit) then
            exit;

        // These are record buffers owned by the standard engine. Never Modify the SKU.
        StockkeepingUnit."Reordering Policy" := StockkeepingUnit."Reordering Policy"::"Maximum Qty.";
        // Maximum Qty. requires maximum > reorder point. With a zero sales/
        // safety target, retain demand planning for open orders or negative stock.
        if CurrentRunLine."Target Quantity" = 0 then
            StockkeepingUnit."Reordering Policy" := StockkeepingUnit."Reordering Policy"::"Lot-for-Lot";
        StockkeepingUnit."Maximum Inventory" := CurrentRunLine."Target Quantity";
        StockkeepingUnit."Reorder Point" := CurrentRunLine."Target Quantity" - CurrentRunLine."Quantity Precision";
        if StockkeepingUnit."Reorder Point" < 0 then
            StockkeepingUnit."Reorder Point" := 0;
        StockkeepingUnit."Include Inventory" := true;
        StockkeepingUnit."Safety Stock Quantity" := CurrentSKU."Safety Stock Quantity";
        StockkeepingUnit."Order Multiple" := CurrentSKU."Order Multiple";
        StockkeepingUnit."Minimum Order Quantity" := 0;
        StockkeepingUnit."Maximum Order Quantity" := 0;
        StockkeepingUnit."Reorder Quantity" := 0;
        StockkeepingUnit."Dampener Quantity" := 0;
        // A zero dampener otherwise falls back to Lot Size * Default Dampener %.
        StockkeepingUnit."Lot Size" := 0;
        StockkeepingUnit."Overflow Level" := CurrentRunLine."Target Quantity";
        Evaluate(StockkeepingUnit."Time Bucket", '<1D>');
        Evaluate(StockkeepingUnit."Dampener Period", '<0D>');
        Evaluate(StockkeepingUnit."Rescheduling Period", '<0D>');
        Evaluate(StockkeepingUnit."Lot Accumulation Period", '<0D>');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnFindCombinationOnBeforeSKUFindSet', '', false, false)]
    local procedure RestrictStoredSKUs(var SKU: Record "Stockkeeping Unit"; var Item: Record Item)
    begin
        if not Calculating then
            exit;
        SKU.SetRange("Item No.", CurrentSKU."Item No.");
        SKU.SetRange("Location Code", CurrentSKU."Location Code");
        SKU.SetRange("Variant Code", CurrentSKU."Variant Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnPlanItemOnBeforeTempSKUFind', '', false, false)]
    local procedure RestrictPlannedSKUs(var TempSKU: Record "Stockkeeping Unit" temporary; var PlanningStartDate: Date)
    begin
        if not Calculating then
            exit;
        TempSKU.SetRange("Item No.", CurrentSKU."Item No.");
        TempSKU.SetRange("Location Code", CurrentSKU."Location Code");
        TempSKU.SetRange("Variant Code", CurrentSKU."Variant Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnCalculatePlanFromWorksheetOnBeforeUnfoldItemTracking', '', false, false)]
    local procedure FreezeExistingSupply(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date; var LineNo: Integer; var TempTrkgReservEntry: Record "Reservation Entry" temporary)
    var
        TempSupply: Record "Inventory Profile" temporary;
    begin
        if not Calculating then
            exit;
        TempSupply.Copy(InventoryProfile, true);
        TempSupply.Reset();
        TempSupply.SetRange("Item No.", CurrentSKU."Item No.");
        TempSupply.SetRange("Variant Code", CurrentSKU."Variant Code");
        TempSupply.SetRange(IsSupply, true);
        if TempSupply.FindSet() then
            repeat
                TempSupply."Planning Flexibility" := TempSupply."Planning Flexibility"::None;
                TempSupply.Modify();
            until TempSupply.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", 'OnCodeOnBeforeInitProgressWindow', '', false, false)]
    local procedure HideOrderProgress(ReqTemplate: Record "Req. Wksh. Template"; var HideProgressWindow: Boolean)
    begin
        if CarryingOut then
            HideProgressWindow := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Carry Out Action", 'OnInsertTransHeaderOnBeforeTransHeaderInsert', '', false, false)]
    local procedure MarkTransferOrder(var TransHeader: Record "Transfer Header"; ReqLine: Record "Requisition Line")
    begin
        if not (CarryingOut and IsOwnedLine(ReqLine)) then
            exit;
        TransHeader."DP Run ID KBS" := PlannerRun."Run ID";
        TransHeader."Posting Date" := PlannerRun."Planning Date";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Carry Out Action", 'OnAfterInsertTransLine', '', false, false)]
    local procedure LinkTransferLine(var TransHeader: Record "Transfer Header"; var ReqLine: Record "Requisition Line"; var TransLine: Record "Transfer Line"; var NextLineNo: Integer)
    var
        Proposal: Record "DP Proposal Log KBS";
    begin
        if not (CarryingOut and IsOwnedLine(ReqLine)) then
            exit;
        TransHeader.TestField("DP Run ID KBS", PlannerRun."Run ID");
        if not Proposal.Get(PlannerRun."Run ID", ReqLine."DP Proposal No. KBS") then
            Error(MissingProposalErr, ReqLine."DP Proposal No. KBS");
        Proposal."Transfer Order No." := TransLine."Document No.";
        Proposal."Transfer Line No." := TransLine."Line No.";
        Proposal.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"DP Worksheet Guard KBS", 'OnCheckAccess', '', false, false)]
    local procedure AllowManagedChanges(RequisitionLine: Record "Requisition Line"; var Allowed: Boolean)
    begin
        if Configured and
           (RequisitionLine."Worksheet Template Name" = PlannerSetup."Worksheet Template Name") and
           (RequisitionLine."Journal Batch Name" = PlannerSetup."Worksheet Batch Name")
        then
            Allowed := true;
    end;
}
