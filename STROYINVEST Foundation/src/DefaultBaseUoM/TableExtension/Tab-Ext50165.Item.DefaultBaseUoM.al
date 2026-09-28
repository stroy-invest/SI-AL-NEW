tableextension 50165 "SI Item Default Base UoM" extends Item
{
    fields
    {
        modify("Item Category Code")
        {
            trigger OnAfterValidate()
            var
                ItemCategory: Record "Item Category";
            begin
                if Rec."Base Unit of Measure" <> '' then
                    exit;

                if Rec."Item Category Code" = '' then
                    exit;

                if not ItemCategory.Get(Rec."Item Category Code") then
                    exit;

                if ItemCategory."SI Default Base UoM Code" = '' then
                    Error(DefaultBaseUoMNotSpecifiedErr, Rec."Item Category Code");

                Rec.Validate("Base Unit of Measure", ItemCategory."SI Default Base UoM Code");
            end;
        }
    }

    var
        DefaultBaseUoMNotSpecifiedErr: Label 'Для категорії товару %1 не вказано базову одиницю виміру за замовчуванням.';
}