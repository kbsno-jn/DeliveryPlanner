namespace Knowit.DeliveryPlanner;

page 78915 "DP API Store Categories KBS"
{
    PageType = API;
    Caption = 'deliveryStoreCategory', Locked = true;
    APIPublisher = 'knowit';
    APIGroup = 'deliveryPlanner';
    APIVersion = 'v1.0';
    EntityName = 'deliveryStoreCategory';
    EntitySetName = 'deliveryStoreCategories';
    EntityCaption = 'Delivery Store Category', Locked = true;
    EntitySetCaption = 'Delivery Store Categories', Locked = true;
    SourceTable = "DP Store Category KBS";
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
                field(code; Rec.Code) { Caption = 'Code', Locked = true; }
                field(description; Rec.Description) { Caption = 'Description', Locked = true; }
                field(coverageDays; Rec."Coverage Days") { Caption = 'Coverage Days', Locked = true; }
                field(allocationWeight; Rec."Allocation Weight") { Caption = 'Allocation Weight', Locked = true; }
            }
        }
    }
}
