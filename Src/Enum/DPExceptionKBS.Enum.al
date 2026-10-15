namespace Knowit.DeliveryPlanner;

enum 78901 "DP Exception KBS"
{
    Extensible = false;
    Caption = 'DeliveryPlanner-avvik';

    value(0; None) { Caption = ' '; }
    value(1; "Missing Setup") { Caption = 'Mangler oppsett'; }
    value(2; "Out of Stock Unmet Need") { Caption = 'Tom – udekket behov'; }
    value(3; "Unmet Need") { Caption = 'Udekket behov'; }
    value(4; "Out of Stock") { Caption = 'Tom i butikk'; }
    value(5; "Over Maximum") { Caption = 'Over makslager'; }
    value(6; "Awaiting Approval") { Caption = 'Venter på godkjenning'; }
}
