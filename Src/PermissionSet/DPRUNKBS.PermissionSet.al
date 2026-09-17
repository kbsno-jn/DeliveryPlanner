namespace Knowit.DeliveryPlanner;

permissionset 62108 "DP RUN KBS"
{
    Assignable = true;
    Caption = 'DeliveryPlanner - Kjøring';

    Permissions =
        tabledata "DP Setup KBS" = R,
        tabledata "DP Store Category KBS" = R,
        tabledata "DP Run KBS" = RIMD,
        tabledata "DP Run Line KBS" = RIMD,
        tabledata "DP Proposal Log KBS" = RIMD,
        tabledata "DP Allocation Buffer KBS" = RIMD,
        page "DP Runs KBS" = X,
        page "DP Run Lines KBS" = X,
        page "DP Proposal Log KBS" = X,
        codeunit "DP Management KBS" = X,
        codeunit "DP Worker KBS" = X,
        codeunit "DP Job Queue KBS" = X,
        codeunit "DP Planning Adapter KBS" = X,
        codeunit "DP Worksheet Guard KBS" = X,
        codeunit "DP Inventory KBS" = X,
        codeunit "DP Allocation KBS" = X;
}
