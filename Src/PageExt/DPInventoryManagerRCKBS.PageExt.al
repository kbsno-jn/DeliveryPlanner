namespace Knowit.DeliveryPlanner;

using Microsoft.Warehouse.RoleCenters;

pageextension 78906 "DP Inventory Manager RC KBS" extends "Whse. Basic Role Center"
{
    layout
    {
        addafter(Control1906245608)
        {
            part(DPKPIActivitiesKBS; "DP KPI Activities KBS")
            {
                ApplicationArea = All;
            }
        }
    }
}
