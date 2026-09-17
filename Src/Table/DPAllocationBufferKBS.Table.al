namespace Knowit.DeliveryPlanner;

table 62105 "DP Allocation Buffer KBS"
{
    Caption = 'DeliveryPlanner-fordelingsbuffer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Location Code"; Code[10]) { Caption = 'Butikklokasjon'; }
        field(2; Need; Decimal) { Caption = 'Behov'; DecimalPlaces = 0 : 5; }
        field(3; Weight; Decimal) { Caption = 'Vekt'; DecimalPlaces = 0 : 5; }
        field(4; Increment; Decimal) { Caption = 'Antallstrinn'; DecimalPlaces = 0 : 5; }
        field(5; Allocation; Decimal) { Caption = 'Tildeling'; DecimalPlaces = 0 : 5; }
        field(6; "Ideal Allocation"; Decimal) { Caption = 'Ideell tildeling'; DecimalPlaces = 0 : 5; }
        field(7; "Run Line Entry No."; Integer) { Caption = 'Beregningslinjenr.'; }
    }
    keys
    {
        key(PK; "Location Code") { Clustered = true; }
    }
}
