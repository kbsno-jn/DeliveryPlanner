namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;

tableextension 78900 "DP Location KBS" extends Location
{
    AllowInCustomizations = AsReadWrite;
    fields
    {
        field(78900; "DP Enabled KBS"; Boolean)
        {
            Caption = 'DeliveryPlanner aktivert';
            DataClassification = CustomerContent;
            ToolTip = 'Angir om lokasjonen er en butikk som skal forsynes av DeliveryPlanner. Aktiver også ønskede lagerføringsenheter.';

            trigger OnValidate()
            var
                Setup: Record "DP Setup KBS";
            begin
                if not "DP Enabled KBS" then
                    exit;
                TestField("Use As In-Transit", false);
                if Setup.Get('') then
                    if Code = Setup."Hub Location Code" then
                        Error(HubCannotBeStoreErr);
            end;
        }
        field(78901; "DP Category Code KBS"; Code[10])
        {
            Caption = 'DeliveryPlanner-butikkategori';
            DataClassification = CustomerContent;
            TableRelation = "DP Store Category KBS".Code;
            ToolTip = 'Angir butikkens vekt ved like mange dagers dekning, og dekningsdager når butikken ikke har leveringsdager.';
        }
        field(78902; "DP Delivery Monday KBS"; Boolean)
        {
            Caption = 'Levering mandag';
            DataClassification = CustomerContent;
            ToolTip = 'Angir at varer fra hovedlageret kommer frem til butikken på mandager. Uten leveringsdager fylles butikken hver natt.';
        }
        field(78903; "DP Delivery Tuesday KBS"; Boolean)
        {
            Caption = 'Levering tirsdag';
            DataClassification = CustomerContent;
            ToolTip = 'Angir at varer fra hovedlageret kommer frem til butikken på tirsdager. Uten leveringsdager fylles butikken hver natt.';
        }
        field(78904; "DP Delivery Wednesday KBS"; Boolean)
        {
            Caption = 'Levering onsdag';
            DataClassification = CustomerContent;
            ToolTip = 'Angir at varer fra hovedlageret kommer frem til butikken på onsdager. Uten leveringsdager fylles butikken hver natt.';
        }
        field(78905; "DP Delivery Thursday KBS"; Boolean)
        {
            Caption = 'Levering torsdag';
            DataClassification = CustomerContent;
            ToolTip = 'Angir at varer fra hovedlageret kommer frem til butikken på torsdager. Uten leveringsdager fylles butikken hver natt.';
        }
        field(78906; "DP Delivery Friday KBS"; Boolean)
        {
            Caption = 'Levering fredag';
            DataClassification = CustomerContent;
            ToolTip = 'Angir at varer fra hovedlageret kommer frem til butikken på fredager. Uten leveringsdager fylles butikken hver natt.';
        }
        field(78907; "DP Delivery Saturday KBS"; Boolean)
        {
            Caption = 'Levering lørdag';
            DataClassification = CustomerContent;
            ToolTip = 'Angir at varer fra hovedlageret kommer frem til butikken på lørdager. Uten leveringsdager fylles butikken hver natt.';
        }
        field(78908; "DP Delivery Sunday KBS"; Boolean)
        {
            Caption = 'Levering søndag';
            DataClassification = CustomerContent;
            ToolTip = 'Angir at varer fra hovedlageret kommer frem til butikken på søndager. Uten leveringsdager fylles butikken hver natt.';
        }
    }

    procedure DPHasDeliveryPlanKBS(): Boolean
    begin
        exit("DP Delivery Monday KBS" or "DP Delivery Tuesday KBS" or "DP Delivery Wednesday KBS" or
            "DP Delivery Thursday KBS" or "DP Delivery Friday KBS" or "DP Delivery Saturday KBS" or "DP Delivery Sunday KBS");
    end;

    procedure DPIsDeliveryDayKBS(ReceiptDate: Date): Boolean
    begin
        case Date2DWY(ReceiptDate, 1) of
            1:
                exit("DP Delivery Monday KBS");
            2:
                exit("DP Delivery Tuesday KBS");
            3:
                exit("DP Delivery Wednesday KBS");
            4:
                exit("DP Delivery Thursday KBS");
            5:
                exit("DP Delivery Friday KBS");
            6:
                exit("DP Delivery Saturday KBS");
            7:
                exit("DP Delivery Sunday KBS");
        end;
    end;

    var
        HubCannotBeStoreErr: Label 'Hovedlageret kan ikke aktiveres som butikk i DeliveryPlanner.';
}
