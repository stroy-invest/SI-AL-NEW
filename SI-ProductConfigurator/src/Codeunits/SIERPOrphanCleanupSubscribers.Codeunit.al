codeunit 53020 "SI ERP Orphan Cleanup Subs."
{
    Permissions =
        tabledata "SI Product Config." = RIMD,
        tabledata "SI Product Config. Value" = RIMD,
        tabledata "SI Config. ERP Projection" = RIMD,
        tabledata "SI Item ERP Projection" = RIMD;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterDeleteEvent', '', false, false)]
    local procedure ItemOnAfterDelete(var Rec: Record Item; RunTrigger: Boolean)
    begin
        if Rec."No." = '' then
            exit;

        CleanupAfterItemDeleted(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Variant", 'OnAfterDeleteEvent', '', false, false)]
    local procedure ItemVariantOnAfterDelete(var Rec: Record "Item Variant"; RunTrigger: Boolean)
    begin
        if (Rec."Item No." = '') or (Rec.Code = '') then
            exit;

        CleanupAfterVariantDeleted(Rec."Item No.", Rec.Code);
    end;

    local procedure CleanupAfterItemDeleted(ItemNo: Code[20])
    var
        ConfigProjection: Record "SI Config. ERP Projection";
        ProductConfig: Record "SI Product Config.";
        ItemProjection: Record "SI Item ERP Projection";
        OtherConfigProjection: Record "SI Config. ERP Projection";
        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
        ConfigurationNos: List of [Code[20]];
        ConfigurationNo: Code[20];
    begin
        // Materialized and prepared configurations whose ERP projection pointed
        // to the deleted Item.
        ConfigProjection.SetRange("Item No.", ItemNo);
        if ConfigProjection.FindSet() then
            repeat
                AddUniqueConfigurationNo(
                    ConfigurationNos,
                    ConfigProjection."Configuration No.");
            until ConfigProjection.Next() = 0;

        // Variant configurations may exist even without a persisted projection.
        ProductConfig.SetRange("Base Item No.", ItemNo);
        if ProductConfig.FindSet() then
            repeat
                AddUniqueConfigurationNo(ConfigurationNos, ProductConfig."No.");
            until ProductConfig.Next() = 0;

        foreach ConfigurationNo in ConfigurationNos do
            ERPProjectionMgt.DeleteOrphanedConfiguration(ConfigurationNo);

        // Remove only truly orphaned Item-level technical projections.
        // At this point the standard Item is already gone.
        ItemProjection.SetRange("Item No.", ItemNo);
        if ItemProjection.FindSet(true) then
            repeat
                OtherConfigProjection.Reset();
                OtherConfigProjection.SetRange(
                    "Item Projection Entry No.",
                    ItemProjection."Entry No.");

                if OtherConfigProjection.IsEmpty() then
                    ItemProjection.Delete(false);
            until ItemProjection.Next() = 0;
    end;

    local procedure CleanupAfterVariantDeleted(
        ItemNo: Code[20];
        VariantCode: Code[10])
    var
        ConfigProjection: Record "SI Config. ERP Projection";
        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
        ConfigurationNos: List of [Code[20]];
        ConfigurationNo: Code[20];
    begin
        ConfigProjection.SetRange("Item No.", ItemNo);
        ConfigProjection.SetRange("Variant Code", VariantCode);

        if ConfigProjection.FindSet() then
            repeat
                AddUniqueConfigurationNo(
                    ConfigurationNos,
                    ConfigProjection."Configuration No.");
            until ConfigProjection.Next() = 0;

        foreach ConfigurationNo in ConfigurationNos do
            ERPProjectionMgt.DeleteOrphanedConfiguration(ConfigurationNo);
    end;

    local procedure AddUniqueConfigurationNo(
        var ConfigurationNos: List of [Code[20]];
        ConfigurationNo: Code[20])
    begin
        if ConfigurationNo = '' then
            exit;

        if not ConfigurationNos.Contains(ConfigurationNo) then
            ConfigurationNos.Add(ConfigurationNo);
    end;
}
