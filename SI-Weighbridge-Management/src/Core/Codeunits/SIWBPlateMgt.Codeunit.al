codeunit 59000 "SI WB Plate Mgt."
{
    procedure CanCorrectVehiclePlate(
        WeighingRecord: Record "SI Weighing Record"): Boolean
    begin
        exit(
            not IsPlausiblePlate(
                WeighingRecord."Source Vehicle Plate"));
    end;

    procedure CanCorrectTrailerPlate(
        WeighingRecord: Record "SI Weighing Record"): Boolean
    begin
        exit(
            not IsPlausiblePlate(
                WeighingRecord."Source Trailer Plate"));
    end;

    procedure ApplyCorrection(
        var WeighingRecord: Record "SI Weighing Record";
        NewVehiclePlate: Text[50];
        NewTrailerPlate: Text[50])
    var
        Changed: Boolean;
    begin
        NewVehiclePlate := NewVehiclePlate.Trim();
        NewTrailerPlate := NewTrailerPlate.Trim();
        // ------------------------------------------------------------
        // Vehicle
        // ------------------------------------------------------------

        if NewVehiclePlate <> WeighingRecord."Vehicle Plate" then begin
            if not CanCorrectVehiclePlate(WeighingRecord) then
                Error(
                    'Номер авто не можна виправити вручну, оскільки значення, отримане від камери "%1", має допустимий формат.',
                    WeighingRecord."Source Vehicle Plate");

            ValidateManualPlate(
                NewVehiclePlate,
                'номер авто');

            WeighingRecord."Vehicle Plate" := NewVehiclePlate;
            WeighingRecord."Vehicle Plate Source" :=
                "SI WB Plate Source"::Manual;

            WeighingRecord."Vehicle Plate Corrected At" :=
                CurrentDateTime();

            WeighingRecord."Vehicle Plate Corrected By" :=
                UserSecurityId();

            Changed := true;
        end;

        // ------------------------------------------------------------
        // Trailer
        // ------------------------------------------------------------

        if NewTrailerPlate <> WeighingRecord."Trailer Plate" then begin
            if not CanCorrectTrailerPlate(WeighingRecord) then
                Error(
                    'Номер причепа не можна виправити вручну, оскільки значення, отримане від камери "%1", має допустимий формат.',
                    WeighingRecord."Source Trailer Plate");

            ValidateManualPlate(
                NewTrailerPlate,
                'номер причепа');

            WeighingRecord."Trailer Plate" := NewTrailerPlate;
            WeighingRecord."Trailer Plate Source" :=
                "SI WB Plate Source"::Manual;

            WeighingRecord."Trailer Plate Corrected At" :=
                CurrentDateTime();

            WeighingRecord."Trailer Plate Corrected By" :=
                UserSecurityId();

            Changed := true;
        end;

        if Changed then
            WeighingRecord.Modify(true);
    end;

    procedure ValidateManualPlate(
        PlateValue: Text;
        FieldCaption: Text)
    begin
        if PlateValue = '' then
            Error(
                '%1 не може бути порожнім.',
                FieldCaption);

        if not IsPlausiblePlate(PlateValue) then
            Error(
                '%1 "%2" має недопустимий формат. Дозволені лише латинські або кириличні літери, цифри, пробіли та знак "-". Значення повинно містити хоча б одну літеру або цифру.',
                FieldCaption,
                PlateValue);
    end;

    procedure IsPlausiblePlate(PlateValue: Text): Boolean
    var
        Character: Char;
        Position: Integer;
        HasAlphaNumeric: Boolean;
    begin
        if PlateValue = '' then
            exit(false);

        for Position := 1 to StrLen(PlateValue) do begin
            Character := PlateValue[Position];

            if not IsAllowedPlateCharacter(Character) then
                exit(false);

            if IsLetter(Character) or IsDigit(Character) then
                HasAlphaNumeric := true;
        end;

        exit(HasAlphaNumeric);
    end;

    local procedure IsAllowedPlateCharacter(Character: Char): Boolean
    begin
        if IsLetter(Character) then
            exit(true);

        if IsDigit(Character) then
            exit(true);

        // Normal space
        if Character = 32 then
            exit(true);

        // Hyphen-minus "-"
        if Character = 45 then
            exit(true);

        exit(false);
    end;

    local procedure IsLetter(Character: Char): Boolean
    var
        CharacterCode: Integer;
    begin
        CharacterCode := Character;

        // Latin A-Z
        if (CharacterCode >= 65) and
           (CharacterCode <= 90)
        then
            exit(true);

        // Latin a-z
        if (CharacterCode >= 97) and
           (CharacterCode <= 122)
        then
            exit(true);

        // Cyrillic U+0400..U+0481
        //
        // Includes Ukrainian:
        // І і, Ї ї, Є є, Ґ ґ
        // as well as the standard Cyrillic alphabet.
        if (CharacterCode >= 1024) and
           (CharacterCode <= 1153)
        then
            exit(true);

        // Cyrillic letters U+048A..U+052F.
        //
        // U+0482..U+0489 are deliberately excluded:
        // these are a symbol and combining marks, not ordinary letters.
        if (CharacterCode >= 1162) and
           (CharacterCode <= 1327)
        then
            exit(true);

        exit(false);
    end;

    local procedure IsDigit(Character: Char): Boolean
    var
        CharacterCode: Integer;
    begin
        CharacterCode := Character;

        exit(
            (CharacterCode >= 48) and
            (CharacterCode <= 57));
    end;
}