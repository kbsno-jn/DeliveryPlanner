namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;

pageextension 78900 "DP Location Card KBS" extends "Location Card"
{
    layout
    {
        addafter(General)
        {
            group(DeliveryPlannerKBS)
            {
                Caption = 'DeliveryPlanner';

                field(DPEnabledKBS; Rec."DP Enabled KBS") { ApplicationArea = All; }
                field(DPCategoryCodeKBS; Rec."DP Category Code KBS") { ApplicationArea = All; }
                group(DPDeliveryDaysKBS)
                {
                    Caption = 'Leveringsdager';
                    InstructionalText = 'Dager varer fra hovedlageret kommer frem til butikken. Transporttiden hentes fra speditørtjenesten på overføringsruten. Uten leveringsdager fylles butikken hver natt.';

                    field(DPDeliveryMondayKBS; Rec."DP Delivery Monday KBS") { ApplicationArea = All; }
                    field(DPDeliveryTuesdayKBS; Rec."DP Delivery Tuesday KBS") { ApplicationArea = All; }
                    field(DPDeliveryWednesdayKBS; Rec."DP Delivery Wednesday KBS") { ApplicationArea = All; }
                    field(DPDeliveryThursdayKBS; Rec."DP Delivery Thursday KBS") { ApplicationArea = All; }
                    field(DPDeliveryFridayKBS; Rec."DP Delivery Friday KBS") { ApplicationArea = All; }
                    field(DPDeliverySaturdayKBS; Rec."DP Delivery Saturday KBS") { ApplicationArea = All; }
                    field(DPDeliverySundayKBS; Rec."DP Delivery Sunday KBS") { ApplicationArea = All; }
                }
            }
        }
    }
    actions
    {
        addlast(Navigation)
        {
            action(DPAssortmentKBS)
            {
                Caption = 'DeliveryPlanner-sortiment';
                ApplicationArea = All;
                Image = ItemAvailability;
                ToolTip = 'Åpner lagerføringsenhetene for denne lokasjonen slik at du kan velge sortiment og makslager.';
                RunObject = page "DP Assortment KBS";
                RunPageLink = "Location Code" = field(Code);
            }
        }
    }
}
