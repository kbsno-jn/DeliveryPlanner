namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;

table 62100 "DP Setup KBS"
{
    Caption = 'DeliveryPlanner-oppsett';
    DataClassification = CustomerContent;
    DrillDownPageId = "DP Setup KBS";
    LookupPageId = "DP Setup KBS";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primærnøkkel';
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Aktivert';
            ToolTip = 'Angir om DeliveryPlanner kan beregne påfylling og opprette overføringsordrer.';
        }
        field(3; "Hub Location Code"; Code[10])
        {
            Caption = 'Hovedlager';
            TableRelation = Location.Code where("Use As In-Transit" = const(false));
            ToolTip = 'Angir lokasjonen som forsyner alle aktiverte butikker.';

            trigger OnValidate()
            var
                Location: Record Location;
            begin
                if "Hub Location Code" = '' then
                    exit;
                Location.Get("Hub Location Code");
                Location.TestField("Use As In-Transit", false);
                Location.TestField("DP Enabled KBS", false);
            end;
        }
        field(4; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Rekvisisjonskladdmal';
            TableRelation = "Req. Wksh. Template".Name where(Recurring = const(false), Type = const("Req."));
            ToolTip = 'Angir den ikke-gjentakende rekvisisjonsmalen for DeliveryPlanner. Bruk en egen kladd.';

            trigger OnValidate()
            begin
                if "Worksheet Template Name" <> xRec."Worksheet Template Name" then
                    "Worksheet Batch Name" := '';
            end;
        }
        field(5; "Worksheet Batch Name"; Code[10])
        {
            Caption = 'Rekvisisjonskladdnavn';
            TableRelation = "Requisition Wksh. Name".Name where("Worksheet Template Name" = field("Worksheet Template Name"));
            ToolTip = 'Angir den dedikerte kladden. Linjene i denne kladden administreres av DeliveryPlanner.';
        }
        field(6; "Sales History Days"; Integer)
        {
            Caption = 'Dager med salgshistorikk';
            InitValue = 56;
            MinValue = 1;
            ToolTip = 'Angir antall avsluttede kalenderdager som brukes til å beregne netto daglig salg.';
        }
        field(7; "Job Start Time"; Time)
        {
            Caption = 'Starttid for nattjobb';
            InitValue = 020000T;
            ToolTip = 'Angir tidspunktet for nattjobben i jobbbrukerens tidssone. Legg kjøringen etter salgsimporten.';
        }
    }
    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
