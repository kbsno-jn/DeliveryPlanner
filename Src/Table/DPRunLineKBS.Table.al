namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

table 62103 "DP Run Line KBS"
{
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
            ToolTip = 'Angir antallet etter kapasitetskontroll, vektet fordeling og avrunding.';
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
            ToolTip = 'Angir kategoriens fordelingsvekt ved beregningen.';
            DecimalPlaces = 0 : 5;
        }
        field(19; "Coverage Days"; Integer)
        {
            Caption = 'Dekningsdager';
            ToolTip = 'Angir kategoriens dekningsperiode ved beregningen.';
        }
        field(20; "Reason"; Text[250])
        {
            Caption = 'Begrunnelse';
            ToolTip = 'Angir hvorfor forslaget er begrenset eller varen er utelatt.';
        }
    }
    keys
    {
        key(PK; "Run ID", "Entry No.") { Clustered = true; }
        key(ItemVariantLocation; "Item No.", "Variant Code", "Location Code") { }
        key(ByItem; "Run ID", "Item No.", "Variant Code", "Location Code") { }
    }
}
