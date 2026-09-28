table 53003 "SI Family Parameter"
{
    Caption = 'Параметр сімейства';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Family Parameters";
    LookupPageId = "SI Family Parameters";

    fields
    {
        field(1; "Family Code"; Code[30])
        {
            Caption = 'Код сімейства';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "SI Product Family".Code;

            trigger OnValidate()
            var
                ProductFamily: Record "SI Product Family";
            begin
                if "Family Code" = '' then
                    exit;

                ProductFamily.Get("Family Code");

                if ProductFamily.Blocked then
                    Error(BlockedFamilyErr, ProductFamily.Code);
            end;
        }

        field(2; "Parameter Code"; Code[30])
        {
            Caption = 'Код параметра';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "SI Product Parameter".Code;

            trigger OnValidate()
            var
                ProductParameter: Record "SI Product Parameter";
            begin
                if "Parameter Code" = '' then begin
                    Clear("Default Value Code");
                    exit;
                end;

                ProductParameter.Get("Parameter Code");

                if ProductParameter.Blocked then
                    Error(BlockedParameterErr, ProductParameter.Code);

                if (ProductParameter."Value Type" = ProductParameter."Value Type"::Reference) and
                   (ProductParameter."Reference Type" = ProductParameter."Reference Type"::None)
                then
                    Error(ReferenceTypeRequiredErr, ProductParameter.Code);

                ValidateParameterCategory(ProductParameter);

                if xRec."Parameter Code" <> "Parameter Code" then
                    Clear("Default Value Code");
            end;
        }

        field(10; "Parameter Order"; Integer)
        {
            Caption = 'Порядок параметра';
            DataClassification = CustomerContent;
            MinValue = 0;
        }

        field(20; Mandatory; Boolean)
        {
            Caption = 'Обов’язковий';
            DataClassification = CustomerContent;
        }

        field(30; "Identity Parameter"; Boolean)
        {
            Caption = 'Входить до ідентичності';
            Editable = false;
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Ідентичність визначається полем ERP Projection Role.';
            ObsoleteTag = '1.4.0.0';
        }

        field(40; "ERP Projection Role"; Enum "SI ERP Projection Role")
        {
            Caption = 'Роль в ERP-проєкції';
            DataClassification = CustomerContent;
        }

        field(50; "Include in Description"; Boolean)
        {
            Caption = 'Входить у назву';
            DataClassification = CustomerContent;
        }

        field(60; "Description Order"; Integer)
        {
            Caption = 'Порядок у назві';
            DataClassification = CustomerContent;
            MinValue = 0;
        }

        field(70; "Include in Code"; Boolean)
        {
            Caption = 'Входить у код';
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Короткі ERP-коди генеруються через No. Series.';
            ObsoleteTag = '1.4.0.0';
        }

        field(80; "Code Order"; Integer)
        {
            Caption = 'Порядок у коді';
            DataClassification = CustomerContent;
            MinValue = 0;
            ObsoleteState = Pending;
            ObsoleteReason = 'Короткі ERP-коди генеруються через No. Series.';
            ObsoleteTag = '1.4.0.0';
        }

        field(90; "Include in Search"; Boolean)
        {
            Caption = 'Входить у пошук';
            DataClassification = CustomerContent;
        }

        field(100; "Recipe Relevant"; Boolean)
        {
            Caption = 'Значущий для рецептури';
            DataClassification = CustomerContent;
        }

        field(110; "Default Value Code"; Code[30])
        {
            Caption = 'Значення за замовчуванням';
            DataClassification = CustomerContent;

            TableRelation =
                "SI Parameter Value".Code
                where("Parameter Code" = field("Parameter Code"));

            trigger OnValidate()
            var
                ProductParameter: Record "SI Product Parameter";
                ParameterValue: Record "SI Parameter Value";
            begin
                if "Default Value Code" = '' then
                    exit;

                TestField("Parameter Code");

                ProductParameter.Get("Parameter Code");
                ProductParameter.TestField(
                    "Value Type",
                    ProductParameter."Value Type"::"Controlled Value");

                ParameterValue.Get(
                    "Parameter Code",
                    "Default Value Code");

                if ParameterValue.Blocked then
                    Error(
                        BlockedDefaultValueErr,
                        "Default Value Code",
                        "Parameter Code");
            end;
        }

        field(120; Blocked; Boolean)
        {
            Caption = 'Заблоковано';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Family Code", "Parameter Code")
        {
            Clustered = true;
        }

        key(ParameterOrder; "Family Code", "Parameter Order", "Parameter Code")
        {
        }

        key(DescriptionOrder; "Family Code", "Description Order", "Parameter Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;
        "Family Code",
            "Parameter Code",
            Mandatory,
            "ERP Projection Role")
        {
        }
    }

    trigger OnInsert()
    begin
        ValidateSetup();
    end;

    trigger OnModify()
    begin
        ValidateSetup();
    end;

    local procedure ValidateSetup()
    begin
        TestField("Family Code");
        TestField("Parameter Code");

        ValidateParameterCategoryForCurrentRecord();
        ValidateOrderFields();
        ValidateDefaultValue();
    end;

    local procedure ValidateParameterCategoryForCurrentRecord()
    var
        ProductParameter: Record "SI Product Parameter";
    begin
        ProductParameter.Get("Parameter Code");

        if (ProductParameter."Value Type" = ProductParameter."Value Type"::Reference) and
           (ProductParameter."Reference Type" = ProductParameter."Reference Type"::None)
        then
            Error(ReferenceTypeRequiredErr, ProductParameter.Code);

        ValidateParameterCategory(ProductParameter);
    end;

    local procedure ValidateParameterCategory(
        ProductParameter: Record "SI Product Parameter")
    var
        ProductFamily: Record "SI Product Family";
        ItemCategory: Record "Item Category";
        CurrentCategoryCode: Code[20];
    begin
        if ProductParameter."Base Item Category Code" = '' then
            exit;

        if "Family Code" = '' then
            exit;

        ProductFamily.Get("Family Code");
        CurrentCategoryCode := ProductFamily."Item Category Code";

        while CurrentCategoryCode <> '' do begin
            if CurrentCategoryCode =
               ProductParameter."Base Item Category Code"
            then
                exit;

            if not ItemCategory.Get(CurrentCategoryCode) then
                break;

            CurrentCategoryCode := ItemCategory."Parent Category";
        end;

        Error(
            ParameterCategoryMismatchErr,
            ProductParameter.Code,
            ProductParameter."Base Item Category Code",
            ProductFamily.Code,
            ProductFamily."Item Category Code");
    end;

    local procedure ValidateOrderFields()
    begin
        if "Include in Description" then begin
            if "Description Order" = 0 then
                Error(DescriptionOrderRequiredErr);
        end else
            "Description Order" := 0;

        if "Include in Code" then begin
            if "Code Order" = 0 then
                Error(CodeOrderRequiredErr);
        end else
            "Code Order" := 0;
    end;

    local procedure ValidateDefaultValue()
    var
        ProductParameter: Record "SI Product Parameter";
        ParameterValue: Record "SI Parameter Value";
    begin
        if "Default Value Code" = '' then
            exit;

        ProductParameter.Get("Parameter Code");

        if ProductParameter."Value Type" <>
           ProductParameter."Value Type"::"Controlled Value"
        then
            Error(
                DefaultForControlledOnlyErr,
                "Parameter Code");

        ParameterValue.Get(
            "Parameter Code",
            "Default Value Code");

        if ParameterValue.Blocked then
            Error(
                BlockedDefaultValueErr,
                "Default Value Code",
                "Parameter Code");
    end;

    var
        BlockedFamilyErr: Label
            'Не можна використовувати заблоковане сімейство %1.';

        BlockedParameterErr: Label
            'Не можна використовувати заблокований параметр %1.';

        BlockedDefaultValueErr: Label
            'Значення %1 параметра %2 заблоковане й не може бути значенням за замовчуванням.';

        DescriptionOrderRequiredErr: Label
            'Для параметра, який входить у назву, потрібно вказати порядок у назві.';

        CodeOrderRequiredErr: Label
            'Для параметра, який входить у код, потрібно вказати порядок у коді.';

        ProjectionRequiresIdentityErr: Label
            'Параметр, який формує Item або Variant, повинен визначати ідентичність продукту.';

        NonIdentityRoleInCodeErr: Label
            'Параметр із роллю «Лише атрибут» або «Лише назва та пошук» не може входити до ERP-коду.';

        DefaultForControlledOnlyErr: Label
            'Значення за замовчуванням можна вибирати лише для параметра типу «Контрольоване значення». Параметр: %1.';

        ReferenceTypeRequiredErr: Label
            'Для параметра %1 типу «Кероване посилання» потрібно вибрати джерело посилання.';

        ParameterCategoryMismatchErr: Label
            'Параметр %1 належить до базової категорії %2 і не може бути доданий до сімейства %3 з категорією %4.';
}