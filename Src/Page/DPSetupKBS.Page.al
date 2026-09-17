namespace Knowit.DeliveryPlanner;

page 62100 "DP Setup KBS"
{
    Caption = 'DeliveryPlanner-oppsett';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "DP Setup KBS";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Generelt';
                field(Enabled; Rec.Enabled) { ApplicationArea = All; }
                field(HubLocationCode; Rec."Hub Location Code") { ApplicationArea = All; ShowMandatory = true; }
                field(SalesHistoryDays; Rec."Sales History Days") { ApplicationArea = All; }
            }
            group(Worksheet)
            {
                Caption = 'Rekvisisjonskladd';
                field(WorksheetTemplateName; Rec."Worksheet Template Name") { ApplicationArea = All; ShowMandatory = true; }
                field(WorksheetBatchName; Rec."Worksheet Batch Name") { ApplicationArea = All; ShowMandatory = true; }
            }
            group(Scheduling)
            {
                Caption = 'Nattjobb';
                field(JobStartTime; Rec."Job Start Time") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(CreateDefaults)
            {
                Caption = 'Opprett standardoppsett';
                ApplicationArea = All;
                Image = Setup;
                ToolTip = 'Oppretter foreslåtte butikkategorier og en egen rekvisisjonskladd for DeliveryPlanner.';

                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    Management.CreateDefaults();
                    CurrPage.Update(false);
                end;
            }
            action(Calculate)
            {
                Caption = 'Beregn DeliveryPlanner';
                ApplicationArea = All;
                Image = CalculatePlan;
                ToolTip = 'Beregner behov med standard planmotor og oppdaterer DeliveryPlanner-kladden for gjennomgang.';

                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    Management.Calculate();
                end;
            }
            action(RunPlanner)
            {
                Caption = 'Kjør DeliveryPlanner';
                ApplicationArea = All;
                Image = CarryOutActionMessage;
                ToolTip = 'Beregner kladden på nytt, utfører handlingsmeldingene og frigir nye overføringsordrer.';

                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    Management.RunPlanner();
                end;
            }
            action(CreateNightJob)
            {
                Caption = 'Opprett nattjobb';
                ApplicationArea = All;
                Image = Job;
                ToolTip = 'Oppretter en gjentakende jobbkøpost for DeliveryPlanner. Kontroller tidssone og at salgsimporten er ferdig før kjøring.';

                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    Management.CreateNightJob();
                end;
            }
        }
        area(Navigation)
        {
            action(StoreCategories)
            {
                Caption = 'Butikkategorier';
                ApplicationArea = All;
                Image = Category;
                ToolTip = 'Definerer dekningsdager og fordelingsvekter for små, mellomstore og store butikker.';
                RunObject = page "DP Store Categories KBS";
            }
            action(Assortment)
            {
                Caption = 'Butikksortiment';
                ApplicationArea = All;
                Image = ItemAvailability;
                ToolTip = 'Velger lagerføringsenheter som skal planlegges og angir makslager, sikkerhetslager og ordremultippel.';
                RunObject = page "DP Assortment KBS";
            }
            action(OpenWorksheet)
            {
                Caption = 'Åpne rekvisisjonskladd';
                ApplicationArea = All;
                Image = Worksheet;
                ToolTip = 'Åpner DeliveryPlanner-kladden med standardforslag, tildeling og begrunnelse.';

                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    Management.OpenWorksheet();
                end;
            }
            action(RunHistory)
            {
                Caption = 'Kjøringslogg';
                ApplicationArea = All;
                Image = Log;
                ToolTip = 'Viser tidligere kjøringer, beregningsgrunnlag, opprettede ordre og feilmeldinger.';
                RunObject = page "DP Runs KBS";
            }
        }
        area(Promoted)
        {
            actionref(CalculatePromoted; Calculate) { }
            actionref(RunPlannerPromoted; RunPlanner) { }
            actionref(AssortmentPromoted; Assortment) { }
            actionref(RunHistoryPromoted; RunHistory) { }
        }
    }
    trigger OnOpenPage()
    begin
        Management.InitializeSetup();
        Rec.Get('');
    end;

    var
        Management: Codeunit "DP Management KBS";
}
