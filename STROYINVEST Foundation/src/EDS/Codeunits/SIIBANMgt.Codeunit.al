codeunit 50444 "SI IBAN Mgt."
{
    procedure Normalize(IBAN: Text): Text
    var
        Result: Text;
    begin
        Result := IBAN.Trim();
        Result := Result.Replace(' ', '');
        Result := Result.Replace('-', '');

        exit(Result.ToUpper());
    end;

    procedure ValidateUA(IBAN: Text)
    var
        NormalizedIBAN: Text;
    begin
        NormalizedIBAN := Normalize(IBAN);

        if StrLen(NormalizedIBAN) <> 29 then
            Error(
                'Український IBAN повинен містити 29 символів. Отримано: %1.',
                StrLen(NormalizedIBAN));

        if CopyStr(NormalizedIBAN, 1, 2) <> 'UA' then
            Error('IBAN повинен починатися з коду країни UA.');

        ValidateDigits(
            CopyStr(NormalizedIBAN, 3, 27),
            'Позиції 3–29 українського IBAN повинні містити тільки цифри.');

        if CalculateMod97(NormalizedIBAN) <> 1 then
            Error('Контрольна сума IBAN некоректна (MOD-97).');
    end;

    procedure IsValidUA(IBAN: Text): Boolean
    begin
        exit(TryValidateUA(IBAN));
    end;

    procedure GetNBUId(IBAN: Text): Code[6]
    var
        NormalizedIBAN: Text;
        NBUId: Code[6];
    begin
        ValidateUA(IBAN);

        NormalizedIBAN := Normalize(IBAN);

        NBUId := CopyStr(
            NormalizedIBAN,
            5,
            MaxStrLen(NBUId));

        exit(NBUId);
    end;

    [TryFunction]
    local procedure TryValidateUA(IBAN: Text)
    begin
        ValidateUA(IBAN);
    end;

    local procedure ValidateDigits(Value: Text; ErrorText: Text)
    var
        i: Integer;
        Digit: Integer;
    begin
        for i := 1 to StrLen(Value) do
            if not Evaluate(Digit, CopyStr(Value, i, 1)) then
                Error(ErrorText);
    end;

    local procedure CalculateMod97(IBAN: Text): Integer
    var
        Rearranged: Text;
        NumericValue: Text;
        i: Integer;
        Digit: Integer;
        Remainder: Integer;
    begin
        // ISO 13616:
        // move the first four characters to the end and replace letters
        // with A=10 ... Z=35.
        //
        // For UA this becomes:
        // positions 5..29 + U(30) + A(10) + checksum digits.
        Rearranged :=
            CopyStr(IBAN, 5) +
            '3010' +
            CopyStr(IBAN, 3, 2);

        NumericValue := Rearranged;
        Remainder := 0;

        for i := 1 to StrLen(NumericValue) do begin
            if not Evaluate(Digit, CopyStr(NumericValue, i, 1)) then
                Error('IBAN містить символ, який неможливо використати для перевірки MOD-97.');

            Remainder := ((Remainder * 10) + Digit) mod 97;
        end;

        exit(Remainder);
    end;
}
