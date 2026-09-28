codeunit 59101 "SI WB UoM Conversion Mgt."
{

    procedure RecalculateLine(
        var WeighbridgeLine: Record "SI Weighbridge Document Line")
    var
        Item: Record Item;
        ResultQuantity: Decimal;
        ErrorText: Text;
    begin
        WeighbridgeLine.EnsureWeightUoM();

        WeighbridgeLine.ClearCalculatedValues();

        if WeighbridgeLine."Item No." = '' then
            exit;

        if not Item.Get(WeighbridgeLine."Item No.") then begin
            SetLineConversionError(
                WeighbridgeLine,
                StrSubstNo(
                    'Товар %1 не знайдено.',
                    WeighbridgeLine."Item No."));
            exit;
        end;

        if Item."Base Unit of Measure" = '' then begin
            SetLineConversionError(
                WeighbridgeLine,
                StrSubstNo(
                    'Для товару %1 не задано базову одиницю виміру.',
                    Item.Description));
            exit;
        end;

        WeighbridgeLine."Unit of Measure Code" :=
            Item."Base Unit of Measure";

        // ============================================================
        // 1. DIRECT / SCALED UOM
        // ============================================================

        if TryDirectConversion(
            WeighbridgeLine."Allocated Weight",
            WeighbridgeLine."Weight UoM Code",
            Item."Base Unit of Measure",
            ResultQuantity)
        then begin
            SetLineConversionSuccess(
                WeighbridgeLine,
                ResultQuantity,
                Item."Base Unit of Measure");

            SetLineDirectConversionProvenance(
                WeighbridgeLine,
                WeighbridgeLine."Weight UoM Code",
                Item."Base Unit of Measure");

            exit;
        end;

        // ============================================================
        // 2. ITEM ATTRIBUTE
        // ============================================================

        Clear(ErrorText);

        if TryResolveLineFromItemAttributes(
            WeighbridgeLine,
            Item."Base Unit of Measure",
            ResultQuantity,
            ErrorText)
        then begin
            SetLineConversionSuccess(
                WeighbridgeLine,
                ResultQuantity,
                Item."Base Unit of Measure");

            exit;
        end;

        if ErrorText <> '' then begin
            SetLineConversionError(
                WeighbridgeLine,
                ErrorText);

            exit;
        end;

        // ============================================================
        // 3. PRODUCT CONFIGURATOR SEMANTIC VALUE
        // ============================================================

        Clear(ErrorText);

        if TryResolveLineFromProductConfiguration(
            WeighbridgeLine,
            Item."Base Unit of Measure",
            ResultQuantity,
            ErrorText)
        then begin
            SetLineConversionSuccess(
                WeighbridgeLine,
                ResultQuantity,
                Item."Base Unit of Measure");

            exit;
        end;

        if ErrorText <> '' then begin
            SetLineConversionError(
                WeighbridgeLine,
                ErrorText);

            exit;
        end;

        // ============================================================
        // 4. NO CONVERSION PATH
        // ============================================================

        SetLineConversionError(
            WeighbridgeLine,
            StrSubstNo(
                'Вибраний товар має одиницю виміру %1, не пов''язану з одиницею виміру вагового комплексу (%2). ' +
                'Зазначте кратність базової одиниці товару до %2 або задайте фізичний параметр товару ' +
                '(питому вагу, густину, насипну щільність тощо) з похідною одиницею виміру.',
                Item."Base Unit of Measure",
                WeighbridgeLine."Weight UoM Code"));
    end;

    local procedure TryDirectConversion(
        SourceQuantity: Decimal;
        SourceUoMCode: Code[10];
        TargetUoMCode: Code[10];
        var ResultQuantity: Decimal): Boolean
    var
        UoMMgt: Codeunit "SI UoM Mgt.";
    begin
        if not UoMMgt.AreConvertible(
            SourceUoMCode,
            TargetUoMCode)
        then
            exit(false);

        ClearLastError();

        if not TryConvertQuantity(
            SourceQuantity,
            SourceUoMCode,
            TargetUoMCode,
            ResultQuantity)
        then
            exit(false);

        exit(true);
    end;

    [TryFunction]
    local procedure TryConvertQuantity(
        SourceQuantity: Decimal;
        SourceUoMCode: Code[10];
        TargetUoMCode: Code[10];
        var ResultQuantity: Decimal)
    var
        UoMMgt: Codeunit "SI UoM Mgt.";
    begin
        ResultQuantity :=
            UoMMgt.ConvertQuantity(
                SourceQuantity,
                SourceUoMCode,
                TargetUoMCode);
    end;

    local procedure EvaluateAttributeCandidate(
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        SourceUoMCode: Code[10];
        TargetUoMCode: Code[10];
        var CandidateDerivedUoMCode: Code[10];
        var CandidateValue: Decimal;
        var CandidateSourceIsNumerator: Boolean;
        var CandidateCount: Integer;
        var CandidateSourceDescription: Text[150])
    var
        DerivedUoM: Record "Unit of Measure";
        AttributeNumericValue: Decimal;
        SourceIsNumerator: Boolean;
    begin
        if ItemAttribute."SI UoM Code" = '' then
            exit;

        if not DerivedUoM.Get(
            ItemAttribute."SI UoM Code")
        then
            exit;

        if DerivedUoM."SI Blocked" then
            exit;

        if DerivedUoM."SI UoM Kind" <>
           DerivedUoM."SI UoM Kind"::Derived
        then
            exit;

        AttributeNumericValue :=
            ItemAttributeValue."Numeric Value";

        if AttributeNumericValue <= 0 then
            exit;

        if not IsDerivedBridge(
            DerivedUoM,
            SourceUoMCode,
            TargetUoMCode,
            SourceIsNumerator)
        then
            exit;

        CandidateCount += 1;

        if CandidateCount = 1 then begin
            CandidateDerivedUoMCode :=
                ItemAttribute."SI UoM Code";

            CandidateValue :=
                AttributeNumericValue;

            CandidateSourceIsNumerator :=
                SourceIsNumerator;

            CandidateSourceDescription :=
                CopyStr(
                    StrSubstNo(
                        'Атрибут товару «%1»',
                        ItemAttribute.Name),
                    1,
                    MaxStrLen(CandidateSourceDescription));
        end;
    end;

    // ================================================================
    // PRODUCT CONFIGURATOR
    // ================================================================

    local procedure TryResolveLineFromProductConfiguration(
        var WeighbridgeLine: Record "SI Weighbridge Document Line";
        TargetUoMCode: Code[10];
        var ResultQuantity: Decimal;
        var ErrorText: Text): Boolean
    var
        CandidateDerivedUoMCode: Code[10];
        CandidateValue: Decimal;
        CandidateSourceIsNumerator: Boolean;
        CandidateCount: Integer;
        CandidateSourceDescription: Text[150];
    begin
        FindLineProductConfigurationCandidates(
            WeighbridgeLine,
            TargetUoMCode,
            CandidateDerivedUoMCode,
            CandidateValue,
            CandidateSourceIsNumerator,
            CandidateCount,
            CandidateSourceDescription);

        if CandidateCount = 0 then
            exit(false);

        if CandidateCount > 1 then begin
            ErrorText :=
                StrSubstNo(
                    'Для товару знайдено декілька параметрів конфігурації, які можуть використовуватися для перерахунку %1 у %2. ' +
                    'Перевірте конфігурацію товару або варіанта.',
                    WeighbridgeLine."Weight UoM Code",
                    TargetUoMCode);

            exit(false);
        end;

        if not CalculateDerivedResult(
            CandidateValue,
            CandidateDerivedUoMCode,
            CandidateSourceIsNumerator,
            WeighbridgeLine."Allocated Weight",
            WeighbridgeLine."Weight UoM Code",
            TargetUoMCode,
            ResultQuantity,
            ErrorText)
        then
            exit(false);

        SetLineDerivedConversionProvenance(
            WeighbridgeLine,
            'PRODUCT_CONFIG',
            CandidateSourceDescription,
            CandidateValue,
            CandidateDerivedUoMCode);

        exit(true);
    end;

    local procedure FindLineProductConfigurationCandidates(
        WeighbridgeLine: Record "SI Weighbridge Document Line";
        TargetUoMCode: Code[10];
        var CandidateDerivedUoMCode: Code[10];
        var CandidateValue: Decimal;
        var CandidateSourceIsNumerator: Boolean;
        var CandidateCount: Integer;
        var CandidateSourceDescription: Text[150])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemConfigurationNo: Code[20];
        VariantConfigurationNo: Code[20];
    begin
        CandidateCount := 0;

        if WeighbridgeLine."Variant Code" <> '' then begin
            if ItemVariant.Get(
                WeighbridgeLine."Item No.",
                WeighbridgeLine."Variant Code")
            then begin
                ItemVariant.CalcFields(
                    "SI Configuration No.",
                    "SI Item Configuration No.");

                VariantConfigurationNo :=
                    ItemVariant."SI Configuration No.";

                ItemConfigurationNo :=
                    ItemVariant."SI Item Configuration No.";
            end;
        end else
            if Item.Get(WeighbridgeLine."Item No.") then begin
                Item.CalcFields("SI Configuration No.");

                ItemConfigurationNo :=
                    Item."SI Configuration No.";
            end;

        if VariantConfigurationNo <> '' then
            FindCandidatesInConfiguration(
                VariantConfigurationNo,
                WeighbridgeLine."Weight UoM Code",
                TargetUoMCode,
                CandidateDerivedUoMCode,
                CandidateValue,
                CandidateSourceIsNumerator,
                CandidateCount,
                CandidateSourceDescription);

        if (ItemConfigurationNo <> '') and
        (ItemConfigurationNo <> VariantConfigurationNo)
        then
            FindCandidatesInConfiguration(
                ItemConfigurationNo,
                WeighbridgeLine."Weight UoM Code",
                TargetUoMCode,
                CandidateDerivedUoMCode,
                CandidateValue,
                CandidateSourceIsNumerator,
                CandidateCount,
                CandidateSourceDescription);
    end;

    local procedure FindCandidatesInConfiguration(
        ConfigurationNo: Code[20];
        SourceUoMCode: Code[10];
        TargetUoMCode: Code[10];
        var CandidateDerivedUoMCode: Code[10];
        var CandidateValue: Decimal;
        var CandidateSourceIsNumerator: Boolean;
        var CandidateCount: Integer;
        var CandidateSourceDescription: Text[150])
    var
        ConfigValue: Record "SI Product Config. Value";
        ParameterValue: Record "SI Parameter Value";
    begin
        ConfigValue.Reset();

        ConfigValue.SetRange(
            "Configuration No.",
            ConfigurationNo);

        ConfigValue.SetRange(
            "Value Type",
            ConfigValue."Value Type"::"Controlled Value");

        ConfigValue.SetFilter(
            "Parameter Value Code",
            '<>%1',
            '');

        if not ConfigValue.FindSet() then
            exit;

        repeat
            if ParameterValue.Get(
                ConfigValue."Parameter Code",
                ConfigValue."Parameter Value Code")
            then
                EvaluateParameterValueCandidate(
                    ConfigValue,
                    ParameterValue,
                    SourceUoMCode,
                    TargetUoMCode,
                    CandidateDerivedUoMCode,
                    CandidateValue,
                    CandidateSourceIsNumerator,
                    CandidateCount,
                    CandidateSourceDescription);

        until ConfigValue.Next() = 0;
    end;

    local procedure EvaluateParameterValueCandidate(
        ConfigValue: Record "SI Product Config. Value";
        ParameterValue: Record "SI Parameter Value";
        SourceUoMCode: Code[10];
        TargetUoMCode: Code[10];
        var CandidateDerivedUoMCode: Code[10];
        var CandidateValue: Decimal;
        var CandidateSourceIsNumerator: Boolean;
        var CandidateCount: Integer;
        var CandidateSourceDescription: Text[150])
    var
        ProductParameter: Record "SI Product Parameter";
        DerivedUoM: Record "Unit of Measure";
        SourceIsNumerator: Boolean;
        ParameterDescription: Text[100];
    begin
        if ParameterValue.Blocked then
            exit;

        if ParameterValue."Numeric Value" <= 0 then
            exit;

        if ParameterValue."Numeric UoM Code" = '' then
            exit;

        if not DerivedUoM.Get(
            ParameterValue."Numeric UoM Code")
        then
            exit;

        if DerivedUoM."SI Blocked" then
            exit;

        if DerivedUoM."SI UoM Kind" <>
           DerivedUoM."SI UoM Kind"::Derived
        then
            exit;

        if not IsDerivedBridge(
            DerivedUoM,
            SourceUoMCode,
            TargetUoMCode,
            SourceIsNumerator)
        then
            exit;

        CandidateCount += 1;

        if CandidateCount = 1 then begin
            CandidateDerivedUoMCode :=
                ParameterValue."Numeric UoM Code";

            CandidateValue :=
                ParameterValue."Numeric Value";

            CandidateSourceIsNumerator :=
                SourceIsNumerator;

            if ProductParameter.Get(
                ConfigValue."Parameter Code")
            then
                ParameterDescription :=
                    ProductParameter.Description;

            if ParameterDescription = '' then
                ParameterDescription :=
                    ConfigValue."Parameter Code";

            CandidateSourceDescription :=
                CopyStr(
                    StrSubstNo(
                        'Параметр конфігурації «%1»',
                        ParameterDescription),
                    1,
                    MaxStrLen(CandidateSourceDescription));
        end;
    end;

    // ================================================================
    // DERIVED UOM COMMON LOGIC

    local procedure IsDerivedBridge(
        DerivedUoM: Record "Unit of Measure";
        SourceUoMCode: Code[10];
        TargetUoMCode: Code[10];
        var SourceIsNumerator: Boolean): Boolean
    var
        UoMMgt: Codeunit "SI UoM Mgt.";
    begin
        // Example:
        //   KG/M3
        //   source KG = numerator
        //   target M3 = denominator
        if UoMMgt.AreConvertible(
            SourceUoMCode,
            DerivedUoM."SI Numerator UoM Code")
        and
           UoMMgt.AreConvertible(
            TargetUoMCode,
            DerivedUoM."SI Denominator UoM Code")
        then begin
            SourceIsNumerator := true;
            exit(true);
        end;

        // Reverse case:
        // source corresponds to denominator,
        // target corresponds to numerator.
        if UoMMgt.AreConvertible(
            SourceUoMCode,
            DerivedUoM."SI Denominator UoM Code")
        and
           UoMMgt.AreConvertible(
            TargetUoMCode,
            DerivedUoM."SI Numerator UoM Code")
        then begin
            SourceIsNumerator := false;
            exit(true);
        end;

        exit(false);
    end;

    local procedure CalculateDerivedResult(
        DerivedValue: Decimal;
        DerivedUoMCode: Code[10];
        SourceIsNumerator: Boolean;
        SourceQuantity: Decimal;
        SourceUoMCode: Code[10];
        TargetUoMCode: Code[10];
        var ResultQuantity: Decimal;
        var ErrorText: Text): Boolean
    begin
        ClearLastError();

        if SourceIsNumerator then begin
            if not TryCalculateDenominatorQuantity(
                DerivedValue,
                DerivedUoMCode,
                SourceQuantity,
                SourceUoMCode,
                TargetUoMCode,
                ResultQuantity)
            then begin
                ErrorText :=
                    GetLastErrorText();

                exit(false);
            end;
        end else begin
            if not TryCalculateNumeratorQuantity(
                DerivedValue,
                DerivedUoMCode,
                SourceQuantity,
                SourceUoMCode,
                TargetUoMCode,
                ResultQuantity)
            then begin
                ErrorText :=
                    GetLastErrorText();

                exit(false);
            end;
        end;

        exit(true);
    end;

    [TryFunction]
    local procedure TryCalculateDenominatorQuantity(
        DerivedValue: Decimal;
        DerivedUoMCode: Code[10];
        NumeratorQuantity: Decimal;
        NumeratorUoMCode: Code[10];
        ResultUoMCode: Code[10];
        var ResultQuantity: Decimal)
    var
        DerivedCalc: Codeunit "SI Derived UoM Calc.";
    begin
        ResultQuantity :=
            DerivedCalc.CalculateDenominatorQuantity(
                DerivedValue,
                DerivedUoMCode,
                NumeratorQuantity,
                NumeratorUoMCode,
                ResultUoMCode);
    end;

    [TryFunction]
    local procedure TryCalculateNumeratorQuantity(
        DerivedValue: Decimal;
        DerivedUoMCode: Code[10];
        DenominatorQuantity: Decimal;
        DenominatorUoMCode: Code[10];
        ResultUoMCode: Code[10];
        var ResultQuantity: Decimal)
    var
        DerivedCalc: Codeunit "SI Derived UoM Calc.";
    begin
        ResultQuantity :=
            DerivedCalc.CalculateNumeratorQuantity(
                DerivedValue,
                DerivedUoMCode,
                DenominatorQuantity,
                DenominatorUoMCode,
                ResultUoMCode);
    end;

    // ================================================================
    // RESULT / STATUS

    local procedure SetLineConversionError(
        var WeighbridgeLine: Record "SI Weighbridge Document Line";
        ErrorText: Text)
    begin
        Clear(WeighbridgeLine.Quantity);

        WeighbridgeLine."UoM Error Text" :=
            CopyStr(
                ErrorText,
                1,
                MaxStrLen(
                    WeighbridgeLine."UoM Error Text"));
    end;

    local procedure SetLineConversionSuccess(
        var WeighbridgeLine: Record "SI Weighbridge Document Line";
        ResultQuantity: Decimal;
        TargetUoMCode: Code[10])
    begin
        WeighbridgeLine.Quantity :=
            ResultQuantity;

        WeighbridgeLine."Unit of Measure Code" :=
            TargetUoMCode;

        Clear(WeighbridgeLine."UoM Error Text");
    end;

    local procedure SetLineDirectConversionProvenance(
        var WeighbridgeLine: Record "SI Weighbridge Document Line";
        SourceUoMCode: Code[10];
        TargetUoMCode: Code[10])
    begin
        WeighbridgeLine."Conversion Source Type" :=
            'DIRECT_SCALED';

        WeighbridgeLine."Conversion Source Description" :=
            CopyStr(
                StrSubstNo(
                    'Прямий/масштабований перерахунок %1 → %2',
                    SourceUoMCode,
                    TargetUoMCode),
                1,
                MaxStrLen(
                    WeighbridgeLine."Conversion Source Description"));
    end;

    local procedure SetLineDerivedConversionProvenance(
        var WeighbridgeLine: Record "SI Weighbridge Document Line";
        SourceType: Code[30];
        SourceDescription: Text[150];
        ConversionFactor: Decimal;
        ConversionFactorUoMCode: Code[10])
    begin
        WeighbridgeLine."Conversion Source Type" :=
            SourceType;

        WeighbridgeLine."Conversion Source Description" :=
            CopyStr(
                SourceDescription,
                1,
                MaxStrLen(
                    WeighbridgeLine."Conversion Source Description"));

        WeighbridgeLine."Conversion Factor" :=
            ConversionFactor;

        WeighbridgeLine."Conversion Factor UoM Code" :=
            ConversionFactorUoMCode;
    end;

    local procedure TryResolveLineFromItemAttributes(
        var WeighbridgeLine: Record "SI Weighbridge Document Line";
        TargetUoMCode: Code[10];
        var ResultQuantity: Decimal;
        var ErrorText: Text): Boolean
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        CandidateDerivedUoMCode: Code[10];
        CandidateValue: Decimal;
        CandidateSourceIsNumerator: Boolean;
        CandidateCount: Integer;
        CandidateSourceDescription: Text[150];
    begin
        CandidateCount := 0;

        ItemAttributeValueMapping.Reset();

        ItemAttributeValueMapping.SetRange(
            "Table ID",
            Database::Item);

        ItemAttributeValueMapping.SetRange(
            "No.",
            WeighbridgeLine."Item No.");

        if not ItemAttributeValueMapping.FindSet() then
            exit(false);

        repeat
            if ItemAttribute.Get(
                ItemAttributeValueMapping."Item Attribute ID")
            then
                if ItemAttribute."SI UoM Code" <> '' then
                    if ItemAttributeValue.Get(
                        ItemAttributeValueMapping."Item Attribute ID",
                        ItemAttributeValueMapping."Item Attribute Value ID")
                    then
                        EvaluateAttributeCandidate(
                            ItemAttribute,
                            ItemAttributeValue,
                            WeighbridgeLine."Weight UoM Code",
                            TargetUoMCode,
                            CandidateDerivedUoMCode,
                            CandidateValue,
                            CandidateSourceIsNumerator,
                            CandidateCount,
                            CandidateSourceDescription);

        until ItemAttributeValueMapping.Next() = 0;

        if CandidateCount = 0 then
            exit(false);

        if CandidateCount > 1 then begin
            ErrorText :=
                StrSubstNo(
                    'Для товару знайдено декілька атрибутів, які можуть використовуватися для перерахунку %1 у %2. ' +
                    'Перевірте фізичні характеристики товару.',
                    WeighbridgeLine."Weight UoM Code",
                    TargetUoMCode);

            exit(false);
        end;

        if not CalculateDerivedResult(
            CandidateValue,
            CandidateDerivedUoMCode,
            CandidateSourceIsNumerator,
            WeighbridgeLine."Allocated Weight",
            WeighbridgeLine."Weight UoM Code",
            TargetUoMCode,
            ResultQuantity,
            ErrorText)
        then
            exit(false);

        SetLineDerivedConversionProvenance(
            WeighbridgeLine,
            'ITEM_ATTRIBUTE',
            CandidateSourceDescription,
            CandidateValue,
            CandidateDerivedUoMCode);

        exit(true);
    end;

    // ================================================================
    // NOTIFICATION

    procedure EnsureCanAdvance(
        WeighbridgeDocument: Record "SI Weighbridge Document")
    var
        WeighbridgeLine: Record "SI Weighbridge Document Line";
        AllocatedTotal: Decimal;
    begin
        if WeighbridgeDocument.Status =
           "SI WB Document Status"::Error
        then
            Error(
                'Документ має статус "Помилка" і не може бути переданий на наступну стадію.');

        case WeighbridgeDocument."Operation Type" of
            "SI WB Operation Type"::Receipt:
                begin
                    if WeighbridgeDocument."Shipment Scenario" <>
                       "SI WB Shipment Scenario"::Supply
                    then
                        Error(
                            'Для надходження сценарій повинен бути "Постачання".');

                    WeighbridgeDocument.TestField("Vendor No.");
                end;

            "SI WB Operation Type"::Shipment:
                case WeighbridgeDocument."Shipment Scenario" of
                    "SI WB Shipment Scenario"::Sales:
                        WeighbridgeDocument.TestField("Customer No.");

                    "SI WB Shipment Scenario"::"Internal Transfer":
                        WeighbridgeDocument.TestField("Project No.");

                    else
                        Error(
                            'Для відвантаження необхідно вибрати сценарій "Продаж" або "Внутрішнє переміщення".');
                end;

            else
                Error(
                    'Для документа %1 не визначено допустиму операцію.',
                    WeighbridgeDocument."Document No.");
        end;

        WeighbridgeLine.Reset();
        WeighbridgeLine.SetRange(
            "Document Entry No.",
            WeighbridgeDocument."Entry No.");

        if not WeighbridgeLine.FindSet() then
            Error(
                'Документ %1 не містить товарних рядків.',
                WeighbridgeDocument."Document No.");

        repeat
            WeighbridgeLine.TestField("Item No.");

            if WeighbridgeLine."UoM Error Text" <> '' then
                Error(
                    'Рядок %1 містить помилку перерахунку одиниць виміру.\\%2',
                    WeighbridgeLine."Line No.",
                    WeighbridgeLine."UoM Error Text");

            AllocatedTotal +=
                WeighbridgeLine."Allocated Weight";
        until WeighbridgeLine.Next() = 0;

        if AllocatedTotal <> WeighbridgeDocument."Net Weight" then
            Error(
                'Розподілена вага (%1 кг) повинна дорівнювати фактичній вазі нетто (%2 кг).',
                AllocatedTotal,
                WeighbridgeDocument."Net Weight");
    end;

    procedure ScaleUoMCode(): Code[10]
    begin
        exit('KG');
    end;

}
