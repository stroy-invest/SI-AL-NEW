codeunit 53039 "SI SKU Location Mgt."
{
    procedure ConfigureFromCurrentContext()
    var
        ProductTreeContext: Codeunit "SI Product Tree Context";
        LocationSelect: Page "SI SKU Location Select";
        TempSelection: Record "SI SKU Location Buffer" temporary;
        Item: Record Item;
        CreateSKU: Report "Create Stockkeeping Unit";
        NodeType: Text[20];
        ItemNo: Code[20];
        VariantCode: Code[10];
        CreatedCount: Integer;
    begin
        ProductTreeContext.GetContext(NodeType, ItemNo, VariantCode);

        if not (NodeType in ['Item', 'Variant']) or (ItemNo = '') then
            Error(SelectProductErr);

        Item.Get(ItemNo);

        Clear(LocationSelect);
        LocationSelect.Load(ItemNo, VariantCode);
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
                CreateSKU.CreateSKUIfRequired(Item, TempSelection."Location Code", VariantCode);
                CreatedCount += 1;
            until TempSelection.Next() = 0;

        Message(CreatedMsg, CreatedCount);
    end;

    var
        SelectProductErr: Label 'Спочатку виберіть товар або варіант у дереві товарів.';
        NoLocationsSelectedMsg: Label 'Не вибрано жодного нового місця зберігання.';
        CreatedMsg: Label 'Створено SKU: %1.';
}
