codeunit 58004 "SI Item UoM Conversion"
{
    procedure ConvertItemQuantity(
        ItemNo: Code[20];
        VariantCode: Code[10];
        Quantity: Decimal;
        FromUoMCode: Code[10];
        ToUoMCode: Code[10]): Decimal
    var
        UoMMgt: Codeunit "SI UoM Mgt.";
        DerivedValue: Decimal;
        DerivedUoMCode: Code[10];
        SourceDescription: Text;
        ResolvedFromUoMCode: Code[10];
        ResolvedToUoMCode: Code[10];
    begin
        if Quantity = 0 then
            exit(0);

        ResolvedFromUoMCode := ResolveLocalUoMCode(FromUoMCode);
        ResolvedToUoMCode := ResolveLocalUoMCode(ToUoMCode);

        if UoMMgt.AreConvertible(ResolvedFromUoMCode, ResolvedToUoMCode) then
            exit(UoMMgt.ConvertQuantity(Quantity, ResolvedFromUoMCode, ResolvedToUoMCode));

        ResolvePhysicalBridge(
            ItemNo,
            VariantCode,
            ResolvedFromUoMCode,
            ResolvedToUoMCode,
            DerivedValue,
            DerivedUoMCode,
            SourceDescription);

        exit(UoMMgt.ConvertQuantityWithDerivedValue(
            Quantity,
            ResolvedFromUoMCode,
            ResolvedToUoMCode,
            DerivedValue,
            DerivedUoMCode));
    end;

    procedure CanConvertItemQuantity(
        ItemNo: Code[20];
        VariantCode: Code[10];
        FromUoMCode: Code[10];
        ToUoMCode: Code[10]): Boolean
    var
        UoMMgt: Codeunit "SI UoM Mgt.";
        DerivedValue: Decimal;
        DerivedUoMCode: Code[10];
        SourceDescription: Text;
        ResolvedFromUoMCode: Code[10];
        ResolvedToUoMCode: Code[10];
    begin
        if not TryResolveLocalUoMCode(FromUoMCode, ResolvedFromUoMCode) then
            exit(false);
        if not TryResolveLocalUoMCode(ToUoMCode, ResolvedToUoMCode) then
            exit(false);

        if UoMMgt.AreConvertible(ResolvedFromUoMCode, ResolvedToUoMCode) then
            exit(true);

        exit(TryResolvePhysicalBridge(
            ItemNo,
            VariantCode,
            ResolvedFromUoMCode,
            ResolvedToUoMCode,
            DerivedValue,
            DerivedUoMCode,
            SourceDescription));
    end;

    procedure ResolveLocalUoMCode(UoMCodeOrInternationalCode: Code[10]): Code[10]
    var
        ResolvedUoMCode: Code[10];
    begin
        if TryResolveLocalUoMCode(UoMCodeOrInternationalCode, ResolvedUoMCode) then
            exit(ResolvedUoMCode);

        Error(UoMNotFoundErr, UoMCodeOrInternationalCode);
    end;

    procedure TryResolveLocalUoMCode(UoMCodeOrInternationalCode: Code[10]; var ResolvedUoMCode: Code[10]): Boolean
    var
        UnitOfMeasure: Record "Unit of Measure";
        MatchCount: Integer;
    begin
        Clear(ResolvedUoMCode);

        // A real BC UoM Code always wins. This preserves existing tenants where the
        // local code itself is KG, T, M3, etc.
        if UnitOfMeasure.Get(UoMCodeOrInternationalCode) then begin
            ResolvedUoMCode := UnitOfMeasure.Code;
            exit(true);
        end;

        // Otherwise treat the supplied value as a canonical/international code.
        // Example: canonical KG resolves to local PROD code КГ.
        UnitOfMeasure.Reset();
        UnitOfMeasure.SetRange("International Standard Code", UoMCodeOrInternationalCode);
        if UnitOfMeasure.FindSet() then
            repeat
                MatchCount += 1;
                if MatchCount = 1 then
                    ResolvedUoMCode := UnitOfMeasure.Code;
            until UnitOfMeasure.Next() = 0;

        if MatchCount > 1 then
            Error(AmbiguousInternationalUoMErr, UoMCodeOrInternationalCode);

        exit(MatchCount = 1);
    end;

    procedure ResolvePhysicalBridge(
        ItemNo: Code[20];
        VariantCode: Code[10];
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
        var DerivedValue: Decimal;
        var DerivedUoMCode: Code[10];
        var SourceDescription: Text)
    begin
        if TryResolvePhysicalBridge(
            ItemNo,
            VariantCode,
            FromUoMCode,
            ToUoMCode,
            DerivedValue,
            DerivedUoMCode,
            SourceDescription)
        then
            exit;

        Error(
            NoPhysicalBridgeErr,
            ItemNo,
            FormatVariant(VariantCode),
            FromUoMCode,
            ToUoMCode);
    end;

    local procedure TryResolvePhysicalBridge(
        ItemNo: Code[20];
        VariantCode: Code[10];
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
        var DerivedValue: Decimal;
        var DerivedUoMCode: Code[10];
        var SourceDescription: Text): Boolean
    var
        MatchCount: Integer;
        CandidateList: Text;
    begin
        Clear(DerivedValue);
        Clear(DerivedUoMCode);
        Clear(SourceDescription);

        // 1. Most specific: Variant Configuration Parameter.
        Clear(MatchCount);
        Clear(CandidateList);
        OnResolveVariantConfigurationParameters(
            ItemNo,
            VariantCode,
            FromUoMCode,
            ToUoMCode,
            MatchCount,
            DerivedValue,
            DerivedUoMCode,
            SourceDescription,
            CandidateList);
        if FinishLevel(
            MatchCount,
            'Variant Configuration Parameter',
            ItemNo,
            VariantCode,
            FromUoMCode,
            ToUoMCode,
            CandidateList)
        then
            exit(true);

        // 2. Item Configuration Parameter.
        Clear(MatchCount);
        Clear(CandidateList);
        Clear(DerivedValue);
        Clear(DerivedUoMCode);
        Clear(SourceDescription);
        OnResolveItemConfigurationParameters(
            ItemNo,
            FromUoMCode,
            ToUoMCode,
            MatchCount,
            DerivedValue,
            DerivedUoMCode,
            SourceDescription,
            CandidateList);
        if FinishLevel(
            MatchCount,
            'Item Configuration Parameter',
            ItemNo,
            VariantCode,
            FromUoMCode,
            ToUoMCode,
            CandidateList)
        then
            exit(true);

        // 3. Standard Item Attribute.
        Clear(MatchCount);
        Clear(CandidateList);
        Clear(DerivedValue);
        Clear(DerivedUoMCode);
        Clear(SourceDescription);
        CollectItemAttributeCandidates(
            ItemNo,
            FromUoMCode,
            ToUoMCode,
            MatchCount,
            DerivedValue,
            DerivedUoMCode,
            SourceDescription,
            CandidateList);
        if FinishLevel(
            MatchCount,
            'Item Attribute',
            ItemNo,
            VariantCode,
            FromUoMCode,
            ToUoMCode,
            CandidateList)
        then
            exit(true);

        // 4. Least specific: Item Category Attribute (including inherited parent-category defaults).
        Clear(MatchCount);
        Clear(CandidateList);
        Clear(DerivedValue);
        Clear(DerivedUoMCode);
        Clear(SourceDescription);
        CollectCategoryAttributeCandidates(
            ItemNo,
            FromUoMCode,
            ToUoMCode,
            MatchCount,
            DerivedValue,
            DerivedUoMCode,
            SourceDescription,
            CandidateList);
        if FinishLevel(
            MatchCount,
            'Category Attribute',
            ItemNo,
            VariantCode,
            FromUoMCode,
            ToUoMCode,
            CandidateList)
        then
            exit(true);

        exit(false);
    end;

    local procedure CollectItemAttributeCandidates(
        ItemNo: Code[20];
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
        var MatchCount: Integer;
        var DerivedValue: Decimal;
        var DerivedUoMCode: Code[10];
        var SourceDescription: Text;
        var CandidateList: Text)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", ItemNo);
        if not ItemAttributeValueMapping.FindSet() then
            exit;

        repeat
            if ItemAttribute.Get(ItemAttributeValueMapping."Item Attribute ID") then
                if IsNumericBridgeAttribute(ItemAttribute, FromUoMCode, ToUoMCode) then
                    if ItemAttributeValue.Get(
                        ItemAttributeValueMapping."Item Attribute ID",
                        ItemAttributeValueMapping."Item Attribute Value ID")
                    then
                        if ItemAttributeValue."Numeric Value" > 0 then
                            AddCandidate(
                                ItemAttributeValue."Numeric Value",
                                ItemAttribute."SI UoM Code",
                                StrSubstNo('Item Attribute "%1" (ID %2)', ItemAttribute.Name, ItemAttribute.ID),
                                MatchCount,
                                DerivedValue,
                                DerivedUoMCode,
                                SourceDescription,
                                CandidateList);
        until ItemAttributeValueMapping.Next() = 0;
    end;

    local procedure CollectCategoryAttributeCandidates(
        ItemNo: Code[20];
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
        var MatchCount: Integer;
        var DerivedValue: Decimal;
        var DerivedUoMCode: Code[10];
        var SourceDescription: Text;
        var CandidateList: Text)
    var
        Item: Record Item;
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        ItemAttribute: Record "Item Attribute";
    begin
        if not Item.Get(ItemNo) then
            exit;

        if Item."Item Category Code" = '' then
            exit;

        TempItemAttributeValue.LoadCategoryAttributesFactBoxData(Item."Item Category Code");
        if not TempItemAttributeValue.FindSet() then
            exit;

        repeat
            if ItemAttribute.Get(TempItemAttributeValue."Attribute ID") then
                if IsNumericBridgeAttribute(ItemAttribute, FromUoMCode, ToUoMCode) then
                    if TempItemAttributeValue."Numeric Value" > 0 then
                        AddCandidate(
                            TempItemAttributeValue."Numeric Value",
                            ItemAttribute."SI UoM Code",
                            StrSubstNo(
                                'Category Attribute "%1" (ID %2; category %3/inherited)',
                                ItemAttribute.Name,
                                ItemAttribute.ID,
                                Item."Item Category Code"),
                            MatchCount,
                            DerivedValue,
                            DerivedUoMCode,
                            SourceDescription,
                            CandidateList);
        until TempItemAttributeValue.Next() = 0;
    end;

    local procedure IsNumericBridgeAttribute(
        ItemAttribute: Record "Item Attribute";
        FromUoMCode: Code[10];
        ToUoMCode: Code[10]): Boolean
    var
        UoMMgt: Codeunit "SI UoM Mgt.";
    begin
        if ItemAttribute.Blocked then
            exit(false);

        if not (ItemAttribute.Type in [ItemAttribute.Type::Integer, ItemAttribute.Type::Decimal]) then
            exit(false);

        if ItemAttribute."SI UoM Code" = '' then
            exit(false);

        exit(UoMMgt.CanConvertQuantityWithDerivedUoM(
            FromUoMCode,
            ToUoMCode,
            ItemAttribute."SI UoM Code"));
    end;

    local procedure AddCandidate(
        CandidateValue: Decimal;
        CandidateUoMCode: Code[10];
        CandidateSource: Text;
        var MatchCount: Integer;
        var DerivedValue: Decimal;
        var DerivedUoMCode: Code[10];
        var SourceDescription: Text;
        var CandidateList: Text)
    begin
        MatchCount += 1;
        DerivedValue := CandidateValue;
        DerivedUoMCode := CandidateUoMCode;
        SourceDescription := CandidateSource;

        if CandidateList <> '' then
            CandidateList += '; ';
        CandidateList += StrSubstNo('%1 = %2 %3', CandidateSource, CandidateValue, CandidateUoMCode);
    end;

    local procedure FinishLevel(
        MatchCount: Integer;
        LevelName: Text;
        ItemNo: Code[20];
        VariantCode: Code[10];
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
        CandidateList: Text): Boolean
    begin
        if MatchCount > 1 then
            Error(
                AmbiguousPhysicalBridgeErr,
                LevelName,
                ItemNo,
                FormatVariant(VariantCode),
                FromUoMCode,
                ToUoMCode,
                CandidateList);

        exit(MatchCount = 1);
    end;

    procedure AddExternalCandidate(
        CandidateValue: Decimal;
        CandidateUoMCode: Code[10];
        CandidateSource: Text;
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
        var MatchCount: Integer;
        var DerivedValue: Decimal;
        var DerivedUoMCode: Code[10];
        var SourceDescription: Text;
        var CandidateList: Text)
    var
        UoMMgt: Codeunit "SI UoM Mgt.";
    begin
        if CandidateValue <= 0 then
            exit;

        if CandidateUoMCode = '' then
            exit;

        if not UoMMgt.CanConvertQuantityWithDerivedUoM(
            FromUoMCode,
            ToUoMCode,
            CandidateUoMCode)
        then
            exit;

        AddCandidate(
            CandidateValue,
            CandidateUoMCode,
            CandidateSource,
            MatchCount,
            DerivedValue,
            DerivedUoMCode,
            SourceDescription,
            CandidateList);
    end;

    local procedure FormatVariant(VariantCode: Code[10]): Text
    begin
        if VariantCode = '' then
            exit('<без варіанта>');

        exit(VariantCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResolveVariantConfigurationParameters(
        ItemNo: Code[20];
        VariantCode: Code[10];
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
        var MatchCount: Integer;
        var DerivedValue: Decimal;
        var DerivedUoMCode: Code[10];
        var SourceDescription: Text;
        var CandidateList: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResolveItemConfigurationParameters(
        ItemNo: Code[20];
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
        var MatchCount: Integer;
        var DerivedValue: Decimal;
        var DerivedUoMCode: Code[10];
        var SourceDescription: Text;
        var CandidateList: Text)
    begin
    end;

    var
        UoMNotFoundErr: Label 'Не знайдено одиницю вимірювання з кодом або міжнародним стандартним кодом %1.';
        AmbiguousInternationalUoMErr: Label 'Знайдено кілька одиниць вимірювання з міжнародним стандартним кодом %1. Міжнародний код має однозначно визначати локальну одиницю вимірювання.';
        NoPhysicalBridgeErr: Label 'Для товару %1, варіанта %2 не знайдено фізичного параметра, який дозволяє перерахунок %3 → %4.';
        AmbiguousPhysicalBridgeErr: Label 'Неоднозначний фізичний перерахунок на рівні %1 для товару %2, варіанта %3 (%4 → %5). Знайдено кілька сумісних параметрів: %6';
}
