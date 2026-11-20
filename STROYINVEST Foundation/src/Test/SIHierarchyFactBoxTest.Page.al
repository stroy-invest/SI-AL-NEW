page 50294 "SI Hierarchy FactBox Test"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Тест дерева з FactBox';
    Editable = false;

    layout
    {
        area(Content)
        {
            usercontrol(Hierarchy; "SI Adaptive Item Hierarchy")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    CurrPage.Hierarchy.RenderTree(GetCategoryTreeJson());
                    CurrPage.Hierarchy.RenderProducts(GetProductTreeJson(SelectedGroupCode));
                end;

                trigger NodeSelected(GroupCode: Text)
                begin
                    SelectedGroupCode := CopyStr(GroupCode, 1, MaxStrLen(SelectedGroupCode));
                    CurrPage.Hierarchy.RenderProducts(GetProductTreeJson(SelectedGroupCode));
                    RefreshCategoryContext();
                    // Deliberately no CurrPage.Update(false).
                end;
            }
        }
        /*
        area(FactBoxes)
        {
            part(CategoryAttributes; "SI Category Attributes FactBox")
            {
                ApplicationArea = All;
                Caption = 'Атрибути категорії';
                Visible = CategoryAttributesVisible;
            }
        }*/
    }

    var
        SelectedGroupCode: Code[20];
        CategoryAttributesVisible: Boolean;

    local procedure RefreshCategoryContext()
    begin
        CategoryAttributesVisible := HasEffectiveCategoryAttributes(SelectedGroupCode);
        /*
        if CategoryAttributesVisible then
            CurrPage.CategoryAttributes.Page.LoadAttributes(SelectedGroupCode)
        else
            CurrPage.CategoryAttributes.Page.ClearAttributes();
            */
    end;

    local procedure HasEffectiveCategoryAttributes(ItemCategoryCode: Code[20]): Boolean
    var
        ItemCategory: Record "Item Category";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        CurrentCategoryCode: Code[20];
        SafetyCounter: Integer;
    begin
        CurrentCategoryCode := ItemCategoryCode;

        while CurrentCategoryCode <> '' do begin
            ItemAttributeValueMapping.Reset();
            ItemAttributeValueMapping.SetRange("Table ID", Database::"Item Category");
            ItemAttributeValueMapping.SetRange("No.", CurrentCategoryCode);
            if not ItemAttributeValueMapping.IsEmpty() then
                exit(true);

            if not ItemCategory.Get(CurrentCategoryCode) then
                exit(false);

            CurrentCategoryCode := ItemCategory."Parent Category";
            SafetyCounter += 1;
            if SafetyCounter > 100 then
                exit(false);
        end;

        exit(false);
    end;

    local procedure GetProductTreeJson(ItemCategoryCode: Code[20]): Text
    var
        Item: Record Item;
        JsonText: Text;
        IsFirstItem: Boolean;
    begin
        if ItemCategoryCode = '' then
            exit('[]');

        Item.SetRange("Item Category Code", ItemCategoryCode);
        Item.SetCurrentKey("Item Category Code", "No.");

        JsonText := '[';
        IsFirstItem := true;
        if Item.FindSet() then
            repeat
                if not IsFirstItem then
                    JsonText += ',';

                JsonText += BuildProductNodeJson(Item);
                IsFirstItem := false;
            until Item.Next() = 0;
        JsonText += ']';

        exit(JsonText);
    end;

    local procedure BuildProductNodeJson(Item: Record Item): Text
    var
        ItemVariant: Record "Item Variant";
        ItemName: Text;
        VariantsJson: Text;
        IsFirstVariant: Boolean;
    begin
        ItemName := Item.Description;
        if ItemName = '' then
            ItemName := Item."No.";

        VariantsJson := '[';
        IsFirstVariant := true;
        ItemVariant.SetRange("Item No.", Item."No.");
        ItemVariant.SetCurrentKey("Item No.", Code);
        if ItemVariant.FindSet() then
            repeat
                if not IsFirstVariant then
                    VariantsJson += ',';

                VariantsJson +=
                    '{' +
                        '"variantCode":"' + JsonEscape(ItemVariant.Code) + '",' +
                        '"name":"' + JsonEscape(GetVariantDisplayName(ItemVariant)) + '"' +
                    '}';
                IsFirstVariant := false;
            until ItemVariant.Next() = 0;
        VariantsJson += ']';

        exit(
            '{' +
                '"itemNo":"' + JsonEscape(Item."No.") + '",' +
                '"name":"' + JsonEscape(ItemName) + '",' +
                '"baseUomCode":"' + JsonEscape(Item."Base Unit of Measure") + '",' +
                '"children":' + VariantsJson +
            '}');
    end;

    local procedure GetVariantDisplayName(ItemVariant: Record "Item Variant"): Text
    begin
        if ItemVariant.Description <> '' then
            exit(ItemVariant.Description);

        exit(ItemVariant.Code);
    end;

    local procedure GetCategoryTreeJson(): Text
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
        CategoryKindText: Text;
        FinishedProductTypeText: Text;
    begin
        NodeName := ItemCategory.Description;
        if NodeName = '' then
            NodeName := ItemCategory.Code;

        CategoryKindText := Format(ItemCategory."SI Category Kind");
        FinishedProductTypeText := Format(ItemCategory."SI Finished Type");
        ChildCategory.SetRange("Parent Category", ItemCategory.Code);

        exit(
            '{' +
                '"code":"' + JsonEscape(ItemCategory.Code) + '",' +
                '"name":"' + JsonEscape(NodeName) + '",' +
                '"parentCode":"' + JsonEscape(ItemCategory."Parent Category") + '",' +
                '"baseUomCode":"' + JsonEscape(ItemCategory."SI Default Base UoM Code") + '",' +
                '"categoryKind":"' + JsonEscape(CategoryKindText) + '",' +
                '"finishedProductType":"' + JsonEscape(FinishedProductTypeText) + '",' +
                '"children":' + BuildCategoryJson(ChildCategory) +
            '}');
    end;

    local procedure JsonEscape(Value: Text): Text
    begin
        Value := Value.Replace('\', '\\');
        Value := Value.Replace('"', '\"');
        Value := Value.Replace('/', '\/');
        Value := Value.Replace('<', '\u003C');
        Value := Value.Replace('>', '\u003E');
        Value := Value.Replace('&', '\u0026');
        exit(Value);
    end;

}
