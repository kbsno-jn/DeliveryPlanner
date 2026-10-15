namespace Knowit.DeliveryPlanner;

permissionset 78907 "DP ADMIN KBS"
{
    Assignable = true;
    Caption = 'DeliveryPlanner - Administrasjon';

    Permissions =
        tabledata "DP Setup KBS" = RIMD,
        tabledata "DP Store Category KBS" = RIMD,
        tabledata "DP Run KBS" = RIMD,
        tabledata "DP Run Line KBS" = RIMD,
        tabledata "DP Proposal Log KBS" = RIMD,
        tabledata "DP Allocation Buffer KBS" = RIMD,
        tabledata "DP Store Order KBS" = RIMD,
        tabledata "DP KPI Buffer KBS" = RIMD,
        table "DP Setup KBS" = X,
        table "DP Store Category KBS" = X,
        table "DP Run KBS" = X,
        table "DP Run Line KBS" = X,
        table "DP Proposal Log KBS" = X,
        table "DP Allocation Buffer KBS" = X,
        table "DP Store Order KBS" = X,
        table "DP KPI Buffer KBS" = X,
        page "DP Setup KBS" = X,
        page "DP Store Categories KBS" = X,
        page "DP Assortment KBS" = X,
        page "DP Runs KBS" = X,
        page "DP Run Lines KBS" = X,
        page "DP Proposal Log KBS" = X,
        page "DP Location Batch Update KBS" = X,
        page "DP Exceptions KBS" = X,
        page "DP KPI Activities KBS" = X,
        page "DP KPIs KBS" = X,
        page "DP Store Orders KBS" = X,
        query "DP Daily Item Movement KBS" = X,
        codeunit "DP Management KBS" = X,
        codeunit "DP Worker KBS" = X,
        codeunit "DP Job Queue KBS" = X,
        codeunit "DP Planning Adapter KBS" = X,
        codeunit "DP Worksheet Guard KBS" = X,
        codeunit "DP Inventory KBS" = X,
        codeunit "DP Allocation KBS" = X,
        codeunit "DP Delivery Schedule KBS" = X,
        codeunit "DP Setup Check KBS" = X,
        codeunit "DP KPI Mgt KBS" = X,
        codeunit "DP Notification KBS" = X,
        codeunit "DP Send Email KBS" = X,
        codeunit "DP Approval KBS" = X;
}
