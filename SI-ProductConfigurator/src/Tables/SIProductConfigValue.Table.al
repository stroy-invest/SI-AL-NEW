table 53005 "SI Product Config. Value"
{
    Caption = 'Значення конфігурації продукту';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Configuration No."; Code[20])
        {
            Caption = 'Номер конфігурації';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "SI Product Config."."No.";

            trigger OnValidate()
            begin
                CheckConfigurationEditable();
            end;
        }

        field(2; "Parameter Code"; Code[30])
        {
            Caption = 'Код параметра';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "SI Product Parameter".Code;

            trigger OnValidate()
            begin
                CheckConfigurationEditable();
                ValidateParameter();
            end;
        }

        field(10; "Value Type"; Enum "SI Param. Value Type")
        {
            Caption = 'Тип значення';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(20; "Parameter Value Code"; Code[30])
        {
            Caption = 'Контрольоване значення';
            DataClassification = CustomerContent;

            TableRelation =
                "SI Parameter Value".Code
                where("Parameter Code" = field("Parameter Code"));

            trigger OnValidate()
            begin
                CheckConfigurationEditable();
                ValidateControlledValue();
            end;
        }

        field(30; "Decimal Value"; Decimal)
        {
            Caption = 'Десяткове значення';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                CheckConfigurationEditable();
                TestExpectedValueType("Value Type"::Decimal);
                ClearOtherValueFields(FieldNo("Decimal Value"));
                BuildScalarDisplayValue(Format("Decimal Value"));
            end;
        }

        field(40; "Integer Value"; Integer)
        {
            Caption = 'Ціле значення';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckConfigurationEditable();
                TestExpectedValueType("Value Type"::Integer);
                ClearOtherValueFields(FieldNo("Integer Value"));
                BuildScalarDisplayValue(Format("Integer Value"));
            end;
        }

        field(50; "Text Value"; Text[250])
        {
            Caption = 'Текстове значення';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckConfigurationEditable();
                TestExpectedValueType("Value Type"::Text);
                ClearOtherValueFields(FieldNo("Text Value"));
                BuildScalarDisplayValue("Text Value");
            end;
        }

        field(60; "Boolean Value"; Boolean)
        {
            Caption = 'Значення Так/Ні';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckConfigurationEditable();
                TestExpectedValueType("Value Type"::Boolean);
                ClearOtherValueFields(FieldNo("Boolean Value"));
                BuildScalarDisplayValue(Format("Boolean Value"));
            end;
        }

        field(70; "Date Value"; Date)
        {
            Caption = 'Значення дати';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckConfigurationEditable();
                TestExpectedValueType("Value Type"::Date);
                ClearOtherValueFields(FieldNo("Date Value"));
                BuildScalarDisplayValue(Format("Date Value"));
            end;
        }

        field(80; "Display Value"; Text[250])
        {
            Caption = 'Відображуване значення';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(90; "Parameter Order"; Integer)
        {
            Caption = 'Порядок параметра';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(100; "Reference SystemId"; Guid)
        {
            Caption = 'Ідентифікатор посилання';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(110; "Reference Key"; Text[250])
        {
            Caption = 'Ключ посилання';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(120; "Maintenance Editable"; Boolean)
        {
            Caption = 'Дозволено технічне редагування';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Configuration No.", "Parameter Code")
        {
            Clustered = true;
        }

        key(ParameterOrder;
        "Configuration No.",
            "Parameter Order",
            "Parameter Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(
            DropDown;
        "Configuration No.",
            "Parameter Code",
            "Display Value")
        {
        }
    }

    trigger OnInsert()
    begin
        CheckConfigurationEditable();

        TestField("Configuration No.");
        TestField("Parameter Code");

        ValidateParameter();
    end;

    trigger OnModify()
    begin
        CheckConfigurationEditable();

        TestField("Configuration No.");
        TestField("Parameter Code");

        ValidateParameterMetadata();
    end;

    trigger OnDelete()
    begin
        CheckConfigurationDeleteAllowed();
    end;

    trigger OnRename()
    begin
        //CheckConfigurationEditable();
        Error(RenameNotAllowedErr);
    end;

    internal procedure SetMaintenanceInsertMode(Enabled: Boolean)
    begin
        MaintenanceInsertMode := Enabled;
    end;

    internal procedure ValidateCompleteValue()
    begin
        TestField("Configuration No.");
        TestField("Parameter Code");

        ValidateParameterMetadata();

        case "Value Type" of
            "Value Type"::"Controlled Value":
                begin
                    TestField("Parameter Value Code");
                    ValidateControlledValue();
                end;

            "Value Type"::Decimal:
                BuildScalarDisplayValue(Format("Decimal Value"));

            "Value Type"::Integer:
                BuildScalarDisplayValue(Format("Integer Value"));

            "Value Type"::Text:
                begin
                    TestField("Text Value");
                    BuildScalarDisplayValue("Text Value");
                end;

            "Value Type"::Boolean:
                BuildScalarDisplayValue(Format("Boolean Value"));

            "Value Type"::Date:
                begin
                    TestField("Date Value");
                    BuildScalarDisplayValue(Format("Date Value"));
                end;

            "Value Type"::Reference:
                ValidateReferenceValue();
        end;
    end;

    internal procedure SetReferenceValue(
        ReferenceSystemId: Guid;
        ReferenceKey: Text[250];
        ReferenceDisplayValue: Text[250])
    begin
        CheckConfigurationEditable();
        TestExpectedValueType("Value Type"::Reference);
        ClearOtherValueFields(0);
        "Reference SystemId" := ReferenceSystemId;
        "Reference Key" := ReferenceKey;
        "Display Value" := ReferenceDisplayValue;
        ValidateReferenceValue();
    end;

    local procedure ValidateReferenceValue()
    var
        ProductConfig: Record "SI Product Config.";
        ProductParameter: Record "SI Product Parameter";
        FamilyParameter: Record "SI Family Parameter";
        ReferenceParameterMgt: Codeunit "SI Reference Parameter Mgt.";
    begin
        TestExpectedValueType("Value Type"::Reference);
        ProductConfig.Get("Configuration No.");
        FamilyParameter.Get(ProductConfig."Family Code", "Parameter Code");
        ProductParameter.Get("Parameter Code");
        ProductParameter.TestField("Reference Type");

        ReferenceParameterMgt.ValidateValue(
            ProductConfig,
            FamilyParameter,
            ProductParameter."Reference Type",
            "Reference SystemId",
            "Reference Key",
            "Display Value");
    end;

    local procedure ValidateParameter()
    var
        FamilyParameter: Record "SI Family Parameter";
    begin
        ValidateParameterMetadata(FamilyParameter);
        ApplyDefaultValue(FamilyParameter);
    end;

    local procedure ValidateParameterMetadata()
    var
        FamilyParameter: Record "SI Family Parameter";
    begin
        ValidateParameterMetadata(FamilyParameter);
    end;

    local procedure ValidateParameterMetadata(
        var FamilyParameter: Record "SI Family Parameter")
    var
        ProductConfig: Record "SI Product Config.";
        ProductParameter: Record "SI Product Parameter";
    begin
        if "Parameter Code" = '' then begin
            ClearParameterMetadata();
            ClearValueFields();
            exit;
        end;

        TestField("Configuration No.");

        ProductConfig.Get("Configuration No.");
        ProductConfig.TestField("Family Code");

        if not FamilyParameter.Get(
            ProductConfig."Family Code",
            "Parameter Code")
        then
            Error(
                ParameterNotInFamilyErr,
                "Parameter Code",
                ProductConfig."Family Code");

        if FamilyParameter.Blocked then
            Error(
                BlockedFamilyParameterErr,
                "Parameter Code",
                ProductConfig."Family Code");

        ValidateParameterRole(ProductConfig, FamilyParameter);

        ProductParameter.Get("Parameter Code");

        if ProductParameter.Blocked then
            Error(
                BlockedParameterErr,
                ProductParameter.Code);

        "Value Type" := ProductParameter."Value Type";
        "Parameter Order" := FamilyParameter."Parameter Order";
    end;

    local procedure ValidateParameterRole(
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter")
    begin
        if ProductConfig."Base Item No." <> '' then begin
            if FamilyParameter."ERP Projection Role" <>
               FamilyParameter."ERP Projection Role"::"Variant Identity"
            then
                Error(
                    VariantModeParameterErr,
                    FamilyParameter."Parameter Code");

            exit;
        end;

        if FamilyParameter."ERP Projection Role" <>
           FamilyParameter."ERP Projection Role"::"Item Identity"
        then
            Error(
                ItemModeParameterErr,
                FamilyParameter."Parameter Code");
    end;

    local procedure ApplyDefaultValue(
        FamilyParameter: Record "SI Family Parameter")
    begin
        if "Display Value" <> '' then
            exit;

        if "Value Type" <> "Value Type"::"Controlled Value" then
            exit;

        if FamilyParameter."Default Value Code" = '' then
            exit;

        Validate(
            "Parameter Value Code",
            FamilyParameter."Default Value Code");
    end;

    local procedure ValidateControlledValue()
    var
        ParameterValue: Record "SI Parameter Value";
    begin
        if "Parameter Value Code" = '' then begin
            Clear("Display Value");
            exit;
        end;

        TestExpectedValueType(
            "Value Type"::"Controlled Value");

        TestField("Parameter Code");

        ParameterValue.Get(
            "Parameter Code",
            "Parameter Value Code");

        if ParameterValue.Blocked then
            Error(
                BlockedParameterValueErr,
                "Parameter Value Code",
                "Parameter Code");

        ClearOtherValueFields(
            FieldNo("Parameter Value Code"));

        if ParameterValue."Display Value" <> '' then
            "Display Value" :=
                ParameterValue."Display Value"
        else
            "Display Value" := ParameterValue.Code;
    end;

    local procedure TestExpectedValueType(
        ExpectedValueType: Enum "SI Param. Value Type")
    begin
        if "Value Type" <> ExpectedValueType then
            Error(
                InvalidValueTypeErr,
                "Parameter Code",
                Format("Value Type"),
                Format(ExpectedValueType));
    end;

    local procedure BuildScalarDisplayValue(
        RawValue: Text)
    var
        ProductParameter: Record "SI Product Parameter";
    begin
        if "Parameter Code" = '' then begin
            "Display Value" := CopyStr(
                RawValue,
                1,
                MaxStrLen("Display Value"));
            exit;
        end;

        ProductParameter.Get("Parameter Code");

        "Display Value" := CopyStr(
            ProductParameter."Value Prefix" +
            RawValue +
            ProductParameter."Value Suffix",
            1,
            MaxStrLen("Display Value"));
    end;

    local procedure ClearParameterMetadata()
    begin
        Clear("Value Type");
        Clear("Parameter Order");
    end;

    local procedure ClearValueFields()
    begin
        Clear("Parameter Value Code");
        Clear("Decimal Value");
        Clear("Integer Value");
        Clear("Text Value");
        Clear("Boolean Value");
        Clear("Date Value");
        Clear("Reference SystemId");
        Clear("Reference Key");
        Clear("Display Value");
    end;

    local procedure ClearOtherValueFields(
        CurrentFieldNo: Integer)
    begin
        if CurrentFieldNo <>
           FieldNo("Parameter Value Code")
        then
            Clear("Parameter Value Code");

        if CurrentFieldNo <>
           FieldNo("Decimal Value")
        then
            Clear("Decimal Value");

        if CurrentFieldNo <>
           FieldNo("Integer Value")
        then
            Clear("Integer Value");

        if CurrentFieldNo <>
           FieldNo("Text Value")
        then
            Clear("Text Value");

        if CurrentFieldNo <>
           FieldNo("Boolean Value")
        then
            Clear("Boolean Value");

        if CurrentFieldNo <>
           FieldNo("Date Value")
        then
            Clear("Date Value");

        Clear("Reference SystemId");
        Clear("Reference Key");
    end;

    local procedure CheckConfigurationEditable()
    var
        ProductConfig: Record "SI Product Config.";
    begin
        if "Configuration No." = '' then
            exit;

        ProductConfig.Get("Configuration No.");

        if ProductConfig.Blocked then
            Error(
                BlockedConfigurationErr,
                ProductConfig."No.");

        if ProductConfig.Status = ProductConfig.Status::Draft then
            exit;

        if MaintenanceInsertMode then
            exit;

        if (ProductConfig.Status = ProductConfig.Status::Projected) and
           "Maintenance Editable"
        then
            exit;

        Error(
            ConfigurationNotEditableErr,
            ProductConfig."No.",
            Format(ProductConfig.Status));
    end;

    local procedure CheckConfigurationDeleteAllowed()
    var
        ProductConfig: Record "SI Product Config.";
    begin
        if "Configuration No." = '' then
            exit;

        ProductConfig.Get("Configuration No.");

        if ProductConfig.Blocked then
            Error(BlockedConfigurationErr, ProductConfig."No.");

        if ProductConfig.Status <> ProductConfig.Status::Draft then
            Error(
                ConfigurationNotEditableErr,
                ProductConfig."No.",
                Format(ProductConfig.Status));
    end;

    var
        MaintenanceInsertMode: Boolean;
        ParameterNotInFamilyErr: Label
            'Параметр %1 не налаштований для сімейства %2.';

        BlockedFamilyParameterErr: Label
            'Параметр %1 заблокований для сімейства %2.';

        BlockedParameterErr: Label
            'Параметр %1 заблокований і не може використовуватися.';

        BlockedParameterValueErr: Label
            'Значення %1 параметра %2 заблоковане й не може використовуватися.';

        InvalidValueTypeErr: Label
            'Параметр %1 має тип «%2». Для цього поля очікується тип «%3».';

        BlockedConfigurationErr: Label
            'Конфігурація %1 заблокована й не може змінюватися.';

        ConfigurationNotEditableErr: Label
            'Конфігурацію %1 зі статусом «%2» не можна змінювати.';
        RenameNotAllowedErr: Label
            'Не можна змінювати параметр або номер конфігурації в уже створеному рядку. Видаліть рядок і створіть новий.';
        ItemModeParameterErr: Label 'Параметр %1 не визначає ідентичність товару й недоступний у режимі створення нового товару.';
        VariantModeParameterErr: Label 'Параметр %1 не визначає ідентичність варіанта й недоступний у режимі створення варіанта.';

}