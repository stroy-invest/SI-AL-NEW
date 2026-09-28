tableextension 50185 "SI Item Category Validation" extends "Item Category"
{
    fields
    {
        modify(Description)
        {
            trigger OnAfterValidate()
            begin
                ValidateSiblingDescriptionUniqueness();
            end;
        }
    }

    trigger OnBeforeInsert()
    begin
        ValidateSiblingDescriptionUniqueness();
    end;

    trigger OnBeforeModify()
    begin
        ValidateSiblingDescriptionUniqueness();
    end;

    local procedure ValidateSiblingDescriptionUniqueness()
    var
        SiblingCategory: Record "Item Category";
        NormalizedDescription: Text;
    begin
        NormalizedDescription := NormalizeDescription(Description);
        if NormalizedDescription = '' then
            exit;

        SiblingCategory.SetRange("Parent Category", "Parent Category");
        if SiblingCategory.FindSet() then
            repeat
                if SiblingCategory.Code <> Code then
                    if NormalizeDescription(SiblingCategory.Description) = NormalizedDescription then
                        Error(DuplicateSiblingDescriptionErr, Description);
            until SiblingCategory.Next() = 0;
    end;

    local procedure NormalizeDescription(Value: Text): Text
    begin
        Value := DelChr(Value, '<>', ' ');
        while StrPos(Value, '  ') > 0 do
            Value := Value.Replace('  ', ' ');

        exit(UpperCase(Value));
    end;

    var
        DuplicateSiblingDescriptionErr: Label
            'Категорія з назвою «%1» вже існує на цьому рівні ієрархії. Вкажіть іншу назву.';
}
