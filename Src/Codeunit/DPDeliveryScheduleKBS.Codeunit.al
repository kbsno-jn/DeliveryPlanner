namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;

codeunit 78908 "DP Delivery Schedule KBS"
{
    /// <summary>
    /// Determines whether an order shipped on the planning date arrives on a delivery day,
    /// and how many days its quantity must cover. Stores without delivery days are replenished
    /// every night and keep the category coverage. Returns false when no delivery day is reachable
    /// within the search horizon.
    /// </summary>
    procedure GetSchedule(HubCode: Code[10]; Store: Record Location; PlanningDate: Date; CategoryCoverageDays: Integer; var ShipsNow: Boolean; var ReceiptDate: Date; var NextReceiptDate: Date; var CoverageDays: Integer): Boolean
    var
        ShipmentDate: Date;
        LaterReceiptDate: Date;
    begin
        ReceiptDate := CalcReceiptDate(HubCode, Store.Code, PlanningDate);
        if not Store.DPHasDeliveryPlanKBS() then begin
            ShipsNow := true;
            NextReceiptDate := 0D;
            CoverageDays := CategoryCoverageDays;
            exit(true);
        end;

        ShipsNow := Store.DPIsDeliveryDayKBS(ReceiptDate);
        // Later nights may ship on a shorter or longer route calendar, so search by shipment date.
        NextReceiptDate := 0D;
        ShipmentDate := PlanningDate + 1;
        while (NextReceiptDate = 0D) and (ShipmentDate <= PlanningDate + MaxSearchDays()) do begin
            LaterReceiptDate := CalcReceiptDate(HubCode, Store.Code, ShipmentDate);
            if (LaterReceiptDate > ReceiptDate) and Store.DPIsDeliveryDayKBS(LaterReceiptDate) then
                NextReceiptDate := LaterReceiptDate;
            ShipmentDate += 1;
        end;
        if NextReceiptDate = 0D then
            exit(false);
        CoverageDays := NextReceiptDate - PlanningDate;
        exit(true);
    end;

    /// <summary>
    /// Returns the first receipt date on a delivery day for an order shipped on or after the planning date.
    /// </summary>
    procedure GetFirstDeliveryDate(HubCode: Code[10]; Store: Record Location; PlanningDate: Date): Date
    var
        ShipmentDate: Date;
        ReceiptDate: Date;
    begin
        ShipmentDate := PlanningDate;
        while ShipmentDate <= PlanningDate + MaxSearchDays() do begin
            ReceiptDate := CalcReceiptDate(HubCode, Store.Code, ShipmentDate);
            if Store.DPIsDeliveryDayKBS(ReceiptDate) then
                exit(ReceiptDate);
            ShipmentDate += 1;
        end;
        exit(0D);
    end;

    /// <summary>
    /// Mirrors the transfer order date calculation: hub outbound handling, the route's shipping
    /// agent service time and store inbound handling, using the locations' base calendars.
    /// </summary>
    procedure CalcReceiptDate(HubCode: Code[10]; StoreCode: Code[10]; ShipmentDate: Date) ReceiptDate: Date
    var
        TransferRoute: Record "Transfer Route";
        Hub: Record Location;
        Store: Record Location;
        ShippingTime: DateFormula;
        InTransitCode: Code[10];
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
    begin
        Hub.Get(HubCode);
        Store.Get(StoreCode);
        TransferRoute.GetTransferRoute(HubCode, StoreCode, InTransitCode, ShippingAgentCode, ShippingAgentServiceCode);
        TransferRoute.GetShippingTime(HubCode, StoreCode, ShippingAgentCode, ShippingAgentServiceCode, ShippingTime);
        TransferRoute.CalcReceiptDate(ShipmentDate, ReceiptDate, ShippingTime,
            Hub."Outbound Whse. Handling Time", Store."Inbound Whse. Handling Time",
            HubCode, StoreCode, ShippingAgentCode, ShippingAgentServiceCode);
    end;

    procedure MaxSearchDays(): Integer
    begin
        exit(28);
    end;
}
