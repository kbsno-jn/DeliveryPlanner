namespace Knowit.DeliveryPlanner;

using System.Upgrade;

codeunit 78907 "DP Upgrade KBS"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        UpgradeSetupDefaults();
        UpgradeRunLinePlanningDate();
    end;

    local procedure UpgradeSetupDefaults()
    var
        Setup: Record "DP Setup KBS";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // InitValue does not apply to existing records; give upgraded setups the same defaults as new ones.
        if not Setup.Get('') then
            exit;
        if Setup."Min. Days In Stock" <= 0 then begin
            Setup."Min. Days In Stock" := 14;
            Setup.Modify(false);
        end;
        // Zero is a valid choice for these fields, so the defaults are applied once only.
        if UpgradeTag.HasUpgradeTag(MonitoringDefaultsTag()) then
            exit;
        Setup."Sales Alert %" := 50;
        Setup."Log Retention Days" := 90;
        Setup."Approval Factor" := 2;
        Setup."Approval History Orders" := 4;
        Setup.Modify(false);
        UpgradeTag.SetUpgradeTag(MonitoringDefaultsTag());
    end;

    // Reporting filters run lines on their own planning date, so lines from earlier versions get it from their run.
    local procedure UpgradeRunLinePlanningDate()
    var
        RunRecord: Record "DP Run KBS";
        RunLine: Record "DP Run Line KBS";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(RunLinePlanningDateTag()) then
            exit;
        RunRecord.SetLoadFields("Planning Date");
        if RunRecord.FindSet() then
            repeat
                RunLine.SetRange("Run ID", RunRecord."Run ID");
                RunLine.ModifyAll("Planning Date", RunRecord."Planning Date", false);
            until RunRecord.Next() = 0;
        UpgradeTag.SetUpgradeTag(RunLinePlanningDateTag());
    end;

    // Registered tags are set on install, so new companies keep the values they choose.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(MonitoringDefaultsTag());
        PerCompanyUpgradeTags.Add(RunLinePlanningDateTag());
    end;

    local procedure MonitoringDefaultsTag(): Code[250]
    begin
        exit('KBS-DELIVERYPLANNER-MONITORING-DEFAULTS-20261016');
    end;

    local procedure RunLinePlanningDateTag(): Code[250]
    begin
        exit('KBS-DELIVERYPLANNER-RUNLINE-PLANNINGDATE-20261016');
    end;
}
