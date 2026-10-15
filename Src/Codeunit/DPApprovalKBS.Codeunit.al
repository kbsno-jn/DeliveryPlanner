namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Transfer;

codeunit 78913 "DP Approval KBS"
{
    Permissions = tabledata "DP Store Order KBS" = rim;

    /// <summary>
    /// Average order quantity of the store's latest released or approved orders. Returns 0 when the
    /// store has fewer than HistoryOrders earlier orders, so new stores are never held back.
    /// </summary>
    procedure GetAverageQuantity(StoreCode: Code[10]; HistoryOrders: Integer): Decimal
    var
        StoreOrder: Record "DP Store Order KBS";
        Total: Decimal;
        Counted: Integer;
    begin
        if HistoryOrders < 1 then
            exit(0);
        StoreOrder.SetCurrentKey("Location Code", "Planning Date");
        StoreOrder.SetRange("Location Code", StoreCode);
        StoreOrder.SetFilter("Approval Status", '%1|%2', StoreOrder."Approval Status"::None, StoreOrder."Approval Status"::Approved);
        StoreOrder.SetLoadFields(Quantity);
        StoreOrder.Ascending(false);
        if StoreOrder.FindSet() then
            repeat
                Total += StoreOrder.Quantity;
                Counted += 1;
            until (Counted = HistoryOrders) or (StoreOrder.Next() = 0);
        if Counted < HistoryOrders then
            exit(0);
        exit(Total / Counted);
    end;

    procedure NeedsApproval(Setup: Record "DP Setup KBS"; Quantity: Decimal; AverageQuantity: Decimal): Boolean
    begin
        if (Setup."Approval Factor" <= 0) or (AverageQuantity <= 0) then
            exit(false);
        exit(Quantity > Setup."Approval Factor" * AverageQuantity);
    end;

    procedure GetOrderQuantity(TransferOrderNo: Code[20]): Decimal
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", TransferOrderNo);
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.CalcSums("Quantity (Base)");
        exit(TransferLine."Quantity (Base)");
    end;

    procedure RegisterOrder(RunRecord: Record "DP Run KBS"; TransferHeader: Record "Transfer Header"; Quantity: Decimal; AverageQuantity: Decimal; Status: Enum "DP Approval Status KBS")
    var
        StoreOrder: Record "DP Store Order KBS";
    begin
        StoreOrder.Init();
        StoreOrder."Run ID" := RunRecord."Run ID";
        StoreOrder."Location Code" := TransferHeader."Transfer-to Code";
        StoreOrder."Transfer Order No." := TransferHeader."No.";
        StoreOrder."Planning Date" := RunRecord."Planning Date";
        StoreOrder.Quantity := Quantity;
        StoreOrder."Average Quantity" := AverageQuantity;
        StoreOrder."Approval Status" := Status;
        StoreOrder.Insert(true);
    end;

    // Releasing a held order with the standard Release action is the approval.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Transfer Document", 'OnAfterReleaseTransferDoc', '', false, false)]
    local procedure ApproveOnRelease(var TransferHeader: Record "Transfer Header")
    var
        StoreOrder: Record "DP Store Order KBS";
    begin
        if TransferHeader."DP Approval Status KBS" <> TransferHeader."DP Approval Status KBS"::"Awaiting Approval" then
            exit;
        TransferHeader."DP Approval Status KBS" := TransferHeader."DP Approval Status KBS"::Approved;
        TransferHeader.Modify();
        StoreOrder.SetCurrentKey("Transfer Order No.");
        StoreOrder.SetRange("Transfer Order No.", TransferHeader."No.");
        StoreOrder.SetRange("Approval Status", StoreOrder."Approval Status"::"Awaiting Approval");
        StoreOrder.ModifyAll("Approval Status", StoreOrder."Approval Status"::Approved);
    end;
}
