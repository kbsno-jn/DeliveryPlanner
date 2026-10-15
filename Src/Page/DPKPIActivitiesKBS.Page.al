namespace Knowit.DeliveryPlanner;

page 78908 "DP KPI Activities KBS"
{
    Caption = 'DeliveryPlanner';
    PageType = CardPart;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            cuegroup(Supply)
            {
                Caption = 'Butikkforsyning siste kjøring';

                field(ServiceLevel; ServiceLevel)
                {
                    ApplicationArea = All;
                    Caption = 'Servicegrad (%)';
                    DecimalPlaces = 0 : 1;
                    StyleExpr = ServiceLevelStyle;
                    ToolTip = 'Angir andelen dager i analyseperioden aktive varer var på lager i butikkene.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"DP KPIs KBS");
                    end;
                }
                field(AvgDaysOfCover; AvgDaysOfCover)
                {
                    ApplicationArea = All;
                    Caption = 'Snitt dager med dekning';
                    DecimalPlaces = 0 : 1;
                    ToolTip = 'Angir hvor mange dager beholdning og varer på vei i snitt rekker, før nattens tildeling.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"DP KPIs KBS");
                    end;
                }
                field(OutOfStock; OutOfStock)
                {
                    ApplicationArea = All;
                    Caption = 'Tomme varer';
                    StyleExpr = OutOfStockStyle;
                    ToolTip = 'Angir hvor mange kombinasjoner av vare og butikk som var tomme da kjøringen startet.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"DP Exceptions KBS");
                    end;
                }
                field(Exceptions; ExceptionCount)
                {
                    ApplicationArea = All;
                    Caption = 'Avvik';
                    ToolTip = 'Angir hvor mange linjer i siste kjøring som har et avvik.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"DP Exceptions KBS");
                    end;
                }
                field(AwaitingApproval; AwaitingApproval)
                {
                    ApplicationArea = All;
                    Caption = 'Ordrer til godkjenning';
                    StyleExpr = AwaitingStyle;
                    ToolTip = 'Angir hvor mange overføringsordrer som venter på godkjenning. Frigi ordren for å godkjenne den.';

                    trigger OnDrillDown()
                    begin
                        KPIMgt.ShowAwaitingApproval();
                    end;
                }
            }
            group(LastRun)
            {
                Caption = 'Siste kjøring';

                field(LastRunStarted; LastRunStarted)
                {
                    ApplicationArea = All;
                    Caption = 'Startet';
                    ToolTip = 'Angir når kjøringen som nøkkeltallene bygger på, startet.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"DP Runs KBS");
                    end;
                }
                field(SalesWarning; SalesWarningText)
                {
                    ApplicationArea = All;
                    Caption = 'Salgsimport';
                    StyleExpr = SalesWarningStyle;
                    ToolTip = 'Angir om salget for i går så ut til å være importert da kjøringen startet.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Refresh();
    end;

    local procedure Refresh()
    var
        RunRecord: Record "DP Run KBS";
        TempTotal: Record "DP KPI Buffer KBS" temporary;
    begin
        Clear(ServiceLevel);
        Clear(AvgDaysOfCover);
        Clear(OutOfStock);
        Clear(ExceptionCount);
        Clear(LastRunStarted);
        SalesWarningText := '';
        if KPIMgt.GetLatestRun(RunRecord) then begin
            KPIMgt.CalcTotals(RunRecord, TempTotal);
            ServiceLevel := TempTotal."Service Level %";
            AvgDaysOfCover := TempTotal."Avg. Days of Cover";
            OutOfStock := TempTotal."Out of Stock";
            ExceptionCount := TempTotal."Exception Count";
            LastRunStarted := RunRecord."Started At";
            if RunRecord."Sales Warning" then
                SalesWarningText := StrSubstNo(SalesMissingTxt, RunRecord."Stores Without Sales", RunRecord."Stores Checked")
            else
                SalesWarningText := SalesOkTxt;
        end;
        AwaitingApproval := KPIMgt.CountAwaitingApproval();

        ServiceLevelStyle := 'Favorable';
        if ServiceLevel < 95 then
            ServiceLevelStyle := 'Ambiguous';
        if ServiceLevel < 90 then
            ServiceLevelStyle := 'Unfavorable';
        OutOfStockStyle := 'Favorable';
        if OutOfStock > 0 then
            OutOfStockStyle := 'Unfavorable';
        AwaitingStyle := 'Favorable';
        if AwaitingApproval > 0 then
            AwaitingStyle := 'Ambiguous';
        SalesWarningStyle := 'Favorable';
        if RunRecord."Sales Warning" then
            SalesWarningStyle := 'Unfavorable';
    end;

    var
        KPIMgt: Codeunit "DP KPI Mgt KBS";
        ServiceLevel: Decimal;
        AvgDaysOfCover: Decimal;
        OutOfStock: Integer;
        ExceptionCount: Integer;
        AwaitingApproval: Integer;
        LastRunStarted: DateTime;
        SalesWarningText: Text;
        ServiceLevelStyle: Text;
        OutOfStockStyle: Text;
        AwaitingStyle: Text;
        SalesWarningStyle: Text;
        SalesMissingTxt: Label '%1 av %2 butikker manglet salg', Comment = '%1 = stores without sales, %2 = stores checked';
        SalesOkTxt: Label 'OK';
}
