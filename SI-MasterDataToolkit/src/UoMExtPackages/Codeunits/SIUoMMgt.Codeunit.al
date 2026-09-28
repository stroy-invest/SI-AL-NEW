codeunit 58000 "SI UoM Mgt."
{
    procedure ValidateUoM(var UnitOfMeasure: Record "Unit of Measure")
    begin
        UnitOfMeasure.TestField("SI UoM Kind");

        case UnitOfMeasure."SI UoM Kind" of
            UnitOfMeasure."SI UoM Kind"::Base:
                ValidateBase(UnitOfMeasure);

            UnitOfMeasure."SI UoM Kind"::Scaled:
                ValidateScaled(UnitOfMeasure);

            UnitOfMeasure."SI UoM Kind"::Derived:
                ValidateDerived(UnitOfMeasure);

            UnitOfMeasure."SI UoM Kind"::Packaging:
                ValidatePackaging(UnitOfMeasure);
        end;
    end;

    procedure HandleKindChange(var UnitOfMeasure: Record "Unit of Measure")
    begin
        case UnitOfMeasure."SI UoM Kind" of
            UnitOfMeasure."SI UoM Kind"::" ",
            UnitOfMeasure."SI UoM Kind"::Base,
            UnitOfMeasure."SI UoM Kind"::Packaging:
                begin
                    Clear(UnitOfMeasure."SI Reference UoM Code");
                    Clear(UnitOfMeasure."SI Conversion Factor");
                    Clear(UnitOfMeasure."SI Numerator UoM Code");
                    Clear(UnitOfMeasure."SI Numerator Quantity");
                    Clear(UnitOfMeasure."SI Denominator UoM Code");
                    Clear(UnitOfMeasure."SI Denominator Quantity");
                end;

            UnitOfMeasure."SI UoM Kind"::Scaled:
                begin
                    Clear(UnitOfMeasure."SI Numerator UoM Code");
                    Clear(UnitOfMeasure."SI Numerator Quantity");
                    Clear(UnitOfMeasure."SI Denominator UoM Code");
                    Clear(UnitOfMeasure."SI Denominator Quantity");
                end;

            UnitOfMeasure."SI UoM Kind"::Derived:
                begin
                    Clear(UnitOfMeasure."SI Reference UoM Code");
                    Clear(UnitOfMeasure."SI Conversion Factor");

                    if UnitOfMeasure."SI Numerator Quantity" <= 0 then
                        UnitOfMeasure."SI Numerator Quantity" := 1;
                    if UnitOfMeasure."SI Denominator Quantity" <= 0 then
                        UnitOfMeasure."SI Denominator Quantity" := 1;
                end;
        end;
    end;

    procedure ValidateItemAttributeUoM(var ItemAttribute: Record "Item Attribute")
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if ItemAttribute."SI UoM Code" = '' then begin
            ItemAttribute."Unit of Measure" := '';
            exit;
        end;

        UnitOfMeasure.Get(ItemAttribute."SI UoM Code");
        UnitOfMeasure.TestField("SI Blocked", false);
        UnitOfMeasure.TestField("SI UoM Kind");

        ItemAttribute."Unit of Measure" := GetDisplaySymbol(UnitOfMeasure);
    end;

    procedure GetDisplaySymbol(UnitOfMeasure: Record "Unit of Measure"): Text[30]
    begin
        if UnitOfMeasure."SI Symbol" <> '' then
            exit(UnitOfMeasure."SI Symbol");

        if UnitOfMeasure."International Standard Code" <> '' then
            exit(UnitOfMeasure."International Standard Code");

        exit(UnitOfMeasure.Code);
    end;

    procedure GetRootBaseUoMCode(UoMCode: Code[10]): Code[10]
    begin
        exit(GetRootBaseUoMCodeInternal(UoMCode, 0));
    end;

    procedure GetFactorToRootBase(UoMCode: Code[10]): Decimal
    begin
        exit(GetFactorToRootBaseInternal(UoMCode, 0));
    end;

    procedure ConvertQuantity(Quantity: Decimal; FromUoMCode: Code[10]; ToUoMCode: Code[10]): Decimal
    var
        FromRootCode: Code[10];
        ToRootCode: Code[10];
        FromFactor: Decimal;
        ToFactor: Decimal;
    begin
        if Quantity = 0 then
            exit(0);

        FromRootCode := GetRootBaseUoMCode(FromUoMCode);
        ToRootCode := GetRootBaseUoMCode(ToUoMCode);

        if FromRootCode <> ToRootCode then
            Error(
                'Одиниці вимірювання %1 і %2 належать до різних базових груп і не можуть бути перераховані.',
                FromUoMCode,
                ToUoMCode);

        FromFactor := GetFactorToRootBase(FromUoMCode);
        ToFactor := GetFactorToRootBase(ToUoMCode);

        exit(Quantity * FromFactor / ToFactor);
    end;

    procedure ConvertQuantityWithDerivedValue(
        Quantity: Decimal;
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
        DerivedValue: Decimal;
        DerivedUoMCode: Code[10]): Decimal
    var
        DerivedUoM: Record "Unit of Measure";
        DerivedUoMCalc: Codeunit "SI Derived UoM Calc.";
    begin
        if Quantity = 0 then
            exit(0);

        if AreConvertible(FromUoMCode, ToUoMCode) then
            exit(ConvertQuantity(Quantity, FromUoMCode, ToUoMCode));

        if DerivedValue = 0 then
            Error(
                'Значення похідної величини %1 не може дорівнювати нулю для перерахунку %2 → %3.',
                DerivedUoMCode,
                FromUoMCode,
                ToUoMCode);

        if not DerivedUoM.Get(DerivedUoMCode) then
            Error('Похідну одиницю вимірювання %1 не знайдено.', DerivedUoMCode);

        ValidateUoM(DerivedUoM);

        if AreConvertible(FromUoMCode, DerivedUoM."SI Denominator UoM Code") and
           AreConvertible(ToUoMCode, DerivedUoM."SI Numerator UoM Code")
        then
            exit(DerivedUoMCalc.CalculateNumeratorQuantity(
                DerivedValue,
                DerivedUoMCode,
                Quantity,
                FromUoMCode,
                ToUoMCode));

        if AreConvertible(FromUoMCode, DerivedUoM."SI Numerator UoM Code") and
           AreConvertible(ToUoMCode, DerivedUoM."SI Denominator UoM Code")
        then
            exit(DerivedUoMCalc.CalculateDenominatorQuantity(
                DerivedValue,
                DerivedUoMCode,
                Quantity,
                FromUoMCode,
                ToUoMCode));

        Error(
            'Похідна одиниця %1 не описує перерахунок між %2 та %3.',
            DerivedUoMCode,
            FromUoMCode,
            ToUoMCode);
    end;

    procedure CanConvertQuantityWithDerivedUoM(
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
        DerivedUoMCode: Code[10]): Boolean
    var
        DerivedUoM: Record "Unit of Measure";
    begin
        if (FromUoMCode = '') or (ToUoMCode = '') or (DerivedUoMCode = '') then
            exit(false);

        if AreConvertible(FromUoMCode, ToUoMCode) then
            exit(true);

        if not DerivedUoM.Get(DerivedUoMCode) then
            exit(false);

        if DerivedUoM."SI Blocked" then
            exit(false);

        if DerivedUoM."SI UoM Kind" <> DerivedUoM."SI UoM Kind"::Derived then
            exit(false);

        exit(
            (AreConvertible(FromUoMCode, DerivedUoM."SI Denominator UoM Code") and
             AreConvertible(ToUoMCode, DerivedUoM."SI Numerator UoM Code")) or
            (AreConvertible(FromUoMCode, DerivedUoM."SI Numerator UoM Code") and
             AreConvertible(ToUoMCode, DerivedUoM."SI Denominator UoM Code")));
    end;

    procedure AreConvertible(UoMCode1: Code[10]; UoMCode2: Code[10]): Boolean
    var
        RootCode1: Code[10];
        RootCode2: Code[10];
    begin
        if (UoMCode1 = '') or (UoMCode2 = '') then
            exit(false);

        if not TryGetRootBaseUoMCode(UoMCode1, RootCode1) then
            exit(false);

        if not TryGetRootBaseUoMCode(UoMCode2, RootCode2) then
            exit(false);

        exit(RootCode1 = RootCode2);
    end;

    [TryFunction]
    procedure TryGetRootBaseUoMCode(UoMCode: Code[10]; var RootCode: Code[10])
    begin
        RootCode := GetRootBaseUoMCode(UoMCode);
    end;

    procedure GetUoMSetupWarning(UoMCode: Code[10]): Text
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UoMCode = '' then
            exit('');

        if not UnitOfMeasure.Get(UoMCode) then
            exit(StrSubstNo('Одиницю вимірювання %1 не знайдено.', UoMCode));

        if UnitOfMeasure."SI UoM Kind" = UnitOfMeasure."SI UoM Kind"::" " then
            exit(StrSubstNo(
                'Для одиниці вимірювання %1 не визначено тип. Задайте тип одиниці вимірювання.',
                UoMCode));

        if UnitOfMeasure."SI UoM Kind" = UnitOfMeasure."SI UoM Kind"::Scaled then
            if (UnitOfMeasure."SI Reference UoM Code" = '') or
               (UnitOfMeasure."SI Conversion Factor" <= 0)
            then
                exit(StrSubstNo(
                    'Одиниця вимірювання %1 є масштабованою, але для неї не налаштовано базову одиницю або коефіцієнт перерахунку. Для роботи з пакованнями заповніть ці параметри.',
                    UoMCode));

        if UnitOfMeasure."SI UoM Kind" = UnitOfMeasure."SI UoM Kind"::Derived then
            exit(StrSubstNo(
                'Одиниця вимірювання %1 є похідною. Похідну одиницю не слід використовувати як базову кількісну одиницю товару.',
                UoMCode));

        if UnitOfMeasure."SI UoM Kind" = UnitOfMeasure."SI UoM Kind"::Packaging then
            exit(StrSubstNo(
                'Одиниця вимірювання %1 є пакувальною. Її коефіцієнт визначається окремо для конкретного товару, тому її не слід використовувати як базову одиницю товару.',
                UoMCode));

        exit('');
    end;

    local procedure GetRootBaseUoMCodeInternal(UoMCode: Code[10]; Depth: Integer): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if Depth > 20 then
            Error('Виявлено циклічний або надто довгий ланцюжок перерахунку одиниць вимірювання.');

        UnitOfMeasure.Get(UoMCode);
        UnitOfMeasure.TestField("SI Blocked", false);
        UnitOfMeasure.TestField("SI UoM Kind");

        case UnitOfMeasure."SI UoM Kind" of
            UnitOfMeasure."SI UoM Kind"::Base:
                exit(UnitOfMeasure.Code);

            UnitOfMeasure."SI UoM Kind"::Scaled:
                begin
                    ValidateScaled(UnitOfMeasure);
                    exit(GetRootBaseUoMCodeInternal(UnitOfMeasure."SI Reference UoM Code", Depth + 1));
                end;

            UnitOfMeasure."SI UoM Kind"::Derived:
                Error(
                    'Одиниця вимірювання %1 є похідною і не підтримує прямий кількісний перерахунок.',
                    UnitOfMeasure.Code);

            UnitOfMeasure."SI UoM Kind"::Packaging:
                Error(
                    'Одиниця вимірювання %1 є пакувальною. Її коефіцієнт визначається на рівні конкретного товару.',
                    UnitOfMeasure.Code);
        end;
    end;

    local procedure GetFactorToRootBaseInternal(UoMCode: Code[10]; Depth: Integer): Decimal
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if Depth > 20 then
            Error('Виявлено циклічний або надто довгий ланцюжок перерахунку одиниць вимірювання.');

        UnitOfMeasure.Get(UoMCode);
        UnitOfMeasure.TestField("SI Blocked", false);
        UnitOfMeasure.TestField("SI UoM Kind");

        case UnitOfMeasure."SI UoM Kind" of
            UnitOfMeasure."SI UoM Kind"::Base:
                exit(1);

            UnitOfMeasure."SI UoM Kind"::Scaled:
                begin
                    ValidateScaled(UnitOfMeasure);
                    exit(
                        UnitOfMeasure."SI Conversion Factor" *
                        GetFactorToRootBaseInternal(UnitOfMeasure."SI Reference UoM Code", Depth + 1));
                end;

            UnitOfMeasure."SI UoM Kind"::Derived:
                Error(
                    'Одиниця вимірювання %1 є похідною і не підтримує прямий кількісний перерахунок.',
                    UnitOfMeasure.Code);

            UnitOfMeasure."SI UoM Kind"::Packaging:
                Error(
                    'Одиниця вимірювання %1 є пакувальною. Її коефіцієнт визначається на рівні конкретного товару.',
                    UnitOfMeasure.Code);
        end;
    end;

    local procedure ValidateBase(UnitOfMeasure: Record "Unit of Measure")
    begin
        UnitOfMeasure.TestField("SI Reference UoM Code", '');
        UnitOfMeasure.TestField("SI Conversion Factor", 0);
        UnitOfMeasure.TestField("SI Numerator UoM Code", '');
        UnitOfMeasure.TestField("SI Numerator Quantity", 0);
        UnitOfMeasure.TestField("SI Denominator UoM Code", '');
        UnitOfMeasure.TestField("SI Denominator Quantity", 0);
    end;

    local procedure ValidateScaled(UnitOfMeasure: Record "Unit of Measure")
    var
        ReferenceUoM: Record "Unit of Measure";
    begin
        UnitOfMeasure.TestField("SI Reference UoM Code");
        UnitOfMeasure.TestField("SI Conversion Factor");

        if UnitOfMeasure."SI Conversion Factor" <= 0 then
            Error('Коефіцієнт перерахунку для масштабованої одиниці має бути більшим за нуль.');

        if UnitOfMeasure.Code = UnitOfMeasure."SI Reference UoM Code" then
            Error('Одиниця вимірювання не може посилатися сама на себе.');

        ReferenceUoM.Get(UnitOfMeasure."SI Reference UoM Code");
        ReferenceUoM.TestField("SI Blocked", false);

        if ReferenceUoM."SI UoM Kind" in
           [ReferenceUoM."SI UoM Kind"::Derived, ReferenceUoM."SI UoM Kind"::Packaging]
        then
            Error('Масштабована одиниця не може посилатися на похідну або пакувальну одиницю вимірювання.');

        UnitOfMeasure.TestField("SI Numerator UoM Code", '');
        UnitOfMeasure.TestField("SI Numerator Quantity", 0);
        UnitOfMeasure.TestField("SI Denominator UoM Code", '');
        UnitOfMeasure.TestField("SI Denominator Quantity", 0);
    end;

    local procedure ValidateDerived(UnitOfMeasure: Record "Unit of Measure")
    var
        NumeratorUoM: Record "Unit of Measure";
        DenominatorUoM: Record "Unit of Measure";
    begin
        UnitOfMeasure.TestField("SI Numerator UoM Code");
        UnitOfMeasure.TestField("SI Numerator Quantity");
        UnitOfMeasure.TestField("SI Denominator UoM Code");
        UnitOfMeasure.TestField("SI Denominator Quantity");

        if UnitOfMeasure."SI Numerator Quantity" <= 0 then
            Error('Кількість чисельника має бути більшою за нуль.');

        if UnitOfMeasure."SI Denominator Quantity" <= 0 then
            Error('Кількість знаменника має бути більшою за нуль.');

        UnitOfMeasure.TestField("SI Reference UoM Code", '');
        UnitOfMeasure.TestField("SI Conversion Factor", 0);

        if UnitOfMeasure.Code = UnitOfMeasure."SI Numerator UoM Code" then
            Error('Одиниця вимірювання не може використовувати саму себе як чисельник.');

        if UnitOfMeasure.Code = UnitOfMeasure."SI Denominator UoM Code" then
            Error('Одиниця вимірювання не може використовувати саму себе як знаменник.');

        if UnitOfMeasure."SI Numerator UoM Code" = UnitOfMeasure."SI Denominator UoM Code" then
            Error('Чисельник і знаменник похідної одиниці не можуть бути однаковими.');

        NumeratorUoM.Get(UnitOfMeasure."SI Numerator UoM Code");
        NumeratorUoM.TestField("SI Blocked", false);
        NumeratorUoM.TestField("SI UoM Kind");
        if NumeratorUoM."SI UoM Kind" in
           [NumeratorUoM."SI UoM Kind"::Derived, NumeratorUoM."SI UoM Kind"::Packaging]
        then
            Error('Одиниця чисельника %1 має бути базовою або масштабованою.', NumeratorUoM.Code);

        DenominatorUoM.Get(UnitOfMeasure."SI Denominator UoM Code");
        DenominatorUoM.TestField("SI Blocked", false);
        DenominatorUoM.TestField("SI UoM Kind");
        if DenominatorUoM."SI UoM Kind" in
           [DenominatorUoM."SI UoM Kind"::Derived, DenominatorUoM."SI UoM Kind"::Packaging]
        then
            Error('Одиниця знаменника %1 має бути базовою або масштабованою.', DenominatorUoM.Code);
    end;

    local procedure ValidatePackaging(UnitOfMeasure: Record "Unit of Measure")
    begin
        UnitOfMeasure.TestField("SI Reference UoM Code", '');
        UnitOfMeasure.TestField("SI Conversion Factor", 0);
        UnitOfMeasure.TestField("SI Numerator UoM Code", '');
        UnitOfMeasure.TestField("SI Numerator Quantity", 0);
        UnitOfMeasure.TestField("SI Denominator UoM Code", '');
        UnitOfMeasure.TestField("SI Denominator Quantity", 0);
    end;
}
