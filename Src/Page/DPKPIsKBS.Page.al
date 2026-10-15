namespace Knowit.DeliveryPlanner;

page 78909 "DP KPIs KBS"
{
    Caption = 'DeliveryPlanner-nøkkeltall';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    SourceTable = "DP KPI Buffer KBS";
    SourceTableTemporary = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(RunInfo)
            {
                Caption = 'Kjøring';

                field(RunStarted; RunRecord."Started At")
                {
                    ApplicationArea = All;
                    Caption = 'Startet';
                    ToolTip = 'Angir når kjøringen som nøkkeltallene bygger på, startet.';
                }
                field(RunCreatedOrders; RunRecord."Create Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Opprettet ordrer';
                    ToolTip = 'Angir om kjøringen var nattjobben eller Kjør DeliveryPlanner, og ikke bare en beregning.';
                }
            }
            repeater(Lines)
            {
                field(GroupType; Rec."Group Type") { ApplicationArea = All; }
                field(GroupCode; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(LineCount; Rec."Line Count") { ApplicationArea = All; }
                field(ServiceLevel; Rec."Service Level %") { ApplicationArea = All; StyleExpr = ServiceLevelStyle; }
                field(AvgDaysOfCover; Rec."Avg. Days of Cover") { ApplicationArea = All; }
                field(OutOfStock; Rec."Out of Stock") { ApplicationArea = All; }
                field(OverMaximum; Rec."Over Maximum") { ApplicationArea = All; }
                field(OverstockQuantity; Rec."Overstock Quantity") { ApplicationArea = All; }
                field(UnmetQuantity; Rec."Unmet Quantity") { ApplicationArea = All; }
                field(ExceptionCount; Rec."Exception Count") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(Exceptions)
            {
                Caption = 'Avvik';
                ApplicationArea = All;
                Image = ErrorLog;
                ToolTip = 'Viser avvikene for butikken eller kategorien.';

                trigger OnAction()
                var
                    RunLine: Record "DP Run Line KBS";
                begin
                    RunLine.SetRange("Run ID", RunRecord."Run ID");
                    if Rec."Group Type" = Rec."Group Type"::Store then
                        RunLine.SetRange("Location Code", Rec.Code)
                    else
                        RunLine.SetRange("Category Code", Rec.Code);
                    Page.Run(Page::"DP Exceptions KBS", RunLine);
                end;
            }
            action(StoreOrders)
            {
                Caption = 'Butikkordrer';
                ApplicationArea = All;
                Image = TransferOrder;
                ToolTip = 'Viser ordrene DeliveryPlanner har opprettet, med snittet de ble sammenlignet med.';
                RunObject = page "DP Store Orders KBS";
            }
        }
        area(Promoted)
        {
            actionref(ExceptionsPromoted; Exceptions) { }
        }
    }

    trigger OnOpenPage()
    var
        KPIMgt: Codeunit "DP KPI Mgt KBS";
    begin
        if KPIMgt.GetLatestRun(RunRecord) then
            KPIMgt.FillBuffer(RunRecord, Rec);
        Rec.Reset();
        if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        ServiceLevelStyle := 'Standard';
        if Rec."Service Level %" < 95 then
            ServiceLevelStyle := 'Ambiguous';
        if Rec."Service Level %" < 90 then
            ServiceLevelStyle := 'Unfavorable';
    end;

    var
        RunRecord: Record "DP Run KBS";
        ServiceLevelStyle: Text;
}
