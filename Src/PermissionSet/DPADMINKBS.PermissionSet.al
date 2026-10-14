namespace Knowit.DeliveryPlanner;

permissionset 62107 "DP ADMIN KBS"
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
        table "DP Setup KBS" = X,
        table "DP Store Category KBS" = X,
        table "DP Run KBS" = X,
        table "DP Run Line KBS" = X,
        table "DP Proposal Log KBS" = X,
        table "DP Allocation Buffer KBS" = X,
        page "DP Setup KBS" = X,
        page "DP Store Categories KBS" = X,
        page "DP Assortment KBS" = X,
        page "DP Runs KBS" = X,
        page "DP Run Lines KBS" = X,
        page "DP Proposal Log KBS" = X,
        page "DP Location Batch Update KBS" = X,
        codeunit "DP Management KBS" = X,
        codeunit "DP Worker KBS" = X,
        codeunit "DP Job Queue KBS" = X,
        codeunit "DP Planning Adapter KBS" = X,
        codeunit "DP Worksheet Guard KBS" = X,
        codeunit "DP Inventory KBS" = X,
        codeunit "DP Allocation KBS" = X;
}
