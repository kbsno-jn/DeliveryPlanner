namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Transfer;

tableextension 62103 "DP Transfer Header KBS" extends "Transfer Header"
{
    fields
    {
        field(62100; "DP Run ID KBS"; Guid)
        {
            Caption = 'DeliveryPlanner-kjørings-ID';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Angir DeliveryPlanner-kjøringen som opprettet overføringsordren.';
        }
    }
    keys
    {
        key(DPRunKBS; "DP Run ID KBS") { }
    }
}
