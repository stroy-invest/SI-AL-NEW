codeunit 53012 "SI ERP Item Materializer"
{
    Permissions =
        tabledata Item = RIM,
        tabledata "Item Templ." = R;

    procedure ResolveItemCode(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        Item: Record Item;
        ItemProjection: Record "SI Item ERP Projection";
        CandidateCode: Code[20];
    begin
        if PrevBuffer."Existing Item No." <> '' then begin
            ValidateExistingResolutionSource(PrevBuffer);
            ValidateExistingItemOwnership(PrevBuffer."Existing Item No.", PrevBuffer);
            exit;
        end;

        PrevBuffer.TestField("Generated Item Code");
        CandidateCode := CopyStr(PrevBuffer."Generated Item Code", 1, MaxStrLen(CandidateCode));

        if not Item.Get(CandidateCode) then
            exit;

        if FindMatchingProjection(CandidateCode, PrevBuffer, ItemProjection) then begin
            PrevBuffer."Existing Item Prj. Entry No." := ItemProjection."Entry No.";
            PrevBuffer."Existing Item No." := CandidateCode;
            exit;
        end;

        CandidateCode := BuildCollisionSafeCode(PrevBuffer);

        if Item.Get(CandidateCode) then begin
            if FindMatchingProjection(CandidateCode, PrevBuffer, ItemProjection) then begin
                PrevBuffer."Existing Item Prj. Entry No." := ItemProjection."Entry No.";
                PrevBuffer."Existing Item No." := CandidateCode;
                PrevBuffer."Generated Item Code" := CandidateCode;
                exit;
            end;

            Error(
                DeterministicCodeCollisionErr,
                CandidateCode,
                PrevBuffer."Configuration No.",
                PrevBuffer."Item Projection Key Hash");
        end;

        PrevBuffer."Generated Item Code" := CandidateCode;
    end;

    procedure FindOrCreate(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var Item: Record Item): Boolean
    begin
        ResolveItemCode(PrevBuffer);

        if PrevBuffer."Existing Item No." <> '' then begin
            ValidateExistingResolutionSource(PrevBuffer);
            Item.Get(PrevBuffer."Existing Item No.");
            ValidateExistingItem(Item, PrevBuffer);
            ValidateExistingItemOwnership(Item."No.", PrevBuffer);
            exit(false);
        end;

        PrevBuffer.TestField("Generated Item Code");

        if Item.Get(CopyStr(PrevBuffer."Generated Item Code", 1, MaxStrLen(Item."No."))) then begin
            if not IsItemOwnedByProjection(Item."No.", PrevBuffer) then
                Error(
                    ItemCodeOwnedByOtherIdentityErr,
                    Item."No.",
                    PrevBuffer."Configuration No.");

            ValidateExistingItem(Item, PrevBuffer);
            exit(false);
        end;

        CreateItem(Item, PrevBuffer);
        exit(true);
    end;

    local procedure ValidateExistingResolutionSource(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    begin
        if IsExplicitBaseItemMode(
            PrevBuffer,
            PrevBuffer."Existing Item No.")
        then
            exit;

        if PrevBuffer."Existing Item Prj. Entry No." <> 0 then
            exit;

        Error(
            UnconfirmedExistingItemErr,
            PrevBuffer."Existing Item No.",
            PrevBuffer."Configuration No.");
    end;

    local procedure BuildCollisionSafeCode(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary): Code[20]
    var
        BaseCode: Text;
        HashPart: Text;
        Candidate: Text;
        MaxCodeLength: Integer;
        HashLength: Integer;
        PrefixLength: Integer;
    begin
        PrevBuffer.TestField("Item Projection Key Hash");

        MaxCodeLength := 20;
        HashLength := 12;
        PrefixLength := MaxCodeLength - HashLength - 1;

        BaseCode := DelChr(UpperCase(PrevBuffer."Generated Item Code"), '=', ' ');
        if BaseCode = '' then
            BaseCode := DelChr(UpperCase(PrevBuffer."Family Code"), '=', ' ');

        HashPart := CopyStr(UpperCase(PrevBuffer."Item Projection Key Hash"), 1, HashLength);
        Candidate := CopyStr(BaseCode, 1, PrefixLength) + '-' + HashPart;

        exit(CopyStr(Candidate, 1, MaxCodeLength));
    end;

    local procedure FindMatchingProjection(
        ItemNo: Code[20];
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ItemProjection: Record "SI Item ERP Projection"): Boolean
    begin
        ItemProjection.Reset();
        ItemProjection.SetRange("Item No.", ItemNo);
        ItemProjection.SetRange("Family Code", PrevBuffer."Family Code");
        ItemProjection.SetRange("Item Projection Key Hash", PrevBuffer."Item Projection Key Hash");

        if ItemProjection.FindSet() then
            repeat
                if ItemProjection."Item Projection Key" = PrevBuffer."Item Projection Key" then
                    exit(true);
            until ItemProjection.Next() = 0;

        exit(false);
    end;

    local procedure IsItemOwnedByProjection(
        ItemNo: Code[20];
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary): Boolean
    var
        ItemProjection: Record "SI Item ERP Projection";
    begin
        exit(FindMatchingProjection(ItemNo, PrevBuffer, ItemProjection));
    end;

    local procedure ValidateExistingItemOwnership(
        ItemNo: Code[20];
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ItemProjection: Record "SI Item ERP Projection";
        MatchingProjectionFound: Boolean;
    begin
        if IsExplicitBaseItemMode(PrevBuffer, ItemNo) then
            exit;

        ItemProjection.SetRange("Item No.", ItemNo);
        if ItemProjection.FindSet() then
            repeat
                if (ItemProjection."Family Code" = PrevBuffer."Family Code") and
                   (ItemProjection."Item Projection Key Hash" = PrevBuffer."Item Projection Key Hash") and
                   (ItemProjection."Item Projection Key" = PrevBuffer."Item Projection Key")
                then
                    MatchingProjectionFound := true
                else
                    Error(
                        ItemHasMultipleSemanticIdentitiesErr,
                        ItemNo,
                        ItemProjection."Entry No.",
                        PrevBuffer."Configuration No.");
            until ItemProjection.Next() = 0;

        if (PrevBuffer."Existing Item Prj. Entry No." <> 0) and not MatchingProjectionFound then
            Error(
                ExistingProjectionIdentityMismatchErr,
                PrevBuffer."Existing Item Prj. Entry No.",
                ItemNo,
                PrevBuffer."Configuration No.");
    end;


    local procedure IsExplicitBaseItemMode(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        ItemNo: Code[20]): Boolean
    var
        ProductConfig: Record "SI Product Config.";
    begin
        if not ProductConfig.Get(PrevBuffer."Configuration No.") then
            exit(false);

        exit(
            (ProductConfig."Base Item No." <> '') and
            (ProductConfig."Base Item No." = ItemNo));
    end;

    local procedure CreateItem(
        var Item: Record Item;
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    begin
        PrevBuffer.TestField("Generated Item Code");
        PrevBuffer.TestField("Generated Item Description");
        PrevBuffer.TestField("Item Category Code");
        PrevBuffer.TestField("Item Template Code");
        PrevBuffer.TestField("Base UoM Code");

        Item.Init();
        Item.Validate("No.", CopyStr(PrevBuffer."Generated Item Code", 1, MaxStrLen(Item."No.")));
        Item.Insert(true);

        // Спочатку застосовуємо стандартний Item Template. Він задає ERP-профіль:
        // posting groups, costing, replenishment, planning та інші стандартні поля.
        ApplyResolvedItemTemplate(Item, PrevBuffer);

        // Після шаблону накладаємо значення, за які відповідає ERP Projection.
        Item.Validate(
            Description,
            CopyStr(
                PrevBuffer."Generated Item Description",
                1,
                MaxStrLen(Item.Description)));

        Item.Validate(
            "Search Description",
            CopyStr(
                UpperCase(PrevBuffer."Generated Item Description"),
                1,
                MaxStrLen(Item."Search Description")));

        Item.Validate(
            "Item Category Code",
            PrevBuffer."Item Category Code");

        Item.Validate(
            "Base Unit of Measure",
            PrevBuffer."Base UoM Code");

        Item.Blocked := false;
        Item.Modify(true);
    end;

    local procedure ApplyResolvedItemTemplate(
        var Item: Record Item;
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        if not ItemTempl.Get(PrevBuffer."Item Template Code") then
            Error(
                ItemTemplateNotFoundErr,
                PrevBuffer."Item Template Code",
                PrevBuffer."Family Code");

        ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl, true);

        // ApplyItemTemplate модифікує запис; перечитуємо його перед projection overrides.
        Item.Get(Item."No.");
    end;

    local procedure ValidateExistingItem(
        Item: Record Item;
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    begin
        if Item.Blocked then
            Error(ItemBlockedErr, Item."No.");

        if Item."Item Category Code" <> PrevBuffer."Item Category Code" then
            Error(
                ItemCategoryMismatchErr,
                Item."No.",
                Item."Item Category Code",
                PrevBuffer."Item Category Code");
    end;

    var
        UnconfirmedExistingItemErr: Label
            'Товар %1 не має підтвердженого джерела повторного використання для конфігурації %2. Збіг технічного коду не є ERP-ідентичністю.';

        ItemTemplateNotFoundErr: Label
            'Шаблон товару %1, визначений для сімейства %2, не знайдено. Товар не створено.';

        ItemBlockedErr: Label
            'Товар %1 заблокований і не може використовуватися для ERP-проєкції.';

        ItemCategoryMismatchErr: Label
            'Товар %1 належить до категорії %2, але ERP-проєкція вимагає категорію %3.';

        ItemCodeOwnedByOtherIdentityErr: Label
            'Код товару %1 уже використовується іншою семантичною ERP-ідентичністю. Конфігурацію %2 не матеріалізовано.';

        DeterministicCodeCollisionErr: Label
            'Не вдалося безпечно сформувати унікальний код товару %1 для конфігурації %2. Hash ключа: %3.';

        ItemHasMultipleSemanticIdentitiesErr: Label
            'Критичне порушення цілісності: товар %1 уже пов’язаний з іншою ERP-ідентичністю через запис проєкції %2. Конфігурацію %3 не можна матеріалізувати до виправлення зв’язків.';

        ExistingProjectionIdentityMismatchErr: Label
            'Запис ERP-проєкції %1 для товару %2 не відповідає семантичній ідентичності конфігурації %3.';
}
