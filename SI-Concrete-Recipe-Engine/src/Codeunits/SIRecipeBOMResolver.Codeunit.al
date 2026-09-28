namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item;

codeunit 62203 "SI Recipe BOM Resolver"
{
    procedure GetProductionBOMNo(ItemNo: Code[20]; VariantCode: Code[10]): Code[20]
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if VariantCode <> '' then begin
            ItemVariant.Get(ItemNo, VariantCode);
            if ItemVariant."SI Production BOM No." <> '' then
                exit(ItemVariant."SI Production BOM No.");
        end;

        Item.Get(ItemNo);
        exit(Item."Production BOM No.");
    end;
}
