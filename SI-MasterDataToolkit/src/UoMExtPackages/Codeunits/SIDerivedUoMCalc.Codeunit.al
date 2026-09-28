codeunit 58003 "SI Derived UoM Calc."
{
    procedure CalculateNumeratorQuantity(
        DerivedValue: Decimal;
        DerivedUoMCode: Code[10];
        DenominatorQuantity: Decimal;
        DenominatorUoMCode: Code[10];
        ResultUoMCode: Code[10]): Decimal
    var
        DerivedUoM: Record "Unit of Measure";
        UoMMgt: Codeunit "SI UoM Mgt.";
        NormalizedDenominatorQty: Decimal;
        ResultInNumeratorUoM: Decimal;
        SourceDenominatorUoMCode: Code[10];
        TargetNumeratorUoMCode: Code[10];
    begin
        LoadAndValidateDerivedUoM(DerivedUoMCode, DerivedUoM);

        SourceDenominatorUoMCode := DenominatorUoMCode;
        if SourceDenominatorUoMCode = '' then
            SourceDenominatorUoMCode := DerivedUoM."SI Denominator UoM Code";

        TargetNumeratorUoMCode := ResultUoMCode;
        if TargetNumeratorUoMCode = '' then
            TargetNumeratorUoMCode := DerivedUoM."SI Numerator UoM Code";

        NormalizedDenominatorQty := UoMMgt.ConvertQuantity(
            DenominatorQuantity,
            SourceDenominatorUoMCode,
            DerivedUoM."SI Denominator UoM Code");

        ResultInNumeratorUoM :=
            DerivedValue *
            NormalizedDenominatorQty *
            DerivedUoM."SI Numerator Quantity" /
            DerivedUoM."SI Denominator Quantity";

        exit(UoMMgt.ConvertQuantity(
            ResultInNumeratorUoM,
            DerivedUoM."SI Numerator UoM Code",
            TargetNumeratorUoMCode));
    end;

    procedure CalculateDenominatorQuantity(
        DerivedValue: Decimal;
        DerivedUoMCode: Code[10];
        NumeratorQuantity: Decimal;
        NumeratorUoMCode: Code[10];
        ResultUoMCode: Code[10]): Decimal
    var
        DerivedUoM: Record "Unit of Measure";
        UoMMgt: Codeunit "SI UoM Mgt.";
        NormalizedNumeratorQty: Decimal;
        ResultInDenominatorUoM: Decimal;
        SourceNumeratorUoMCode: Code[10];
        TargetDenominatorUoMCode: Code[10];
    begin
        if DerivedValue = 0 then
            Error(ZeroDerivedValueErr, DerivedUoMCode);

        LoadAndValidateDerivedUoM(DerivedUoMCode, DerivedUoM);

        SourceNumeratorUoMCode := NumeratorUoMCode;
        if SourceNumeratorUoMCode = '' then
            SourceNumeratorUoMCode := DerivedUoM."SI Numerator UoM Code";

        TargetDenominatorUoMCode := ResultUoMCode;
        if TargetDenominatorUoMCode = '' then
            TargetDenominatorUoMCode := DerivedUoM."SI Denominator UoM Code";

        NormalizedNumeratorQty := UoMMgt.ConvertQuantity(
            NumeratorQuantity,
            SourceNumeratorUoMCode,
            DerivedUoM."SI Numerator UoM Code");

        ResultInDenominatorUoM :=
            NormalizedNumeratorQty *
            DerivedUoM."SI Denominator Quantity" /
            (DerivedValue * DerivedUoM."SI Numerator Quantity");

        exit(UoMMgt.ConvertQuantity(
            ResultInDenominatorUoM,
            DerivedUoM."SI Denominator UoM Code",
            TargetDenominatorUoMCode));
    end;

    procedure GetNumeratorUoMCode(DerivedUoMCode: Code[10]): Code[10]
    var
        DerivedUoM: Record "Unit of Measure";
    begin
        LoadAndValidateDerivedUoM(DerivedUoMCode, DerivedUoM);
        exit(DerivedUoM."SI Numerator UoM Code");
    end;

    procedure GetDenominatorUoMCode(DerivedUoMCode: Code[10]): Code[10]
    var
        DerivedUoM: Record "Unit of Measure";
    begin
        LoadAndValidateDerivedUoM(DerivedUoMCode, DerivedUoM);
        exit(DerivedUoM."SI Denominator UoM Code");
    end;

    local procedure LoadAndValidateDerivedUoM(
        DerivedUoMCode: Code[10];
        var DerivedUoM: Record "Unit of Measure")
    var
        UoMMgt: Codeunit "SI UoM Mgt.";
    begin
        if DerivedUoMCode = '' then
            Error(DerivedUoMRequiredErr);

        if not DerivedUoM.Get(DerivedUoMCode) then
            Error(DerivedUoMNotFoundErr, DerivedUoMCode);

        DerivedUoM.TestField("SI Blocked", false);

        if DerivedUoM."SI UoM Kind" <> DerivedUoM."SI UoM Kind"::Derived then
            Error(NotDerivedUoMErr, DerivedUoMCode);

        UoMMgt.ValidateUoM(DerivedUoM);
    end;

    var
        DerivedUoMRequiredErr: Label 'Не задано код похідної одиниці вимірювання.';
        DerivedUoMNotFoundErr: Label 'Похідну одиницю вимірювання %1 не знайдено.';
        NotDerivedUoMErr: Label 'Одиниця вимірювання %1 не є похідною.';
        ZeroDerivedValueErr: Label 'Значення похідної величини для %1 не може дорівнювати нулю під час зворотного розрахунку.';
}
