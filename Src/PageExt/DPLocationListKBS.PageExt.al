namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Location;

pageextension 78905 "DP Location List KBS" extends "Location List"
{
    layout
    {
        addlast(Control1)
        {
            field(DPEnabledKBS; Rec."DP Enabled KBS") { ApplicationArea = All; }
            field(DPCategoryCodeKBS; Rec."DP Category Code KBS") { ApplicationArea = All; }
        }
    }
    actions
    {
        addlast(processing)
        {
            action(DPSetStoreSettingsKBS)
            {
                Caption = 'Angi DeliveryPlanner';
                ApplicationArea = All;
                Image = UpdateDescription;
                ToolTip = 'Setter DeliveryPlanner aktivert og butikkategori på de merkede lokasjonene. Er bare én linje merket, gjelder endringen alle lokasjonene i filteret.';

                trigger OnAction()
                var
                    Location: Record Location;
                    Management: Codeunit "DP Management KBS";
                    BatchUpdate: Page "DP Location Batch Update KBS";
                    NewEnabled: Boolean;
                    NewCategoryCode: Code[10];
                    UpdatedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(Location);
                    // A single highlighted line is just the cursor; then the user means the filtered list.
                    if Location.Count() <= 1 then begin
                        Location.Reset();
                        Location.CopyFilters(Rec);
                    end;
                    if Location.IsEmpty() then
                        Error(NoLocationsErr);
                    BatchUpdate.SetLocationCount(Location.Count());
                    if BatchUpdate.RunModal() <> Action::OK then
                        exit;
                    BatchUpdate.GetValues(NewEnabled, NewCategoryCode);
                    UpdatedCount := Management.SetStoreSettings(Location, NewEnabled, NewCategoryCode);
                    Message(StoresUpdatedMsg, UpdatedCount);
                    CurrPage.Update(false);
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(DPSetStoreSettingsKBS_Promoted; DPSetStoreSettingsKBS) { }
        }
    }

    var
        StoresUpdatedMsg: Label '%1 lokasjoner er oppdatert.', Comment = '%1 = number of locations';
        NoLocationsErr: Label 'Ingen lokasjoner er merket eller finnes i filteret.';
}
