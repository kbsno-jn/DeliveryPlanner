namespace Knowit.DeliveryPlanner;

page 78912 "DP API Run Lines KBS"
{
    PageType = API;
    Caption = 'deliveryRunLine', Locked = true;
    APIPublisher = 'knowit';
    APIGroup = 'deliveryPlanner';
    APIVersion = 'v1.0';
    EntityName = 'deliveryRunLine';
    EntitySetName = 'deliveryRunLines';
    EntityCaption = 'Delivery Run Line', Locked = true;
    EntitySetCaption = 'Delivery Run Lines', Locked = true;
    SourceTable = "DP Run Line KBS";
    SourceTableView = sorting("Planning Date", "Location Code", "Item No.");
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DataAccessIntent = ReadOnly;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId) { Caption = 'Id', Locked = true; }
                field(runId; Rec."Run ID") { Caption = 'Run Id', Locked = true; }
                field(entryNumber; Rec."Entry No.") { Caption = 'Entry No.', Locked = true; }
                field(planningDate; Rec."Planning Date") { Caption = 'Planning Date', Locked = true; }
                field(itemNumber; Rec."Item No.") { Caption = 'Item No.', Locked = true; }
                field(variantCode; Rec."Variant Code") { Caption = 'Variant Code', Locked = true; }
                field(locationCode; Rec."Location Code") { Caption = 'Location Code', Locked = true; }
                field(categoryCode; Rec."Category Code") { Caption = 'Category Code', Locked = true; }
                field(soldQuantity; Rec."Sold Quantity") { Caption = 'Sold Quantity', Locked = true; }
                field(daysInStock; Rec."Days In Stock") { Caption = 'Days In Stock', Locked = true; }
                field(soldLastDay; Rec."Sold Last Day") { Caption = 'Sold Last Day', Locked = true; }
                field(dailySales; Rec."Daily Sales") { Caption = 'Daily Sales', Locked = true; }
                field(daysOfCover; Rec."Days of Cover") { Caption = 'Days of Cover', Locked = true; }
                field(shipsNow; Rec."Ships Now") { Caption = 'Ships Now', Locked = true; }
                field(receiptDate; Rec."Receipt Date") { Caption = 'Receipt Date', Locked = true; }
                field(nextReceiptDate; Rec."Next Receipt Date") { Caption = 'Next Receipt Date', Locked = true; }
                field(coverageDays; Rec."Coverage Days") { Caption = 'Coverage Days', Locked = true; }
                field(targetQuantity; Rec."Target Quantity") { Caption = 'Target Quantity', Locked = true; }
                field(maximumInventory; Rec."Maximum Inventory") { Caption = 'Maximum Inventory', Locked = true; }
                field(inventory; Rec.Inventory) { Caption = 'Inventory', Locked = true; }
                field(incomingQuantity; Rec."Incoming Quantity") { Caption = 'Incoming Quantity', Locked = true; }
                field(outgoingQuantity; Rec."Outgoing Quantity") { Caption = 'Outgoing Quantity', Locked = true; }
                field(capacityQuantity; Rec."Capacity Quantity") { Caption = 'Capacity Quantity', Locked = true; }
                field(needQuantity; Rec."Need Quantity") { Caption = 'Need Quantity', Locked = true; }
                field(suggestedQuantity; Rec."Suggested Quantity") { Caption = 'Suggested Quantity', Locked = true; }
                field(allocatedQuantity; Rec."Allocated Quantity") { Caption = 'Allocated Quantity', Locked = true; }
                field(unmetQuantity; Rec."Unmet Quantity") { Caption = 'Unmet Quantity', Locked = true; }
                field(orderMultiple; Rec."Order Multiple") { Caption = 'Order Multiple', Locked = true; }
                field(allocationWeight; Rec."Allocation Weight") { Caption = 'Allocation Weight', Locked = true; }
                field(exception; Rec.Exception) { Caption = 'Exception', Locked = true; }
                field(reason; Rec.Reason) { Caption = 'Reason', Locked = true; }
            }
        }
    }
}
