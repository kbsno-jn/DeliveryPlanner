namespace Knowit.DeliveryPlanner;

page 78913 "DP API Store Orders KBS"
{
    PageType = API;
    Caption = 'deliveryStoreOrder', Locked = true;
    APIPublisher = 'knowit';
    APIGroup = 'deliveryPlanner';
    APIVersion = 'v1.0';
    EntityName = 'deliveryStoreOrder';
    EntitySetName = 'deliveryStoreOrders';
    EntityCaption = 'Delivery Store Order', Locked = true;
    EntitySetCaption = 'Delivery Store Orders', Locked = true;
    SourceTable = "DP Store Order KBS";
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
                field(entryNumber; Rec."Entry No.") { Caption = 'Entry No.', Locked = true; }
                field(runId; Rec."Run ID") { Caption = 'Run Id', Locked = true; }
                field(planningDate; Rec."Planning Date") { Caption = 'Planning Date', Locked = true; }
                field(locationCode; Rec."Location Code") { Caption = 'Location Code', Locked = true; }
                field(transferOrderNumber; Rec."Transfer Order No.") { Caption = 'Transfer Order No.', Locked = true; }
                field(quantity; Rec.Quantity) { Caption = 'Quantity', Locked = true; }
                field(averageQuantity; Rec."Average Quantity") { Caption = 'Average Quantity', Locked = true; }
                field(approvalStatus; Rec."Approval Status") { Caption = 'Approval Status', Locked = true; }
            }
        }
    }
}
