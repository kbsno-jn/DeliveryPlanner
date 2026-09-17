namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Requisition;
using System.Threading;

codeunit 62100 "DP Management KBS"
{
    procedure InitializeSetup()
    var
        Setup: Record "DP Setup KBS";
    begin
        if Setup.Get('') then
            exit;
        Setup.Init();
        Setup."Primary Key" := '';
        Setup."Sales History Days" := 56;
        Setup."Job Start Time" := 020000T;
        Setup.Insert(true);
    end;

    procedure CreateDefaults()
    var
        Setup: Record "DP Setup KBS";
        WorksheetTemplate: Record "Req. Wksh. Template";
        Batch: Record "Requisition Wksh. Name";
    begin
        InitializeSetup();
        Setup.Get('');
        if Setup."Worksheet Template Name" = '' then
            Setup."Worksheet Template Name" := 'DELIVERY';
        if Setup."Worksheet Batch Name" = '' then
            Setup."Worksheet Batch Name" := 'AUTO';
        if not WorksheetTemplate.Get(Setup."Worksheet Template Name") then begin
            WorksheetTemplate.Init();
            WorksheetTemplate.Name := Setup."Worksheet Template Name";
            WorksheetTemplate.Description := WorksheetDescriptionLbl;
            WorksheetTemplate.Validate(Type, WorksheetTemplate.Type::"Req.");
            WorksheetTemplate.Validate(Recurring, false);
            WorksheetTemplate."Increment Batch Name" := false;
            WorksheetTemplate.Insert(true);
        end;
        WorksheetTemplate.TestField(Type, WorksheetTemplate.Type::"Req.");
        WorksheetTemplate.TestField(Recurring, false);
        WorksheetTemplate.TestField("Increment Batch Name", false);
        if not Batch.Get(WorksheetTemplate.Name, Setup."Worksheet Batch Name") then begin
            Batch.Init();
            Batch."Worksheet Template Name" := WorksheetTemplate.Name;
            Batch.Name := Setup."Worksheet Batch Name";
            Batch.Description := WorksheetDescriptionLbl;
            Batch.Insert(true);
        end;
        Setup.Modify(true);
        CreateCategory('SMALL', SmallCategoryLbl, 7, 1);
        CreateCategory('MEDIUM', MediumCategoryLbl, 14, 2);
        CreateCategory('LARGE', LargeCategoryLbl, 21, 3);
    end;

    procedure Calculate()
    begin
        Execute(false);
        if GuiAllowed() then
            OpenWorksheet();
    end;

    procedure RunPlanner()
    var
        RunRecord: Record "DP Run KBS";
        RunID: Guid;
    begin
        RunID := Execute(true);
        if GuiAllowed() then begin
            RunRecord.SetRange("Run ID", RunID);
            Page.Run(Page::"DP Runs KBS", RunRecord);
        end;
    end;

    procedure Execute(CreateOrders: Boolean): Guid
    var
        RunRecord: Record "DP Run KBS";
        FailureText: Text;
    begin
        InitializeSetup();
        RunRecord.Init();
        RunRecord."Run ID" := CreateGuid();
        RunRecord."Started At" := CurrentDateTime();
        RunRecord."Planning Date" := Today();
        RunRecord."Create Orders" := CreateOrders;
        RunRecord.Status := RunRecord.Status::Running;
        RunRecord."User ID" := CopyStr(UserId(), 1, MaxStrLen(RunRecord."User ID"));
        RunRecord.Insert(true);
        // The one Boolean Codeunit.Run below owns the complete worker transaction.
        Commit();
        ClearLastError();
        if not Codeunit.Run(Codeunit::"DP Worker KBS", RunRecord) then begin
            FailureText := GetLastErrorText();
            RunRecord.Get(RunRecord."Run ID");
            RunRecord.Status := RunRecord.Status::Failed;
            RunRecord."Finished At" := CurrentDateTime();
            RunRecord."Error Text" := CopyStr(FailureText, 1, MaxStrLen(RunRecord."Error Text"));
            RunRecord.Modify(true);
            Commit();
            Error(RunFailedErr, RunRecord."Run ID", FailureText);
        end;
        exit(RunRecord."Run ID");
    end;

    procedure OpenWorksheet()
    var
        Setup: Record "DP Setup KBS";
        ReqLine: Record "Requisition Line";
    begin
        Setup.Get('');
        Setup.TestField("Worksheet Template Name");
        Setup.TestField("Worksheet Batch Name");
        ReqLine."Worksheet Template Name" := Setup."Worksheet Template Name";
        ReqLine."Journal Batch Name" := Setup."Worksheet Batch Name";
        ReqLine.SetRange("Worksheet Template Name", Setup."Worksheet Template Name");
        ReqLine.SetRange("Journal Batch Name", Setup."Worksheet Batch Name");
        Page.Run(Page::"Req. Worksheet", ReqLine);
    end;

    procedure CreateNightJob()
    var
        Setup: Record "DP Setup KBS";
        Job: Record "Job Queue Entry";
        Category: Record "Job Queue Category";
        RunDateFormula: DateFormula;
        NextRunDate: Date;
    begin
        Setup.Get('');
        Job.SetRange("Object Type to Run", Job."Object Type to Run"::Codeunit);
        Job.SetRange("Object ID to Run", Codeunit::"DP Job Queue KBS");
        if not Job.FindFirst() then begin
            if not Category.Get('DELIVERY') then begin
                Category.Init();
                Category.Code := 'DELIVERY';
                Category.Description := CopyStr(JobDescriptionLbl, 1, MaxStrLen(Category.Description));
                Category.Insert(true);
            end;
            Job.Init();
            Job.ID := CreateGuid();
            Job.Validate("Object Type to Run", Job."Object Type to Run"::Codeunit);
            Job.Validate("Object ID to Run", Codeunit::"DP Job Queue KBS");
            Job.Description := JobDescriptionLbl;
            Job.Status := Job.Status::"On Hold";
            Job.Validate("Run on Mondays", true);
            Job.Validate("Run on Tuesdays", true);
            Job.Validate("Run on Wednesdays", true);
            Job.Validate("Run on Thursdays", true);
            Job.Validate("Run on Fridays", true);
            Job.Validate("Run on Saturdays", true);
            Job.Validate("Run on Sundays", true);
            Evaluate(RunDateFormula, '<1D>');
            Job.Validate("Next Run Date Formula", RunDateFormula);
            Job.Validate("Starting Time", Setup."Job Start Time");
            NextRunDate := Today();
            if Time() >= Setup."Job Start Time" then
                NextRunDate += 1;
            Job."Earliest Start Date/Time" := CreateDateTime(NextRunDate, Setup."Job Start Time");
            Job."Maximum No. of Attempts to Run" := 3;
            Job."Rerun Delay (sec.)" := 300;
            Job.Validate("Job Queue Category Code", Category.Code);
            Job.Insert(true);
        end;
        if GuiAllowed() then
            Page.Run(Page::"Job Queue Entry Card", Job);
    end;

    local procedure CreateCategory(CategoryCode: Code[10]; Description: Text[100]; CoverageDays: Integer; Weight: Decimal)
    var
        Category: Record "DP Store Category KBS";
    begin
        if Category.Get(CategoryCode) then
            exit;
        Category.Init();
        Category.Code := CategoryCode;
        Category.Description := Description;
        Category.Validate("Coverage Days", CoverageDays);
        Category.Validate("Allocation Weight", Weight);
        Category.Insert(true);
    end;

    var
        WorksheetDescriptionLbl: Label 'Automatisk butikkforsyning';
        JobDescriptionLbl: Label 'DeliveryPlanner – nattlig butikkforsyning';
        SmallCategoryLbl: Label 'Liten butikk';
        MediumCategoryLbl: Label 'Mellomstor butikk';
        LargeCategoryLbl: Label 'Stor butikk';
        RunFailedErr: Label 'DeliveryPlanner-kjøring %1 feilet: %2', Comment = '%1 = run ID, %2 = original error';
}
