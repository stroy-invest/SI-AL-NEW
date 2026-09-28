codeunit 54012 "SI BP Naming Mgt."
{
    procedure HandleNameChange(var BusinessPartner: Record "SI Business Partner")
    begin
        BusinessPartner.Name := CopyStr(CleanBusinessName(BusinessPartner.Name), 1, MaxStrLen(BusinessPartner.Name));
        UpdateDerivedNames(BusinessPartner);
    end;

    procedure UpdateDerivedNames(var BusinessPartner: Record "SI Business Partner")
    var
        CountryLegalForm: Record "SI Country Legal Form";
        ShortLegalFormName: Text;
        ShortNameBK: Text;
    begin
        ShortLegalFormName := '';

        if (BusinessPartner."Country/Region Code" <> '') and
           (BusinessPartner."Local Legal Form Code" <> '') and
           CountryLegalForm.Get(
                BusinessPartner."Country/Region Code",
                BusinessPartner."Local Legal Form Code")
        then
            ShortLegalFormName := CountryLegalForm."Short Name";

        ShortNameBK := BusinessPartner.Name;
        if (ShortNameBK <> '') and (ShortLegalFormName <> '') then
            ShortNameBK += ' ' + ShortLegalFormName;

        BusinessPartner."Short Name BK" :=
            CopyStr(CollapseSpaces(ShortNameBK), 1, MaxStrLen(BusinessPartner."Short Name BK"));

        BusinessPartner."Search Name" :=
            CopyStr(BuildSearchName(BusinessPartner.Name), 1, MaxStrLen(BusinessPartner."Search Name"));
    end;

    procedure CleanBusinessName(Value: Text): Text
    begin
        Value := ReplaceWithSpace(Value, '"');
        Value := ReplaceWithSpace(Value, '«');
        Value := ReplaceWithSpace(Value, '»');
        Value := ReplaceWithSpace(Value, '„');
        Value := ReplaceWithSpace(Value, '“');
        Value := ReplaceWithSpace(Value, '”');
        Value := ReplaceWithSpace(Value, '.');
        Value := ReplaceWithSpace(Value, ',');
        Value := ReplaceWithSpace(Value, ';');
        Value := ReplaceWithSpace(Value, ':');
        Value := ReplaceWithSpace(Value, '!');
        Value := ReplaceWithSpace(Value, '?');
        Value := ReplaceWithSpace(Value, '(');
        Value := ReplaceWithSpace(Value, ')');
        Value := ReplaceWithSpace(Value, '[');
        Value := ReplaceWithSpace(Value, ']');
        Value := ReplaceWithSpace(Value, '{');
        Value := ReplaceWithSpace(Value, '}');

        exit(CollapseSpaces(Value));
    end;

    procedure BuildSearchName(Value: Text): Text
    var
        Result: Text;
        Character: Char;
        Position: Integer;
    begin
        Value := UpperCase(CleanBusinessName(Value));
        Value := TransliterateUkrainian(Value);

        for Position := 1 to StrLen(Value) do begin
            Character := Value[Position];
            if (StrPos('ABCDEFGHIJKLMNOPQRSTUVWXYZ', Format(Character)) > 0) or
               (StrPos('0123456789', Format(Character)) > 0)
            then
                Result += Format(Character);
        end;

        exit(Result);
    end;

    local procedure TransliterateUkrainian(Value: Text): Text
    begin
        Value := Value.Replace('Щ', 'SHCH');
        Value := Value.Replace('Ж', 'ZH');
        Value := Value.Replace('Х', 'KH');
        Value := Value.Replace('Ц', 'TS');
        Value := Value.Replace('Ч', 'CH');
        Value := Value.Replace('Ш', 'SH');
        Value := Value.Replace('Ю', 'YU');
        Value := Value.Replace('Я', 'YA');
        Value := Value.Replace('Є', 'YE');
        Value := Value.Replace('Ї', 'YI');
        Value := Value.Replace('Й', 'Y');
        Value := Value.Replace('Ґ', 'G');
        Value := Value.Replace('А', 'A');
        Value := Value.Replace('Б', 'B');
        Value := Value.Replace('В', 'V');
        Value := Value.Replace('Г', 'H');
        Value := Value.Replace('Д', 'D');
        Value := Value.Replace('Е', 'E');
        Value := Value.Replace('З', 'Z');
        Value := Value.Replace('И', 'Y');
        Value := Value.Replace('І', 'I');
        Value := Value.Replace('К', 'K');
        Value := Value.Replace('Л', 'L');
        Value := Value.Replace('М', 'M');
        Value := Value.Replace('Н', 'N');
        Value := Value.Replace('О', 'O');
        Value := Value.Replace('П', 'P');
        Value := Value.Replace('Р', 'R');
        Value := Value.Replace('С', 'S');
        Value := Value.Replace('Т', 'T');
        Value := Value.Replace('У', 'U');
        Value := Value.Replace('Ф', 'F');
        Value := Value.Replace('Ь', '');
        Value := Value.Replace('Ъ', '');
        Value := Value.Replace('Ы', 'Y');
        Value := Value.Replace('Э', 'E');

        exit(Value);
    end;

    local procedure ReplaceWithSpace(Value: Text; CharacterToReplace: Text): Text
    begin
        exit(Value.Replace(CharacterToReplace, ' '));
    end;

    local procedure CollapseSpaces(Value: Text): Text
    begin
        Value := DelChr(Value, '<>', ' ');
        while StrPos(Value, '  ') > 0 do
            Value := Value.Replace('  ', ' ');

        exit(Value);
    end;
}
