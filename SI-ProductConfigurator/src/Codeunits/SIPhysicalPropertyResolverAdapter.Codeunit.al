codeunit 53019 "SI Physical Prop. Adapter"
{
    // Adapter between SI Product Configurator parameter values and the generic
    // UoM-driven physical-property resolver published by SI Master Data Toolkit.
    // MDT remains independent from Product Configurator.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI Item UoM Conversion", 'OnResolveVariantConfigurationParameters', '', false, false)]
    local procedure ResolveVariantConfigurationParameters(
        ItemNo: Code[20];
        VariantCode: Code[10];
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
        var MatchCount: Integer;
        var DerivedValue: Decimal;
        var DerivedUoMCode: Code[10];
        var SourceDescription: Text;
        var CandidateList: Text)
    var
        ConfigProjection: Record "SI Config. ERP Projection";
    begin
        if (ItemNo = '') or (VariantCode = '') then
            exit;

        ConfigProjection.SetRange("Item No.", ItemNo);
        ConfigProjection.SetRange("Variant Code", VariantCode);
        ConfigProjection.SetRange(Status, ConfigProjection.Status::Projected);

        if ConfigProjection.FindSet() then
            repeat
                CollectConfigurationCandidates(
                    ConfigProjection."Configuration No.",
                    'Variant Configuration Parameter',
                    FromUoMCode,
                    ToUoMCode,
                    MatchCount,
                    DerivedValue,
                    DerivedUoMCode,
                    SourceDescription,
                    CandidateList);
            until ConfigProjection.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI Item UoM Conversion", 'OnResolveItemConfigurationParameters', '', false, false)]
    local procedure ResolveItemConfigurationParameters(
        ItemNo: Code[20];
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
        var MatchCount: Integer;
        var DerivedValue: Decimal;
        var DerivedUoMCode: Code[10];
        var SourceDescription: Text;
        var CandidateList: Text)
    var
        ConfigProjection: Record "SI Config. ERP Projection";
        ProductConfig: Record "SI Product Config.";
    begin
        if ItemNo = '' then
            exit;

        ConfigProjection.SetRange("Item No.", ItemNo);
        ConfigProjection.SetRange("Variant Code", '');
        ConfigProjection.SetRange(Status, ConfigProjection.Status::Projected);

        if ConfigProjection.FindSet() then
            repeat
                if ProductConfig.Get(ConfigProjection."Configuration No.") then
                    // Item configurations materialize the Item itself. Variant
                    // configurations have Base Item No. populated and are handled
                    // by the more-specific subscriber above.
                    if ProductConfig."Base Item No." = '' then
                        CollectConfigurationCandidates(
                            ConfigProjection."Configuration No.",
                            'Item Configuration Parameter',
                            FromUoMCode,
                            ToUoMCode,
                            MatchCount,
                            DerivedValue,
                            DerivedUoMCode,
                            SourceDescription,
                            CandidateList);
            until ConfigProjection.Next() = 0;
    end;

    local procedure CollectConfigurationCandidates(
        ConfigurationNo: Code[20];
        LevelName: Text;
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
        var MatchCount: Integer;
        var DerivedValue: Decimal;
        var DerivedUoMCode: Code[10];
        var SourceDescription: Text;
        var CandidateList: Text)
    var
        ConfigValue: Record "SI Product Config. Value";
        ProductParameter: Record "SI Product Parameter";
        ParameterValue: Record "SI Parameter Value";
        UoMMgt: Codeunit "SI UoM Mgt.";
        CandidateValue: Decimal;
        CandidateUoMCode: Code[10];
        CandidateSource: Text;
    begin
        ConfigValue.SetRange("Configuration No.", ConfigurationNo);
        if not ConfigValue.FindSet() then
            exit;

        repeat
            Clear(CandidateValue);
            Clear(CandidateUoMCode);

            if ProductParameter.Get(ConfigValue."Parameter Code") then
                if not ProductParameter.Blocked then begin
                    case ConfigValue."Value Type" of
                        ConfigValue."Value Type"::Decimal:
                            begin
                                CandidateValue := ConfigValue."Decimal Value";
                                CandidateUoMCode := ProductParameter."Unit of Measure Code";
                            end;

                        ConfigValue."Value Type"::Integer:
                            begin
                                CandidateValue := ConfigValue."Integer Value";
                                CandidateUoMCode := ProductParameter."Unit of Measure Code";
                            end;

                        ConfigValue."Value Type"::"Controlled Value":
                            if (ConfigValue."Parameter Value Code" <> '') and
                               ParameterValue.Get(
                                   ConfigValue."Parameter Code",
                                   ConfigValue."Parameter Value Code")
                            then
                                if not ParameterValue.Blocked then begin
                                    CandidateValue := ParameterValue."Numeric Value";
                                    CandidateUoMCode := ParameterValue."Numeric UoM Code";
                                    if CandidateUoMCode = '' then
                                        CandidateUoMCode := ProductParameter."Unit of Measure Code";
                                end;
                    end;

                    if (CandidateUoMCode <> '') and
                       UoMMgt.CanConvertQuantityWithDerivedUoM(
                           FromUoMCode,
                           ToUoMCode,
                           CandidateUoMCode)
                    then begin
                        CandidateSource := StrSubstNo(
                            '%1: %2 / %3 [%4]',
                            LevelName,
                            ConfigurationNo,
                            ConfigValue."Parameter Code",
                            CandidateUoMCode);

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
                end;
        until ConfigValue.Next() = 0;
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
        CandidateList += CandidateSource;
    end;
}
