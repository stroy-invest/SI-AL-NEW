codeunit 53002 "SI Naming Engine"
{
    // Формування кодів, назв і канонічних представлень продукту.

    procedure BuildItemCode(ConfigurationNo: Code[20]): Text
    begin
        exit(
            BuildRoleCode(
                ConfigurationNo,
                Enum::"SI ERP Projection Role"::"Item Identity"));
    end;

    procedure BuildItemDescription(
        ConfigurationNo: Code[20]): Text
    begin
        exit(
            BuildRoleDescription(
                ConfigurationNo,
                Enum::"SI ERP Projection Role"::"Item Identity",
                true));
    end;

    procedure BuildVariantCode(ConfigurationNo: Code[20]): Text
    var
        IdentityMgt: Codeunit "SI Product Identity Mgt.";
    begin
        // Variant presentation is allowed only when the current configuration
        // actually has a Variant Identity. A family prefix by itself must not
        // produce a phantom variant code.
        if IdentityMgt.BuildVariantKey(ConfigurationNo) = '' then
            exit('');

        exit(
            BuildRoleCode(
                ConfigurationNo,
                Enum::"SI ERP Projection Role"::"Variant Identity"));
    end;

    procedure BuildVariantDescription(
        ConfigurationNo: Code[20]): Text
    var
        IdentityMgt: Codeunit "SI Product Identity Mgt.";
    begin
        // Do not build a base name or family prefix for a non-existing variant.
        if IdentityMgt.BuildVariantKey(ConfigurationNo) = '' then
            exit('');

        exit(
            BuildRoleDescription(
                ConfigurationNo,
                Enum::"SI ERP Projection Role"::"Variant Identity",
                false));
    end;

    procedure BuildDescription(ConfigurationNo: Code[20]): Text
    var
        ProductConfig: Record "SI Product Config.";
        ProductFamily: Record "SI Product Family";
        FamilyParameter: Record "SI Family Parameter";
        ConfigValue: Record "SI Product Config. Value";
        ResultBuilder: TextBuilder;
        FirstParameter: Boolean;
        DescriptionValue: Text[250];
    begin
        ProductConfig.Get(ConfigurationNo);
        ProductConfig.TestField("Family Code");

        ProductFamily.Get(ProductConfig."Family Code");

        if ProductConfig."Include Base Name" then
            AppendWithSpace(
                ResultBuilder,
                ResolveBaseName(ProductConfig, ProductFamily));

        if ProductConfig."Base Item No." = '' then
            AppendWithSpace(
                ResultBuilder,
                ProductFamily."Name Prefix");

        FamilyParameter.SetCurrentKey(
            "Family Code",
            "Description Order",
            "Parameter Code");
        FamilyParameter.SetRange(
            "Family Code",
            ProductConfig."Family Code");
        FamilyParameter.SetRange(
            "Include in Description",
            true);
        FamilyParameter.SetRange(Blocked, false);

        FirstParameter := true;
        if FamilyParameter.FindSet() then
            repeat
                if ConfigValue.Get(
                    ConfigurationNo,
                    FamilyParameter."Parameter Code")
                then begin
                    DescriptionValue := ResolveDescriptionValue(
                        ProductConfig,
                        FamilyParameter,
                        ConfigValue);

                    if DescriptionValue <> '' then begin
                        AppendDescriptionParameter(
                            ResultBuilder,
                            DescriptionValue,
                            ProductConfig."Compact Description Parts",
                            FirstParameter);
                        FirstParameter := false;
                    end;
                end;
            until FamilyParameter.Next() = 0;

        exit(ResultBuilder.ToText());
    end;

    procedure BuildShortDescription(
        ConfigurationNo: Code[20]): Text
    var
        DescriptionText: Text;
    begin
        DescriptionText := BuildDescription(ConfigurationNo);

        exit(CopyStr(DescriptionText, 1, 100));
    end;

    procedure BuildCompositeKey(ConfigurationNo: Code[20]): Text
    var
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        ConfigValue: Record "SI Product Config. Value";
        ResultBuilder: TextBuilder;
        CanonicalValue: Text;
    begin
        ProductConfig.Get(ConfigurationNo);
        ProductConfig.TestField("Family Code");

        ResultBuilder.Append(ProductConfig."Family Code");

        if ProductConfig."Base Item No." <> '' then begin
            ResultBuilder.Append('|ITEMNO=');
            ResultBuilder.Append(ProductConfig."Base Item No.");
        end;

        FamilyParameter.SetCurrentKey(
            "Family Code",
            "Parameter Order",
            "Parameter Code");
        FamilyParameter.SetRange(
            "Family Code",
            ProductConfig."Family Code");
        FamilyParameter.SetRange(Blocked, false);

        if FamilyParameter.FindSet() then
            repeat
                if FamilyParameter."ERP Projection Role" in [
                    FamilyParameter."ERP Projection Role"::"Item Identity",
                    FamilyParameter."ERP Projection Role"::"Variant Identity"]
                then
                    if ConfigValue.Get(
                        ConfigurationNo,
                        FamilyParameter."Parameter Code")
                    then begin
                        CanonicalValue := GetCanonicalValue(ConfigValue);

                        if CanonicalValue <> '' then begin
                            ResultBuilder.Append('|');
                            ResultBuilder.Append(
                                FamilyParameter."Parameter Code");
                            ResultBuilder.Append('=');
                            ResultBuilder.Append(CanonicalValue);
                        end;
                    end;
            until FamilyParameter.Next() = 0;

        exit(ResultBuilder.ToText());
    end;

    procedure BuildSearchText(
        ConfigurationNo: Code[20];
        DescriptionText: Text): Text
    var
        ProductConfig: Record "SI Product Config.";
        ProductFamily: Record "SI Product Family";
        FamilyParameter: Record "SI Family Parameter";
        ConfigValue: Record "SI Product Config. Value";
        ResultBuilder: TextBuilder;
    begin
        ProductConfig.Get(ConfigurationNo);
        ProductConfig.TestField("Family Code");

        ProductFamily.Get(ProductConfig."Family Code");

        AppendWithSpace(
            ResultBuilder,
            ProductConfig."Family Code");
        AppendWithSpace(
            ResultBuilder,
            ProductFamily.Description);
        AppendWithSpace(
            ResultBuilder,
            ProductFamily."Description EN");
        AppendWithSpace(
            ResultBuilder,
            ProductFamily."Name Prefix");
        AppendWithSpace(
            ResultBuilder,
            DescriptionText);

        FamilyParameter.SetCurrentKey(
            "Family Code",
            "Parameter Order",
            "Parameter Code");
        FamilyParameter.SetRange(
            "Family Code",
            ProductConfig."Family Code");
        FamilyParameter.SetRange(
            "Include in Search",
            true);
        FamilyParameter.SetRange(Blocked, false);

        if FamilyParameter.FindSet() then
            repeat
                if ConfigValue.Get(
                    ConfigurationNo,
                    FamilyParameter."Parameter Code")
                then begin
                    AppendWithSpace(
                        ResultBuilder,
                        FamilyParameter."Parameter Code");
                    AppendWithSpace(
                        ResultBuilder,
                        GetCanonicalValue(ConfigValue));
                    AppendWithSpace(
                        ResultBuilder,
                        ConfigValue."Display Value");
                end;
            until FamilyParameter.Next() = 0;

        exit(ResultBuilder.ToText());
    end;

    procedure GetCanonicalValue(
        ConfigValue: Record "SI Product Config. Value"): Text
    begin
        case ConfigValue."Value Type" of
            ConfigValue."Value Type"::"Controlled Value":
                exit(ConfigValue."Parameter Value Code");

            ConfigValue."Value Type"::Decimal:
                exit(
                    Format(
                        ConfigValue."Decimal Value",
                        0,
                        9));

            ConfigValue."Value Type"::Integer:
                exit(
                    Format(
                        ConfigValue."Integer Value",
                        0,
                        9));

            ConfigValue."Value Type"::Text:
                exit(
                    UpperCase(
                        DelChr(
                            ConfigValue."Text Value",
                            '<>',
                            ' ')));

            ConfigValue."Value Type"::Boolean:
                exit(
                    Format(
                        ConfigValue."Boolean Value",
                        0,
                        9));

            ConfigValue."Value Type"::Date:
                exit(
                    Format(
                        ConfigValue."Date Value",
                        0,
                        9));

            ConfigValue."Value Type"::Reference:
                exit(ConfigValue."Reference Key");
        end;

        exit('');
    end;

    procedure BuildHash(InputText: Text): Text
    var
        CryptographyMgt: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        if InputText = '' then
            exit('');

        exit(
            CryptographyMgt.GenerateHash(
                InputText,
                HashAlgorithm::SHA256));
    end;

    local procedure BuildRoleCode(
        ConfigurationNo: Code[20];
        ProjectionRole: Enum "SI ERP Projection Role"): Text
    var
        ProductConfig: Record "SI Product Config.";
        ProductFamily: Record "SI Product Family";
        FamilyParameter: Record "SI Family Parameter";
        ConfigValue: Record "SI Product Config. Value";
        ResultBuilder: TextBuilder;
        CanonicalValue: Text;
    begin
        ProductConfig.Get(ConfigurationNo);
        ProductConfig.TestField("Family Code");
        ProductFamily.Get(ProductConfig."Family Code");

        if ProjectionRole = ProjectionRole::"Item Identity" then
            AppendWithSeparator(
                ResultBuilder,
                ResolveItemCodePrefix(ProductFamily),
                '-')
        else
            if ProjectionRole = ProjectionRole::"Variant Identity" then
                AppendWithSeparator(ResultBuilder, ProductFamily."Variant Code Prefix", '-');

        FamilyParameter.SetCurrentKey(
            "Family Code",
            "Code Order",
            "Parameter Code");
        FamilyParameter.SetRange(
            "Family Code",
            ProductConfig."Family Code");
        FamilyParameter.SetRange(
            "ERP Projection Role",
            ProjectionRole);
        FamilyParameter.SetRange(
            "Include in Code",
            true);
        FamilyParameter.SetRange(Blocked, false);

        if FamilyParameter.FindSet() then
            repeat
                if ConfigValue.Get(
                    ConfigurationNo,
                    FamilyParameter."Parameter Code")
                then begin
                    ConfigValue.ValidateCompleteValue();

                    CanonicalValue :=
                        GetERPCodeValue(ConfigValue);

                    if CanonicalValue = '' then
                        Error(
                            CanonicalValueEmptyErr,
                            FamilyParameter."Parameter Code",
                            ConfigurationNo);

                    AppendWithSeparator(
                        ResultBuilder,
                        CanonicalValue,
                        '-');
                end else
                    if FamilyParameter.Mandatory then
                        Error(
                            ConfigValueMissingErr,
                            FamilyParameter."Parameter Code",
                            ConfigurationNo);
            until FamilyParameter.Next() = 0;

        exit(ResultBuilder.ToText());
    end;

    local procedure BuildRoleDescription(
        ConfigurationNo: Code[20];
        ProjectionRole: Enum "SI ERP Projection Role";
        IncludeFamilyPrefix: Boolean): Text
    var
        ProductConfig: Record "SI Product Config.";
        ProductFamily: Record "SI Product Family";
        FamilyParameter: Record "SI Family Parameter";
        ConfigValue: Record "SI Product Config. Value";
        ResultBuilder: TextBuilder;
        FirstParameter: Boolean;
        DescriptionValue: Text[250];
    begin
        ProductConfig.Get(ConfigurationNo);
        ProductConfig.TestField("Family Code");

        ProductFamily.Get(ProductConfig."Family Code");

        if ProductConfig."Include Base Name" then
            AppendWithSpace(
                ResultBuilder,
                ResolveBaseName(ProductConfig, ProductFamily));

        if IncludeFamilyPrefix then
            AppendWithSpace(
                ResultBuilder,
                ProductFamily."Name Prefix");

        FamilyParameter.SetCurrentKey(
            "Family Code",
            "Description Order",
            "Parameter Code");
        FamilyParameter.SetRange(
            "Family Code",
            ProductConfig."Family Code");
        FamilyParameter.SetRange(
            "ERP Projection Role",
            ProjectionRole);
        FamilyParameter.SetRange(
            "Include in Description",
            true);
        FamilyParameter.SetRange(Blocked, false);

        FirstParameter := true;
        if FamilyParameter.FindSet() then
            repeat
                if ConfigValue.Get(
                    ConfigurationNo,
                    FamilyParameter."Parameter Code")
                then begin
                    ConfigValue.ValidateCompleteValue();

                    DescriptionValue := ResolveDescriptionValue(
                        ProductConfig,
                        FamilyParameter,
                        ConfigValue);

                    if DescriptionValue = '' then
                        Error(
                            DisplayValueEmptyErr,
                            FamilyParameter."Parameter Code",
                            ConfigurationNo);

                    AppendDescriptionParameter(
                        ResultBuilder,
                        DescriptionValue,
                        ProductConfig."Compact Description Parts",
                        FirstParameter);
                    FirstParameter := false;
                end else
                    if FamilyParameter.Mandatory then
                        Error(
                            ConfigValueMissingErr,
                            FamilyParameter."Parameter Code",
                            ConfigurationNo);
            until FamilyParameter.Next() = 0;

        exit(ResultBuilder.ToText());
    end;

    local procedure ResolveItemCodePrefix(
        ProductFamily: Record "SI Product Family"): Text
    begin
        if ProductFamily."Item Code Prefix" <> '' then
            exit(ProductFamily."Item Code Prefix");

        exit(ProductFamily.Code);
    end;

    local procedure ResolveBaseName(
        ProductConfig: Record "SI Product Config.";
        ProductFamily: Record "SI Product Family"): Text
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
    begin
        if ProductConfig."Base Item No." <> '' then begin
            if Item.Get(ProductConfig."Base Item No.") then
                exit(Item.Description);

            exit('');
        end;

        if ProductFamily."Item Category Code" = '' then
            exit('');

        if ItemCategory.Get(ProductFamily."Item Category Code") then
            exit(ItemCategory.Description);

        exit('');
    end;

    local procedure GetERPCodeValue(
        ConfigValue: Record "SI Product Config. Value"): Text
    var
        ParameterValue: Record "SI Parameter Value";
    begin
        if ConfigValue."Value Type" = ConfigValue."Value Type"::"Controlled Value" then
            if ParameterValue.Get(
                ConfigValue."Parameter Code",
                ConfigValue."Parameter Value Code")
            then
                if ParameterValue."ERP Code" <> '' then
                    exit(ParameterValue."ERP Code");

        exit(GetCanonicalValue(ConfigValue));
    end;

    local procedure GetConfigValue(
        ConfigurationNo: Code[20];
        ParameterCode: Code[30];
        var ConfigValue: Record "SI Product Config. Value")
    begin
        if ConfigValue.Get(
            ConfigurationNo,
            ParameterCode)
        then
            exit;

        Error(
            ConfigValueMissingErr,
            ParameterCode,
            ConfigurationNo);
    end;

    local procedure AppendWithSeparator(
        var ResultBuilder: TextBuilder;
        ValueToAppend: Text;
        Separator: Text)
    begin
        if ValueToAppend = '' then
            exit;

        if ResultBuilder.Length() > 0 then
            ResultBuilder.Append(Separator);

        ResultBuilder.Append(ValueToAppend);
    end;

    local procedure ResolveDescriptionValue(
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        ConfigValue: Record "SI Product Config. Value"): Text
    var
        DescriptionValue: Text[250];
    begin
        DescriptionValue := ConfigValue."Display Value";

        OnResolveDescriptionValue(
            ProductConfig,
            FamilyParameter,
            ConfigValue,
            DescriptionValue);

        exit(DescriptionValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResolveDescriptionValue(
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        ConfigValue: Record "SI Product Config. Value";
        var DescriptionValue: Text[250])
    begin
    end;

    local procedure AppendDescriptionParameter(
        var ResultBuilder: TextBuilder;
        ValueToAppend: Text;
        CompactDescriptionParts: Boolean;
        FirstParameter: Boolean)
    begin
        if not CompactDescriptionParts or FirstParameter then begin
            AppendWithSpace(ResultBuilder, ValueToAppend);
            exit;
        end;

        AppendWithSeparator(ResultBuilder, ValueToAppend, '');
    end;

    local procedure AppendWithSpace(
        var ResultBuilder: TextBuilder;
        ValueToAppend: Text)
    begin
        AppendWithSeparator(
            ResultBuilder,
            ValueToAppend,
            ' ');
    end;

    var
        ConfigValueMissingErr: Label
            'Для параметра %1 не задано значення у конфігурації %2.';

        CanonicalValueEmptyErr: Label
            'Параметр %1 у конфігурації %2 не має канонічного значення.';

        DisplayValueEmptyErr: Label
            'Параметр %1 у конфігурації %2 не має відображуваного значення.';
}