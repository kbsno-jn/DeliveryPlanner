namespace Knowit.DeliveryPlanner;

codeunit 78911 "DP Notification KBS"
{
    procedure SendRunFailure(RunRecord: Record "DP Run KBS")
    var
        Body: TextBuilder;
    begin
        Body.AppendLine(StrSubstNo(FailureIntroTxt, Format(RunRecord."Started At")));
        Body.AppendLine('');
        Body.AppendLine(RunRecord."Error Text");
        Body.AppendLine('');
        Body.AppendLine(FailureActionTxt);
        Send(StrSubstNo(FailureSubjectTxt, CompanyName()), Body.ToText());
    end;

    /// <summary>
    /// Sends a summary only when someone has to act: missing sales or orders waiting for approval.
    /// </summary>
    procedure SendRunSummary(RunRecord: Record "DP Run KBS")
    var
        Body: TextBuilder;
    begin
        if not RunRecord."Sales Warning" and (RunRecord."Orders Awaiting Approval" = 0) then
            exit;
        Body.AppendLine(StrSubstNo(SummaryIntroTxt, Format(RunRecord."Planning Date"), RunRecord."Orders Created"));
        Body.AppendLine('');
        if RunRecord."Sales Warning" then
            Body.AppendLine(StrSubstNo(SalesWarningTxt, RunRecord."Stores Without Sales", RunRecord."Stores Checked"));
        if RunRecord."Orders Awaiting Approval" > 0 then
            Body.AppendLine(StrSubstNo(AwaitingApprovalTxt, RunRecord."Orders Awaiting Approval"));
        Send(StrSubstNo(SummarySubjectTxt, CompanyName()), Body.ToText());
    end;

    local procedure Send(Subject: Text; Body: Text)
    var
        Setup: Record "DP Setup KBS";
        SendEmail: Codeunit "DP Send Email KBS";
        Dimensions: Dictionary of [Text, Text];
    begin
        if not Setup.Get('') then
            exit;
        if Setup."Notification Email" = '' then
            exit;
        SendEmail.SetMessage(Setup."Notification Email", Subject, Body);
        if not SendEmail.Run() then begin
            Dimensions.Add('Error', GetLastErrorText());
            Session.LogMessage('DP0003', EmailFailedTelemetryTxt, Verbosity::Warning, DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher, Dimensions);
        end;
    end;

    var
        FailureSubjectTxt: Label 'DeliveryPlanner feilet i %1', Comment = '%1 = company name';
        FailureIntroTxt: Label 'Nattjobben for DeliveryPlanner startet %1 og feilet. Ingen nye overføringsordrer er opprettet fra denne kjøringen.', Comment = '%1 = start time';
        FailureActionTxt: Label 'Rett feilen og kjør DeliveryPlanner manuelt fra DeliveryPlanner-oppsett. Jobbkøen prøver automatisk på nytt opptil tre ganger.';
        SummarySubjectTxt: Label 'DeliveryPlanner krever oppfølging i %1', Comment = '%1 = company name';
        SummaryIntroTxt: Label 'DeliveryPlanner har beregnet påfylling for %1 og opprettet %2 overføringsordrer.', Comment = '%1 = planning date, %2 = number of orders';
        SalesWarningTxt: Label '- %1 av %2 butikker manglet bokført salg for i går. Salgsimporten var trolig ikke ferdig, så påfyllingen kan være for lav. Kontroller importen og kjør DeliveryPlanner på nytt om nødvendig.', Comment = '%1 = stores without sales, %2 = stores checked';
        AwaitingApprovalTxt: Label '- %1 overføringsordrer venter på godkjenning fordi de er mye større enn butikkens vanlige ordrer. Frigi ordren for å godkjenne den, eller slett den.', Comment = '%1 = number of orders';
        EmailFailedTelemetryTxt: Label 'DeliveryPlanner notification email could not be sent.', Locked = true;
}
