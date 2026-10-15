namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Transfer;

tableextension 78903 "DP Transfer Header KBS" extends "Transfer Header"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(78900; "DP Run ID KBS"; Guid)
        {
            Caption = 'DeliveryPlanner-kjørings-ID';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Angir DeliveryPlanner-kjøringen som opprettet overføringsordren.';
        }
        field(78901; "DP Approval Status KBS"; Enum "DP Approval Status KBS")
        {
            Caption = 'DeliveryPlanner-godkjenning';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Angir om ordren venter på godkjenning fordi den er mye større enn butikkens vanlige ordrer. Frigi ordren for å godkjenne den, eller slett den for å avvise den.';
        }
    }
    keys
    {
        key(DPRunKBS; "DP Run ID KBS") { }
        key(DPApprovalKBS; "DP Approval Status KBS") { }
    }
}
