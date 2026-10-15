namespace Knowit.DeliveryPlanner;

table 78906 "DP KPI Buffer KBS"
{
    AllowInCustomizations = Never;
    Caption = 'DeliveryPlanner-nøkkeltall';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group Type"; Option)
        {
            Caption = 'Gruppe';
            OptionMembers = Store,Category;
            OptionCaption = 'Butikk,Kategori';
            ToolTip = 'Angir om linjen gjelder en butikk eller en butikkategori.';
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Kode';
            ToolTip = 'Angir butikken eller kategorien.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Beskrivelse';
            ToolTip = 'Angir navnet på butikken eller kategorien.';
        }
        field(4; "Line Count"; Integer)
        {
            Caption = 'Antall varer';
            ToolTip = 'Angir hvor mange aktive kombinasjoner av vare og butikk som ble beregnet.';
        }
        field(5; "Service Level %"; Decimal)
        {
            Caption = 'Servicegrad (%)';
            DecimalPlaces = 0 : 1;
            ToolTip = 'Angir andelen dager i analyseperioden varene var på lager.';
        }
        field(6; "Avg. Days of Cover"; Decimal)
        {
            Caption = 'Snitt dager med dekning';
            DecimalPlaces = 0 : 1;
            ToolTip = 'Angir hvor mange dager beholdning og varer på vei i snitt rekker, for varer med salg. Måles før nattens tildeling.';
        }
        field(7; "Out of Stock"; Integer)
        {
            Caption = 'Tomme varer';
            ToolTip = 'Angir hvor mange varer som var tomme i butikken da kjøringen startet.';
        }
        field(8; "Over Maximum"; Integer)
        {
            Caption = 'Over makslager';
            ToolTip = 'Angir hvor mange varer der beholdning og varer på vei var over makslageret.';
        }
        field(9; "Overstock Quantity"; Decimal)
        {
            Caption = 'Overlager (antall)';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Angir hvor mange enheter beholdning og varer på vei til sammen lå over makslageret.';
        }
        field(10; "Unmet Quantity"; Decimal)
        {
            Caption = 'Udekket antall';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Angir behovet som ikke ble dekket fordi hovedlageret hadde for lite.';
        }
        field(11; "Exception Count"; Integer)
        {
            Caption = 'Avvik';
            ToolTip = 'Angir hvor mange linjer som har et avvik.';
        }
        field(20; "Days In Stock Sum"; Decimal) { Caption = 'Sum dager på lager'; }
        field(21; "History Days Sum"; Decimal) { Caption = 'Sum analysedager'; }
        field(22; "Days of Cover Sum"; Decimal) { Caption = 'Sum dager med dekning'; }
        field(23; "Days of Cover Count"; Integer) { Caption = 'Antall med dekning'; }
    }
    keys
    {
        key(PK; "Group Type", "Code") { Clustered = true; }
    }
}
