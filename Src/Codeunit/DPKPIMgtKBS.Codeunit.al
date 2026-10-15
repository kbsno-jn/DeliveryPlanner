namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;

codeunit 78910 "DP KPI Mgt KBS"
{
    /// <summary>
    /// The run that the exception list and key figures describe: the latest run that finished,
    /// whether it created orders or only calculated them.
    /// </summary>
    procedure GetLatestRun(var RunRecord: Record "DP Run KBS"): Boolean
    begin
        RunRecord.Reset();
        RunRecord.SetCurrentKey("Started At");
        RunRecord.SetFilter(Status, '%1|%2', RunRecord.Status::Completed, RunRecord.Status::Calculated);
        exit(RunRecord.FindLast());
    end;

    procedure CalcTotals(RunRecord: Record "DP Run KBS"; var TempTotal: Record "DP KPI Buffer KBS" temporary)
    var
        TempByGroup: Record "DP KPI Buffer KBS" temporary;
    begin
        FillBuffer(RunRecord, TempByGroup);
        Clear(TempTotal);
        TempByGroup.SetRange("Group Type", TempByGroup."Group Type"::Store);
        if TempByGroup.FindSet() then
            repeat
                TempTotal."Line Count" += TempByGroup."Line Count";
                TempTotal."Out of Stock" += TempByGroup."Out of Stock";
                TempTotal."Over Maximum" += TempByGroup."Over Maximum";
                TempTotal."Overstock Quantity" += TempByGroup."Overstock Quantity";
                TempTotal."Unmet Quantity" += TempByGroup."Unmet Quantity";
                TempTotal."Exception Count" += TempByGroup."Exception Count";
                TempTotal."Days In Stock Sum" += TempByGroup."Days In Stock Sum";
                TempTotal."History Days Sum" += TempByGroup."History Days Sum";
                TempTotal."Days of Cover Sum" += TempByGroup."Days of Cover Sum";
                TempTotal."Days of Cover Count" += TempByGroup."Days of Cover Count";
            until TempByGroup.Next() = 0;
        Finish(TempTotal);
    end;

    /// <summary>
    /// One line per store and one per category for the run. Lines with missing setup are counted as
    /// exceptions but left out of service level and cover, since they were not calculated.
    /// </summary>
    procedure FillBuffer(RunRecord: Record "DP Run KBS"; var TempKPI: Record "DP KPI Buffer KBS" temporary)
    var
        RunLine: Record "DP Run Line KBS";
        Location: Record Location;
        Category: Record "DP Store Category KBS";
        HistoryDays: Integer;
    begin
        TempKPI.Reset();
        TempKPI.DeleteAll();
        HistoryDays := GetHistoryDays(RunRecord);
        RunLine.SetRange("Run ID", RunRecord."Run ID");
        RunLine.SetLoadFields("Location Code", "Category Code", Exception, Inventory, "Incoming Quantity", "Maximum Inventory",
            "Days In Stock", "Daily Sales", "Days of Cover", "Unmet Quantity");
        if RunLine.FindSet() then
            repeat
                AddLine(TempKPI, TempKPI."Group Type"::Store, RunLine."Location Code", RunLine, HistoryDays);
                if RunLine."Category Code" <> '' then
                    AddLine(TempKPI, TempKPI."Group Type"::Category, RunLine."Category Code", RunLine, HistoryDays);
            until RunLine.Next() = 0;

        TempKPI.Reset();
        if TempKPI.FindSet() then
            repeat
                if TempKPI."Group Type" = TempKPI."Group Type"::Store then begin
                    if Location.Get(TempKPI.Code) then
                        TempKPI.Description := Location.Name;
                end else
                    if Category.Get(TempKPI.Code) then
                        TempKPI.Description := Category.Description;
                Finish(TempKPI);
                TempKPI.Modify();
            until TempKPI.Next() = 0;
    end;

    procedure CountAwaitingApproval(): Integer
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.SetRange("DP Approval Status KBS", TransferHeader."DP Approval Status KBS"::"Awaiting Approval");
        exit(TransferHeader.Count());
    end;

    procedure ShowAwaitingApproval()
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.SetRange("DP Approval Status KBS", TransferHeader."DP Approval Status KBS"::"Awaiting Approval");
        Page.Run(Page::"Transfer Orders", TransferHeader);
    end;

    local procedure AddLine(var TempKPI: Record "DP KPI Buffer KBS" temporary; GroupType: Option; GroupCode: Code[10]; RunLine: Record "DP Run Line KBS"; HistoryDays: Integer)
    begin
        if not TempKPI.Get(GroupType, GroupCode) then begin
            TempKPI.Init();
            TempKPI."Group Type" := GroupType;
            TempKPI.Code := GroupCode;
            TempKPI.Insert();
        end;
        TempKPI."Line Count" += 1;
        if RunLine.Exception <> RunLine.Exception::None then
            TempKPI."Exception Count" += 1;
        if RunLine.Exception <> RunLine.Exception::"Missing Setup" then begin
            TempKPI."Days In Stock Sum" += RunLine."Days In Stock";
            TempKPI."History Days Sum" += HistoryDays;
            if RunLine.Inventory <= 0 then
                TempKPI."Out of Stock" += 1;
            if (RunLine."Maximum Inventory" > 0) and (RunLine.Inventory + RunLine."Incoming Quantity" > RunLine."Maximum Inventory") then begin
                TempKPI."Over Maximum" += 1;
                TempKPI."Overstock Quantity" += RunLine.Inventory + RunLine."Incoming Quantity" - RunLine."Maximum Inventory";
            end;
            if RunLine."Daily Sales" > 0 then begin
                TempKPI."Days of Cover Sum" += RunLine."Days of Cover";
                TempKPI."Days of Cover Count" += 1;
            end;
            TempKPI."Unmet Quantity" += RunLine."Unmet Quantity";
        end;
        TempKPI.Modify();
    end;

    local procedure Finish(var TempKPI: Record "DP KPI Buffer KBS" temporary)
    begin
        if TempKPI."History Days Sum" > 0 then
            TempKPI."Service Level %" := Round(TempKPI."Days In Stock Sum" / TempKPI."History Days Sum" * 100, 0.1)
        else
            TempKPI."Service Level %" := 0;
        if TempKPI."Days of Cover Count" > 0 then
            TempKPI."Avg. Days of Cover" := Round(TempKPI."Days of Cover Sum" / TempKPI."Days of Cover Count", 0.1)
        else
            TempKPI."Avg. Days of Cover" := 0;
    end;

    local procedure GetHistoryDays(RunRecord: Record "DP Run KBS"): Integer
    var
        Setup: Record "DP Setup KBS";
    begin
        if RunRecord."Sales History Days" > 0 then
            exit(RunRecord."Sales History Days");
        if Setup.Get('') then
            exit(Setup."Sales History Days");
        exit(0);
    end;
}
