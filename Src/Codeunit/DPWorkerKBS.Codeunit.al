namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;

codeunit 62101 "DP Worker KBS"
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
    begin
        Setup.LockTable();
        Setup.Get('');
        ValidateSetup(Setup, RunRecord."Create Orders");
        ValidateWorksheet(Setup);
        ValidateAssortment(Setup);
        Adapter.Configure(Setup, RunRecord);
        BindSubscription(Adapter);
        DeletePreviousProposals(Setup);
        BuildSnapshots(Setup, RunRecord, HubAvailability);
        CalculateStandardPlan(RunRecord, Adapter);
        CaptureProposals(Setup, RunRecord);
        AllocateStock(RunRecord, HubAvailability);
        ApplyAllocations(Setup, RunRecord);
        if RunRecord."Create Orders" then
            Adapter.CarryOutAndRelease();
        UnbindSubscription(Adapter);
        RunRecord."Finished At" := CurrentDateTime();
        if RunRecord."Create Orders" then
            RunRecord.Status := RunRecord.Status::Completed
        else
            RunRecord.Status := RunRecord.Status::Calculated;
        RunRecord.Modify(true);
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

    local procedure ValidateAssortment(Setup: Record "DP Setup KBS")
    var
        SKU: Record "Stockkeeping Unit";
        Store: Record Location;
        Category: Record "DP Store Category KBS";
        Route: Record "Transfer Route";
        Transit: Record Location;
        ReqLine: Record "Requisition Line";
        ActiveCount: Integer;
    begin
        SKU.SetRange("DP Enabled KBS", true);
        if SKU.FindSet() then
            repeat
                Store.Get(SKU."Location Code");
                if Store."DP Enabled KBS" then begin
                    ActiveCount += 1;
                    Store.TestField("Use As In-Transit", false);
                    if Store.Code = Setup."Hub Location Code" then
                        Error(HubStoreErr, Store.Code);
                    Store.TestField("DP Category Code KBS");
                    Category.Get(Store."DP Category Code KBS");
                    if Category."Coverage Days" < 1 then
                        Category.FieldError("Coverage Days");
                    if Category."Allocation Weight" <= 0 then
                        Category.FieldError("Allocation Weight");
                    SKU.TestField("Replenishment System", SKU."Replenishment System"::Transfer);
                    SKU.TestField("Transfer-from Code", Setup."Hub Location Code");
                    if SKU."Maximum Inventory" <= 0 then
                        SKU.FieldError("Maximum Inventory");
                    if (SKU."Safety Stock Quantity" < 0) or (SKU."Safety Stock Quantity" > SKU."Maximum Inventory") then
                        SKU.FieldError("Safety Stock Quantity");
                    if SKU."Order Multiple" < 0 then
                        SKU.FieldError("Order Multiple");
                    if not Route.Get(Setup."Hub Location Code", Store.Code) then
                        Error(RouteErr, Setup."Hub Location Code", Store.Code);
                    Route.TestField("In-Transit Code");
                    Transit.Get(Route."In-Transit Code");
                    Transit.TestField("Use As In-Transit", true);
                    ReqLine.Reset();
                    ReqLine.SetRange(Type, ReqLine.Type::Item);
                    ReqLine.SetRange("No.", SKU."Item No.");
                    ReqLine.SetRange("Variant Code", SKU."Variant Code");
                    ReqLine.SetRange("Location Code", SKU."Location Code");
                    if ReqLine.FindSet() then
                        repeat
                            if (ReqLine."Worksheet Template Name" <> Setup."Worksheet Template Name") or
                               (ReqLine."Journal Batch Name" <> Setup."Worksheet Batch Name")
                            then
                                Error(OtherWorksheetErr, SKU."Item No.", SKU."Variant Code", SKU."Location Code",
                                    ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name");
                        until ReqLine.Next() = 0;
                end;
            until SKU.Next() = 0;
        if ActiveCount = 0 then
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
                    Item.Get(SKU."Item No.");
                    Item.TestField(Type, Item.Type::Inventory);
                    Blocked := Item.Blocked;
                    if SKU."Variant Code" <> '' then begin
                        Variant.Get(SKU."Item No.", SKU."Variant Code");
                        Blocked := Blocked or Variant.Blocked;
                    end;
                    Inventory.BuildRunLine(SKU, Setup, RunRecord, RunLine);
                    if Blocked then begin
                        RunLine."Need Quantity" := 0;
                        RunLine.Reason := BlockedItemLbl;
                    end;
                    RunLine.Insert(true);
                    ItemKey := GetItemKey(SKU."Item No.", SKU."Variant Code");
                    if not HubAvailability.ContainsKey(ItemKey) then
                        HubAvailability.Add(ItemKey, Inventory.GetHubAvailable(SKU."Item No.", SKU."Variant Code", Setup."Hub Location Code"));
                end;
            until SKU.Next() = 0;
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
                TempBuffer.Insert();
            until RunLine.Next() = 0;
        Allocation.Allocate(TempBuffer, Available);
        if TempBuffer.FindSet() then
            repeat
                RunLine.Get(RunRecord."Run ID", TempBuffer."Run Line Entry No.");
                RunLine."Allocated Quantity" := TempBuffer.Allocation;
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
                RunLine."Allocated Quantity" := Actual;
                RunLine.Modify(true);
            until RunLine.Next() = 0;
    end;

    local procedure FilterWorksheet(var ReqLine: Record "Requisition Line"; Setup: Record "DP Setup KBS")
    begin
        ReqLine.Reset();
        ReqLine.SetRange("Worksheet Template Name", Setup."Worksheet Template Name");
        ReqLine.SetRange("Journal Batch Name", Setup."Worksheet Batch Name");
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
        OtherWorksheetErr: Label 'Vare %1, variant %2, butikk %3 har forslag i kladden %4/%5. Behandle disse før DeliveryPlanner kjøres.', Comment = '%1 = item, %2 = variant, %3 = store, %4 = template, %5 = batch';
        HubStoreErr: Label 'Hovedlager %1 kan ikke være aktivert som butikk.', Comment = '%1 = location';
        RouteErr: Label 'Overføringsrute fra %1 til %2 mangler.', Comment = '%1 = hub, %2 = store';
        NoAssortmentErr: Label 'Aktiver minst én SKU i en aktiv DeliveryPlanner-butikk.';
        InvalidProposalErr: Label 'Standardforslag %1 har ugyldig mengde eller enhetsomregning.', Comment = '%1 = worksheet line number';
        UnitPrecisionErr: Label 'Tildelingen for vare %1 kan ikke uttrykkes i enhet %2 med gyldig antallspresisjon og ordremultippel.', Comment = '%1 = item, %2 = unit of measure';
        BlockedItemLbl: Label 'Varen eller varianten er blokkert.';
        NoNeedLbl: Label 'Lagermålet er dekket, eller makslageret har ingen ledig plass.';
        NoStandardProposalLbl: Label 'Standardmotoren foreslo ingen ny overføring i planleggingsperioden.';
        BelowIncrementLbl: Label 'Leverbar mengde er mindre enn ett gyldig mengdetrinn.';
        ShortageLbl: Label 'Tildelingen er begrenset av hovedlagerets beholdning og butikkens fordelingsvekt.';
        LimitedLbl: Label 'Forslaget er begrenset av salgsmål, makslager eller ordremultippel.';
}
