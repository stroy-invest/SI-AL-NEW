page 50182 "SI Item Class. Workspace"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Дерево груп товарів';

    layout
    {
        area(Content)
        {
            group(TreeArea)
            {
                ShowCaption = false;

                usercontrol(ItemGroupTree; "SI Item Group Tree")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        CurrPage.ItemGroupTree.RenderTree(GetCategoryTreeJson());
                    end;

                    trigger NodeSelected(GroupCode: Text)
                    begin
                        SelectedGroupCode := CopyStr(GroupCode, 1, MaxStrLen(SelectedGroupCode));
                        ClearProductContext();
                        RefreshCategoryContext();
                        RefreshProductTree();
                        CurrPage.Update(false);
                    end;

                    trigger NodeOpenRequested(GroupCode: Text)
                    var
                        ItemCategory: Record "Item Category";
                    begin
                        if GroupCode = '' then
                            exit;

                        if not ItemCategory.Get(CopyStr(GroupCode, 1, MaxStrLen(ItemCategory.Code))) then
                            exit;

                        Page.Run(Page::"Item Category Card", ItemCategory);
                    end;

                    trigger AddCategoryRequested(GroupCode: Text)
                    var
                        ItemCategoryWorkspaceMgt: Codeunit "SI Item Cat. Workspace Mgt.";
                        NewCategoryCode: Code[20];
                        ContextCategoryCode: Code[20];
                    begin
                        ContextCategoryCode := CopyStr(GroupCode, 1, MaxStrLen(ContextCategoryCode));
                        if ContextCategoryCode = '' then
                            exit;

                        if not ItemCategoryWorkspaceMgt.CreateCategoryFromContext(ContextCategoryCode, NewCategoryCode) then
                            exit;

                        SelectCategoryAfterCreate(NewCategoryCode);
                    end;

                    trigger DeleteCategoryRequested(GroupCode: Text)
                    var
                        ItemCategoryWorkspaceMgt: Codeunit "SI Item Cat. Workspace Mgt.";
                        ParentCategoryCode: Code[20];
                        ContextCategoryCode: Code[20];
                    begin
                        ContextCategoryCode := CopyStr(GroupCode, 1, MaxStrLen(ContextCategoryCode));
                        if ContextCategoryCode = '' then
                            exit;

                        if not ItemCategoryWorkspaceMgt.DeleteCategoryFromContext(ContextCategoryCode, ParentCategoryCode) then
                            exit;

                        SelectCategoryAfterDelete(ParentCategoryCode);
                    end;
                }
            }

            group(ProductsArea)
            {
                Caption = 'Товари';

                usercontrol(ProductTree; "SI Product Tree")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        CurrPage.ProductTree.RenderProducts(GetProductTreeJson(SelectedGroupCode));
                    end;

                    trigger ProductSelected(NodeType: Text; ItemNo: Text; VariantCode: Text)
                    begin
                        SetProductContext(NodeType, ItemNo, VariantCode);
                        CurrPage.Update(false);
                    end;

                    trigger ProductOpenRequested(NodeType: Text; ItemNo: Text; VariantCode: Text)
                    var
                        OpenItemNo: Code[20];
                        OpenVariantCode: Code[10];
                    begin
                        OpenItemNo := CopyStr(ItemNo, 1, MaxStrLen(OpenItemNo));
                        OpenVariantCode := CopyStr(VariantCode, 1, MaxStrLen(OpenVariantCode));

                        case NodeType of
                            'Item':
                                OpenItemCard(OpenItemNo);
                            'Variant':
                                OpenVariant(OpenItemNo, OpenVariantCode);
                        end;
                    end;
                }
            }

            // Compatibility providers. They remain hidden deliberately: dependent apps
            // can continue using the same Item / Variant context as before the UI refactor.
            part(GroupItems; "SI Group Items Part")
            {
                ApplicationArea = All;
                Visible = false;
                UpdatePropagation = Both;
            }

            part(ItemVariants; "SI Item Variants Part")
            {
                ApplicationArea = All;
                Visible = false;
                UpdatePropagation = Both;
            }
        }

        area(FactBoxes)
        {
            part(CategoryAttributes; "SI Category Attributes FactBox")
            {
                ApplicationArea = All;
                Caption = 'Атрибути категорії';
                Visible = CategoryAttributesVisible;
            }
        }
    }

    var
        SelectedGroupCode: Code[20];
        SelectedItemNo: Code[20];
        SelectedVariantCode: Code[10];
        CategoryAttributesVisible: Boolean;

    local procedure ClearProductContext()
    begin
        Clear(SelectedItemNo);
        Clear(SelectedVariantCode);

        CurrPage.GroupItems.Page.SetCategoryFilter(SelectedGroupCode);
        CurrPage.ItemVariants.Page.SetItemContext('');

        OnProductContextChanged('Category', '', '');
    end;

    local procedure SetProductContext(NodeType: Text; ItemNo: Text; VariantCode: Text)
    begin
        SelectedItemNo := CopyStr(ItemNo, 1, MaxStrLen(SelectedItemNo));
        Clear(SelectedVariantCode);

        case NodeType of
            'Item':
                begin
                    CurrPage.GroupItems.Page.SetSelectedItem(SelectedItemNo);
                    CurrPage.ItemVariants.Page.SetItemContext(SelectedItemNo);
                end;
            'Variant':
                begin
                    SelectedVariantCode := CopyStr(VariantCode, 1, MaxStrLen(SelectedVariantCode));
                    CurrPage.GroupItems.Page.SetSelectedItem(SelectedItemNo);
                    CurrPage.ItemVariants.Page.SetSelectedVariant(SelectedItemNo, SelectedVariantCode);
                end;
            else begin
                Clear(SelectedItemNo);
                CurrPage.GroupItems.Page.SetCategoryFilter(SelectedGroupCode);
                CurrPage.ItemVariants.Page.SetItemContext('');
            end;
        end;

        OnProductContextChanged(NodeType, SelectedItemNo, SelectedVariantCode);
    end;

    local procedure RefreshCategoryContext()
    begin
        CategoryAttributesVisible := HasEffectiveCategoryAttributes(SelectedGroupCode);
        if CategoryAttributesVisible then
            CurrPage.CategoryAttributes.Page.LoadAttributes(SelectedGroupCode)
        else
            CurrPage.CategoryAttributes.Page.ClearAttributes();
    end;

    local procedure RefreshProductTree()
    begin
        CurrPage.ProductTree.RenderProducts(GetProductTreeJson(SelectedGroupCode));
    end;

    local procedure SelectCategoryAfterCreate(ItemCategoryCode: Code[20])
    begin
        SelectedGroupCode := ItemCategoryCode;
        ClearProductContext();
        RefreshCategoryContext();
        RefreshProductTree();

        CurrPage.ItemGroupTree.RenderTree(GetCategoryTreeJson());
        CurrPage.ItemGroupTree.SelectNode(SelectedGroupCode);
        CurrPage.Update(false);
    end;

    local procedure SelectCategoryAfterDelete(ParentCategoryCode: Code[20])
    begin
        SelectedGroupCode := ParentCategoryCode;
        ClearProductContext();
        RefreshCategoryContext();
        RefreshProductTree();

        CurrPage.ItemGroupTree.RenderTree(GetCategoryTreeJson());
        if SelectedGroupCode <> '' then
            CurrPage.ItemGroupTree.SelectNode(SelectedGroupCode);
        CurrPage.Update(false);
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

    local procedure OpenItemCard(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        if ItemNo = '' then
            exit;
        if not Item.Get(ItemNo) then
            exit;

        // Open modally so the workspace can refresh immediately after
        // the user closes the standard Item Card.
        Page.RunModal(Page::"Item Card", Item);
        RefreshProductsAfterEdit('Item', ItemNo, '');
    end;

    local procedure OpenVariant(ItemNo: Code[20]; VariantCode: Code[10])
    var
        ItemVariant: Record "Item Variant";
    begin
        if (ItemNo = '') or (VariantCode = '') then
            exit;

        ItemVariant.SetRange("Item No.", ItemNo);
        ItemVariant.SetRange(Code, VariantCode);

        // The Item Variants page can add, edit and delete variants.
        // Refresh the workspace tree as soon as the page is closed.
        Page.RunModal(Page::"Item Variants", ItemVariant);
        RefreshProductsAfterEdit('Variant', ItemNo, VariantCode);
    end;

    local procedure RefreshProductsAfterEdit(NodeType: Text; ItemNo: Code[20]; VariantCode: Code[10])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        CanRestoreSelection: Boolean;
    begin
        RefreshProductTree();

        // Preserve the current selection when the edited ERP object still
        // exists in the currently selected category. If it was deleted or
        // moved to another category, clear the product context instead.
        if Item.Get(ItemNo) then
            if Item."Item Category Code" = SelectedGroupCode then
                case NodeType of
                    'Item':
                        CanRestoreSelection := true;
                    'Variant':
                        CanRestoreSelection :=
                            ItemVariant.Get(ItemNo, VariantCode);
                end;

        if CanRestoreSelection then begin
            SetProductContext(NodeType, ItemNo, VariantCode);
            CurrPage.ProductTree.SelectProduct(NodeType, ItemNo, VariantCode);
        end else
            ClearProductContext();

        CurrPage.Update(false);
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

    [IntegrationEvent(false, false)]
    local procedure OnProductContextChanged(NodeType: Text; ItemNo: Code[20]; VariantCode: Code[10])
    begin
    end;
}
