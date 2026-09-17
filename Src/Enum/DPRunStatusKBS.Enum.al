namespace Knowit.DeliveryPlanner;

enum 62100 "DP Run Status KBS"
{
    Extensible = false;
    Caption = 'DeliveryPlanner-status';

    value(0; Running) { Caption = 'Kjører'; }
    value(1; Calculated) { Caption = 'Beregnet'; }
    value(2; Completed) { Caption = 'Fullført'; }
    value(3; Failed) { Caption = 'Mislykket'; }
}
