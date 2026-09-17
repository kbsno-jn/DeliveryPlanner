namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;

page 62102 "DP Assortment KBS"
{
    Caption = 'DeliveryPlanner-butikksortiment';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Stockkeeping Unit";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Assortment)
            {
                field(LocationCode; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Butikklokasjon';
                    ToolTip = 'Angir lokasjonen for lagerføringsenheten.';
                    Editable = false;
                }
                field(ItemNo; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Varenr.';
                    ToolTip = 'Angir varen for lagerføringsenheten.';
                    Editable = false;
                }
                field(VariantCode; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Caption = 'Variantkode';
                    ToolTip = 'Angir varevarianten for lagerføringsenheten.';
                    Editable = false;
                }
                field(Description; Rec."Description")
                {
                    ApplicationArea = All;
                    Caption = 'Beskrivelse';
                    ToolTip = 'Angir varens beskrivelse.';
                    Editable = false;
                }
                field(DPEnabledKBS; Rec."DP Enabled KBS")
                {
                    ApplicationArea = All;
                }
                field(MaximumInventory; Rec."Maximum Inventory")
                {
                    ApplicationArea = All;
                    Caption = 'Makslager';
                    ToolTip = 'Angir det harde taket for fysisk beholdning og inngående antall i basisenheter.';
                }
                field(SafetyStockQuantity; Rec."Safety Stock Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Sikkerhetslager';
                    ToolTip = 'Angir minste lagermål, også når varen mangler salgshistorikk.';
                }
                field(OrderMultiple; Rec."Order Multiple")
                {
                    ApplicationArea = All;
                    Caption = 'Ordremultippel';
                    ToolTip = 'Angir kollistørrelsen som antallet skal avrundes til i basisenheter.';
                }
                field(ReplenishmentSystem; Rec."Replenishment System")
                {
                    ApplicationArea = All;
                    Caption = 'Etterforsyningssystem';
                    ToolTip = 'Angir forsyningsmetoden. Aktiverte enheter skal bruke overføring.';
                }
                field(TransferFromCode; Rec."Transfer-from Code")
                {
                    ApplicationArea = All;
                    Caption = 'Overfør fra-kode';
                    ToolTip = 'Angir hovedlageret som den aktiverte enheten skal forsynes fra.';
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(SKUCard)
            {
                Caption = 'Lagerføringsenhet';
                ApplicationArea = All;
                Image = SKU;
                ToolTip = 'Åpner lagerføringsenheten med alle standard planleggingsparametere.';
                RunObject = page "Stockkeeping Unit Card";
                RunPageLink = "Location Code" = field("Location Code"), "Item No." = field("Item No."), "Variant Code" = field("Variant Code");
            }
            action(LocationCard)
            {
                Caption = 'Butikklokasjon';
                ApplicationArea = All;
                Image = Warehouse;
                ToolTip = 'Åpner lokasjonen slik at du kan velge butikkategori og aktivere butikken.';
                RunObject = page "Location Card";
                RunPageLink = Code = field("Location Code");
            }
        }
    }
}
