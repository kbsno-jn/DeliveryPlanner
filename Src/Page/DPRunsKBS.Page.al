namespace Knowit.DeliveryPlanner;

page 62103 "DP Runs KBS"
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
            actionref(ProposalLogPromoted; ProposalLog) { }
        }
    }
}
