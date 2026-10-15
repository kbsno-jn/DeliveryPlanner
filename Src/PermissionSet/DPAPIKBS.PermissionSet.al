namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;

permissionset 78909 "DP API KBS"
{
    Assignable = true;
    Caption = 'DeliveryPlanner - Rapportering';

    // Read-only access for Power BI and other API consumers.
    Permissions =
        tabledata "DP Run KBS" = R,
        tabledata "DP Run Line KBS" = R,
        tabledata "DP Store Order KBS" = R,
        tabledata "DP Store Category KBS" = R,
        tabledata Location = R,
        table "DP Run KBS" = X,
        table "DP Run Line KBS" = X,
        table "DP Store Order KBS" = X,
        table "DP Store Category KBS" = X,
        page "DP API Runs KBS" = X,
        page "DP API Run Lines KBS" = X,
        page "DP API Store Orders KBS" = X,
        page "DP API Stores KBS" = X,
        page "DP API Store Categories KBS" = X;
}
