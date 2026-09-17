namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;

codeunit 62104 "DP Worksheet Guard KBS"
{
    Permissions = tabledata "DP Setup KBS" = r;

    var
        ManagedWorksheetErr: Label 'Kladden %1/%2 administreres av DeliveryPlanner. Bruk Beregn DeliveryPlanner eller Kjør DeliveryPlanner for å oppdatere og utføre forslagene.', Comment = '%1 = worksheet template, %2 = worksheet batch';

    procedure CheckAccess(RequisitionLine: Record "Requisition Line")
    var
        Setup: Record "DP Setup KBS";
        Allowed: Boolean;
        Managed: Boolean;
    begin
        if RequisitionLine.IsTemporary() then
            exit;
        Managed := not IsNullGuid(RequisitionLine."DP Run ID KBS");
        if not Managed then
            if Setup.Get() then
                Managed := (Setup."Worksheet Template Name" <> '') and (Setup."Worksheet Batch Name" <> '') and
                    (RequisitionLine."Worksheet Template Name" = Setup."Worksheet Template Name") and
                    (RequisitionLine."Journal Batch Name" = Setup."Worksheet Batch Name");
        if not Managed then
            exit;
        // The permission exists only while a manually bound adapter is in scope.
        // An error unwinds that instance; there is no session flag to leak into later work.
        OnCheckAccess(RequisitionLine, Allowed);
        if not Allowed then
            Error(ManagedWorksheetErr, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure GuardInsert(var Rec: Record "Requisition Line"; RunTrigger: Boolean)
    begin
        CheckAccess(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure GuardModify(var Rec: Record "Requisition Line"; var xRec: Record "Requisition Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        CheckAccess(Rec);
        CheckAccess(xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure GuardDelete(var Rec: Record "Requisition Line"; RunTrigger: Boolean)
    begin
        CheckAccess(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnBeforeRenameEvent', '', false, false)]
    local procedure GuardRename(var Rec: Record "Requisition Line"; var xRec: Record "Requisition Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        CheckAccess(Rec);
        CheckAccess(xRec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", 'OnBeforeCarryOutBatchActionCode', '', false, false)]
    local procedure GuardBatchAction(var RequisitionLine: Record "Requisition Line"; var ReqLine2: Record "Requisition Line"; var IsHandled: Boolean)
    begin
        CheckAccess(RequisitionLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", 'OnBeforeOnRun', '', false, false)]
    local procedure GuardSingleAction(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
        CheckAccess(RequisitionLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Carry Out Action", 'OnBeforeInsertTransHeader', '', false, false)]
    local procedure GuardTransferHeader(ReqLine: Record "Requisition Line"; var TransHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
        CheckAccess(ReqLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Carry Out Action", 'OnInsertTransLineOnAfterTransLineInit', '', false, false)]
    local procedure GuardTransferLine(var TransLine: Record "Transfer Line"; ReqLine: Record "Requisition Line")
    begin
        CheckAccess(ReqLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAccess(RequisitionLine: Record "Requisition Line"; var Allowed: Boolean)
    begin
    end;
}
