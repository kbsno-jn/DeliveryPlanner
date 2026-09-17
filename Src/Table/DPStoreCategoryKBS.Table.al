namespace Knowit.DeliveryPlanner;

table 62101 "DP Store Category KBS"
{
    Caption = 'DeliveryPlanner-butikkategori';
    DataClassification = CustomerContent;
    LookupPageId = "DP Store Categories KBS";
    DrillDownPageId = "DP Store Categories KBS";
    DataCaptionFields = Code, Description;

    fields
    {
        field(1; Code; Code[10])
        {
            Caption = 'Kode';
            NotBlank = true;
            ToolTip = 'Angir en unik kode for butikkategorien.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Beskrivelse';
            ToolTip = 'Angir navn eller beskrivelse for butikkategorien.';
        }
        field(3; "Coverage Days"; Integer)
        {
            Caption = 'Dekningsdager';
            MinValue = 1;
            InitValue = 7;
            ToolTip = 'Angir hvor mange dager med gjennomsnittlig salg butikkens lagermål skal dekke.';
        }
        field(4; "Allocation Weight"; Decimal)
        {
            Caption = 'Fordelingsvekt';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            InitValue = 1;
            ToolTip = 'Angir butikkens relative andel fra første enhet når hovedlageret ikke kan dekke alle behov.';

            trigger OnValidate()
            begin
                if "Allocation Weight" <= 0 then
                    Error(PositiveWeightErr);
            end;
        }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
    fieldgroups
    {
        fieldgroup(DropDown; Code, Description, "Coverage Days", "Allocation Weight") { }
    }

    var
        PositiveWeightErr: Label 'Fordelingsvekten må være større enn null.';
}
