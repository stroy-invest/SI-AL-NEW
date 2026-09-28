codeunit 50189 "SI Product Selector Mgt."
{
    procedure SelectProduct(var ItemNo: Code[20]; var VariantCode: Code[10]): Boolean
    var
        ProductSelector: Page "SI Product Selector";
    begin
        ProductSelector.SetInitialSelection(ItemNo, VariantCode);
        ProductSelector.RunModal();

        exit(ProductSelector.TryGetSelection(ItemNo, VariantCode));
    end;

    procedure GetProductDisplayName(ItemNo: Code[20]; VariantCode: Code[10]): Text
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemName: Text;
        VariantName: Text;
    begin
        if (ItemNo = '') or (not Item.Get(ItemNo)) then
            exit('');

        ItemName := Item.Description;
        if ItemName = '' then
            ItemName := Item."No.";

        if VariantCode = '' then
            exit(ItemName);

        if not ItemVariant.Get(ItemNo, VariantCode) then
            exit(ItemName);

        VariantName := ItemVariant.Description;
        if VariantName = '' then
            VariantName := ItemVariant.Code;

        exit(VariantName);
    end;
}
