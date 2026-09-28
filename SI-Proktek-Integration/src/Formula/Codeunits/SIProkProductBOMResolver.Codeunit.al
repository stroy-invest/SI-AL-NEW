codeunit 57063 "SI Prok Product BOM Resolver"
{
    procedure ResolveProductionBOM(ItemNo: Code[20]; VariantCode: Code[10]): Code[20]
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMNo: Code[20];
    begin
        if ItemNo = '' then
            Error('Не вказано товар.');

        Item.Get(ItemNo);
        if VariantCode <> '' then
            ItemVariant.Get(ItemNo, VariantCode);

        // Phase 1 contract: Item is the authoritative BOM source.
        // Variant-specific BOM override can be added here later without changing callers.
        ProductionBOMNo := Item."Production BOM No.";
        if ProductionBOMNo = '' then
            Error('Для товару %1 не призначено Production BOM.', ItemNo);

        if not ProductionBOMHeader.Get(ProductionBOMNo) then
            Error('Production BOM %1, призначений товару %2, не знайдено.', ProductionBOMNo, ItemNo);

        exit(ProductionBOMNo);
    end;
}
