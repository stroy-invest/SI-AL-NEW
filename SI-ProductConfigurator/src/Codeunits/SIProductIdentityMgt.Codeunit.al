codeunit 53010 "SI Product Identity Mgt."
{
    procedure BuildIdentity(var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ProductConfig: Record "SI Product Config.";
        ItemKey: Text;
        VariantKey: Text;
    begin
        PrevBuffer.TestField("Configuration No.");
        PrevBuffer.TestField("Family Code");
        ProductConfig.Get(PrevBuffer."Configuration No.");

        ItemKey := BuildRoleKey(
            PrevBuffer."Configuration No.",
            Enum::"SI ERP Projection Role"::"Item Identity",
            true);

        if ProductConfig."Base Item No." <> '' then
            VariantKey := BuildRoleKey(
                PrevBuffer."Configuration No.",
                Enum::"SI ERP Projection Role"::"Variant Identity",
                true)
        else
            Clear(VariantKey);

        PrevBuffer."Item Projection Key" :=
            CopyStr(
                ItemKey,
                1,
                MaxStrLen(PrevBuffer."Item Projection Key"));

        PrevBuffer."Item Projection Key Hash" :=
            CopyStr(
                BuildKeyHash(ItemKey),
                1,
                MaxStrLen(PrevBuffer."Item Projection Key Hash"));

        PrevBuffer."Variant Projection Key" :=
            CopyStr(
                VariantKey,
                1,
                MaxStrLen(PrevBuffer."Variant Projection Key"));

        PrevBuffer."Variant Projection Key Hash" :=
            CopyStr(
                BuildKeyHash(VariantKey),
                1,
                MaxStrLen(PrevBuffer."Variant Projection Key Hash"));
    end;

    procedure BuildItemKey(ConfigurationNo: Code[20]): Text
    begin
        exit(
            BuildRoleKey(
                ConfigurationNo,
                Enum::"SI ERP Projection Role"::"Item Identity",
                true));
    end;

    procedure BuildVariantKey(ConfigurationNo: Code[20]): Text
    var
        ProductConfig: Record "SI Product Config.";
    begin
        ProductConfig.Get(ConfigurationNo);

        if ProductConfig."Base Item No." = '' then
            exit('');

        exit(
            BuildRoleKey(
                ConfigurationNo,
                Enum::"SI ERP Projection Role"::"Variant Identity",
                true));
    end;

    procedure BuildItemKeyHash(ItemProjectionKey: Text): Text
    begin
        exit(BuildKeyHash(ItemProjectionKey));
    end;

    procedure BuildVariantKeyHash(VariantProjectionKey: Text): Text
    begin
        exit(BuildKeyHash(VariantProjectionKey));
    end;

    procedure HasItemIdentity(FamilyCode: Code[30]): Boolean
    var
        FamilyParameter: Record "SI Family Parameter";
    begin
        FamilyParameter.SetRange("Family Code", FamilyCode);
        FamilyParameter.SetRange(
            "ERP Projection Role",
            FamilyParameter."ERP Projection Role"::"Item Identity");
        FamilyParameter.SetRange(Blocked, false);

        exit(not FamilyParameter.IsEmpty());
    end;

    procedure HasVariantIdentity(FamilyCode: Code[30]): Boolean
    var
        FamilyParameter: Record "SI Family Parameter";
    begin
        FamilyParameter.SetRange("Family Code", FamilyCode);
        FamilyParameter.SetRange(
            "ERP Projection Role",
            FamilyParameter."ERP Projection Role"::"Variant Identity");
        FamilyParameter.SetRange(Blocked, false);

        exit(not FamilyParameter.IsEmpty());
    end;

    procedure ClearIdentity(var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    begin
        Clear(PrevBuffer."Item Projection Key");
        Clear(PrevBuffer."Item Projection Key Hash");
        Clear(PrevBuffer."Variant Projection Key");
        Clear(PrevBuffer."Variant Projection Key Hash");
    end;

    local procedure BuildRoleKey(
        ConfigurationNo: Code[20];
        ProjectionRole: Enum "SI ERP Projection Role";
        RoleRequired: Boolean): Text
    var
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        ConfigValue: Record "SI Product Config. Value";
        ResultBuilder: TextBuilder;
        CanonicalValue: Text;
        RoleParameterFound: Boolean;
        RoleValueIncluded: Boolean;
    begin
        ProductConfig.Get(ConfigurationNo);
        ProductConfig.TestField("Family Code");

        if (ProjectionRole = ProjectionRole::"Item Identity") and
           (ProductConfig."Base Item No." <> '')
        then
            exit(BuildBaseItemKey(ProductConfig."Base Item No."));

        ResultBuilder.Append(ProductConfig."Family Code");

        FamilyParameter.SetCurrentKey(
            "Family Code",
            "Parameter Order",
            "Parameter Code");
        FamilyParameter.SetRange(
            "Family Code",
            ProductConfig."Family Code");
        FamilyParameter.SetRange(
            "ERP Projection Role",
            ProjectionRole);
        FamilyParameter.SetRange(Blocked, false);

        if FamilyParameter.FindSet() then
            repeat
                RoleParameterFound := true;

                if ConfigValue.Get(
                    ConfigurationNo,
                    FamilyParameter."Parameter Code")
                then begin
                    ConfigValue.ValidateCompleteValue();

                    CanonicalValue := GetCanonicalValue(ConfigValue);
                    if CanonicalValue = '' then
                        Error(
                            CanonicalValueEmptyErr,
                            FamilyParameter."Parameter Code",
                            ConfigurationNo);

                    AppendKeyPart(
                        ResultBuilder,
                        FamilyParameter."Parameter Code",
                        CanonicalValue);

                    RoleValueIncluded := true;
                end else
                    if RoleRequired and FamilyParameter.Mandatory then
                        Error(
                            RoleValueMissingErr,
                            FamilyParameter."Parameter Code",
                            ConfigurationNo,
                            Format(ProjectionRole));
            until FamilyParameter.Next() = 0;

        if not RoleParameterFound then begin
            if (ProjectionRole = ProjectionRole::"Item Identity") and
               (ProductConfig."Base Item No." <> '')
            then
                exit(BuildBaseItemKey(ProductConfig."Base Item No."));

            if RoleRequired then
                Error(
                    NoRoleParametersErr,
                    ProductConfig."Family Code",
                    Format(ProjectionRole));

            exit('');
        end;

        if not RoleValueIncluded then begin
            if (ProjectionRole = ProjectionRole::"Item Identity") and
               (ProductConfig."Base Item No." <> '')
            then
                exit(BuildBaseItemKey(ProductConfig."Base Item No."));

            if RoleRequired then
                Error(
                    NoRoleValuesErr,
                    ProductConfig."Family Code",
                    ConfigurationNo,
                    Format(ProjectionRole));

            exit('');
        end;

        exit(ResultBuilder.ToText());
    end;

    local procedure GetCanonicalValue(
        ConfigValue: Record "SI Product Config. Value"): Text
    begin
        case ConfigValue."Value Type" of
            ConfigValue."Value Type"::"Controlled Value":
                exit(ConfigValue."Parameter Value Code");

            ConfigValue."Value Type"::Decimal:
                exit(Format(ConfigValue."Decimal Value", 0, 9));

            ConfigValue."Value Type"::Integer:
                exit(Format(ConfigValue."Integer Value", 0, 9));

            ConfigValue."Value Type"::Text:
                exit(ConfigValue."Text Value".Trim());

            ConfigValue."Value Type"::Boolean:
                exit(Format(ConfigValue."Boolean Value", 0, 9));

            ConfigValue."Value Type"::Date:
                exit(Format(ConfigValue."Date Value", 0, 9));

            ConfigValue."Value Type"::Reference:
                exit(ConfigValue."Reference Key");
        end;

        exit('');
    end;

    local procedure BuildBaseItemKey(BaseItemNo: Code[20]): Text
    var
        ResultBuilder: TextBuilder;
    begin
        ResultBuilder.Append('ITEM|NO=');
        ResultBuilder.Append(BaseItemNo);
        exit(ResultBuilder.ToText());
    end;

    local procedure BuildKeyHash(ProjectionKey: Text): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        if ProjectionKey = '' then
            exit('');

        exit(
            CryptographyManagement.GenerateHash(
                ProjectionKey,
                HashAlgorithmType::SHA256));
    end;

    local procedure AppendKeyPart(
        var ResultBuilder: TextBuilder;
        ParameterCode: Code[30];
        CanonicalValue: Text)
    begin
        if ResultBuilder.Length() > 0 then
            ResultBuilder.Append('|');

        ResultBuilder.Append(ParameterCode);
        ResultBuilder.Append('=');
        ResultBuilder.Append(CanonicalValue);
    end;

    var
        RoleValueMissingErr: Label
            'Для параметра %1 не задано значення у конфігурації %2. ERP-роль: %3.';

        CanonicalValueEmptyErr: Label
            'Значення параметра %1 у конфігурації %2 не має канонічного представлення.';

        NoRoleParametersErr: Label
            'Для сімейства %1 не налаштовано параметрів із ERP-роллю %2.';

        NoRoleValuesErr: Label
            'Для сімейства %1 у конфігурації %2 не задано жодного значення параметрів із ERP-роллю %3.';
}