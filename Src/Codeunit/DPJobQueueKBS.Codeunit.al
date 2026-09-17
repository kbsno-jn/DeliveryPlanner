namespace Knowit.DeliveryPlanner;

using System.Threading;

codeunit 62102 "DP Job Queue KBS"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        Management: Codeunit "DP Management KBS";
    begin
        Management.Execute(true);
    end;
}
