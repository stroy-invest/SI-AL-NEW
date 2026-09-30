codeunit 53039 "SI SKU Location Mgt."
{
    procedure ConfigureFromCurrentContext()
    var
        ProductTreeContext: Codeunit "SI Product Tree Context";
        LocationSelect: Page "SI SKU Location Select";
        TempSelection: Record "SI SKU Location Buffer" temporary;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        NodeType: Text[20];
        ItemNo: Code[20];
        VariantCode: Code[10];
        IncludeAllVariants: Boolean;
        CreatedCount: Integer;
        ScopeChoice: Integer;
    begin
        ProductTreeContext.GetContext(NodeType, ItemNo, VariantCode);

        if not (NodeType in ['Item', 'Variant']) or (ItemNo = '') then
            Error(SelectProductErr);

        Item.Get(ItemNo);

        if (NodeType = 'Item') and HasVariants(ItemNo) then begin
            ScopeChoice := Dialog.StrMenu(ScopeOptionsTxt, 2, ScopeQuestionTxt);
            if ScopeChoice = 0 then
                exit;

            IncludeAllVariants := ScopeChoice = 2;
        end;

        Clear(LocationSelect);
        LocationSelect.Load(ItemNo, VariantCode, IncludeAllVariants);
        LocationSelect.RunModal();
        if not LocationSelect.WasApplyRequested() then
            exit;

        LocationSelect.GetSelected(TempSelection);
        if TempSelection.IsEmpty() then begin
            Message(NoLocationsSelectedMsg);
            exit;
        end;

        if TempSelection.FindSet() then
            repeat
                CreatedCount += CreateSKUForContext(Item, TempSelection."Location Code", VariantCode);

                if IncludeAllVariants then begin
                    ItemVariant.Reset();
                    ItemVariant.SetRange("Item No.", Item."No.");
                    if ItemVariant.FindSet() then
                        repeat
                            CreatedCount += CreateSKUForContext(Item, TempSelection."Location Code", ItemVariant.Code);
                        until ItemVariant.Next() = 0;
                end;
            until TempSelection.Next() = 0;

        Message(CreatedMsg, CreatedCount);
    end;

    local procedure HasVariants(ItemNo: Code[20]): Boolean
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.SetRange("Item No.", ItemNo);
        exit(not ItemVariant.IsEmpty());
    end;

    local procedure CreateSKUForContext(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]): Integer
    var
        SKU: Record "Stockkeeping Unit";
        CreateSKU: Report "Create Stockkeeping Unit";
    begin
        if SKU.Get(LocationCode, Item."No.", VariantCode) then
            exit(0);

        CreateSKU.CreateSKUIfRequired(Item, LocationCode, VariantCode);

        if SKU.Get(LocationCode, Item."No.", VariantCode) then
            exit(1);

        exit(0);
    end;

    var
        SelectProductErr: Label 'Спочатку виберіть товар або варіант у дереві товарів.';
        NoLocationsSelectedMsg: Label 'Не вибрано жодного нового місця зберігання.';
        CreatedMsg: Label 'Створено SKU: %1.';
        ScopeQuestionTxt: Label 'Товар має варіанти. Для яких товарів налаштувати вибрані місця зберігання?';
        ScopeOptionsTxt: Label 'Тільки для поточного товару,Для поточного товару та всіх його варіантів';
}
