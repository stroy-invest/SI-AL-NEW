codeunit 53001 "SI ERP Projection Mgt."
{
    // Orchestrates ERP preview and MVP materialization into standard Item and Item Variant records.

    procedure OpenPreview(ConfigurationNo: Code[20])
    var
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        PreviewPage: Page "SI ERP Projection Preview";
    begin
        BuildPreview(ConfigurationNo, PrevBuffer);

        PreviewPage.SetPreviewBuffer(PrevBuffer);
        PreviewPage.RunModal();
    end;

    procedure Materialize(ConfigurationNo: Code[20])
    var
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
    begin
        BuildPreview(ConfigurationNo, PrevBuffer);
        Materialize(PrevBuffer);
        Message(MaterializationCompletedMsg);
    end;

    procedure CreateProjection(ConfigurationNo: Code[20])
    var
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        ConfigProjection: Record "SI Config. ERP Projection";
    begin
        if ConfigProjection.Get(ConfigurationNo) then
            Error(ProjectionAlreadyExistsErr, ConfigurationNo);

        BuildPreview(ConfigurationNo, PrevBuffer);

        if (PrevBuffer.Status <> PrevBuffer.Status::Ready) or
           (not PrevBuffer."Is Ready")
        then begin
            PersistFailedProjection(PrevBuffer);
            Message(
                ProjectionCreationFailedErr,
                PrevBuffer."Validation Message");
            exit;
        end;

        PersistPreparedProjection(PrevBuffer);
        Message(ProjectionCreatedMsg, ConfigurationNo);
    end;

    procedure HasProjection(ConfigurationNo: Code[20]): Boolean
    var
        ConfigProjection: Record "SI Config. ERP Projection";
    begin
        if ConfigurationNo = '' then
            exit(false);

        exit(ConfigProjection.Get(ConfigurationNo));
    end;

    procedure CanDeleteProjection(ConfigurationNo: Code[20]): Boolean
    begin
        if ConfigurationNo = '' then
            exit(false);

        exit(not HasMaterializedERPLinks(ConfigurationNo));
    end;

    procedure HasMaterializedERPLinks(ConfigurationNo: Code[20]): Boolean
    var
        ProductConfig: Record "SI Product Config.";
        ConfigProjection: Record "SI Config. ERP Projection";
        ItemProjection: Record "SI Item ERP Projection";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if ConfigurationNo = '' then
            exit(false);

        if not ProductConfig.Get(ConfigurationNo) then
            exit(false);

        if not ConfigProjection.Get(ConfigurationNo) then
            exit(false);

        if ConfigProjection."Item No." = '' then
            exit(false);

        if not Item.Get(ConfigProjection."Item No.") then
            exit(false);

        if ConfigProjection."Item Projection Entry No." = 0 then
            exit(false);

        if not ItemProjection.Get(ConfigProjection."Item Projection Entry No.") then
            exit(false);

        if ItemProjection."Item No." <> ConfigProjection."Item No." then
            exit(false);

        // Variant configuration: the real ERP result is Item + Item Variant.
        if ProductConfig."Base Item No." <> '' then begin
            if ProductConfig."Base Item No." <> ConfigProjection."Item No." then
                exit(false);

            if ConfigProjection."Variant Code" = '' then
                exit(false);

            exit(
                ItemVariant.Get(
                    ConfigProjection."Item No.",
                    ConfigProjection."Variant Code"));
        end;

        // Item configuration: existence of the linked standard Item plus
        // the linked SI Item ERP Projection is sufficient proof of materialization.
        exit(true);
    end;

    procedure SyncConfigurationDisplayNameFromERP(ConfigurationNo: Code[20]): Text
    var
        ProductConfig: Record "SI Product Config.";
        ConfigProjection: Record "SI Config. ERP Projection";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        NewDisplayName: Text;
    begin
        if not HasMaterializedERPLinks(ConfigurationNo) then
            Error(SyncNameNotMaterializedErr, ConfigurationNo);

        ProductConfig.Get(ConfigurationNo);
        ConfigProjection.Get(ConfigurationNo);

        if ProductConfig."Base Item No." = '' then begin
            Item.Get(ConfigProjection."Item No.");
            NewDisplayName := Item.Description;
        end else begin
            ItemVariant.Get(ConfigProjection."Item No.", ConfigProjection."Variant Code");
            NewDisplayName := ItemVariant.Description;
        end;

        NewDisplayName := DelChr(NewDisplayName, '<>', ' ');
        if NewDisplayName = '' then
            Error(SyncNameEmptyErr, ConfigurationNo);

        if ProductConfig.Description = NewDisplayName then
            exit(ProductConfig.Description);

        ProductConfig.Description := CopyStr(NewDisplayName, 1, MaxStrLen(ProductConfig.Description));
        ProductConfig.Modify(false);

        exit(ProductConfig.Description);
    end;

    procedure GetProjectionLifecycleStatus(ConfigurationNo: Code[20]): Text
    var
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
    begin
        if HasMaterializedERPLinks(ConfigurationNo) then
            exit(MaterializedStatusTxt);

        BuildPreview(ConfigurationNo, PrevBuffer);

        if (PrevBuffer.Status = PrevBuffer.Status::Ready) and PrevBuffer."Is Ready" then
            exit(ReadyForMaterializationStatusTxt);

        exit(ProjectionErrorStatusTxt);
    end;

    procedure DeleteProjection(ConfigurationNo: Code[20]): Boolean
    var
        ProductConfig: Record "SI Product Config.";
        ChildVariantConfig: Record "SI Product Config.";
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        ChildConfigurationNos: List of [Code[20]];
        ChildConfigurationNo: Code[20];
        ItemNo: Code[20];
        ChildCount: Integer;
    begin
        if ConfigurationNo = '' then
            exit(false);

        if not ProductConfig.Get(ConfigurationNo) then
            exit(false);

        if HasMaterializedERPLinks(ConfigurationNo) then
            Error(MaterializedProjectionDeleteErr, ConfigurationNo);

        // Item configuration: collect the currently related variant branch first.
        if ProductConfig."Base Item No." = '' then begin
            ItemNo := ResolveConfigurationItemNo(ConfigurationNo);

            if ItemNo <> '' then begin
                ChildVariantConfig.SetRange("Family Code", ProductConfig."Family Code");
                ChildVariantConfig.SetRange("Base Item No.", ItemNo);

                if ChildVariantConfig.FindSet() then
                    repeat
                        if HasMaterializedERPLinks(ChildVariantConfig."No.") then
                            Error(
                                MaterializedChildVariantDeleteErr,
                                ChildVariantConfig.Description);

                        ChildConfigurationNos.Add(ChildVariantConfig."No.");
                    until ChildVariantConfig.Next() = 0;
            end;

            ChildCount := ChildConfigurationNos.Count();

            if ChildCount > 0 then begin
                if not Confirm(
                    DeleteItemBranchQst,
                    false,
                    ProductConfig.Description,
                    ChildCount)
                then
                    exit(false);
            end else
                if not ConfirmDeleteSingleConfiguration(ProductConfig) then
                    exit(false);

            // Child-first deletion prevents orphaned variant configurations.
            foreach ChildConfigurationNo in ChildConfigurationNos do
                DeleteSingleUnmaterializedConfiguration(ChildConfigurationNo);

            DeleteSingleUnmaterializedConfiguration(ConfigurationNo);
            Message(DeleteBranchCompletedMsg, ProductConfig.Description, ChildCount);
            exit(true);
        end;

        if not ConfirmDeleteSingleConfiguration(ProductConfig) then
            exit(false);

        DeleteSingleUnmaterializedConfiguration(ConfigurationNo);
        Message(DeleteSingleCompletedMsg, ProductConfig.Description);
        exit(true);
    end;

    local procedure ConfirmDeleteSingleConfiguration(
        ProductConfig: Record "SI Product Config."): Boolean
    var
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
    begin
        BuildPreview(ProductConfig."No.", PrevBuffer);

        if (PrevBuffer.Status = PrevBuffer.Status::Ready) and
           PrevBuffer."Is Ready"
        then
            exit(
                Confirm(
                    DeleteReadyProjectionQst,
                    false,
                    ProductConfig.Description));

        exit(
            Confirm(
                DeleteInvalidProjectionQst,
                false,
                ProductConfig.Description));
    end;

    local procedure DeleteSingleUnmaterializedConfiguration(
        ConfigurationNo: Code[20])
    var
        ProductConfig: Record "SI Product Config.";
        ProductConfigValue: Record "SI Product Config. Value";
        ConfigProjection: Record "SI Config. ERP Projection";
        CleanupMgt: Codeunit "SI ERP Projection Cleanup Mgt.";
    begin
        if HasMaterializedERPLinks(ConfigurationNo) then
            Error(MaterializedProjectionDeleteErr, ConfigurationNo);

        // Remove technical ERP projection state first, if it exists.
        if ConfigProjection.Get(ConfigurationNo) then
            CleanupMgt.DeleteUnmaterializedTechnicalProjection(ConfigProjection);

        // Configuration values belong to the configuration and must be removed
        // before the configuration record itself.
        ProductConfigValue.SetRange("Configuration No.", ConfigurationNo);
        if not ProductConfigValue.IsEmpty() then
            // Controlled destructive operation:
            // do not invoke Product Config. Value OnDelete editability guard.
            // Eligibility has already been decided by real ERP materialization links.
            ProductConfigValue.DeleteAll(false);

        if not ProductConfig.Get(ConfigurationNo) then
            exit;

        // Deletion permission is governed by real ERP materialization links,
        // not by potentially stale lifecycle enums.
        // Do not rewrite or validate the business lifecycle Status here.
        // Delete eligibility is governed exclusively by HasMaterializedERPLinks().
        // This also allows cleanup of Verified / stale Projected configurations
        // when no real Item/Variant materialization links exist.
        ProductConfig.Delete(false);
    end;

    local procedure ResolveConfigurationItemNo(ConfigurationNo: Code[20]): Code[20]
    var
        ProductConfig: Record "SI Product Config.";
        ConfigProjection: Record "SI Config. ERP Projection";
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
    begin
        if ConfigProjection.Get(ConfigurationNo) then
            if ConfigProjection."Item No." <> '' then
                exit(ConfigProjection."Item No.");

        if not ProductConfig.Get(ConfigurationNo) then
            exit('');

        BuildPreview(ConfigurationNo, PrevBuffer);

        if PrevBuffer."Existing Item No." <> '' then
            exit(PrevBuffer."Existing Item No.");

        exit('');
    end;



    internal procedure DeleteOrphanedConfiguration(ConfigurationNo: Code[20])
    begin
        if ConfigurationNo = '' then
            exit;

        // This entry point is intentionally non-interactive and is used only
        // after the linked standard Item / Item Variant has already been deleted.
        // If a real ERP materialization still exists, do not touch the configuration.
        if HasMaterializedERPLinks(ConfigurationNo) then
            exit;

        DeleteSingleUnmaterializedConfiguration(ConfigurationNo);
    end;

    procedure BuildPreview(
        ConfigurationNo: Code[20];
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ProjectionValidator: Codeunit "SI ERP Projection Validator";
    begin
        PrevBuffer.Reset();
        PrevBuffer.DeleteAll();

        PrevBuffer.Initialize(ConfigurationNo);
        PrevBuffer.Insert();

        ClearLastError();

        if not TryBuildPreview(PrevBuffer) then begin
            ProjectionValidator.SetFailed(
                PrevBuffer,
                GetLastErrorText());

            PrevBuffer.Modify();
        end;
    end;

    [TryFunction]
    local procedure TryBuildPreview(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ContextResolver: Codeunit "SI ERP Context Resolver";
        IdentityMgt: Codeunit "SI Product Identity Mgt.";
        NamingEngine: Codeunit "SI Naming Engine";
        ProjectionValidator: Codeunit "SI ERP Projection Validator";
    begin
        // Resolve and validate mandatory ERP context before identity/reuse logic.
        ContextResolver.ResolveContext(PrevBuffer);
        ProjectionValidator.ValidateResolvedContextOrError(PrevBuffer);

        IdentityMgt.BuildIdentity(PrevBuffer);
        BuildPresentation(PrevBuffer, NamingEngine);

        // Reuse only an explicit Base Item or a confirmed semantic projection.
        FindExistingProjection(PrevBuffer);
        ResolveItemCode(PrevBuffer);
        ProjectionValidator.ValidatePreview(PrevBuffer);

        PrevBuffer.Modify(false);
    end;

    local procedure BuildPresentation(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        NamingEngine: Codeunit "SI Naming Engine")
    var
        ProductConfig: Record "SI Product Config.";
    begin
        ProductConfig.Get(PrevBuffer."Configuration No.");

        Clear(PrevBuffer."Generated Item Code");
        Clear(PrevBuffer."Generated Item Description");
        Clear(PrevBuffer."Generated Variant Code");
        Clear(PrevBuffer."Generated Variant Description");

        if ProductConfig."Base Item No." = '' then begin
            PrevBuffer."Generated Item Code" :=
                CopyStr(
                    NamingEngine.BuildItemCode(
                        PrevBuffer."Configuration No."),
                    1,
                    MaxStrLen(PrevBuffer."Generated Item Code"));

            PrevBuffer."Generated Item Description" :=
                CopyStr(
                    NamingEngine.BuildItemDescription(
                        PrevBuffer."Configuration No."),
                    1,
                    MaxStrLen(PrevBuffer."Generated Item Description"));

            exit;
        end;

        PrevBuffer."Generated Variant Code" :=
            CopyStr(
                NamingEngine.BuildVariantCode(
                    PrevBuffer."Configuration No."),
                1,
                MaxStrLen(PrevBuffer."Generated Variant Code"));

        PrevBuffer."Generated Variant Description" :=
            CopyStr(
                NamingEngine.BuildVariantDescription(
                    PrevBuffer."Configuration No."),
                1,
                MaxStrLen(PrevBuffer."Generated Variant Description"));
    end;

    local procedure ResolveItemCode(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ItemMaterializer: Codeunit "SI ERP Item Materializer";
    begin
        ItemMaterializer.ResolveItemCode(PrevBuffer);
    end;

    local procedure FindExistingProjection(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ProductConfig: Record "SI Product Config.";
        ItemProjection: Record "SI Item ERP Projection";
        ConfigProjection: Record "SI Config. ERP Projection";
        MatchingConfigProjection: Record "SI Config. ERP Projection";
    begin
        Clear(PrevBuffer."Existing Item Prj. Entry No.");
        Clear(PrevBuffer."Existing Item No.");
        Clear(PrevBuffer."Existing Variant Code");

        ProductConfig.Get(PrevBuffer."Configuration No.");

        // Variant mode: Base Item is an explicit user decision.
        if ProductConfig."Base Item No." <> '' then begin
            PrevBuffer."Existing Item No." := ProductConfig."Base Item No.";
            ResolveBaseItemProjection(PrevBuffer, ItemProjection);
            ResolveExistingVariant(PrevBuffer, MatchingConfigProjection);
            exit;
        end;

        // Item mode: reuse only by full semantic identity.
        ResolveItemProjectionByIdentity(PrevBuffer, ItemProjection);

        // A diagnostic/failed Config Projection must never become an Existing Item.
        // Reuse a configuration link only when it is already Projected and the
        // linked Item Projection confirms the current identity.
        if ConfigProjection.Get(PrevBuffer."Configuration No.") then
            if ConfigProjection.Status = ConfigProjection.Status::Projected then
                ReuseConfirmedConfigProjection(
                    PrevBuffer,
                    ConfigProjection,
                    ItemProjection);

        ResolveExistingVariant(PrevBuffer, MatchingConfigProjection);
    end;

    local procedure ResolveItemProjectionByIdentity(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ItemProjection: Record "SI Item ERP Projection")
    begin
        if (PrevBuffer."Family Code" = '') or
           (PrevBuffer."Item Projection Key Hash" = '')
        then
            exit;

        ItemProjection.Reset();
        ItemProjection.SetRange("Family Code", PrevBuffer."Family Code");
        ItemProjection.SetRange(
            "Item Projection Key Hash",
            PrevBuffer."Item Projection Key Hash");

        if ItemProjection.FindSet() then
            repeat
                if ItemProjection."Item Projection Key" =
                   PrevBuffer."Item Projection Key"
                then begin
                    PrevBuffer."Existing Item Prj. Entry No." :=
                        ItemProjection."Entry No.";
                    PrevBuffer."Existing Item No." :=
                        ItemProjection."Item No.";
                    exit;
                end;
            until ItemProjection.Next() = 0;
    end;

    local procedure ResolveBaseItemProjection(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ItemProjection: Record "SI Item ERP Projection")
    var
        ProjectionCount: Integer;
    begin
        ItemProjection.Reset();
        ItemProjection.SetRange("Item No.", PrevBuffer."Existing Item No.");
        ProjectionCount := ItemProjection.Count();

        if ProjectionCount > 1 then
            Error(
                BaseItemMultipleProjectionsErr,
                PrevBuffer."Existing Item No.",
                ProjectionCount,
                PrevBuffer."Configuration No.");

        if ProjectionCount = 1 then begin
            ItemProjection.FindFirst();
            PrevBuffer."Existing Item Prj. Entry No." :=
                ItemProjection."Entry No.";
        end;
    end;

    local procedure ReuseConfirmedConfigProjection(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        ConfigProjection: Record "SI Config. ERP Projection";
        var ItemProjection: Record "SI Item ERP Projection")
    begin
        if ConfigProjection."Item Projection Entry No." = 0 then
            Error(
                ProjectedConfigMissingItemProjectionErr,
                ConfigProjection."Configuration No.");

        if not ItemProjection.Get(ConfigProjection."Item Projection Entry No.") then
            Error(
                ProjectedConfigItemProjectionNotFoundErr,
                ConfigProjection."Configuration No.",
                ConfigProjection."Item Projection Entry No.");

        if (ItemProjection."Family Code" <> PrevBuffer."Family Code") or
           (ItemProjection."Item Projection Key Hash" <>
            PrevBuffer."Item Projection Key Hash") or
           (ItemProjection."Item Projection Key" <>
            PrevBuffer."Item Projection Key") or
           (ItemProjection."Item No." <> ConfigProjection."Item No.")
        then
            Error(
                ProjectedConfigIdentityMismatchErr,
                ConfigProjection."Configuration No.",
                ItemProjection."Entry No.");

        PrevBuffer."Existing Item Prj. Entry No." :=
            ItemProjection."Entry No.";
        PrevBuffer."Existing Item No." := ItemProjection."Item No.";
        PrevBuffer."Existing Variant Code" :=
            ConfigProjection."Variant Code";
    end;

    local procedure ResolveExistingVariant(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var MatchingConfigProjection: Record "SI Config. ERP Projection")
    begin
        if (PrevBuffer."Existing Item No." = '') or
           (PrevBuffer."Variant Projection Key Hash" = '')
        then
            exit;

        MatchingConfigProjection.Reset();
        MatchingConfigProjection.SetRange(
            "Item No.",
            PrevBuffer."Existing Item No.");
        MatchingConfigProjection.SetRange(
            "Variant Projection Key Hash",
            PrevBuffer."Variant Projection Key Hash");
        MatchingConfigProjection.SetFilter("Variant Code", '<>%1', '');

        if MatchingConfigProjection.FindSet() then
            repeat
                if MatchingConfigProjection."Variant Projection Key" =
                   PrevBuffer."Variant Projection Key"
                then begin
                    PrevBuffer."Existing Variant Code" :=
                        MatchingConfigProjection."Variant Code";
                    exit;
                end;
            until MatchingConfigProjection.Next() = 0;
    end;

    procedure PopulateProjectionFromConfiguration(
        var ConfigProjection: Record "SI Config. ERP Projection")
    var
        ProductConfig: Record "SI Product Config.";
        ItemProjection: Record "SI Item ERP Projection";
        IdentityMgt: Codeunit "SI Product Identity Mgt.";
        ProjectionKey: Text;
        ProjectionKeyHash: Text;
        VariantProjectionKey: Text;
        VariantProjectionKeyHash: Text;
        NamingEngine: Codeunit "SI Naming Engine";
    begin
        ProductConfig.Get(ConfigProjection."Configuration No.");
        ProductConfig.TestField("Family Code");

        ProjectionKey :=
            IdentityMgt.BuildItemKey(
                ProductConfig."No.");

        ProjectionKeyHash :=
            IdentityMgt.BuildItemKeyHash(
                ProjectionKey);

        VariantProjectionKey := IdentityMgt.BuildVariantKey(ProductConfig."No.");
        VariantProjectionKeyHash := IdentityMgt.BuildVariantKeyHash(VariantProjectionKey);

        ConfigProjection."Family Code" :=
            ProductConfig."Family Code";

        ConfigProjection."Item Projection Key" :=
            CopyStr(
                ProjectionKey,
                1,
                MaxStrLen(ConfigProjection."Item Projection Key"));

        ConfigProjection."Item Projection Key Hash" :=
            CopyStr(
                ProjectionKeyHash,
                1,
                MaxStrLen(ConfigProjection."Item Projection Key Hash"));

        ConfigProjection."Variant Projection Key" := CopyStr(VariantProjectionKey, 1, MaxStrLen(ConfigProjection."Variant Projection Key"));
        ConfigProjection."Variant Projection Key Hash" := CopyStr(VariantProjectionKeyHash, 1, MaxStrLen(ConfigProjection."Variant Projection Key Hash"));
        // Variant Code is assigned only during materialization by the hexadecimal autonumber service.
        if ConfigProjection.Status <> ConfigProjection.Status::Projected then
            Clear(ConfigProjection."Generated Variant Code");
        ConfigProjection."Generated Variant Description" := CopyStr(NamingEngine.BuildVariantDescription(ProductConfig."No."), 1, MaxStrLen(ConfigProjection."Generated Variant Description"));

        // Non-projected rows are preview/error diagnostics only. Never keep
        // stale materialization links in them, because they must not influence
        // Existing Item resolution during the next preview.
        if ConfigProjection.Status <> ConfigProjection.Status::Projected then begin
            Clear(ConfigProjection."Item Projection Entry No.");
            Clear(ConfigProjection."Item No.");
            Clear(ConfigProjection."Variant Code");
            Clear(ConfigProjection."Projected At");
            Clear(ConfigProjection."Projected By");
        end;

        if ProductConfig."Base Item No." <> '' then
            ConfigProjection."Item No." := ProductConfig."Base Item No.";

        ItemProjection.SetRange(
            "Family Code",
            ProductConfig."Family Code");

        ItemProjection.SetRange(
            "Item Projection Key Hash",
            ProjectionKeyHash);

        if ItemProjection.FindFirst() then
            if ItemProjection."Item Projection Key" =
               ProjectionKey
            then begin
                ConfigProjection."Item Projection Entry No." :=
                    ItemProjection."Entry No.";

                ConfigProjection."Item No." :=
                    ItemProjection."Item No.";
            end;

        if ConfigProjection.Status <>
           ConfigProjection.Status::Projected
        then
            ConfigProjection.Status :=
                ConfigProjection.Status::None;
    end;


    local procedure PersistFailedProjection(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ConfigProjection: Record "SI Config. ERP Projection";
    begin
        ConfigProjection.Init();
        ConfigProjection."Configuration No." := PrevBuffer."Configuration No.";
        ConfigProjection."Family Code" := PrevBuffer."Family Code";
        ConfigProjection."Item Projection Key" := PrevBuffer."Item Projection Key";
        ConfigProjection."Item Projection Key Hash" := PrevBuffer."Item Projection Key Hash";
        ConfigProjection."Generated Variant Code" := PrevBuffer."Generated Variant Code";
        ConfigProjection."Generated Variant Description" := PrevBuffer."Generated Variant Description";
        ConfigProjection."Item Category Code" := PrevBuffer."Item Category Code";
        ConfigProjection."Item Template Code" := PrevBuffer."Item Template Code";
        ConfigProjection."Base UoM Code" := PrevBuffer."Base UoM Code";
        ConfigProjection."Base UoM Source" := PrevBuffer."Base UoM Source";
        ConfigProjection."Variant Projection Key" := PrevBuffer."Variant Projection Key";
        ConfigProjection."Variant Projection Key Hash" := PrevBuffer."Variant Projection Key Hash";
        ConfigProjection.SetError(PrevBuffer."Validation Message");
        ConfigProjection.Insert(true);
    end;

    local procedure PersistPreparedProjection(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ConfigProjection: Record "SI Config. ERP Projection";
    begin
        ConfigProjection.Init();
        ConfigProjection."Configuration No." := PrevBuffer."Configuration No.";
        ConfigProjection."Family Code" := PrevBuffer."Family Code";
        ConfigProjection."Item Projection Key" :=
            PrevBuffer."Item Projection Key";
        ConfigProjection."Item Projection Key Hash" :=
            PrevBuffer."Item Projection Key Hash";
        ConfigProjection."Item No." := PrevBuffer."Existing Item No.";
        ConfigProjection."Variant Code" :=
            PrevBuffer."Existing Variant Code";
        ConfigProjection."Generated Variant Code" :=
            PrevBuffer."Generated Variant Code";
        ConfigProjection."Generated Variant Description" :=
            PrevBuffer."Generated Variant Description";
        ConfigProjection."Item Category Code" :=
            PrevBuffer."Item Category Code";
        ConfigProjection."Item Template Code" :=
            PrevBuffer."Item Template Code";
        ConfigProjection."Base UoM Code" :=
            PrevBuffer."Base UoM Code";
        ConfigProjection."Base UoM Source" :=
            PrevBuffer."Base UoM Source";
        ConfigProjection."Variant Projection Key" :=
            PrevBuffer."Variant Projection Key";
        ConfigProjection."Variant Projection Key Hash" :=
            PrevBuffer."Variant Projection Key Hash";
        ConfigProjection.Status := ConfigProjection.Status::Ready;
        Clear(ConfigProjection."Last Error");
        ConfigProjection.Insert(true);
    end;

    procedure Materialize(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ProjectionValidator: Codeunit "SI ERP Projection Validator";
        ErrorText: Text;
    begin
        if not ProjectionValidator.ValidatePreview(PrevBuffer) then begin
            PrevBuffer.Modify();
            Error(ProjectionNotReadyErr, PrevBuffer."Validation Message");
        end;

        ClearLastError();

        if not TryMaterialize(PrevBuffer) then begin
            ErrorText := GetLastErrorText();
            ProjectionValidator.SetFailed(PrevBuffer, ErrorText);
            PrevBuffer.Modify();
            SaveMaterializationError(PrevBuffer."Configuration No.", ErrorText);
            Error(MaterializationFailedErr, ErrorText);
        end;

        PrevBuffer.SetValidationResult(
            PrevBuffer.Status::Projected,
            false,
            MaterializationCompletedMsg);
        PrevBuffer.Modify();
    end;

    [TryFunction]
    local procedure TryMaterialize(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemProjection: Record "SI Item ERP Projection";
        ItemMaterializer: Codeunit "SI ERP Item Materializer";
        VariantMaterializer: Codeunit "SI ERP Variant Materializer";
    begin
        ItemMaterializer.FindOrCreate(PrevBuffer, Item);
        FindOrCreateItemProjection(PrevBuffer, Item, ItemProjection);

        CheckVariantCollision(
            PrevBuffer,
            Item."No.");

        VariantMaterializer.FindOrCreate(
            Item."No.",
            PrevBuffer,
            ItemVariant);

        PersistConfigProjection(
            PrevBuffer,
            ItemProjection,
            Item,
            ItemVariant);

        MarkConfigurationProjected(
            PrevBuffer."Configuration No.");

        PrevBuffer."Existing Item Prj. Entry No." :=
            ItemProjection."Entry No.";
        PrevBuffer."Existing Item No." := Item."No.";

        if ItemVariant.Code <> '' then
            PrevBuffer."Existing Variant Code" :=
                ItemVariant.Code
        else
            Clear(PrevBuffer."Existing Variant Code");
    end;

    local procedure FindOrCreateItemProjection(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        Item: Record Item;
        var ItemProjection: Record "SI Item ERP Projection")
    begin
        if TryReuseBaseItemProjection(PrevBuffer, Item, ItemProjection) then
            exit;

        if PrevBuffer."Existing Item Prj. Entry No." <> 0 then begin
            ItemProjection.Get(
                PrevBuffer."Existing Item Prj. Entry No.");

            if ItemProjection."Item No." <> Item."No." then
                Error(
                    ProjectionItemMismatchErr,
                    ItemProjection."Entry No.",
                    ItemProjection."Item No.",
                    Item."No.");
            exit;
        end;

        ItemProjection.SetRange(
            "Family Code",
            PrevBuffer."Family Code");
        ItemProjection.SetRange(
            "Item Projection Key Hash",
            PrevBuffer."Item Projection Key Hash");

        if ItemProjection.FindFirst() then begin
            if ItemProjection."Item Projection Key" <>
               PrevBuffer."Item Projection Key"
            then
                Error(
                    ProjectionHashCollisionErr,
                    PrevBuffer."Family Code",
                    PrevBuffer."Item Projection Key Hash");

            if ItemProjection."Item No." <> Item."No." then
                Error(
                    ProjectionItemMismatchErr,
                    ItemProjection."Entry No.",
                    ItemProjection."Item No.",
                    Item."No.");
            exit;
        end;

        ValidateItemSemanticOwnership(Item."No.", PrevBuffer);

        ItemProjection.Init();
        ItemProjection."Family Code" := PrevBuffer."Family Code";
        ItemProjection."Item Projection Key" :=
            PrevBuffer."Item Projection Key";
        ItemProjection."Item Projection Key Hash" :=
            PrevBuffer."Item Projection Key Hash";
        ItemProjection.Validate("Item No.", Item."No.");
        ItemProjection."Item Category Code" :=
            PrevBuffer."Item Category Code";
        ItemProjection."Item Template Code" :=
            PrevBuffer."Item Template Code";
        ItemProjection."Generated Item Code" :=
            PrevBuffer."Generated Item Code";
        ItemProjection."Generated Item Description" :=
            PrevBuffer."Generated Item Description";
        ItemProjection."Base UoM Code" :=
            PrevBuffer."Base UoM Code";
        ItemProjection."Base UoM Source" :=
            PrevBuffer."Base UoM Source";
        ItemProjection."Projected At" := CurrentDateTime();
        ItemProjection."Projected By" :=
            CopyStr(
                UserId(),
                1,
                MaxStrLen(ItemProjection."Projected By"));
        ItemProjection.Insert(true);
    end;


    local procedure TryReuseBaseItemProjection(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        Item: Record Item;
        var ItemProjection: Record "SI Item ERP Projection"): Boolean
    var
        ProductConfig: Record "SI Product Config.";
        ProjectionCount: Integer;
    begin
        ProductConfig.Get(PrevBuffer."Configuration No.");
        if ProductConfig."Base Item No." = '' then
            exit(false);

        if ProductConfig."Base Item No." <> Item."No." then
            Error(
                BaseItemMismatchErr,
                ProductConfig."Base Item No.",
                Item."No.",
                PrevBuffer."Configuration No.");

        ItemProjection.Reset();
        ItemProjection.SetRange("Item No.", Item."No.");
        ProjectionCount := ItemProjection.Count();

        if ProjectionCount > 1 then
            Error(
                BaseItemMultipleProjectionsErr,
                Item."No.",
                ProjectionCount,
                PrevBuffer."Configuration No.");

        if ProjectionCount = 1 then begin
            ItemProjection.FindFirst();
            exit(true);
        end;

        exit(false);
    end;

    local procedure ValidateItemSemanticOwnership(
        ItemNo: Code[20];
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ExistingProjection: Record "SI Item ERP Projection";
        ProductConfig: Record "SI Product Config.";
    begin
        ProductConfig.Get(PrevBuffer."Configuration No.");
        if ProductConfig."Base Item No." = ItemNo then
            exit;

        ExistingProjection.SetRange("Item No.", ItemNo);
        if ExistingProjection.FindSet() then
            repeat
                if (ExistingProjection."Family Code" <> PrevBuffer."Family Code") or
                   (ExistingProjection."Item Projection Key Hash" <> PrevBuffer."Item Projection Key Hash") or
                   (ExistingProjection."Item Projection Key" <> PrevBuffer."Item Projection Key")
                then
                    Error(
                        ItemSemanticOwnershipConflictErr,
                        ItemNo,
                        ExistingProjection."Entry No.",
                        PrevBuffer."Configuration No.");
            until ExistingProjection.Next() = 0;
    end;

    local procedure PersistConfigProjection(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        ItemProjection: Record "SI Item ERP Projection";
        Item: Record Item;
        ItemVariant: Record "Item Variant")
    var
        ConfigProjection: Record "SI Config. ERP Projection";
        IsNew: Boolean;
    begin
        IsNew := not ConfigProjection.Get(
            PrevBuffer."Configuration No.");

        if IsNew then begin
            ConfigProjection.Init();
            ConfigProjection."Configuration No." :=
                PrevBuffer."Configuration No.";
        end;

        ConfigProjection."Family Code" :=
            PrevBuffer."Family Code";
        ConfigProjection."Item Projection Key" :=
            PrevBuffer."Item Projection Key";
        ConfigProjection."Item Projection Key Hash" :=
            PrevBuffer."Item Projection Key Hash";
        ConfigProjection."Item Projection Entry No." :=
            ItemProjection."Entry No.";
        ConfigProjection."Item No." := Item."No.";
        ConfigProjection."Variant Code" := ItemVariant.Code;
        ConfigProjection."Generated Variant Code" :=
            ItemVariant.Code;
        ConfigProjection."Generated Variant Description" :=
            PrevBuffer."Generated Variant Description";
        ConfigProjection."Item Category Code" :=
            PrevBuffer."Item Category Code";
        ConfigProjection."Item Template Code" :=
            PrevBuffer."Item Template Code";
        ConfigProjection."Base UoM Code" :=
            PrevBuffer."Base UoM Code";
        ConfigProjection."Base UoM Source" :=
            PrevBuffer."Base UoM Source";
        ConfigProjection."Variant Projection Key" :=
            PrevBuffer."Variant Projection Key";
        ConfigProjection."Variant Projection Key Hash" :=
            PrevBuffer."Variant Projection Key Hash";
        ConfigProjection.SetLinked(
            ItemProjection."Entry No.");

        if IsNew then
            ConfigProjection.Insert(true)
        else
            ConfigProjection.Modify(true);
    end;

    local procedure CheckVariantCollision(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        ItemNo: Code[20])
    var
        ConfigProjection: Record "SI Config. ERP Projection";
    begin
        if PrevBuffer."Variant Projection Key" = '' then
            exit;

        ConfigProjection.SetRange("Item No.", ItemNo);
        ConfigProjection.SetRange(
            "Variant Projection Key Hash",
            PrevBuffer."Variant Projection Key Hash");
        ConfigProjection.SetFilter(
            "Configuration No.",
            '<>%1',
            PrevBuffer."Configuration No.");

        if ConfigProjection.FindSet() then
            repeat
                if ConfigProjection."Variant Projection Key" <>
                   PrevBuffer."Variant Projection Key"
                then
                    Error(
                        VariantIdentityCollisionErr,
                        ItemNo,
                        PrevBuffer."Variant Projection Key Hash",
                        ConfigProjection."Configuration No.");
            until ConfigProjection.Next() = 0;
    end;

    local procedure MarkConfigurationProjected(
        ConfigurationNo: Code[20])
    var
        ProductConfig: Record "SI Product Config.";
    begin
        ProductConfig.Get(ConfigurationNo);
        ProductConfig.SetProjected();
        ProductConfig.Modify(true);
    end;

    local procedure SaveMaterializationError(
        ConfigurationNo: Code[20];
        ErrorText: Text)
    var
        ConfigProjection: Record "SI Config. ERP Projection";
    begin
        if ConfigProjection.Get(ConfigurationNo) then begin
            ConfigProjection.SetError(ErrorText);
            ConfigProjection.Modify(true);
            exit;
        end;

        ConfigProjection.Init();
        ConfigProjection."Configuration No." := ConfigurationNo;
        ConfigProjection.Validate("Configuration No.");
        ConfigProjection.SetError(ErrorText);
        ConfigProjection.Insert(true);
    end;

    procedure ValidateItemForFamily(
        FamilyCode: Code[30];
        ItemNo: Code[20])
    var
        ProductFamily: Record "SI Product Family";
        Item: Record Item;
    begin
        if ItemNo = '' then
            exit;

        ProductFamily.Get(FamilyCode);
        ProductFamily.TestField("Item Category Code");

        Item.Get(ItemNo);

        if Item."Item Category Code" <>
           ProductFamily."Item Category Code"
        then
            Error(
                ItemCategoryMismatchErr,
                Item."No.",
                Item."Item Category Code",
                ProductFamily.Code,
                ProductFamily."Item Category Code");
    end;

    var
        ProjectionAlreadyExistsErr: Label
            'Для конфігурації %1 ERP-проєкцію вже створено. Спочатку видаліть наявну нематеріалізовану проєкцію або виконайте її матеріалізацію.';

        ProjectionCreationFailedErr: Label
            'ERP-проєкцію не створено: %1';

        ProjectionCreatedMsg: Label
            'ERP-проєкцію конфігурації %1 створено.';

        ProjectionNotFoundErr: Label
            'Для конфігурації %1 ERP-проєкцію не знайдено.';

        ItemSemanticOwnershipConflictErr: Label
            'Критичне порушення цілісності: товар %1 уже належить іншій семантичній ERP-проєкції %2. Конфігурацію %3 не матеріалізовано.';

        BaseItemMismatchErr: Label
            'Базовий товар %1 не відповідає товару %2, визначеному ERP-проєкцією конфігурації %3.';

        BaseItemMultipleProjectionsErr: Label
            'Критичне порушення цілісності: для базового товару %1 знайдено %2 ERP-проєкції. Конфігурацію %3 не матеріалізовано.';

        ProjectedConfigMissingItemProjectionErr: Label
            'Матеріалізована ERP-проєкція конфігурації %1 не містить посилання на ERP-проєкцію товару.';

        ProjectedConfigItemProjectionNotFoundErr: Label
            'Матеріалізована ERP-проєкція конфігурації %1 посилається на відсутній запис ERP-проєкції товару %2.';

        ProjectedConfigIdentityMismatchErr: Label
            'Матеріалізована ERP-проєкція конфігурації %1 не відповідає поточній семантичній ідентичності. Пов’язаний запис товару: %2.';

        LastError: Text[250];

        MaterializationCompletedMsg: Label
            'ERP-проєкцію матеріалізовано успішно.';

        ProjectionNotReadyErr: Label
            'ERP-проєкція не готова до матеріалізації: %1';

        MaterializationFailedErr: Label
            'Не вдалося матеріалізувати ERP-проєкцію: %1';

        ProjectionItemMismatchErr: Label
            'ERP-проєкція товару %1 пов’язана з товаром %2, але поточна матеріалізація визначила товар %3.';

        ProjectionHashCollisionErr: Label
            'Виявлено колізію ключа ERP-проєкції для сімейства %1 та hash %2.';

        VariantIdentityCollisionErr: Label
            'Для товару %1 виявлено колізію hash ключа варіанта %2 з ERP-проєкцією конфігурації %3.';

        ItemCategoryMismatchErr: Label
            'Товар %1 належить до категорії %2, але сімейство %3 пов’язане з категорією %4.';

        MaterializedProjectionDeleteErr: Label
            'ERP-проєкція конфігурації %1 уже матеріалізована і не може бути видалена.';

        DeletePreviewOnlyProjectionQst: Label
            'Видалити нематеріалізований стан ERP-проєкції конфігурації %1?';

        DeletePreviewOnlyProjectionMsg: Label
            'Нематеріалізований стан ERP-проєкції конфігурації %1 видалено.';

        SyncNameNotMaterializedErr: Label
            'Конфігурація %1 не має фактичного матеріалізованого зв’язку з ERP. Синхронізація назви недоступна.';

        SyncNameEmptyErr: Label
            'Пов’язаний ERP-об’єкт для конфігурації %1 не має назви. Синхронізацію не виконано.';

        MaterializedStatusTxt: Label 'Матеріалізовано';
        ReadyForMaterializationStatusTxt: Label 'Готово до матеріалізації';
        ProjectionErrorStatusTxt: Label 'Помилка';

        DeleteReadyProjectionQst: Label
            'Ця ERP-проєкція коректна і готова до матеріалізації. Ви дійсно бажаєте видалити конфігурацію «%1» та її нематеріалізовану ERP-проєкцію?';

        DeleteInvalidProjectionQst: Label
            'Видалити конфігурацію «%1» та її нематеріалізовану ERP-проєкцію?';

        DeleteItemBranchQst: Label
            'Конфігурація товару «%1» має дочірні конфігурації варіантів (%2). Операція видалить усю нематеріалізовану гілку: конфігурацію товару та всі її дочірні варіанти. Продовжити?';

        MaterializedChildVariantDeleteErr: Label
            'Гілку не можна видалити, оскільки дочірня конфігурація варіанта «%1» уже матеріалізована.';

        DeleteSingleCompletedMsg: Label
            'Конфігурацію «%1» та її нематеріалізовану ERP-проєкцію видалено.';

        DeleteBranchCompletedMsg: Label
            'Гілку «%1» видалено. Видалено дочірніх конфігурацій варіантів: %2.';
}
