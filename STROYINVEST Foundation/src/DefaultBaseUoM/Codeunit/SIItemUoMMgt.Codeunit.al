codeunit 50166 "SI Item UoM Mgt."
{
    // SI Item UoM Management

    procedure TryGetCategoryDefaultBaseUoM(
        ItemCategoryCode: Code[20];
        var BaseUoMCode: Code[10]): Boolean
    var
        ItemCategory: Record "Item Category";
    begin
        Clear(BaseUoMCode);

        if ItemCategoryCode = '' then
            exit(false);

        if not ItemCategory.Get(ItemCategoryCode) then
            exit(false);

        BaseUoMCode := ItemCategory."SI Default Base UoM Code";

        exit(BaseUoMCode <> '');
    end;
}