namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;

table 78900 "DP Setup KBS"
{
    AllowInCustomizations = AsReadWrite;
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
        field(8; "Min. Days In Stock"; Integer)
        {
            Caption = 'Minste antall dager på lager';
            InitValue = 14;
            MinValue = 1;
            ToolTip = 'Angir hvor mange dager salget minst fordeles på. Dager uten beholdning holdes utenfor salgstakten, men et salg deles aldri på færre dager enn dette.';
        }
        field(9; "Notification Email"; Text[250])
        {
            Caption = 'Varsel til e-post';
            ExtendedDatatype = EMail;
            ToolTip = 'Angir e-postadressen som får varsel når nattjobben feiler, når salg for i går mangler, eller når ordrer venter på godkjenning. Skill flere adresser med semikolon. Velg avsenderkonto for scenarioet DeliveryPlanner under E-postscenarioer.';
        }
        field(10; "Sales Alert %"; Decimal)
        {
            Caption = 'Varsle ved manglende salg (%)';
            InitValue = 50;
            MinValue = 0;
            MaxValue = 100;
            DecimalPlaces = 0 : 1;
            ToolTip = 'Angir hvor stor andel av butikkene som kan mangle bokført salg for i går før kjøringen varsler at salgsimporten trolig ikke er ferdig. 0 slår av kontrollen. Planen beregnes uansett.';
        }
        field(11; "Log Retention Days"; Integer)
        {
            Caption = 'Behold kjøringslogg (dager)';
            InitValue = 90;
            MinValue = 0;
            ToolTip = 'Angir hvor mange dager kjøringer, beregningsgrunnlag og forslag beholdes. Eldre logger slettes ved neste kjøring. 0 beholder alt.';
        }
        field(12; "Approval Factor"; Decimal)
        {
            Caption = 'Godkjenning over faktor';
            InitValue = 2;
            MinValue = 0;
            DecimalPlaces = 0 : 2;
            ToolTip = 'Angir hvor mange ganger større enn snittet av butikkens siste ordrer en ordre kan være før den venter på godkjenning i stedet for å frigis. 0 slår av godkjenning.';
        }
        field(13; "Approval History Orders"; Integer)
        {
            Caption = 'Ordrer i snittet';
            InitValue = 4;
            MinValue = 1;
            ToolTip = 'Angir hvor mange av butikkens siste frigitte ordrer snittet beregnes fra. Butikker med færre tidligere ordrer godkjennes automatisk.';
        }
    }
    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
