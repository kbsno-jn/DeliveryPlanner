namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Item;

tableextension 78904 "DP Item KBS" extends Item
{
    AllowInCustomizations = AsReadWrite;
    fields
    {
        field(78900; "DP Max. Inv. Small KBS"; Decimal)
        {
            Caption = 'Makslager liten butikk';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            ToolTip = 'Angir makslager i basisenheter for butikker i kategorien SMALL. Opprett standardoppsett overfører verdien til lagerføringsenhetene. 0 betyr at lagerføringsenhetene ikke endres.';
        }
        field(78901; "DP Max. Inv. Medium KBS"; Decimal)
        {
            Caption = 'Makslager mellomstor butikk';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            ToolTip = 'Angir makslager i basisenheter for butikker i kategorien MEDIUM. Opprett standardoppsett overfører verdien til lagerføringsenhetene. 0 betyr at lagerføringsenhetene ikke endres.';
        }
        field(78902; "DP Max. Inv. Large KBS"; Decimal)
        {
            Caption = 'Makslager stor butikk';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            ToolTip = 'Angir makslager i basisenheter for butikker i kategorien LARGE. Opprett standardoppsett overfører verdien til lagerføringsenhetene. 0 betyr at lagerføringsenhetene ikke endres.';
        }
    }
}
