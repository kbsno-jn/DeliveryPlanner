namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 62105 "DP Inventory KBS"
{
    procedure BuildRunLine(SKU: Record "Stockkeeping Unit"; Setup: Record "DP Setup KBS"; RunRecord: Record "DP Run KBS"; var RunLine: Record "DP Run Line KBS")
    var
        Location: Record Location;
        Category: Record "DP Store Category KBS";
        NetPosition: Decimal;
    begin
        if Setup."Sales History Days" <= 0 then
            Error(HistoryDaysErr);
        RunRecord.TestField("Planning Date");
        Location.Get(SKU."Location Code");
        Category.Get(Location."DP Category Code KBS");

        RunLine."Item No." := SKU."Item No.";
        RunLine."Variant Code" := SKU."Variant Code";
        RunLine."Location Code" := SKU."Location Code";
        RunLine."Category Code" := Category.Code;
        RunLine."Coverage Days" := Category."Coverage Days";
        RunLine."Allocation Weight" := Category."Allocation Weight";
        RunLine."Quantity Precision" := GetQuantityPrecision(SKU."Item No.");
        RunLine."Order Multiple" := SKU."Order Multiple";
        RunLine."Daily Sales" := GetDailySales(SKU, RunRecord."Planning Date", Setup."Sales History Days");
        RunLine."Target Quantity" := Maximum(0, Minimum(SKU."Maximum Inventory",
            Maximum(SKU."Safety Stock Quantity", RunLine."Daily Sales" * Category."Coverage Days")));
        RunLine.Inventory := GetInventory(SKU."Item No.", SKU."Variant Code", SKU."Location Code");
        RunLine."Incoming Quantity" := GetIncoming(SKU."Item No.", SKU."Variant Code", SKU."Location Code");
        RunLine."Outgoing Quantity" := GetOutgoing(SKU."Item No.", SKU."Variant Code", SKU."Location Code");
        RunLine."Capacity Quantity" := Maximum(0, SKU."Maximum Inventory" - Maximum(0, RunLine.Inventory) - RunLine."Incoming Quantity");
        NetPosition := RunLine.Inventory + RunLine."Incoming Quantity" - RunLine."Outgoing Quantity";
        RunLine."Need Quantity" := Minimum(RunLine."Capacity Quantity", Maximum(0, RunLine."Target Quantity" - NetPosition));
        RunLine."Suggested Quantity" := 0;
        RunLine."Allocated Quantity" := 0;
        Clear(RunLine.Reason);
        if RunLine."Need Quantity" = 0 then
            if RunLine."Capacity Quantity" = 0 then
                RunLine.Reason := NoCapacityLbl
            else
                RunLine.Reason := TargetCoveredLbl;
    end;

    procedure GetHubAvailable(ItemNo: Code[20]; VariantCode: Code[10]; HubLocation: Code[10]): Decimal
    var
        SKU: Record "Stockkeeping Unit";
        SafetyStock: Decimal;
    begin
        if SKU.Get(HubLocation, ItemNo, VariantCode) then
            SafetyStock := Maximum(0, SKU."Safety Stock Quantity");
        exit(Maximum(0, GetInventory(ItemNo, VariantCode, HubLocation) - GetOutgoing(ItemNo, VariantCode, HubLocation) - SafetyStock));
    end;

    procedure GetQuantityPrecision(ItemNo: Code[20]): Decimal
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Item.Get(ItemNo);
        if ItemUnitOfMeasure.Get(ItemNo, Item."Base Unit of Measure") then
            if ItemUnitOfMeasure."Qty. Rounding Precision" > 0 then
                exit(ItemUnitOfMeasure."Qty. Rounding Precision");
        exit(0.00001);
    end;

    local procedure GetDailySales(SKU: Record "Stockkeeping Unit"; PlanningDate: Date; HistoryDays: Integer): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        SetLedgerFilters(ItemLedgerEntry, SKU."Item No.", SKU."Variant Code", SKU."Location Code");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange("Posting Date", PlanningDate - HistoryDays, PlanningDate - 1);
        ItemLedgerEntry.CalcSums(Quantity);
        exit(Maximum(0, -ItemLedgerEntry.Quantity) / HistoryDays);
    end;

    local procedure GetInventory(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        SetLedgerFilters(ItemLedgerEntry, ItemNo, VariantCode, LocationCode);
        ItemLedgerEntry.CalcSums(Quantity);
        exit(ItemLedgerEntry.Quantity);
    end;

    local procedure SetLedgerFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Variant Code", VariantCode);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
    end;

    local procedure GetIncoming(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        Incoming: Decimal;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.SetRange("Variant Code", VariantCode);
        PurchaseLine.SetRange("Location Code", LocationCode);
        PurchaseLine.SetRange("Drop Shipment", false);
        PurchaseLine.SetFilter("Outstanding Qty. (Base)", '>0');
        PurchaseLine.CalcSums("Outstanding Qty. (Base)");
        Incoming := PurchaseLine."Outstanding Qty. (Base)";

        SetTransferFilters(TransferLine, ItemNo, VariantCode);
        TransferLine.SetRange("Transfer-to Code", LocationCode);
        // Original lines already include the quantity shipped but not received.
        // Derived lines represent the same in-transit units and must not be added.
        if TransferLine.FindSet() then
            repeat
                Incoming += Maximum(0, TransferLine."Quantity (Base)" - TransferLine."Qty. Received (Base)");
            until TransferLine.Next() = 0;
        exit(Incoming);
    end;

    local procedure GetOutgoing(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]): Decimal
    var
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        Outgoing: Decimal;
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.SetRange("Variant Code", VariantCode);
        SalesLine.SetRange("Location Code", LocationCode);
        SalesLine.SetRange("Drop Shipment", false);
        SalesLine.SetFilter("Outstanding Qty. (Base)", '>0');
        SalesLine.CalcSums("Outstanding Qty. (Base)");
        Outgoing := SalesLine."Outstanding Qty. (Base)";

        SetTransferFilters(TransferLine, ItemNo, VariantCode);
        TransferLine.SetRange("Transfer-from Code", LocationCode);
        TransferLine.SetFilter("Outstanding Qty. (Base)", '>0');
        TransferLine.CalcSums("Outstanding Qty. (Base)");
        Outgoing += TransferLine."Outstanding Qty. (Base)";
        exit(Outgoing + GetOtherPhysicalReservations(ItemNo, VariantCode, LocationCode));
    end;

    local procedure SetTransferFilters(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.SetRange("Variant Code", VariantCode);
        TransferLine.SetRange("Derived From Line No.", 0);
    end;

    local procedure GetOtherPhysicalReservations(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]): Decimal
    var
        SupplyReservation: Record "Reservation Entry";
        DemandReservation: Record "Reservation Entry";
        Reserved: Decimal;
    begin
        SupplyReservation.SetRange("Item No.", ItemNo);
        SupplyReservation.SetRange("Variant Code", VariantCode);
        SupplyReservation.SetRange("Location Code", LocationCode);
        SupplyReservation.SetRange(Positive, true);
        SupplyReservation.SetRange("Source Type", Database::"Item Ledger Entry");
        SupplyReservation.SetRange("Reservation Status", SupplyReservation."Reservation Status"::Reservation);
        if SupplyReservation.FindSet() then
            repeat
                if DemandReservation.Get(SupplyReservation."Entry No.", false) then begin
                    if not IsCountedOutgoing(DemandReservation, ItemNo, VariantCode, LocationCode) then
                        Reserved += Minimum(Abs(SupplyReservation."Quantity (Base)"), Abs(DemandReservation."Quantity (Base)"));
                end else
                    Reserved += Abs(SupplyReservation."Quantity (Base)");
            until SupplyReservation.Next() = 0;
        exit(Reserved);
    end;

    local procedure IsCountedOutgoing(ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]): Boolean
    var
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
    begin
        case ReservationEntry."Source Type" of
            Database::"Sales Line":
                if ReservationEntry."Source Subtype" = SalesLine."Document Type"::Order.AsInteger() then
                    if SalesLine.Get(SalesLine."Document Type"::Order, ReservationEntry."Source ID", ReservationEntry."Source Ref. No.") then
                        exit((SalesLine.Type = SalesLine.Type::Item) and (SalesLine."No." = ItemNo) and
                            (SalesLine."Variant Code" = VariantCode) and (SalesLine."Location Code" = LocationCode) and
                            (not SalesLine."Drop Shipment") and (SalesLine."Outstanding Qty. (Base)" > 0));
            Database::"Transfer Line":
                if ReservationEntry."Source Subtype" = 0 then
                    if TransferLine.Get(ReservationEntry."Source ID", ReservationEntry."Source Ref. No.") then
                        exit((TransferLine."Derived From Line No." = 0) and (TransferLine."Item No." = ItemNo) and
                            (TransferLine."Variant Code" = VariantCode) and (TransferLine."Transfer-from Code" = LocationCode) and
                            (TransferLine."Outstanding Qty. (Base)" > 0));
        end;
        exit(false);
    end;

    local procedure Minimum(Left: Decimal; Right: Decimal): Decimal
    begin
        if Left < Right then
            exit(Left);
        exit(Right);
    end;

    local procedure Maximum(Left: Decimal; Right: Decimal): Decimal
    begin
        if Left > Right then
            exit(Left);
        exit(Right);
    end;

    var
        HistoryDaysErr: Label 'Antall dager med salgshistorikk må være større enn null.';
        NoCapacityLbl: Label 'Ingen ledig kapasitet etter beholdning og inngående ordre.';
        TargetCoveredLbl: Label 'Beholdning og inngående ordre dekker målet.';
}
