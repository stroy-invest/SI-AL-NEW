codeunit 53011 "SI Product Config Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        ConfigProjection: Record "SI Config. ERP Projection";
        ProjectionMgt: Codeunit "SI ERP Projection Mgt.";
    begin
        if ConfigProjection.FindSet() then
            repeat
                if ProjectionMgt.HasMaterializedERPLinks(ConfigProjection."Configuration No.") then
                    ProjectionMgt.MarkValuesEverUsed(ConfigProjection."Configuration No.");
            until ConfigProjection.Next() = 0;
        // Version 1.4.0.0 preserves legacy fields only for schema compatibility.
        // ERP identity is determined exclusively by ERP Projection Role.
    end;
}
