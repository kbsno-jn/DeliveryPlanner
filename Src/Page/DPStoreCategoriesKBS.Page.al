namespace Knowit.DeliveryPlanner;

page 78901 "DP Store Categories KBS"
{
    Caption = 'DeliveryPlanner-butikkategorier';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "DP Store Category KBS";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Categories)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(CoverageDays; Rec."Coverage Days") { ApplicationArea = All; }
                field(AllocationWeight; Rec."Allocation Weight") { ApplicationArea = All; }
            }
        }
    }
}
