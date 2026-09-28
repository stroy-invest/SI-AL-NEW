codeunit 53015 "SI ERP Variant No. Mgt."
{
    Permissions =
tabledata "Item Variant" = R,
        tabledata "SI ERP Variant No. Counter" = RIM;

    procedure GetNextCode(ItemNo: Code[20]): Code[10]
    var
        Counter: Record "SI ERP Variant No. Counter";
        ItemVariant: Record "Item Variant";
        MaxVariantNo: BigInteger;
        NextNo: BigInteger;
        VariantCode: Code[10];
    begin
        if ItemNo = '' then
            Error(ItemNoRequiredErr);

        MaxVariantNo := GetMaxVariantNo();

        Counter.LockTable();

        if Counter.Get(ItemNo) then
            NextNo := Counter."Last No."
        else begin
            Counter.Init();
            Counter."Item No." := ItemNo;
            Counter."Last No." := 0;
            Counter.Insert();
            NextNo := 0;
        end;

        repeat
            NextNo := NextNo + 1;

            if NextNo > MaxVariantNo then
                Error(VariantNoExhaustedErr, ItemNo);

            VariantCode := ToFixedHex(NextNo);
        until not ItemVariant.Get(ItemNo, VariantCode);

        Counter."Last No." := NextNo;
        Counter.Modify();

        exit(VariantCode);
    end;

    local procedure GetMaxVariantNo(): BigInteger
    var
        MaxVariantNo: BigInteger;
        Position: Integer;
    begin
        MaxVariantNo := 1;

        for Position := 1 to 10 do
            MaxVariantNo := MaxVariantNo * 16;

        exit(MaxVariantNo - 1);
    end;

    local procedure ToFixedHex(Value: BigInteger): Code[10]
    var
        Result: Text[10];
        HexDigits: Text[16];
        Digit: Integer;
        Position: Integer;
    begin
        Result := '0000000000';
        HexDigits := '0123456789ABCDEF';

        for Position := 10 downto 1 do begin
            Digit := Value mod 16;
            Result[Position] := HexDigits[Digit + 1];
            Value := Value div 16;
        end;

        exit(CopyStr(Result, 1, 10));
    end;

    var
        ItemNoRequiredErr: Label 'Для автоматичної нумерації варіанта не задано номер товару.';
        VariantNoExhaustedErr: Label 'Для товару %1 вичерпано діапазон 10-символьних hexadecimal-кодів варіантів.';
}
