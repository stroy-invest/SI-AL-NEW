codeunit 50197 "SI Category Selector Mgt."
{
    procedure SelectCategory(var CategoryCode: Code[20]): Boolean
    var
        CategorySelector: Page "SI Category Selector";
    begin
        CategorySelector.SetInitialSelection(CategoryCode);
        CategorySelector.RunModal();
        exit(CategorySelector.TryGetSelection(CategoryCode));
    end;

    procedure GetCategoryDisplayName(CategoryCode: Code[20]): Text
    var
        ItemCategory: Record "Item Category";
    begin
        if (CategoryCode = '') or (not ItemCategory.Get(CategoryCode)) then
            exit('');
        if ItemCategory.Description <> '' then
            exit(ItemCategory.Description);
        exit(ItemCategory.Code);
    end;

    procedure GetCategoryTreeJson(): Text
    var
        ItemCategory: Record "Item Category";
    begin
        ItemCategory.SetRange("Parent Category", '');
        exit(BuildCategoryJson(ItemCategory));
    end;

    local procedure BuildCategoryJson(var ItemCategory: Record "Item Category"): Text
    var
        JsonText: Text;
        IsFirst: Boolean;
    begin
        JsonText := '[';
        IsFirst := true;
        if ItemCategory.FindSet() then
            repeat
                if not IsFirst then
                    JsonText += ',';
                JsonText += BuildCategoryNodeJson(ItemCategory);
                IsFirst := false;
            until ItemCategory.Next() = 0;
        JsonText += ']';
        exit(JsonText);
    end;

    local procedure BuildCategoryNodeJson(ItemCategory: Record "Item Category"): Text
    var
        ChildCategory: Record "Item Category";
        NodeName: Text;
    begin
        NodeName := ItemCategory.Description;
        if NodeName = '' then
            NodeName := ItemCategory.Code;
        ChildCategory.SetRange("Parent Category", ItemCategory.Code);
        exit('{"code":"' + JsonEscape(ItemCategory.Code) + '","name":"' + JsonEscape(NodeName) + '","parentCode":"' + JsonEscape(ItemCategory."Parent Category") + '","baseUomCode":"' + JsonEscape(ItemCategory."SI Default Base UoM Code") + '","categoryKind":"' + JsonEscape(Format(ItemCategory."SI Category Kind")) + '","finishedProductType":"' + JsonEscape(Format(ItemCategory."SI Finished Type")) + '","children":' + BuildCategoryJson(ChildCategory) + '}');
    end;

    local procedure JsonEscape(Value: Text): Text
    begin
        Value := Value.Replace('\\', '\\\\');
        Value := Value.Replace('"', '\\"');
        Value := Value.Replace('/', '\\/');
        Value := Value.Replace('<', '\\u003C');
        Value := Value.Replace('>', '\\u003E');
        Value := Value.Replace('&', '\\u0026');
        exit(Value);
    end;
}
