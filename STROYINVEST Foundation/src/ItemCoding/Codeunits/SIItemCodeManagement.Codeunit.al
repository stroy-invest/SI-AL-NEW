codeunit 50160 "SI Item Code Management"
{
    procedure GenerateItemNo(ItemCategoryCode: Code[20]): Code[20]
    var
        ItemCategory: Record "Item Category";
        NoSeries: Codeunit "No. Series";
    begin
        if ItemCategoryCode = '' then
            Error('Необхідно вказати код категорії товару');

        ItemCategory.Get(ItemCategoryCode);

        ItemCategory.TestField("SI Item No. Series Code");

        exit(NoSeries.GetNextNo(ItemCategory."SI Item No. Series Code"));
    end;
}