namespace Knowit.DeliveryPlanner;

using System.Email;

/// <summary>
/// Sends one prepared message. Run through Codeunit.Run so a missing email account or a
/// connector error never turns a successful planner run into a failure.
/// </summary>
codeunit 78912 "DP Send Email KBS"
{
    trigger OnRun()
    var
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
    begin
        EmailMessage.Create(Recipients, Subject, Body, false);
        if not Email.Send(EmailMessage, Enum::"Email Scenario"::"DeliveryPlanner KBS") then
            Error(SendFailedErr);
    end;

    procedure SetMessage(NewRecipients: Text; NewSubject: Text; NewBody: Text)
    begin
        Recipients := NewRecipients;
        Subject := NewSubject;
        Body := NewBody;
    end;

    var
        Recipients: Text;
        Subject: Text;
        Body: Text;
        SendFailedErr: Label 'E-posten fra DeliveryPlanner kunne ikke sendes.';
}
