namespace Knowit.DeliveryPlanner;

page 62106 "DP Location Batch Update KBS"
{
    Caption = 'Angi DeliveryPlanner for valgte lokasjoner';
    PageType = StandardDialog;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(LocationCount; LocationCount)
            {
                ApplicationArea = All;
                Caption = 'Antall lokasjoner';
                Editable = false;
                ToolTip = 'Angir hvor mange lokasjoner som endres: de merkede linjene, eller alle lokasjonene i filteret når bare én linje er merket.';
            }
            field(DPEnabled; StoreEnabled)
            {
                ApplicationArea = All;
                Caption = 'DeliveryPlanner aktivert';
                ToolTip = 'Angir om de valgte lokasjonene skal forsynes av DeliveryPlanner.';
            }
            field(DPCategoryCode; StoreCategoryCode)
            {
                ApplicationArea = All;
                Caption = 'DeliveryPlanner-butikkategori';
                TableRelation = "DP Store Category KBS".Code;
                ToolTip = 'Angir butikkategorien som settes på de valgte lokasjonene. Påkrevd når lokasjonene aktiveres.';
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            if StoreEnabled and (StoreCategoryCode = '') then
                Error(CategoryRequiredErr);
        exit(true);
    end;

    procedure SetLocationCount(NewLocationCount: Integer)
    begin
        LocationCount := NewLocationCount;
    end;

    procedure GetValues(var NewEnabled: Boolean; var NewCategoryCode: Code[10])
    begin
        NewEnabled := StoreEnabled;
        NewCategoryCode := StoreCategoryCode;
    end;

    var
        StoreEnabled: Boolean;
        StoreCategoryCode: Code[10];
        LocationCount: Integer;
        CategoryRequiredErr: Label 'Velg en butikkategori når lokasjonene aktiveres for DeliveryPlanner.';
}
