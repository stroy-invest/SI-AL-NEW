codeunit 53011 "SI Product Config Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        // Version 1.4.0.0 preserves legacy fields only for schema compatibility.
        // ERP identity is determined exclusively by ERP Projection Role.
    end;
}
