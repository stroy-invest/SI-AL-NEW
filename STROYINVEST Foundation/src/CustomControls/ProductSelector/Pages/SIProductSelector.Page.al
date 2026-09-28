page 50189 "SI Product Selector"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    Caption = 'Вибір товару';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(CategoryArea)
            {
                Caption = 'Категорія';

                field(SelectedCategoryName; SelectedCategoryName)
                {
                    ApplicationArea = All;
                    Caption = 'Вибрана категорія';
                    Editable = false;
                }

                usercontrol(ItemGroupTree; "SI Item Group Tree")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        CategoryTreeReady := true;
                        CurrPage.ItemGroupTree.SetSelectionMode(true);
                        CurrPage.ItemGroupTree.RenderTree(CategorySelectorMgt.GetCategoryTreeJson());
                        RestoreInitialCategorySelection();
                    end;

                    trigger NodeSelected(GroupCode: Text)
                    begin
                        SelectedCategoryCode := CopyStr(GroupCode, 1, MaxStrLen(SelectedCategoryCode));
                        SelectedCategoryName := CategorySelectorMgt.GetCategoryDisplayName(SelectedCategoryCode);
                        Clear(SelectedItemNo);
                        Clear(SelectedVariantCode);
                        Clear(InitialItemNo);
                        Clear(InitialVariantCode);
                        Clear(SelectedProductName);
                        RefreshProductTree();
                        CurrPage.Update(false);
                    end;

                    trigger NodeOpenRequested(GroupCode: Text)
                    begin
                    end;

                    trigger AddCategoryRequested(GroupCode: Text)
                    begin
                    end;

                    trigger DeleteCategoryRequested(GroupCode: Text)
                    begin
                    end;
                }
            }

            group(ProductArea)
            {
                Caption = 'Товар / варіант';

                field(SelectedProductName; SelectedProductName)
                {
                    ApplicationArea = All;
                    Caption = 'Вибрано';
                    Editable = false;
                }

                usercontrol(ProductTree; "SI Product Tree")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        ProductTreeReady := true;
                        RefreshProductTree();
                        RestoreInitialProductSelection();
                    end;

                    trigger ProductSelected(NodeType: Text; ItemNo: Text; VariantCode: Text)
                    begin
                        // The control add-in selection is authoritative. Do not call CurrPage.Update()
                        // here: updating the NavigatePage can recreate/re-render the control and
                        // overwrite the just-selected JS node with stale page selection state.
                        SelectedItemNo := CopyStr(ItemNo, 1, MaxStrLen(SelectedItemNo));
                        Clear(SelectedVariantCode);
                        if NodeType = 'Variant' then
                            SelectedVariantCode := CopyStr(VariantCode, 1, MaxStrLen(SelectedVariantCode));

                        // Keep the state used by a possible control reinitialization synchronized
                        // with the current selection (including Variant Code).
                        InitialItemNo := SelectedItemNo;
                        InitialVariantCode := SelectedVariantCode;
                        SelectedProductName := ProductSelectorMgt.GetProductDisplayName(SelectedItemNo, SelectedVariantCode);
                    end;

                    trigger ProductOpenRequested(NodeType: Text; ItemNo: Text; VariantCode: Text)
                    begin
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CancelSelection)
            {
                ApplicationArea = All;
                Caption = 'Скасувати';
                Image = Cancel;
                InFooterBar = true;

                trigger OnAction()
                begin
                    SelectionAccepted := false;
                    CurrPage.Close();
                end;
            }

            action(SelectProduct)
            {
                ApplicationArea = All;
                Caption = 'Вибрати';
                Image = SelectLineToApply;
                InFooterBar = true;
                trigger OnAction()
                begin
                    // ProductSelected has already synchronized the exact Item/Variant into AL.
                    // Accept that state directly; do not start a second asynchronous JS round-trip.
                    if SelectedItemNo = '' then
                        Error('Виберіть товар або варіант.');

                    SelectionAccepted := true;
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        SelectedCategoryCode: Code[20];
        SelectedItemNo: Code[20];
        SelectedVariantCode: Code[10];
        InitialItemNo: Code[20];
        InitialVariantCode: Code[10];
        SelectedCategoryName: Text[250];
        SelectedProductName: Text[500];
        ProductSelectorMgt: Codeunit "SI Product Selector Mgt.";
        CategorySelectorMgt: Codeunit "SI Category Selector Mgt.";
        CategoryTreeReady: Boolean;
        ProductTreeReady: Boolean;
        SelectionAccepted: Boolean;

    procedure SetInitialSelection(ItemNo: Code[20]; VariantCode: Code[10])
    var
        Item: Record Item;
    begin
        InitialItemNo := ItemNo;
        InitialVariantCode := VariantCode;

        if (ItemNo <> '') and Item.Get(ItemNo) then begin
            SelectedCategoryCode := Item."Item Category Code";
            SelectedItemNo := ItemNo;
            SelectedVariantCode := VariantCode;
            SelectedCategoryName := CategorySelectorMgt.GetCategoryDisplayName(SelectedCategoryCode);
            SelectedProductName := ProductSelectorMgt.GetProductDisplayName(SelectedItemNo, SelectedVariantCode);
        end;
    end;

    local procedure RestoreInitialCategorySelection()
    begin
        if CategoryTreeReady and (SelectedCategoryCode <> '') then
            CurrPage.ItemGroupTree.SelectNode(SelectedCategoryCode);
    end;

    local procedure RestoreInitialProductSelection()
    var
        NodeType: Text;
    begin
        if not ProductTreeReady or (InitialItemNo = '') then
            exit;

        NodeType := 'Item';
        if InitialVariantCode <> '' then
            NodeType := 'Variant';
        CurrPage.ProductTree.SelectProduct(NodeType, InitialItemNo, InitialVariantCode);
    end;

    local procedure RefreshProductTree()
    begin
        if ProductTreeReady then
            CurrPage.ProductTree.RenderProducts(GetProductTreeJson(SelectedCategoryCode));
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
                VariantsJson += '{"variantCode":"' + JsonEscape(ItemVariant.Code) + '","name":"' + JsonEscape(GetVariantDisplayName(ItemVariant)) + '"}';
                IsFirstVariant := false;
            until ItemVariant.Next() = 0;
        VariantsJson += ']';

        exit('{"itemNo":"' + JsonEscape(Item."No.") + '","name":"' + JsonEscape(ItemName) + '","baseUomCode":"' + JsonEscape(Item."Base Unit of Measure") + '","children":' + VariantsJson + '}');
    end;

    local procedure GetVariantDisplayName(ItemVariant: Record "Item Variant"): Text
    begin
        if ItemVariant.Description <> '' then
            exit(ItemVariant.Description);
        exit(ItemVariant.Code);
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
    procedure TryGetSelection(var ItemNo: Code[20]; var VariantCode: Code[10]): Boolean
    begin
        if not SelectionAccepted then
            exit(false);

        ItemNo := SelectedItemNo;
        VariantCode := SelectedVariantCode;
        exit(ItemNo <> '');
    end;

}
