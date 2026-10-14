namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
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
        CreatedCount: Integer;
        UpdatedCount: Integer;
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
        CreateCategory(SmallCategoryCodeTok, SmallCategoryLbl, 7, 1);
        CreateCategory(MediumCategoryCodeTok, MediumCategoryLbl, 14, 2);
        CreateCategory(LargeCategoryCodeTok, LargeCategoryLbl, 21, 3);
        ApplyItemMaximums(Setup, CreatedCount, UpdatedCount);
        if GuiAllowed() then
            Message(ItemMaximumsAppliedMsg, CreatedCount, UpdatedCount);
    end;

    procedure SetStoreSettings(var Location: Record Location; NewEnabled: Boolean; NewCategoryCode: Code[10]) UpdatedCount: Integer
    begin
        if NewEnabled and (NewCategoryCode = '') then
            Error(StoreCategoryRequiredErr);
        // Validation rejects hub and in-transit locations; one invalid selection rolls back the whole update.
        if Location.FindSet(true) then
            repeat
                Location.Validate("DP Category Code KBS", NewCategoryCode);
                Location.Validate("DP Enabled KBS", NewEnabled);
                Location.Modify(true);
                UpdatedCount += 1;
            until Location.Next() = 0;
    end;

    procedure ApplyItemMaximums(Setup: Record "DP Setup KBS"; var CreatedCount: Integer; var UpdatedCount: Integer)
    var
        Store: Record Location;
        CategorySize: Option Small,Medium,Large;
    begin
        CreatedCount := 0;
        UpdatedCount := 0;
        Store.SetRange("DP Enabled KBS", true);
        if Store.FindSet() then
            repeat
                case Store."DP Category Code KBS" of
                    SmallCategoryCodeTok:
                        ApplyStoreMaximums(Setup, Store, CategorySize::Small, CreatedCount, UpdatedCount);
                    MediumCategoryCodeTok:
                        ApplyStoreMaximums(Setup, Store, CategorySize::Medium, CreatedCount, UpdatedCount);
                    LargeCategoryCodeTok:
                        ApplyStoreMaximums(Setup, Store, CategorySize::Large, CreatedCount, UpdatedCount);
                end;
            until Store.Next() = 0;
    end;

    local procedure ApplyStoreMaximums(Setup: Record "DP Setup KBS"; Store: Record Location; Size: Option Small,Medium,Large; var CreatedCount: Integer; var UpdatedCount: Integer)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        MaximumInventory: Decimal;
    begin
        Item.SetRange(Type, Item.Type::Inventory);
        case Size of
            Size::Small:
                Item.SetFilter("DP Max. Inv. Small KBS", '>0');
            Size::Medium:
                Item.SetFilter("DP Max. Inv. Medium KBS", '>0');
            Size::Large:
                Item.SetFilter("DP Max. Inv. Large KBS", '>0');
        end;
        if Item.FindSet() then
            repeat
                case Size of
                    Size::Small:
                        MaximumInventory := Item."DP Max. Inv. Small KBS";
                    Size::Medium:
                        MaximumInventory := Item."DP Max. Inv. Medium KBS";
                    Size::Large:
                        MaximumInventory := Item."DP Max. Inv. Large KBS";
                end;
                // Items with variants are planned per variant; the item card value applies to each.
                ItemVariant.SetRange("Item No.", Item."No.");
                if ItemVariant.FindSet() then
                    repeat
                        ApplySKUMaximum(Setup, Store.Code, Item."No.", ItemVariant.Code, MaximumInventory, CreatedCount, UpdatedCount);
                    until ItemVariant.Next() = 0
                else
                    ApplySKUMaximum(Setup, Store.Code, Item."No.", '', MaximumInventory, CreatedCount, UpdatedCount);
            until Item.Next() = 0;
    end;

    local procedure ApplySKUMaximum(Setup: Record "DP Setup KBS"; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; MaximumInventory: Decimal; var CreatedCount: Integer; var UpdatedCount: Integer)
    var
        SKU: Record "Stockkeeping Unit";
    begin
        if SKU.Get(LocationCode, ItemNo, VariantCode) then begin
            if SKU."Maximum Inventory" = MaximumInventory then
                exit;
            SKU.Validate("Maximum Inventory", MaximumInventory);
            SKU.Modify(true);
            UpdatedCount += 1;
            exit;
        end;

        if Setup."Hub Location Code" = '' then
            Error(HubRequiredErr);
        SKU.Init();
        SKU.Validate("Item No.", ItemNo);
        SKU.Validate("Variant Code", VariantCode);
        SKU.Validate("Location Code", LocationCode);
        SKU.Insert(true);
        // Validating the transfer source modifies the record, so it must exist first.
        SKU.Validate("Transfer-from Code", Setup."Hub Location Code");
        SKU.Validate("Replenishment System", SKU."Replenishment System"::Transfer);
        SKU.Validate("Maximum Inventory", MaximumInventory);
        SKU.Modify(true);
        CreatedCount += 1;
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
        SmallCategoryCodeTok: Label 'SMALL', Locked = true;
        MediumCategoryCodeTok: Label 'MEDIUM', Locked = true;
        LargeCategoryCodeTok: Label 'LARGE', Locked = true;
        StoreCategoryRequiredErr: Label 'Velg en butikkategori når lokasjonene aktiveres for DeliveryPlanner.';
        HubRequiredErr: Label 'Angi hovedlager før lagerføringsenheter kan opprettes fra makslager på varekortet.';
        ItemMaximumsAppliedMsg: Label 'Standardoppsettet er opprettet. Makslager fra varekortet: %1 lagerføringsenheter opprettet og %2 oppdatert.', Comment = '%1 = created SKUs, %2 = updated SKUs';
        RunFailedErr: Label 'DeliveryPlanner-kjøring %1 feilet: %2', Comment = '%1 = run ID, %2 = original error';
}
