namespace Knowit.DeliveryPlanner;

page 78904 "DP Run Lines KBS"
{
    Caption = 'DeliveryPlanner-beregningsgrunnlag';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "DP Run Line KBS";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Field1; Rec."Run ID") { ApplicationArea = All; Visible = false; }
                field(Field2; Rec."Entry No.") { ApplicationArea = All; Visible = false; }
                field(Field3; Rec."Item No.") { ApplicationArea = All; }
                field(Field4; Rec."Variant Code") { ApplicationArea = All; }
                field(Field5; Rec."Location Code") { ApplicationArea = All; }
                field(Field29; Rec.Exception) { ApplicationArea = All; }
                field(Field6; Rec."Category Code") { ApplicationArea = All; }
                field(Field21; Rec."Sold Quantity") { ApplicationArea = All; }
                field(Field22; Rec."Days In Stock") { ApplicationArea = All; }
                field(Field31; Rec."Sold Last Day") { ApplicationArea = All; Visible = false; }
                field(Field7; Rec."Daily Sales") { ApplicationArea = All; }
                field(Field27; Rec."Days of Cover") { ApplicationArea = All; }
                field(Field23; Rec."Ships Now") { ApplicationArea = All; }
                field(Field24; Rec."Receipt Date") { ApplicationArea = All; }
                field(Field25; Rec."Next Receipt Date") { ApplicationArea = All; }
                field(Field8; Rec."Target Quantity") { ApplicationArea = All; }
                field(Field9; Rec."Inventory") { ApplicationArea = All; }
                field(Field10; Rec."Incoming Quantity") { ApplicationArea = All; }
                field(Field11; Rec."Outgoing Quantity") { ApplicationArea = All; }
                field(Field26; Rec."Maximum Inventory") { ApplicationArea = All; }
                field(Field12; Rec."Capacity Quantity") { ApplicationArea = All; }
                field(Field13; Rec."Need Quantity") { ApplicationArea = All; }
                field(Field14; Rec."Suggested Quantity") { ApplicationArea = All; }
                field(Field15; Rec."Allocated Quantity") { ApplicationArea = All; }
                field(Field28; Rec."Unmet Quantity") { ApplicationArea = All; }
                field(Field16; Rec."Quantity Precision") { ApplicationArea = All; }
                field(Field17; Rec."Order Multiple") { ApplicationArea = All; }
                field(Field18; Rec."Allocation Weight") { ApplicationArea = All; }
                field(Field19; Rec."Coverage Days") { ApplicationArea = All; }
                field(Field20; Rec."Reason") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(ProposalLog)
            {
                Caption = 'Forslag og ordre';
                ApplicationArea = All;
                Image = OrderList;
                ToolTip = 'Viser de daterte forslagene og overføringsordrelinjene for denne beregningslinjen.';
                RunObject = page "DP Proposal Log KBS";
                RunPageLink = "Run ID" = field("Run ID"), "Run Line Entry No." = field("Entry No.");
            }
        }
    }
}
