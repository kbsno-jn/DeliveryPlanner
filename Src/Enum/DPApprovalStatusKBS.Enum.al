namespace Knowit.DeliveryPlanner;

enum 78902 "DP Approval Status KBS"
{
    Extensible = false;
    Caption = 'DeliveryPlanner-godkjenning';

    value(0; None) { Caption = ' '; }
    value(1; "Awaiting Approval") { Caption = 'Venter på godkjenning'; }
    value(2; Approved) { Caption = 'Godkjent'; }
}
