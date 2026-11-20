page 50295 "SI Item Hierarchy V3 Test"  // Робоча версія. 
                                        // Test з назви не прибирали, оскільки на неї вже посилаються підписники та розширення сторінки
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Дерево груп товарів';
    Editable = false;

    layout
    {
        area(Content)
        {
            usercontrol(Hierarchy; "SI Item Hierarchy V3")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    CurrPage.Hierarchy.RenderTree(GetCategoryTreeJson());
                    CurrPage.Hierarchy.RenderProducts(GetProductTreeJson(SelectedGroupCode));
                    CurrPage.Hierarchy.SetParametersVisible(ParametersVisible);
                    RefreshParameters();
                end;

                trigger NodeSelected(GroupCode: Text)
                begin
                    SelectedGroupCode := CopyStr(GroupCode, 1, MaxStrLen(SelectedGroupCode));
                    SelectedItemNo := '';
                    SelectedVariantCode := '';
                    SelectedNodeType := 'Category';
                    RefreshParameters();
                    CurrPage.Hierarchy.RenderProducts(GetProductTreeJson(SelectedGroupCode));
                    OnProductContextChanged('Category', '', '');
                    // Deliberately no CurrPage.Update(false).
                end;

                trigger NodeOpenRequested(GroupCode: Text)
                var
                    ItemCategory: Record "Item Category";
                    OpenCategoryCode: Code[20];
                begin
                    OpenCategoryCode := CopyStr(GroupCode, 1, MaxStrLen(OpenCategoryCode));
                    if (OpenCategoryCode = '') or (not ItemCategory.Get(OpenCategoryCode)) then
                        exit;

                    Page.RunModal(Page::"Item Category Card", ItemCategory);
                    CurrPage.Hierarchy.RenderTree(GetCategoryTreeJson());
                    if ItemCategory.Get(OpenCategoryCode) then
                        CurrPage.Hierarchy.SelectNode(OpenCategoryCode);
                    CurrPage.Hierarchy.RenderProducts(GetProductTreeJson(SelectedGroupCode));
                    RefreshParameters();
                end;

                trigger ProductOpenRequested(NodeType: Text; ItemNo: Text; VariantCode: Text)
                var
                    Item: Record Item;
                    ItemVariant: Record "Item Variant";
                    OpenItemNo: Code[20];
                    OpenVariantCode: Code[10];
                begin
                    OpenItemNo := CopyStr(ItemNo, 1, MaxStrLen(OpenItemNo));
                    OpenVariantCode := CopyStr(VariantCode, 1, MaxStrLen(OpenVariantCode));
                    if OpenItemNo = '' then
                        exit;

                    case NodeType of
                        'Item':
                            begin
                                if not Item.Get(OpenItemNo) then
                                    exit;
                                Page.RunModal(Page::"Item Card", Item);
                            end;
                        'Variant':
                            begin
                                if OpenVariantCode = '' then
                                    exit;
                                ItemVariant.SetRange("Item No.", OpenItemNo);
                                ItemVariant.SetRange(Code, OpenVariantCode);
                                Page.RunModal(Page::"Item Variants", ItemVariant);
                            end;
                        else
                            exit;
                    end;

                    RefreshProductTreeAfterCardClose(NodeType, OpenItemNo, OpenVariantCode);
                end;

                trigger ProductSelected(NodeType: Text; ItemNo: Text; VariantCode: Text)
                var
                    ContextItemNo: Code[20];
                    ContextVariantCode: Code[10];
                begin
                    ContextItemNo := CopyStr(ItemNo, 1, MaxStrLen(ContextItemNo));
                    ContextVariantCode := CopyStr(VariantCode, 1, MaxStrLen(ContextVariantCode));
                    if (NodeType <> 'Item') and (NodeType <> 'Variant') then
                        exit;
                    SelectedNodeType := CopyStr(NodeType, 1, MaxStrLen(SelectedNodeType));
                    SelectedItemNo := ContextItemNo;
                    if NodeType = 'Variant' then
                        SelectedVariantCode := ContextVariantCode
                    else
                        SelectedVariantCode := '';
                    RefreshParameters();
                    OnProductContextChanged(NodeType, ContextItemNo, ContextVariantCode);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ToggleParameters)
            {
                ApplicationArea = All;
                Caption = 'Показати/сховати параметри';
                ToolTip = 'Показує або приховує панель параметрів праворуч від дерева товарів.';
                Image = ViewDetails;

                trigger OnAction()
                begin
                    ParametersVisible := not ParametersVisible;
                    CurrPage.Hierarchy.SetParametersVisible(ParametersVisible);
                end;
            }
        }

        area(Promoted)
        {
            actionref(ToggleParametersPromoted; ToggleParameters)
            {
            }
        }
    }

    var
        SelectedGroupCode: Code[20];
        ParametersVisible: Boolean;
        SelectedNodeType: Text[20];
        SelectedItemNo: Code[20];
        SelectedVariantCode: Code[10];

    [IntegrationEvent(false, false)]
    local procedure OnProductContextChanged(NodeType: Text; ItemNo: Code[20]; VariantCode: Code[10])
    begin
    end;

    local procedure RefreshProductTreeAfterCardClose(NodeType: Text; ItemNo: Code[20]; VariantCode: Code[10])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        RestoreSelection: Boolean;
    begin
        CurrPage.Hierarchy.RenderProducts(GetProductTreeJson(SelectedGroupCode));

        if Item.Get(ItemNo) then
            if Item."Item Category Code" = SelectedGroupCode then
                case NodeType of
                    'Item':
                        RestoreSelection := true;
                    'Variant':
                        RestoreSelection := ItemVariant.Get(ItemNo, VariantCode);
                end;

        if RestoreSelection then begin
            SelectedNodeType := CopyStr(NodeType, 1, MaxStrLen(SelectedNodeType));
            SelectedItemNo := ItemNo;
            if NodeType = 'Variant' then
                SelectedVariantCode := VariantCode
            else
                SelectedVariantCode := '';
            CurrPage.Hierarchy.SelectProduct(NodeType, ItemNo, SelectedVariantCode);
            OnProductContextChanged(NodeType, ItemNo, SelectedVariantCode);
        end else begin
            SelectedNodeType := 'Category';
            Clear(SelectedItemNo);
            Clear(SelectedVariantCode);
            OnProductContextChanged('Category', '', '');
        end;

        RefreshParameters();
    end;

    local procedure RefreshParameters()
    var
        ParametersJson: JsonObject;
        ContextJson: JsonObject;
        Sections: JsonArray;
        CategoryProvider: Codeunit "SI V3 Category Parameters";
        ItemCategory: Record "Item Category";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        CategoryCode: Code[20];
        TitleText: Text;
        JsonText: Text;
    begin
        CategoryCode := SelectedGroupCode;
        TitleText := 'Параметри та характеристики';
        if (SelectedNodeType = 'Item') or (SelectedNodeType = 'Variant') then begin
            if not Item.Get(SelectedItemNo) then begin
                Clear(SelectedItemNo);
                Clear(SelectedVariantCode);
                SelectedNodeType := 'Category';
            end else begin
                CategoryCode := Item."Item Category Code";
                TitleText := Item.Description;
                if TitleText = '' then
                    TitleText := Item."No.";
                if SelectedNodeType = 'Variant' then
                    if ItemVariant.Get(SelectedItemNo, SelectedVariantCode) then begin
                        if ItemVariant.Description <> '' then
                            TitleText := ItemVariant.Description;
                    end else begin
                        Clear(SelectedVariantCode);
                        SelectedNodeType := 'Item';
                    end;
            end;
        end;
        if SelectedNodeType = 'Category' then
            if ItemCategory.Get(CategoryCode) then begin
                TitleText := ItemCategory.Description;
                if TitleText = '' then
                    TitleText := ItemCategory.Code;
            end;

        ContextJson.Add('nodeType', SelectedNodeType);
        ContextJson.Add('categoryCode', CategoryCode);
        ContextJson.Add('itemNo', SelectedItemNo);
        ContextJson.Add('variantCode', SelectedVariantCode);
        ParametersJson.Add('schemaVersion', 1);
        ParametersJson.Add('context', ContextJson);
        ParametersJson.Add('title', TitleText);
        CategoryProvider.AppendCategorySection(CategoryCode, Sections);
        OnCollectParameterSections(SelectedNodeType, SelectedItemNo, SelectedVariantCode, Sections);
        ParametersJson.Add('sections', Sections);
        ParametersJson.WriteTo(JsonText);
        CurrPage.Hierarchy.RenderParameters(JsonText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectParameterSections(NodeType: Text; ItemNo: Code[20]; VariantCode: Code[10]; var Sections: JsonArray)
    begin
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
    begin
        NodeName := ItemCategory.Description;
        if NodeName = '' then
            NodeName := ItemCategory.Code;

        ChildCategory.SetRange("Parent Category", ItemCategory.Code);

        exit(
            '{' +
                '"code":"' + JsonEscape(ItemCategory.Code) + '",' +
                '"name":"' + JsonEscape(NodeName) + '",' +
                '"parentCode":"' + JsonEscape(ItemCategory."Parent Category") + '",' +
                '"baseUomCode":"' + JsonEscape(ItemCategory."SI Default Base UoM Code") + '",' +
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
