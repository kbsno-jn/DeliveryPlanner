namespace Knowit.DeliveryPlanner;

page 78903 "DP Runs KBS"
{
    Caption = 'DeliveryPlanner-kjøringslogg';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "DP Run KBS";
    SourceTableView = sorting("Started At") order(descending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Runs)
            {
                field(StartedAt; Rec."Started At") { ApplicationArea = All; }
                field(FinishedAt; Rec."Finished At") { ApplicationArea = All; }
                field(PlanningDate; Rec."Planning Date") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field(CreateOrders; Rec."Create Orders") { ApplicationArea = All; }
                field(UserID; Rec."User ID") { ApplicationArea = All; }
                field(SalesWarning; Rec."Sales Warning") { ApplicationArea = All; }
                field(StoresWithoutSales; Rec."Stores Without Sales") { ApplicationArea = All; }
                field(StoresChecked; Rec."Stores Checked") { ApplicationArea = All; Visible = false; }
                field(LineCount; Rec."Line Count") { ApplicationArea = All; }
                field(OrdersCreated; Rec."Orders Created") { ApplicationArea = All; }
                field(OrdersAwaitingApproval; Rec."Orders Awaiting Approval") { ApplicationArea = All; }
                field(SnapshotDuration; Rec."Snapshot Duration") { ApplicationArea = All; Visible = false; }
                field(PlanningDuration; Rec."Planning Duration") { ApplicationArea = All; Visible = false; }
                field(OrderDuration; Rec."Order Duration") { ApplicationArea = All; Visible = false; }
                field(ErrorText; Rec."Error Text") { ApplicationArea = All; }
                field(RunID; Rec."Run ID") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(RunLines)
            {
                Caption = 'Beregningsgrunnlag';
                ApplicationArea = All;
                Image = Entries;
                ToolTip = 'Viser salgstakt, beholdning, kapasitet, behov og tildeling for hver vare, variant og butikk.';
                RunObject = page "DP Run Lines KBS";
                RunPageLink = "Run ID" = field("Run ID");
            }
            action(Exceptions)
            {
                Caption = 'Avvik';
                ApplicationArea = All;
                Image = ErrorLog;
                ToolTip = 'Viser linjene i kjøringen som er tomme, har udekket behov, ligger over makslager eller mangler oppsett.';
                RunObject = page "DP Exceptions KBS";
                RunPageLink = "Run ID" = field("Run ID");
            }
            action(ProposalLog)
            {
                Caption = 'Forslag og ordre';
                ApplicationArea = All;
                Image = OrderList;
                ToolTip = 'Viser daterte kladdforslag og kobling til opprettede overføringsordrelinjer.';
                RunObject = page "DP Proposal Log KBS";
                RunPageLink = "Run ID" = field("Run ID");
            }
        }
        area(Promoted)
        {
            actionref(RunLinesPromoted; RunLines) { }
            actionref(ExceptionsPromoted; Exceptions) { }
            actionref(ProposalLogPromoted; ProposalLog) { }
        }
    }
}
