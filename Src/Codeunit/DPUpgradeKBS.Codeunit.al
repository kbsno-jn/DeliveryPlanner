namespace Knowit.DeliveryPlanner;

using System.Upgrade;

codeunit 78907 "DP Upgrade KBS"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
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

    // Registered tags are set on install, so new companies keep the values they choose.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(MonitoringDefaultsTag());
    end;

    local procedure MonitoringDefaultsTag(): Code[250]
    begin
        exit('KBS-DELIVERYPLANNER-MONITORING-DEFAULTS-20261016');
    end;
}
