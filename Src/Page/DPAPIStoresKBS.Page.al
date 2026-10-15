namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;

page 78914 "DP API Stores KBS"
{
    PageType = API;
    Caption = 'deliveryStore', Locked = true;
    APIPublisher = 'knowit';
    APIGroup = 'deliveryPlanner';
    APIVersion = 'v1.0';
    EntityName = 'deliveryStore';
    EntitySetName = 'deliveryStores';
    EntityCaption = 'Delivery Store', Locked = true;
    EntitySetCaption = 'Delivery Stores', Locked = true;
    SourceTable = Location;
    SourceTableView = where("Use As In-Transit" = const(false));
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
                field(name; Rec.Name) { Caption = 'Name', Locked = true; }
                field(deliveryPlannerEnabled; Rec."DP Enabled KBS") { Caption = 'DeliveryPlanner Enabled', Locked = true; }
                field(categoryCode; Rec."DP Category Code KBS") { Caption = 'Category Code', Locked = true; }
                field(deliveryMonday; Rec."DP Delivery Monday KBS") { Caption = 'Delivery Monday', Locked = true; }
                field(deliveryTuesday; Rec."DP Delivery Tuesday KBS") { Caption = 'Delivery Tuesday', Locked = true; }
                field(deliveryWednesday; Rec."DP Delivery Wednesday KBS") { Caption = 'Delivery Wednesday', Locked = true; }
                field(deliveryThursday; Rec."DP Delivery Thursday KBS") { Caption = 'Delivery Thursday', Locked = true; }
                field(deliveryFriday; Rec."DP Delivery Friday KBS") { Caption = 'Delivery Friday', Locked = true; }
                field(deliverySaturday; Rec."DP Delivery Saturday KBS") { Caption = 'Delivery Saturday', Locked = true; }
                field(deliverySunday; Rec."DP Delivery Sunday KBS") { Caption = 'Delivery Sunday', Locked = true; }
            }
        }
    }
}
