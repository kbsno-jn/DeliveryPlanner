namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;

page 78907 "DP Exceptions KBS"
{
    Caption = 'DeliveryPlanner-avvik';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "DP Run Line KBS";
    SourceTableView = sorting("Run ID", Exception, "Location Code", "Item No.");
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Exception; Rec.Exception) { ApplicationArea = All; StyleExpr = ExceptionStyle; }
                field(LocationCode; Rec."Location Code") { ApplicationArea = All; }
                field(ItemNo; Rec."Item No.") { ApplicationArea = All; }
                field(VariantCode; Rec."Variant Code") { ApplicationArea = All; }
                field(ItemDescription; Rec."Item Description") { ApplicationArea = All; }
                field(Inventory; Rec.Inventory) { ApplicationArea = All; }
                field(IncomingQuantity; Rec."Incoming Quantity") { ApplicationArea = All; }
                field(MaximumInventory; Rec."Maximum Inventory") { ApplicationArea = All; }
                field(DailySales; Rec."Daily Sales") { ApplicationArea = All; }
                field(DaysOfCover; Rec."Days of Cover") { ApplicationArea = All; }
                field(NeedQuantity; Rec."Need Quantity") { ApplicationArea = All; }
                field(AllocatedQuantity; Rec."Allocated Quantity") { ApplicationArea = All; }
                field(UnmetQuantity; Rec."Unmet Quantity") { ApplicationArea = All; }
                field(ReceiptDate; Rec."Receipt Date") { ApplicationArea = All; }
                field(Reason; Rec.Reason) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(SKUCard)
            {
                Caption = 'Lagerføringsenhet';
                ApplicationArea = All;
                Image = SKU;
                ToolTip = 'Åpner lagerføringsenheten for å rette makslager, sikkerhetslager, ordremultippel eller forsyning.';
                RunObject = page "Stockkeeping Unit Card";
                RunPageLink = "Location Code" = field("Location Code"), "Item No." = field("Item No."), "Variant Code" = field("Variant Code");
            }
            action(LocationCard)
            {
                Caption = 'Butikklokasjon';
                ApplicationArea = All;
                Image = Warehouse;
                ToolTip = 'Åpner lokasjonen for å rette butikkategori og leveringsdager.';
                RunObject = page "Location Card";
                RunPageLink = Code = field("Location Code");
            }
            action(ProposalLog)
            {
                Caption = 'Forslag og ordre';
                ApplicationArea = All;
                Image = OrderList;
                ToolTip = 'Viser forslagene og overføringsordrelinjene for linjen.';
                RunObject = page "DP Proposal Log KBS";
                RunPageLink = "Run ID" = field("Run ID"), "Run Line Entry No." = field("Entry No.");
            }
            action(RunLines)
            {
                Caption = 'Hele beregningsgrunnlaget';
                ApplicationArea = All;
                Image = Entries;
                ToolTip = 'Viser alle beregningslinjene i kjøringen, også linjer uten avvik.';
                RunObject = page "DP Run Lines KBS";
                RunPageLink = "Run ID" = field("Run ID");
            }
        }
        area(Promoted)
        {
            actionref(SKUCardPromoted; SKUCard) { }
            actionref(ProposalLogPromoted; ProposalLog) { }
        }
    }

    trigger OnOpenPage()
    var
        RunRecord: Record "DP Run KBS";
        KPIMgt: Codeunit "DP KPI Mgt KBS";
    begin
        if Rec.GetFilter("Run ID") = '' then
            if KPIMgt.GetLatestRun(RunRecord) then
                Rec.SetRange("Run ID", RunRecord."Run ID")
            else
                Rec.SetRange("Run ID", CreateGuid());
        Rec.SetFilter(Exception, '<>%1', Rec.Exception::None);
    end;

    trigger OnAfterGetRecord()
    begin
        case Rec.Exception of
            Rec.Exception::"Missing Setup", Rec.Exception::"Out of Stock Unmet Need":
                ExceptionStyle := 'Unfavorable';
            Rec.Exception::"Unmet Need", Rec.Exception::"Out of Stock", Rec.Exception::"Awaiting Approval":
                ExceptionStyle := 'Ambiguous';
            else
                ExceptionStyle := 'Standard';
        end;
    end;

    var
        ExceptionStyle: Text;
}
