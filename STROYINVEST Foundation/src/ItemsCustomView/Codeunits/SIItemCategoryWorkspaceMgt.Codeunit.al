codeunit 50184 "SI Item Cat. Workspace Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateCategoryFromContext(ContextCategoryCode: Code[20]; var NewCategoryCode: Code[20]): Boolean
    var
        ContextCategory: Record "Item Category";
        ParentCategory: Record "Item Category";
        NewItemCategory: Record "Item Category";
        NewCategoryDialog: Page "SI New Item Category";
        Choice: Integer;
        OptionText: Text;
        PromptText: Text;
        ParentCategoryCode: Code[20];
        InheritedBaseUoMCode: Code[10];
    begin
        Clear(NewCategoryCode);

        if not ContextCategory.Get(ContextCategoryCode) then
            exit(false);

        OptionText := StrSubstNo(
            'Поруч із "%1",Всередині "%1"',
            GetCategoryDisplayName(ContextCategory));
        PromptText := 'Де створити нову категорію?';

        Choice := StrMenu(OptionText, 2, PromptText);
        if Choice = 0 then
            exit(false);

        case Choice of
            1:
                ParentCategoryCode := ContextCategory."Parent Category";
            2:
                ParentCategoryCode := ContextCategory.Code;
        end;

        InheritedBaseUoMCode := GetInheritedBaseUoMCode(ParentCategory, ParentCategoryCode);

        NewCategoryDialog.InitializeContext(ParentCategoryCode, InheritedBaseUoMCode);
        if NewCategoryDialog.RunModal() <> Action::OK then
            exit(false);

        if not NewCategoryDialog.CategoryWasCreated() then
            exit(false);

        NewCategoryCode := NewCategoryDialog.GetCategoryCode();
        if not NewItemCategory.Get(NewCategoryCode) then begin
            Clear(NewCategoryCode);
            exit(false);
        end;

        // The dedicated create dialog has already inserted the category and saved
        // any local attributes. Close that write transaction before opening the
        // standard Item Category Card for the newly created physical record.
        Commit();

        Page.RunModal(Page::"Item Category Card", NewItemCategory);

        // The user may explicitly delete the new category from the standard card.
        if not NewItemCategory.Get(NewCategoryCode) then begin
            Clear(NewCategoryCode);
            exit(false);
        end;

        exit(true);
    end;

    procedure DeleteCategoryFromContext(ContextCategoryCode: Code[20]; var ParentCategoryCode: Code[20]): Boolean
    var
        ItemCategory: Record "Item Category";
        ChildCategory: Record "Item Category";
        Item: Record Item;
        HasSIDependencies: Boolean;
        SIDependencyDescription: Text;
    begin
        Clear(ParentCategoryCode);

        if not ItemCategory.Get(ContextCategoryCode) then
            exit(false);

        ChildCategory.SetRange("Parent Category", ItemCategory.Code);
        if not ChildCategory.IsEmpty() then
            Error(CategoryHasChildrenErr, GetCategoryDisplayName(ItemCategory));

        Item.SetRange("Item Category Code", ItemCategory.Code);
        if not Item.IsEmpty() then
            Error(CategoryHasItemsErr, GetCategoryDisplayName(ItemCategory));

        OnCheckCategoryDeleteDependencies(ItemCategory.Code, HasSIDependencies, SIDependencyDescription);
        if HasSIDependencies then begin
            if SIDependencyDescription = '' then
                SIDependencyDescription := UnspecifiedSIDependencyTxt;
            Error(CategoryHasSIDependenciesErr, GetCategoryDisplayName(ItemCategory), SIDependencyDescription);
        end;

        if not Confirm(DeleteCategoryQst, false, GetCategoryDisplayName(ItemCategory)) then
            exit(false);

        ParentCategoryCode := ItemCategory."Parent Category";
        ItemCategory.Delete(true);

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCategoryDeleteDependencies(ItemCategoryCode: Code[20]; var HasDependencies: Boolean; var DependencyDescription: Text)
    begin
    end;

    local procedure GetInheritedBaseUoMCode(var ParentCategory: Record "Item Category"; ParentCategoryCode: Code[20]): Code[10]
    begin
        if ParentCategoryCode = '' then
            exit('');

        if not ParentCategory.Get(ParentCategoryCode) then
            Error(ParentCategoryNotFoundErr, ParentCategoryCode);

        exit(ParentCategory."SI Default Base UoM Code");
    end;

    local procedure GetCategoryDisplayName(ItemCategory: Record "Item Category"): Text
    begin
        if ItemCategory.Description <> '' then
            exit(ItemCategory.Description);

        exit(ItemCategory.Code);
    end;

    var
        ParentCategoryNotFoundErr: Label 'Батьківську категорію %1 не знайдено.';
        CategoryHasChildrenErr: Label 'Неможливо видалити категорію «%1», оскільки вона містить дочірні категорії.';
        CategoryHasItemsErr: Label 'Неможливо видалити категорію «%1», оскільки до неї віднесено товари.';
        CategoryHasSIDependenciesErr: Label 'Неможливо видалити категорію «%1», оскільки вона використовується в SI-рішеннях: %2.';
        DeleteCategoryQst: Label 'Видалити категорію «%1»?\Цю дію неможливо скасувати.';
        UnspecifiedSIDependencyTxt: Label 'існують активні залежності';
}
