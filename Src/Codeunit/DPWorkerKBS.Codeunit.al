namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;

codeunit 78901 "DP Worker KBS"
{
    TableNo = "DP Run KBS";

    trigger OnRun()
    begin
        ExecuteWorker(Rec);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure ExecuteWorker(var RunRecord: Record "DP Run KBS")
    var
        Setup: Record "DP Setup KBS";
        Adapter: Codeunit "DP Planning Adapter KBS";
        HubAvailability: Dictionary of [Text, Decimal];
        StepStart: DateTime;
    begin
        Setup.LockTable();
        Setup.Get('');
        ValidateSetup(Setup, RunRecord."Create Orders");
        ValidateWorksheet(Setup);
        ValidateAssortment();
        RunRecord."Sales History Days" := Setup."Sales History Days";
        Adapter.Configure(Setup, RunRecord);
        BindSubscription(Adapter);
        StepStart := CurrentDateTime();
        DeletePreviousProposals(Setup);
        BuildSnapshots(Setup, RunRecord, HubAvailability);
        CheckSalesImport(Setup, RunRecord);
        RunRecord."Snapshot Duration" := CurrentDateTime() - StepStart;

        StepStart := CurrentDateTime();
        CalculateStandardPlan(RunRecord, Adapter);
        CaptureProposals(Setup, RunRecord);
        AllocateStock(RunRecord, HubAvailability);
        ApplyAllocations(Setup, RunRecord);
        RunRecord."Planning Duration" := CurrentDateTime() - StepStart;

        if RunRecord."Create Orders" then begin
            StepStart := CurrentDateTime();
            Adapter.CarryOutAndRelease(RunRecord."Orders Created", RunRecord."Orders Awaiting Approval");
            MarkAwaitingApproval(RunRecord);
            RunRecord."Order Duration" := CurrentDateTime() - StepStart;
        end;
        UnbindSubscription(Adapter);
        RunRecord."Finished At" := CurrentDateTime();
        if RunRecord."Create Orders" then
            RunRecord.Status := RunRecord.Status::Completed
        else
            RunRecord.Status := RunRecord.Status::Calculated;
        RunRecord.Modify(true);
    end;

    /// <summary>
    /// The planner trusts yesterday's posted sales. When many stores have no sale at all on any active
    /// item for the last closed day, the sales import has most likely not finished yet.
    /// </summary>
    local procedure CheckSalesImport(Setup: Record "DP Setup KBS"; var RunRecord: Record "DP Run KBS")
    var
        RunLine: Record "DP Run Line KBS";
        StoreSold: Dictionary of [Code[10], Boolean];
        StoreCode: Code[10];
    begin
        RunLine.SetRange("Run ID", RunRecord."Run ID");
        RunLine.SetFilter(Exception, '<>%1', RunLine.Exception::"Missing Setup");
        RunLine.SetLoadFields("Location Code", "Sold Last Day");
        if RunLine.FindSet() then
            repeat
                if not StoreSold.ContainsKey(RunLine."Location Code") then
                    StoreSold.Add(RunLine."Location Code", false);
                if RunLine."Sold Last Day" then
                    StoreSold.Set(RunLine."Location Code", true);
            until RunLine.Next() = 0;

        RunRecord."Line Count" := RunLine.Count();
        RunRecord."Stores Checked" := StoreSold.Count();
        RunRecord."Stores Without Sales" := 0;
        foreach StoreCode in StoreSold.Keys() do
            if not StoreSold.Get(StoreCode) then
                RunRecord."Stores Without Sales" += 1;
        RunRecord."Sales Warning" := (Setup."Sales Alert %" > 0) and (RunRecord."Stores Checked" > 0) and
            (RunRecord."Stores Without Sales" * 100 / RunRecord."Stores Checked" > Setup."Sales Alert %");
    end;

    local procedure MarkAwaitingApproval(RunRecord: Record "DP Run KBS")
    var
        TransferHeader: Record "Transfer Header";
        RunLine: Record "DP Run Line KBS";
    begin
        TransferHeader.SetRange("DP Run ID KBS", RunRecord."Run ID");
        TransferHeader.SetRange("DP Approval Status KBS", TransferHeader."DP Approval Status KBS"::"Awaiting Approval");
        TransferHeader.SetLoadFields("Transfer-to Code");
        if TransferHeader.FindSet() then
            repeat
                RunLine.SetRange("Run ID", RunRecord."Run ID");
                RunLine.SetRange("Location Code", TransferHeader."Transfer-to Code");
                RunLine.SetFilter("Allocated Quantity", '>0');
                RunLine.SetRange(Exception, RunLine.Exception::None);
                RunLine.ModifyAll(Exception, RunLine.Exception::"Awaiting Approval", true);
            until TransferHeader.Next() = 0;
    end;

    local procedure ValidateSetup(Setup: Record "DP Setup KBS"; CreateOrders: Boolean)
    var
        Hub: Record Location;
        WorksheetTemplate: Record "Req. Wksh. Template";
        Batch: Record "Requisition Wksh. Name";
    begin
        if CreateOrders then
            Setup.TestField(Enabled, true);
        Setup.TestField("Hub Location Code");
        Setup.TestField("Worksheet Template Name");
        Setup.TestField("Worksheet Batch Name");
        if Setup."Sales History Days" < 1 then
            Setup.FieldError("Sales History Days");
        if Setup."Min. Days In Stock" < 1 then
            Setup.FieldError("Min. Days In Stock");
        Hub.Get(Setup."Hub Location Code");
        Hub.TestField("Use As In-Transit", false);
        Hub.TestField("DP Enabled KBS", false);
        WorksheetTemplate.Get(Setup."Worksheet Template Name");
        WorksheetTemplate.TestField(Type, WorksheetTemplate.Type::"Req.");
        WorksheetTemplate.TestField(Recurring, false);
        WorksheetTemplate.TestField("Increment Batch Name", false);
        Batch.Get(WorksheetTemplate.Name, Setup."Worksheet Batch Name");
    end;

    local procedure ValidateWorksheet(Setup: Record "DP Setup KBS")
    var
        ReqLine: Record "Requisition Line";
        OldRun: Record "DP Run KBS";
    begin
        FilterWorksheet(ReqLine, Setup);
        if ReqLine.FindSet() then
            repeat
                if IsNullGuid(ReqLine."DP Run ID KBS") then
                    Error(ForeignLineErr, ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", ReqLine."Line No.");
                if not OldRun.Get(ReqLine."DP Run ID KBS") then
                    Error(ForeignLineErr, ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", ReqLine."Line No.");
            until ReqLine.Next() = 0;
    end;

    local procedure ValidateAssortment()
    var
        SKU: Record "Stockkeeping Unit";
        Store: Record Location;
    begin
        // Store and SKU setup problems are reported per line in the exception list instead of
        // stopping every store's replenishment.
        SKU.SetRange("DP Enabled KBS", true);
        if SKU.FindSet() then
            repeat
                if Store.Get(SKU."Location Code") then
                    if Store."DP Enabled KBS" then
                        exit;
            until SKU.Next() = 0;
        Error(NoAssortmentErr);
    end;

    local procedure DeletePreviousProposals(Setup: Record "DP Setup KBS")
    var
        ReqLine: Record "Requisition Line";
    begin
        FilterWorksheet(ReqLine, Setup);
        ReqLine.DeleteAll(true);
    end;

    local procedure BuildSnapshots(Setup: Record "DP Setup KBS"; RunRecord: Record "DP Run KBS"; var HubAvailability: Dictionary of [Text, Decimal])
    var
        SKU: Record "Stockkeeping Unit";
        Store: Record Location;
        Item: Record Item;
        Variant: Record "Item Variant";
        RunLine: Record "DP Run Line KBS";
        Inventory: Codeunit "DP Inventory KBS";
        SetupCheck: Codeunit "DP Setup Check KBS";
        StoreProblems: Dictionary of [Code[10], Text];
        StoreShipsNow: Dictionary of [Code[10], Boolean];
        StoreReceiptDates: Dictionary of [Code[10], Date];
        StoreNextReceiptDates: Dictionary of [Code[10], Date];
        StoreFirstDeliveryDates: Dictionary of [Code[10], Date];
        StoreCoverageDays: Dictionary of [Code[10], Integer];
        Problem: Text;
        EntryNo: Integer;
        ItemKey: Text;
        Blocked: Boolean;
    begin
        SKU.SetRange("DP Enabled KBS", true);
        if SKU.FindSet() then
            repeat
                Store.Get(SKU."Location Code");
                if Store."DP Enabled KBS" then begin
                    EntryNo += 1;
                    RunLine.Init();
                    RunLine."Run ID" := RunRecord."Run ID";
                    RunLine."Entry No." := EntryNo;
                    RunLine."Planning Date" := RunRecord."Planning Date";
                    if not StoreProblems.ContainsKey(Store.Code) then
                        AddStoreSchedule(Setup, RunRecord, Store, StoreProblems, StoreShipsNow, StoreReceiptDates,
                            StoreNextReceiptDates, StoreFirstDeliveryDates, StoreCoverageDays);
                    Problem := StoreProblems.Get(Store.Code);
                    if Problem = '' then
                        Problem := SetupCheck.GetSKUProblem(Setup, SKU);
                    if Problem <> '' then
                        BuildSetupProblemLine(SKU, Store, Problem, RunLine)
                    else begin
                        Item.Get(SKU."Item No.");
                        Blocked := Item.Blocked;
                        if SKU."Variant Code" <> '' then begin
                            Variant.Get(SKU."Item No.", SKU."Variant Code");
                            Blocked := Blocked or Variant.Blocked;
                        end;
                        Inventory.BuildRunLine(SKU, Setup, RunRecord, StoreCoverageDays.Get(Store.Code), RunLine);
                        RunLine."Ships Now" := StoreShipsNow.Get(Store.Code);
                        RunLine."Receipt Date" := StoreReceiptDates.Get(Store.Code);
                        RunLine."Next Receipt Date" := StoreNextReceiptDates.Get(Store.Code);
                        if Blocked then begin
                            RunLine."Need Quantity" := 0;
                            RunLine.Reason := BlockedItemLbl;
                        end else
                            if not RunLine."Ships Now" then begin
                                RunLine."Need Quantity" := 0;
                                RunLine.Reason := StrSubstNo(NoDeliveryLbl, StoreFirstDeliveryDates.Get(Store.Code));
                            end;
                        ItemKey := GetItemKey(SKU."Item No.", SKU."Variant Code");
                        if not HubAvailability.ContainsKey(ItemKey) then
                            HubAvailability.Add(ItemKey, Inventory.GetHubAvailable(SKU."Item No.", SKU."Variant Code", Setup."Hub Location Code"));
                    end;
                    RunLine.Insert(true);
                end;
            until SKU.Next() = 0;
    end;

    local procedure AddStoreSchedule(Setup: Record "DP Setup KBS"; RunRecord: Record "DP Run KBS"; Store: Record Location; var StoreProblems: Dictionary of [Code[10], Text]; var StoreShipsNow: Dictionary of [Code[10], Boolean]; var StoreReceiptDates: Dictionary of [Code[10], Date]; var StoreNextReceiptDates: Dictionary of [Code[10], Date]; var StoreFirstDeliveryDates: Dictionary of [Code[10], Date]; var StoreCoverageDays: Dictionary of [Code[10], Integer])
    var
        Category: Record "DP Store Category KBS";
        SetupCheck: Codeunit "DP Setup Check KBS";
        Schedule: Codeunit "DP Delivery Schedule KBS";
        Problem: Text;
        ShipsNow: Boolean;
        ReceiptDate: Date;
        NextReceiptDate: Date;
        FirstDeliveryDate: Date;
        CoverageDays: Integer;
    begin
        Problem := SetupCheck.GetStoreProblem(Setup, Store);
        if Problem = '' then begin
            Category.Get(Store."DP Category Code KBS");
            if Schedule.GetSchedule(Setup."Hub Location Code", Store, RunRecord."Planning Date", Category."Coverage Days",
                ShipsNow, ReceiptDate, NextReceiptDate, CoverageDays)
            then begin
                if not ShipsNow then
                    FirstDeliveryDate := Schedule.GetFirstDeliveryDate(Setup."Hub Location Code", Store, RunRecord."Planning Date");
            end else
                Problem := StrSubstNo(NoDeliveryDayLbl, Schedule.MaxSearchDays());
        end;
        StoreProblems.Add(Store.Code, Problem);
        StoreShipsNow.Add(Store.Code, ShipsNow);
        StoreReceiptDates.Add(Store.Code, ReceiptDate);
        StoreNextReceiptDates.Add(Store.Code, NextReceiptDate);
        StoreFirstDeliveryDates.Add(Store.Code, FirstDeliveryDate);
        StoreCoverageDays.Add(Store.Code, CoverageDays);
    end;

    local procedure BuildSetupProblemLine(SKU: Record "Stockkeeping Unit"; Store: Record Location; Problem: Text; var RunLine: Record "DP Run Line KBS")
    var
        Inventory: Codeunit "DP Inventory KBS";
    begin
        RunLine."Item No." := SKU."Item No.";
        RunLine."Variant Code" := SKU."Variant Code";
        RunLine."Location Code" := SKU."Location Code";
        RunLine."Category Code" := Store."DP Category Code KBS";
        RunLine."Maximum Inventory" := SKU."Maximum Inventory";
        RunLine.Inventory := Inventory.GetInventory(SKU."Item No.", SKU."Variant Code", SKU."Location Code");
        RunLine."Need Quantity" := 0;
        RunLine.Exception := RunLine.Exception::"Missing Setup";
        RunLine.Reason := CopyStr(Problem, 1, MaxStrLen(RunLine.Reason));
    end;

    local procedure CalculateStandardPlan(RunRecord: Record "DP Run KBS"; var Adapter: Codeunit "DP Planning Adapter KBS")
    var
        RunLine: Record "DP Run Line KBS";
        SKU: Record "Stockkeeping Unit";
    begin
        RunLine.SetRange("Run ID", RunRecord."Run ID");
        RunLine.SetFilter("Need Quantity", '>0');
        if RunLine.FindSet() then
            repeat
                SKU.Get(RunLine."Location Code", RunLine."Item No.", RunLine."Variant Code");
                Adapter.CalculateSKU(SKU, RunLine);
            until RunLine.Next() = 0;
    end;

    local procedure CaptureProposals(Setup: Record "DP Setup KBS"; RunRecord: Record "DP Run KBS")
    var
        ReqLine: Record "Requisition Line";
        RunLine: Record "DP Run Line KBS";
        Proposal: Record "DP Proposal Log KBS";
        EntryNo: Integer;
    begin
        FilterWorksheet(ReqLine, Setup);
        if ReqLine.FindSet(true) then
            repeat
                ReqLine.TestField("DP Run ID KBS", RunRecord."Run ID");
                ReqLine.TestField(Type, ReqLine.Type::Item);
                ReqLine.TestField("Replenishment System", ReqLine."Replenishment System"::Transfer);
                ReqLine.TestField("Ref. Order Type", ReqLine."Ref. Order Type"::Transfer);
                ReqLine.TestField("Action Message", ReqLine."Action Message"::New);
                ReqLine.TestField("Transfer-from Code", Setup."Hub Location Code");
                RunLine.Get(RunRecord."Run ID", ReqLine."DP Run Line No. KBS");
                ReqLine.TestField("No.", RunLine."Item No.");
                ReqLine.TestField("Variant Code", RunLine."Variant Code");
                ReqLine.TestField("Location Code", RunLine."Location Code");
                if (ReqLine."Quantity (Base)" <= 0) or (ReqLine."Qty. per Unit of Measure" <= 0) then
                    Error(InvalidProposalErr, ReqLine."Line No.");
                EntryNo += 1;
                Proposal.Init();
                Proposal."Run ID" := RunRecord."Run ID";
                Proposal."Entry No." := EntryNo;
                Proposal."Run Line Entry No." := RunLine."Entry No.";
                Proposal."Worksheet Line No." := ReqLine."Line No.";
                Proposal."Item No." := ReqLine."No.";
                Proposal."Variant Code" := ReqLine."Variant Code";
                Proposal."Location Code" := ReqLine."Location Code";
                Proposal."Due Date" := ReqLine."Due Date";
                Proposal."Suggested Quantity" := ReqLine."Quantity (Base)";
                Proposal.Insert(true);
                ReqLine."DP Proposal No. KBS" := EntryNo;
                ReqLine."DP Suggested Qty. KBS" := Proposal."Suggested Quantity";
                ReqLine."Accept Action Message" := false;
                ReqLine.Modify(true);
                RunLine."Suggested Quantity" += Proposal."Suggested Quantity";
                RunLine.Modify(true);
            until ReqLine.Next() = 0;
    end;

    local procedure AllocateStock(RunRecord: Record "DP Run KBS"; HubAvailability: Dictionary of [Text, Decimal])
    var
        RunLine: Record "DP Run Line KBS";
        Processed: Dictionary of [Text, Boolean];
        ItemKey: Text;
    begin
        RunLine.SetRange("Run ID", RunRecord."Run ID");
        RunLine.SetFilter(Exception, '<>%1', RunLine.Exception::"Missing Setup");
        if RunLine.FindSet() then
            repeat
                ItemKey := GetItemKey(RunLine."Item No.", RunLine."Variant Code");
                if not Processed.ContainsKey(ItemKey) then begin
                    AllocateItem(RunRecord, RunLine."Item No.", RunLine."Variant Code", HubAvailability.Get(ItemKey));
                    Processed.Add(ItemKey, true);
                end;
            until RunLine.Next() = 0;
    end;

    local procedure AllocateItem(RunRecord: Record "DP Run KBS"; ItemNo: Code[20]; VariantCode: Code[10]; Available: Decimal)
    var
        RunLine: Record "DP Run Line KBS";
        Proposal: Record "DP Proposal Log KBS";
        TempBuffer: Record "DP Allocation Buffer KBS" temporary;
        Allocation: Codeunit "DP Allocation KBS";
        UsableQuantity: Decimal;
        Increment: Decimal;
    begin
        RunLine.SetRange("Run ID", RunRecord."Run ID");
        RunLine.SetRange("Item No.", ItemNo);
        RunLine.SetRange("Variant Code", VariantCode);
        RunLine.SetFilter(Exception, '<>%1', RunLine.Exception::"Missing Setup");
        if RunLine.FindSet() then
            repeat
                Increment := GetIncrement(RunLine);
                UsableQuantity := 0;
                Proposal.SetRange("Run ID", RunRecord."Run ID");
                Proposal.SetRange("Run Line Entry No.", RunLine."Entry No.");
                if Proposal.FindSet() then
                    repeat
                        UsableQuantity += Round(Proposal."Suggested Quantity", Increment, '<');
                    until Proposal.Next() = 0;
                TempBuffer.Init();
                TempBuffer."Location Code" := RunLine."Location Code";
                TempBuffer."Run Line Entry No." := RunLine."Entry No.";
                TempBuffer.Need := Round(Minimum(UsableQuantity, RunLine."Need Quantity"), Increment, '<');
                TempBuffer.Weight := RunLine."Allocation Weight";
                TempBuffer.Increment := Increment;
                TempBuffer.Position := RunLine.Inventory + RunLine."Incoming Quantity" - RunLine."Outgoing Quantity";
                TempBuffer."Daily Rate" := GetAllocationRate(RunLine, TempBuffer.Need);
                TempBuffer.Insert();
            until RunLine.Next() = 0;
        Allocation.Allocate(TempBuffer, Available);
        if TempBuffer.FindSet() then
            repeat
                RunLine.Get(RunRecord."Run ID", TempBuffer."Run Line Entry No.");
                RunLine."Allocated Quantity" := TempBuffer.Allocation;
                RunLine."Unmet Quantity" := TempBuffer.Need - TempBuffer.Allocation;
                if RunLine.Reason = '' then
                    if RunLine."Need Quantity" = 0 then
                        RunLine.Reason := NoNeedLbl
                    else
                        if RunLine."Suggested Quantity" = 0 then
                            RunLine.Reason := NoStandardProposalLbl
                        else
                            if TempBuffer.Need = 0 then
                                RunLine.Reason := BelowIncrementLbl
                            else
                                if TempBuffer.Allocation < TempBuffer.Need then
                                    RunLine.Reason := ShortageLbl
                                else
                                    if RunLine."Suggested Quantity" > TempBuffer.Allocation then
                                        RunLine.Reason := LimitedLbl;
                RunLine.Modify(true);
            until TempBuffer.Next() = 0;
    end;

    local procedure ApplyAllocations(Setup: Record "DP Setup KBS"; RunRecord: Record "DP Run KBS")
    var
        RunLine: Record "DP Run Line KBS";
        Proposal: Record "DP Proposal Log KBS";
        ReqLine: Record "Requisition Line";
        Remaining: Decimal;
        Assigned: Decimal;
        Actual: Decimal;
        Increment: Decimal;
    begin
        RunLine.SetRange("Run ID", RunRecord."Run ID");
        if RunLine.FindSet(true) then
            repeat
                Remaining := RunLine."Allocated Quantity";
                Actual := 0;
                Increment := GetIncrement(RunLine);
                Proposal.SetCurrentKey("Run ID", "Run Line Entry No.", "Due Date", "Entry No.");
                Proposal.SetRange("Run ID", RunRecord."Run ID");
                Proposal.SetRange("Run Line Entry No.", RunLine."Entry No.");
                if Proposal.FindSet(true) then
                    repeat
                        ReqLine.Get(Setup."Worksheet Template Name", Setup."Worksheet Batch Name", Proposal."Worksheet Line No.");
                        Assigned := Round(Minimum(Remaining, Proposal."Suggested Quantity"), Increment, '<');
                        if Assigned = 0 then
                            ReqLine.Delete(true)
                        else begin
                            ReqLine.Validate(Quantity, Assigned / ReqLine."Qty. per Unit of Measure");
                            if (ReqLine."Quantity (Base)" > Assigned) or (ReqLine."Quantity (Base)" <= 0) or
                               (Round(ReqLine."Quantity (Base)", Increment, '<') <> ReqLine."Quantity (Base)")
                            then
                                Error(UnitPrecisionErr, ReqLine."No.", ReqLine."Unit of Measure Code");
                            Assigned := ReqLine."Quantity (Base)";
                            ReqLine."Accept Action Message" := true;
                            ReqLine."DP Reason KBS" := RunLine.Reason;
                            ReqLine.Modify(true);
                        end;
                        Proposal."Allocated Quantity" := Assigned;
                        Proposal.Modify(true);
                        Remaining -= Assigned;
                        Actual += Assigned;
                    until Proposal.Next() = 0;
                if Actual < RunLine."Allocated Quantity" then
                    RunLine."Unmet Quantity" += RunLine."Allocated Quantity" - Actual;
                RunLine."Allocated Quantity" := Actual;
                RunLine.UpdateException();
                RunLine.Modify(true);
            until RunLine.Next() = 0;
    end;

    local procedure FilterWorksheet(var ReqLine: Record "Requisition Line"; Setup: Record "DP Setup KBS")
    begin
        ReqLine.Reset();
        ReqLine.SetRange("Worksheet Template Name", Setup."Worksheet Template Name");
        ReqLine.SetRange("Journal Batch Name", Setup."Worksheet Batch Name");
    end;

    /// <summary>
    /// Consumption per day used to level days of cover. Items without sales history use the
    /// rate implied by their safety-stock target, so they still take part in a shortage.
    /// </summary>
    local procedure GetAllocationRate(RunLine: Record "DP Run Line KBS"; Need: Decimal): Decimal
    begin
        if RunLine."Daily Sales" > 0 then
            exit(RunLine."Daily Sales");
        if RunLine."Coverage Days" < 1 then
            exit(0);
        if RunLine."Target Quantity" > 0 then
            exit(RunLine."Target Quantity" / RunLine."Coverage Days");
        exit(Need / RunLine."Coverage Days");
    end;

    local procedure GetIncrement(RunLine: Record "DP Run Line KBS"): Decimal
    begin
        if RunLine."Order Multiple" > 0 then
            exit(RunLine."Order Multiple");
        exit(RunLine."Quantity Precision");
    end;

    local procedure GetItemKey(ItemNo: Code[20]; VariantCode: Code[10]): Text
    begin
        exit(Format(StrLen(ItemNo)) + ':' + ItemNo + VariantCode);
    end;

    local procedure Minimum(FirstValue: Decimal; SecondValue: Decimal): Decimal
    begin
        if FirstValue < SecondValue then
            exit(FirstValue);
        exit(SecondValue);
    end;

    var
        ForeignLineErr: Label 'Kladden %1/%2 inneholder linje %3 som ikke eies av DeliveryPlanner.', Comment = '%1 = template, %2 = batch, %3 = line number';
        NoAssortmentErr: Label 'Aktiver minst én SKU i en aktiv DeliveryPlanner-butikk.';
        InvalidProposalErr: Label 'Standardforslag %1 har ugyldig mengde eller enhetsomregning.', Comment = '%1 = worksheet line number';
        UnitPrecisionErr: Label 'Tildelingen for vare %1 kan ikke uttrykkes i enhet %2 med gyldig antallspresisjon og ordremultippel.', Comment = '%1 = item, %2 = unit of measure';
        BlockedItemLbl: Label 'Varen eller varianten er blokkert.';
        NoNeedLbl: Label 'Lagermålet er dekket, eller makslageret har ingen ledig plass.';
        NoStandardProposalLbl: Label 'Standardmotoren foreslo ingen ny overføring i planleggingsperioden.';
        BelowIncrementLbl: Label 'Leverbar mengde er mindre enn ett gyldig mengdetrinn.';
        ShortageLbl: Label 'Hovedlageret hadde for lite. Butikkene er fylt opp til like mange dagers dekning, den som går tom først fikk først.';
        NoDeliveryLbl: Label 'Ingen levering fra denne kjøringen. Neste levering %1.', Comment = '%1 = first delivery date';
        NoDeliveryDayLbl: Label 'Ingen leveringsdag innen %1 dager. Kontroller leveringsdagene på lokasjonen og transporttiden på overføringsruten.', Comment = '%1 = number of days';
        LimitedLbl: Label 'Forslaget er begrenset av salgsmål, makslager eller ordremultippel.';
}
