codeunit 50446 "SI UA Identifier Mgt."
{
    procedure ValidateRNOKPP(Value: Text)
    var
        ExpectedCheckDigit: Integer;
        ActualCheckDigit: Integer;
    begin
        ValidateExactDigits(Value, 10, 'РНОКПП');

        ExpectedCheckDigit := CalculateRNOKPPCheckDigit(Value);
        ActualCheckDigit := GetDigit(Value, 10);

        if ExpectedCheckDigit <> ActualCheckDigit then
            Error(
                'Некоректний РНОКПП. Контрольна цифра не відповідає номеру. Перевірте правильність введення.');
    end;

    procedure IsValidRNOKPP(Value: Text): Boolean
    begin
        exit(TryValidateRNOKPP(Value));
    end;

    procedure ValidateEDRPOU(Value: Text)
    var
        ExpectedCheckDigit: Integer;
        ActualCheckDigit: Integer;
    begin
        ValidateExactDigits(Value, 8, 'Код ЄДРПОУ');

        ExpectedCheckDigit := CalculateEDRPOUCheckDigit(Value);
        ActualCheckDigit := GetDigit(Value, 8);

        if ExpectedCheckDigit <> ActualCheckDigit then
            Error(
                'Некоректний код ЄДРПОУ. Контрольна цифра не відповідає коду. Перевірте правильність введення.');
    end;

    procedure IsValidEDRPOU(Value: Text): Boolean
    begin
        exit(TryValidateEDRPOU(Value));
    end;

    [TryFunction]
    local procedure TryValidateRNOKPP(Value: Text)
    begin
        ValidateRNOKPP(Value);
    end;

    [TryFunction]
    local procedure TryValidateEDRPOU(Value: Text)
    begin
        ValidateEDRPOU(Value);
    end;

    local procedure ValidateExactDigits(Value: Text; RequiredLength: Integer; IdentifierCaption: Text)
    var
        Position: Integer;
    begin
        if StrLen(Value) <> RequiredLength then
            Error(
                '%1 повинен містити рівно %2 цифр. Отримано: %3.',
                IdentifierCaption,
                RequiredLength,
                StrLen(Value));

        for Position := 1 to RequiredLength do
            GetDigit(Value, Position);
    end;

    local procedure CalculateRNOKPPCheckDigit(Value: Text): Integer
    var
        Position: Integer;
        WeightedSum: Integer;
        Remainder: Integer;
    begin
        for Position := 1 to 9 do
            WeightedSum += GetDigit(Value, Position) * GetRNOKPPWeight(Position);

        Remainder := WeightedSum mod 11;
        if Remainder < 0 then
            Remainder += 11;

        if Remainder = 10 then
            exit(0);

        exit(Remainder);
    end;

    local procedure CalculateEDRPOUCheckDigit(Value: Text): Integer
    var
        CodeValue: Integer;
        Remainder: Integer;
    begin
        if not Evaluate(CodeValue, Value) then
            Error('Код ЄДРПОУ повинен містити тільки цифри.');

        Remainder := CalculateEDRPOURemainder(Value, CodeValue, 0);
        if Remainder < 10 then
            exit(Remainder);

        Remainder := CalculateEDRPOURemainder(Value, CodeValue, 2);
        if Remainder < 10 then
            exit(Remainder);

        exit(0);
    end;

    local procedure CalculateEDRPOURemainder(Value: Text; CodeValue: Integer; WeightOffset: Integer): Integer
    var
        Position: Integer;
        WeightedSum: Integer;
    begin
        for Position := 1 to 7 do
            WeightedSum +=
                GetDigit(Value, Position) *
                GetEDRPOUWeight(Position, CodeValue, WeightOffset);

        exit(WeightedSum mod 11);
    end;

    local procedure GetRNOKPPWeight(Position: Integer): Integer
    begin
        case Position of
            1:
                exit(-1);
            2:
                exit(5);
            3:
                exit(7);
            4:
                exit(9);
            5:
                exit(4);
            6:
                exit(6);
            7:
                exit(10);
            8:
                exit(5);
            9:
                exit(7);
        end;

        Error('Неприпустима позиція цифри РНОКПП: %1.', Position);
    end;

    local procedure GetEDRPOUWeight(Position: Integer; CodeValue: Integer; WeightOffset: Integer): Integer
    begin
        if (CodeValue < 30000000) or (CodeValue > 60000000) then
            exit(Position + WeightOffset);

        case Position of
            1:
                exit(7 + WeightOffset);
            2:
                exit(1 + WeightOffset);
            3:
                exit(2 + WeightOffset);
            4:
                exit(3 + WeightOffset);
            5:
                exit(4 + WeightOffset);
            6:
                exit(5 + WeightOffset);
            7:
                exit(6 + WeightOffset);
        end;

        Error('Неприпустима позиція цифри коду ЄДРПОУ: %1.', Position);
    end;

    local procedure GetDigit(Value: Text; Position: Integer): Integer
    var
        Digit: Integer;
    begin
        if not Evaluate(Digit, CopyStr(Value, Position, 1)) then
            Error('Значення повинно містити тільки цифри 0–9.');

        exit(Digit);
    end;
}
