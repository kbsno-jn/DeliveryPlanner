namespace Knowit.DeliveryPlanner;

page 78911 "DP API Runs KBS"
{
    PageType = API;
    Caption = 'deliveryRun', Locked = true;
    APIPublisher = 'knowit';
    APIGroup = 'deliveryPlanner';
    APIVersion = 'v1.0';
    EntityName = 'deliveryRun';
    EntitySetName = 'deliveryRuns';
    EntityCaption = 'Delivery Run', Locked = true;
    EntitySetCaption = 'Delivery Runs', Locked = true;
    SourceTable = "DP Run KBS";
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
                field(startedAt; Rec."Started At") { Caption = 'Started At', Locked = true; }
                field(finishedAt; Rec."Finished At") { Caption = 'Finished At', Locked = true; }
                field(planningDate; Rec."Planning Date") { Caption = 'Planning Date', Locked = true; }
                field(status; Rec.Status) { Caption = 'Status', Locked = true; }
                field(createOrders; Rec."Create Orders") { Caption = 'Create Orders', Locked = true; }
                field(salesHistoryDays; Rec."Sales History Days") { Caption = 'Sales History Days', Locked = true; }
                field(lineCount; Rec."Line Count") { Caption = 'Line Count', Locked = true; }
                field(snapshotDuration; Rec."Snapshot Duration") { Caption = 'Snapshot Duration', Locked = true; }
                field(planningDuration; Rec."Planning Duration") { Caption = 'Planning Duration', Locked = true; }
                field(orderDuration; Rec."Order Duration") { Caption = 'Order Duration', Locked = true; }
                field(ordersCreated; Rec."Orders Created") { Caption = 'Orders Created', Locked = true; }
                field(ordersAwaitingApproval; Rec."Orders Awaiting Approval") { Caption = 'Orders Awaiting Approval', Locked = true; }
                field(storesChecked; Rec."Stores Checked") { Caption = 'Stores Checked', Locked = true; }
                field(storesWithoutSales; Rec."Stores Without Sales") { Caption = 'Stores Without Sales', Locked = true; }
                field(salesWarning; Rec."Sales Warning") { Caption = 'Sales Warning', Locked = true; }
                field(errorText; Rec."Error Text") { Caption = 'Error Text', Locked = true; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { Caption = 'Last Modified Date Time', Locked = true; }
            }
        }
    }
}
