codeunit 53014 "SI ERP Projection Cleanup Mgt."
{
    internal procedure Cleanup(var ConfigERPProjection: Record "SI Config. ERP Projection")
    var
        ConfigurationNo: Code[20];
    begin
        ValidateCleanupAllowed(ConfigERPProjection);

        if not Confirm(CleanupConfirmQst, false, ConfigERPProjection."Configuration No.") then
            exit;

        ConfigurationNo := ConfigERPProjection."Configuration No.";
        ConfigERPProjection.Delete(true);

        Message(CleanupCompletedMsg, ConfigurationNo);
    end;

    internal procedure IsCleanupAllowed(ConfigERPProjection: Record "SI Config. ERP Projection"): Boolean
    begin
        exit(
            (ConfigERPProjection."Configuration No." <> '') and
            (ConfigERPProjection.Status <> ConfigERPProjection.Status::Projected) and
            (ConfigERPProjection."Item No." = '') and
            (ConfigERPProjection."Variant Code" = '') and
            (ConfigERPProjection."Item Projection Entry No." = 0) and
            (ConfigERPProjection."Projected At" = 0DT));
    end;

    internal procedure IsForceDeleteAllowed(
        ConfigERPProjection: Record "SI Config. ERP Projection"): Boolean
    begin
        if ConfigERPProjection."Configuration No." = '' then
            exit(false);

        exit(not IsActuallyMaterialized(ConfigERPProjection));
    end;

    internal procedure ForceDeleteUnmaterialized(
        var ConfigERPProjection: Record "SI Config. ERP Projection")
    var
        ProductConfig: Record "SI Product Config.";
        ItemProjection: Record "SI Item ERP Projection";
        OtherConfigProjection: Record "SI Config. ERP Projection";
        ConfigurationNo: Code[20];
        ItemProjectionEntryNo: Integer;
    begin
        ConfigERPProjection.TestField("Configuration No.");

        if not IsForceDeleteAllowed(ConfigERPProjection) then
            Error(MaterializedProjectionErr, ConfigERPProjection."Configuration No.");

        if not Confirm(
            ForceDeleteConfirmQst,
            false,
            ConfigERPProjection."Configuration No.")
        then
            exit;

        ConfigurationNo := ConfigERPProjection."Configuration No.";
        ItemProjectionEntryNo := ConfigERPProjection."Item Projection Entry No.";

        // Delete only the configuration-level technical projection. Standard
        // BC Item and Item Variant records are never deleted by this operation.
        ConfigERPProjection.Delete(false);

        // Remove an orphaned technical Item Projection only when it belonged
        // to this configuration identity and is no longer referenced.
        if ItemProjectionEntryNo <> 0 then begin
            OtherConfigProjection.SetRange(
                "Item Projection Entry No.",
                ItemProjectionEntryNo);

            if OtherConfigProjection.IsEmpty() then
                if ItemProjection.Get(ItemProjectionEntryNo) then
                    if IsSameProjectionIdentity(
                        ItemProjection,
                        ConfigERPProjection)
                    then
                        ItemProjection.Delete(false);
        end;

        if ProductConfig.Get(ConfigurationNo) then begin
            ProductConfig.SetValidationResult(
                ProductConfig.Status::Validated,
                '');
            ProductConfig.Modify(true);
        end;

        Message(ForceDeleteCompletedMsg, ConfigurationNo);
    end;


    internal procedure DeleteUnmaterializedTechnicalProjection(
        var ConfigERPProjection: Record "SI Config. ERP Projection")
    var
        ItemProjection: Record "SI Item ERP Projection";
        OtherConfigProjection: Record "SI Config. ERP Projection";
        ItemProjectionEntryNo: Integer;
    begin
        ConfigERPProjection.TestField("Configuration No.");

        if IsActuallyMaterialized(ConfigERPProjection) then
            Error(MaterializedProjectionErr, ConfigERPProjection."Configuration No.");

        ItemProjectionEntryNo := ConfigERPProjection."Item Projection Entry No.";

        // Delete only the technical configuration projection.
        // Standard BC Item / Variant are never touched here.
        ConfigERPProjection.Delete(false);

        // Remove an orphaned technical Item Projection only if no other
        // configuration projection references it and identities match.
        if ItemProjectionEntryNo <> 0 then begin
            OtherConfigProjection.SetRange(
                "Item Projection Entry No.",
                ItemProjectionEntryNo);

            if OtherConfigProjection.IsEmpty() then
                if ItemProjection.Get(ItemProjectionEntryNo) then
                    if IsSameProjectionIdentity(ItemProjection, ConfigERPProjection) then
                        ItemProjection.Delete(false);
        end;
    end;


    internal procedure CanRepairInvalidSharedItemMapping(
        ConfigERPProjection: Record "SI Config. ERP Projection"): Boolean
    var
        CurrentItemProjection: Record "SI Item ERP Projection";
        OtherItemProjection: Record "SI Item ERP Projection";
    begin
        if (ConfigERPProjection.Status <> ConfigERPProjection.Status::Projected) or
           (ConfigERPProjection."Item No." = '') or
           (ConfigERPProjection."Item Projection Entry No." = 0)
        then
            exit(false);

        if not CurrentItemProjection.Get(ConfigERPProjection."Item Projection Entry No.") then
            exit(false);

        OtherItemProjection.SetRange("Item No.", ConfigERPProjection."Item No.");
        OtherItemProjection.SetFilter("Entry No.", '<>%1', CurrentItemProjection."Entry No.");

        if OtherItemProjection.FindSet() then
            repeat
                if (OtherItemProjection."Family Code" <> CurrentItemProjection."Family Code") or
                   (OtherItemProjection."Item Projection Key Hash" <> CurrentItemProjection."Item Projection Key Hash") or
                   (OtherItemProjection."Item Projection Key" <> CurrentItemProjection."Item Projection Key")
                then
                    exit(true);
            until OtherItemProjection.Next() = 0;

        exit(false);
    end;

    internal procedure RepairInvalidSharedItemMapping(
        var ConfigERPProjection: Record "SI Config. ERP Projection")
    var
        ProductConfig: Record "SI Product Config.";
        ItemProjection: Record "SI Item ERP Projection";
        OtherConfigProjection: Record "SI Config. ERP Projection";
        ConfigurationNo: Code[20];
        ItemProjectionEntryNo: Integer;
    begin
        if not CanRepairInvalidSharedItemMapping(ConfigERPProjection) then
            Error(RepairNotApplicableErr, ConfigERPProjection."Configuration No.");

        if not Confirm(
            RepairInvalidMappingQst,
            false,
            ConfigERPProjection."Configuration No.",
            ConfigERPProjection."Item No.")
        then
            exit;

        ConfigurationNo := ConfigERPProjection."Configuration No.";
        ItemProjectionEntryNo := ConfigERPProjection."Item Projection Entry No.";

        // This is a controlled repair of an invalid technical link. The BC Item is never deleted.
        ConfigERPProjection.Delete(false);

        OtherConfigProjection.SetRange("Item Projection Entry No.", ItemProjectionEntryNo);
        if OtherConfigProjection.IsEmpty() then
            if ItemProjection.Get(ItemProjectionEntryNo) then
                ItemProjection.Delete(false);

        if ProductConfig.Get(ConfigurationNo) then begin
            ProductConfig.SetValidationResult(ProductConfig.Status::Validated, '');
            ProductConfig.Modify(true);
        end;

        Message(RepairCompletedMsg, ConfigurationNo);
    end;

    local procedure IsActuallyMaterialized(
        ConfigERPProjection: Record "SI Config. ERP Projection"): Boolean
    var
        ProductConfig: Record "SI Product Config.";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemProjection: Record "SI Item ERP Projection";
    begin
        if ConfigERPProjection.Status <> ConfigERPProjection.Status::Projected then
            exit(false);

        if ConfigERPProjection."Projected At" = 0DT then
            exit(false);

        if ConfigERPProjection."Item No." = '' then
            exit(false);

        if not Item.Get(ConfigERPProjection."Item No.") then
            exit(false);

        if ConfigERPProjection."Item Projection Entry No." = 0 then
            exit(false);

        if not ItemProjection.Get(
            ConfigERPProjection."Item Projection Entry No.")
        then
            exit(false);

        if ItemProjection."Item No." <> ConfigERPProjection."Item No." then
            exit(false);

        if not ProductConfig.Get(ConfigERPProjection."Configuration No.") then
            exit(false);

        // Variant mode deliberately reuses the Base Item projection. In this
        // mode semantic equality of the Item Projection Key is not required.
        if ProductConfig."Base Item No." <> '' then begin
            if ProductConfig."Base Item No." <> ConfigERPProjection."Item No." then
                exit(false);

            if ConfigERPProjection."Variant Code" = '' then
                exit(false);

            exit(
                ItemVariant.Get(
                    ConfigERPProjection."Item No.",
                    ConfigERPProjection."Variant Code"));
        end;

        if not IsSameProjectionIdentity(
            ItemProjection,
            ConfigERPProjection)
        then
            exit(false);

        // Item mode materializes the Item itself and normally has no Variant.
        if ConfigERPProjection."Variant Code" <> '' then
            if not ItemVariant.Get(
                ConfigERPProjection."Item No.",
                ConfigERPProjection."Variant Code")
            then
                exit(false);

        exit(true);
    end;

    local procedure IsSameProjectionIdentity(
        ItemProjection: Record "SI Item ERP Projection";
        ConfigERPProjection: Record "SI Config. ERP Projection"): Boolean
    begin
        exit(
            (ItemProjection."Family Code" = ConfigERPProjection."Family Code") and
            (ItemProjection."Item Projection Key Hash" =
                ConfigERPProjection."Item Projection Key Hash") and
            (ItemProjection."Item Projection Key" =
                ConfigERPProjection."Item Projection Key"));
    end;

    local procedure ValidateCleanupAllowed(ConfigERPProjection: Record "SI Config. ERP Projection")
    begin
        ConfigERPProjection.TestField("Configuration No.");

        if ConfigERPProjection.Status = ConfigERPProjection.Status::Projected then
            Error(MaterializedProjectionErr, ConfigERPProjection."Configuration No.");

        if ConfigERPProjection."Item No." <> '' then
            Error(LinkedItemErr, ConfigERPProjection."Configuration No.", ConfigERPProjection."Item No.");

        if ConfigERPProjection."Variant Code" <> '' then
            Error(LinkedVariantErr, ConfigERPProjection."Configuration No.", ConfigERPProjection."Variant Code");

        if ConfigERPProjection."Item Projection Entry No." <> 0 then
            Error(LinkedItemProjectionErr, ConfigERPProjection."Configuration No.");

        if ConfigERPProjection."Projected At" <> 0DT then
            Error(ProjectedMetadataErr, ConfigERPProjection."Configuration No.");
    end;

    var
        CleanupConfirmQst: Label
            'Очистити ERP-проєкцію конфігурації %1?\Будуть видалені лише службові записи проєкції. Стандартні об’єкти Business Central не будуть змінені.';

        CleanupCompletedMsg: Label
            'ERP-проєкцію конфігурації %1 очищено.';

        ForceDeleteConfirmQst: Label
            'Примусово видалити нематеріалізовану ERP-проєкцію конфігурації %1?\Буде видалено лише службовий запис і розірвано технічні зв’язки. Стандартні товари та варіанти Business Central не видаляються.';

        ForceDeleteCompletedMsg: Label
            'Нематеріалізовану ERP-проєкцію конфігурації %1 видалено.';

        MaterializedProjectionErr: Label
            'ERP-проєкція конфігурації %1 уже матеріалізована. Для її видалення потрібне кероване скасування матеріалізації.';

        LinkedItemErr: Label
            'ERP-проєкцію конфігурації %1 не можна очистити, оскільки вона вже пов’язана з товаром %2.';

        LinkedVariantErr: Label
            'ERP-проєкцію конфігурації %1 не можна очистити, оскільки вона вже пов’язана з варіантом %2.';

        LinkedItemProjectionErr: Label
            'ERP-проєкцію конфігурації %1 не можна очистити, оскільки вона вже пов’язана з проєкцією товару.';

        ProjectedMetadataErr: Label
            'ERP-проєкцію конфігурації %1 не можна очистити, оскільки для неї вже зафіксовано дату матеріалізації.';


        RepairInvalidMappingQst: Label
            'Виправити некоректну ERP-проєкцію конфігурації %1?\Буде видалено лише помилкові службові зв’язки з товаром %2. Сам товар Business Central не видаляється. Після цього конфігурацію треба матеріалізувати повторно.';

        RepairNotApplicableErr: Label
            'Для ERP-проєкції конфігурації %1 не виявлено помилкового спільного використання товару різними семантичними ідентичностями.';

        RepairCompletedMsg: Label
            'Некоректні зв’язки ERP-проєкції конфігурації %1 видалено. Конфігурацію повернуто у статус «Перевірено»; виконайте матеріалізацію повторно.';
}
