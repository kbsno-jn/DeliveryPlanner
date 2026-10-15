namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

table 78903 "DP Run Line KBS"
{
    AllowInCustomizations = AsReadOnly;
    Caption = 'DeliveryPlanner-beregningslinje';
    DataClassification = CustomerContent;
    DataCaptionFields = "Item No.", "Variant Code", "Location Code";
    LookupPageId = "DP Run Lines KBS";
    DrillDownPageId = "DP Run Lines KBS";
    fields
    {
        field(1; "Run ID"; Guid)
        {
            Caption = 'Kjørings-ID';
            ToolTip = 'Angir kjøringen som beregningen tilhører.';
            TableRelation = "DP Run KBS"."Run ID";
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Løpenummer';
            ToolTip = 'Angir nummeret på beregningslinjen.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Varenr.';
            ToolTip = 'Angir varen som beregningen gjelder.';
            TableRelation = Item."No.";
        }
        field(4; "Variant Code"; Code[10])
        {
            Caption = 'Variantkode';
            ToolTip = 'Angir varevarianten som beregningen gjelder.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(5; "Location Code"; Code[10])
        {
            Caption = 'Butikklokasjon';
            ToolTip = 'Angir butikken som skal forsynes.';
            TableRelation = Location.Code;
        }
        field(6; "Category Code"; Code[10])
        {
            Caption = 'Butikkategori';
            ToolTip = 'Angir butikkategorien på beregningstidspunktet.';
        }
        field(7; "Daily Sales"; Decimal)
        {
            Caption = 'Daglig salg';
            ToolTip = 'Angir netto gjennomsnittlig salg per kalenderdag i basisenheter.';
            DecimalPlaces = 0 : 5;
        }
        field(8; "Target Quantity"; Decimal)
        {
            Caption = 'Lagermål';
            ToolTip = 'Angir målet beregnet fra salg og sikkerhetslager, begrenset av makslager.';
            DecimalPlaces = 0 : 5;
        }
        field(9; "Inventory"; Decimal)
        {
            Caption = 'Beholdning';
            ToolTip = 'Angir bokført beholdning i basisenheter på beregningstidspunktet.';
            DecimalPlaces = 0 : 5;
        }
        field(10; "Incoming Quantity"; Decimal)
        {
            Caption = 'Inngående antall';
            ToolTip = 'Angir gjenstående mottak fra innkjøpsordre og overføringer, inklusive varer underveis.';
            DecimalPlaces = 0 : 5;
        }
        field(11; "Outgoing Quantity"; Decimal)
        {
            Caption = 'Bundet utgående antall';
            ToolTip = 'Angir åpne utgående forpliktelser og øvrige reservasjoner uten dobbelt fradrag.';
            DecimalPlaces = 0 : 5;
        }
        field(12; "Capacity Quantity"; Decimal)
        {
            Caption = 'Ledig kapasitet';
            ToolTip = 'Angir hvor mange basisenheter butikken kan motta innenfor makslageret.';
            DecimalPlaces = 0 : 5;
        }
        field(13; "Need Quantity"; Decimal)
        {
            Caption = 'Påfyllingsbehov';
            ToolTip = 'Angir behovet begrenset av lagermål og ledig kapasitet.';
            DecimalPlaces = 0 : 5;
        }
        field(14; "Suggested Quantity"; Decimal)
        {
            Caption = 'Standardforslag';
            ToolTip = 'Angir antallet som standard planberegning foreslo i basisenheter.';
            DecimalPlaces = 0 : 5;
        }
        field(15; "Allocated Quantity"; Decimal)
        {
            Caption = 'Tildelt antall';
            ToolTip = 'Angir antallet etter kapasitetskontroll, fordeling etter dager med dekning og avrunding.';
            DecimalPlaces = 0 : 5;
        }
        field(16; "Quantity Precision"; Decimal)
        {
            Caption = 'Antallspresisjon';
            ToolTip = 'Angir minste gyldige antall i basisenheter.';
            DecimalPlaces = 0 : 5;
        }
        field(17; "Order Multiple"; Decimal)
        {
            Caption = 'Ordremultippel';
            ToolTip = 'Angir kollistørrelsen som behov og tildeling skal følge.';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Allocation Weight"; Decimal)
        {
            Caption = 'Fordelingsvekt';
            ToolTip = 'Angir kategoriens vekt. Vekten avgjør bare når butikker står likt etter dager med dekning.';
            DecimalPlaces = 0 : 5;
        }
        field(19; "Coverage Days"; Integer)
        {
            Caption = 'Dekningsdager';
            ToolTip = 'Angir hvor mange dager lagermålet dekker: fra planleggingsdatoen til neste mulige levering, eller kategoriens dekningsdager når butikken ikke har leveringsdager.';
        }
        field(20; "Reason"; Text[250])
        {
            Caption = 'Begrunnelse';
            ToolTip = 'Angir hvorfor forslaget er begrenset eller varen er utelatt.';
        }
        field(21; "Sold Quantity"; Decimal)
        {
            Caption = 'Solgt antall';
            ToolTip = 'Angir netto salg i analyseperioden i basisenheter.';
            DecimalPlaces = 0 : 5;
        }
        field(22; "Days In Stock"; Integer)
        {
            Caption = 'Dager på lager';
            ToolTip = 'Angir hvor mange dager i analyseperioden varen hadde beholdning eller ble solgt i butikken. Salget deles på disse dagene, men aldri på færre enn minste antall dager i oppsettet.';
        }
        field(23; "Ships Now"; Boolean)
        {
            Caption = 'Leveres nå';
            ToolTip = 'Angir om ordre fra denne kjøringen kommer frem på en leveringsdag for butikken.';
        }
        field(24; "Receipt Date"; Date)
        {
            Caption = 'Mottaksdato';
            ToolTip = 'Angir når en ordre sendt på planleggingsdatoen kommer frem, beregnet fra overføringsruten.';
        }
        field(25; "Next Receipt Date"; Date)
        {
            Caption = 'Neste mottaksdato';
            ToolTip = 'Angir neste dato butikken kan få varer etter mottaksdatoen. Lagermålet skal dekke salget frem til denne datoen.';
        }
        field(26; "Maximum Inventory"; Decimal)
        {
            Caption = 'Makslager';
            ToolTip = 'Angir makslageret på lagerføringsenheten ved beregningen.';
            DecimalPlaces = 0 : 5;
        }
        field(27; "Days of Cover"; Decimal)
        {
            Caption = 'Dager med dekning';
            ToolTip = 'Angir hvor mange dager beholdning og varer på vei rekker med dagens salgstakt, før tildelingen. Tomt når varen ikke har salg.';
            DecimalPlaces = 0 : 1;
            BlankZero = true;
        }
        field(28; "Unmet Quantity"; Decimal)
        {
            Caption = 'Udekket antall';
            ToolTip = 'Angir behovet som ikke ble dekket fordi hovedlageret hadde for lite.';
            DecimalPlaces = 0 : 5;
        }
        field(29; Exception; Enum "DP Exception KBS")
        {
            Caption = 'Avvik';
            ToolTip = 'Angir det viktigste avviket for linjen: mangler oppsett, tom i butikk, udekket behov eller over makslager.';
        }
        field(31; "Sold Last Day"; Boolean)
        {
            Caption = 'Solgt i går';
            ToolTip = 'Angir om varen hadde bokført salg i butikken dagen før planleggingsdatoen.';
        }
        field(32; "Planning Date"; Date)
        {
            Caption = 'Planleggingsdato';
            ToolTip = 'Angir planleggingsdatoen for kjøringen linjen tilhører. Brukes til filtrering og rapportering.';
        }
        field(30; "Item Description"; Text[100])
        {
            Caption = 'Varebeskrivelse';
            ToolTip = 'Angir varens beskrivelse.';
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Editable = false;
        }
    }
    keys
    {
        key(PK; "Run ID", "Entry No.") { Clustered = true; }
        key(ItemVariantLocation; "Item No.", "Variant Code", "Location Code") { }
        key(ByItem; "Run ID", "Item No.", "Variant Code", "Location Code") { }
        key(ByException; "Run ID", Exception, "Location Code", "Item No.") { }
        key(ByPlanningDate; "Planning Date", "Location Code", "Item No.") { }
    }

    procedure UpdateException()
    var
        OutOfStock: Boolean;
        Unmet: Boolean;
    begin
        if Exception = Exception::"Missing Setup" then
            exit;
        OutOfStock := Inventory <= 0;
        Unmet := "Unmet Quantity" > 0;
        case true of
            OutOfStock and Unmet:
                Exception := Exception::"Out of Stock Unmet Need";
            Unmet:
                Exception := Exception::"Unmet Need";
            OutOfStock:
                Exception := Exception::"Out of Stock";
            ("Maximum Inventory" > 0) and (Inventory + "Incoming Quantity" > "Maximum Inventory"):
                Exception := Exception::"Over Maximum";
            else
                Exception := Exception::None;
        end;
    end;
}
