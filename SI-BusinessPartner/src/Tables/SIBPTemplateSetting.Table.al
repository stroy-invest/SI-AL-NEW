table 54080 "SI BP Template Setting"
{
    Caption = 'Налаштування шаблонів контрагентів';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI BP Template Settings";
    LookupPageId = "SI BP Template Settings";

    fields
    {
        field(1; Code; Code[30])
        {
            Caption = 'Код';
        }

        field(10; "Role Type"; Enum "SI BP Role Type")
        {
            Caption = 'Тип ролі';

            trigger OnValidate()
            begin
                if "Role Type" <> xRec."Role Type" then
                    Clear("Template Code");
                RefreshGeneratedCode();
                CheckUniqueActiveMappingIfComplete();
            end;
        }

        field(20; "Country/Region Code"; Code[10])
        {
            Caption = 'Країна/регіон';
            NotBlank = true;
            TableRelation = "Country/Region".Code;

            trigger OnValidate()
            begin
                RefreshGeneratedCode();
                CheckUniqueActiveMappingIfComplete();
            end;
        }

        field(30; "VAT Status"; Enum "SI BP VAT Status")
        {
            Caption = 'Статус ПДВ';

            trigger OnValidate()
            begin
                RefreshGeneratedCode();
                CheckUniqueActiveMappingIfComplete();
            end;
        }

        field(40; "Template Code"; Code[20])
        {
            Caption = 'Код шаблону';

            trigger OnValidate()
            begin
                ValidateTemplateCode();
                CheckUniqueActiveMappingIfComplete();
            end;
        }

        field(50; Active; Boolean)
        {
            Caption = 'Активне';
            InitValue = true;

            trigger OnValidate()
            begin
                if Active then
                    CheckUniqueActiveMappingIfComplete();
            end;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
        key(Resolution; "Role Type", "Country/Region Code", "VAT Status", Active)
        {
        }
    }

    trigger OnInsert()
    begin
        EnsureGeneratedCode();
        ValidateConfiguration();
    end;

    trigger OnModify()
    begin
        EnsureGeneratedCode();
        ValidateConfiguration();
    end;

    procedure ValidateConfiguration()
    begin
        TestField("Country/Region Code");
        TestField("Template Code");
        ValidateTemplateCode();
        if Active then
            CheckUniqueActiveMapping();
    end;

    local procedure RefreshGeneratedCode()
    var
        NewCode: Code[30];
    begin
        if "Country/Region Code" = '' then
            exit;

        NewCode := BuildGeneratedCode();
        if NewCode <> '' then
            Code := NewCode;
    end;

    local procedure EnsureGeneratedCode()
    begin
        TestField("Country/Region Code");
        Code := BuildGeneratedCode();
        if Code = '' then
            Error(CannotGenerateCodeErr);
    end;

    local procedure BuildGeneratedCode(): Code[30]
    var
        RoleToken: Text[10];
        VATToken: Text[10];
    begin
        case "Role Type" of
            "Role Type"::Customer:
                RoleToken := 'CUST';
            "Role Type"::Vendor:
                RoleToken := 'VEND';
        end;

        case "VAT Status" of
            "VAT Status"::VAT:
                VATToken := 'VAT';
            "VAT Status"::"Non-VAT":
                VATToken := 'NOVAT';
        end;

        if (RoleToken = '') or (VATToken = '') then
            exit('');

        exit(CopyStr(UpperCase("Country/Region Code") + '-' + RoleToken + '-' + VATToken, 1, MaxStrLen(Code)));
    end;

    local procedure ValidateTemplateCode()
    var
        CustomerTemplate: Record "Customer Templ.";
        VendorTemplate: Record "Vendor Templ.";
    begin
        if "Template Code" = '' then
            exit;

        case "Role Type" of
            "Role Type"::Customer:
                if not CustomerTemplate.Get("Template Code") then
                    Error(CustomerTemplateNotFoundErr, "Template Code");
            "Role Type"::Vendor:
                if not VendorTemplate.Get("Template Code") then
                    Error(VendorTemplateNotFoundErr, "Template Code");
        end;
    end;

    local procedure CheckUniqueActiveMappingIfComplete()
    begin
        if not Active then
            exit;
        if "Country/Region Code" = '' then
            exit;
        if "Template Code" = '' then
            exit;
        CheckUniqueActiveMapping();
    end;

    local procedure CheckUniqueActiveMapping()
    var
        TemplateSetting: Record "SI BP Template Setting";
    begin
        TemplateSetting.SetRange("Role Type", "Role Type");
        TemplateSetting.SetRange("Country/Region Code", "Country/Region Code");
        TemplateSetting.SetRange("VAT Status", "VAT Status");
        TemplateSetting.SetRange(Active, true);
        TemplateSetting.SetFilter(Code, '<>%1', Code);

        if not TemplateSetting.IsEmpty() then
            Error(DuplicateActiveMappingErr, Format("Role Type"), "Country/Region Code", Format("VAT Status"));
    end;

    var
        CustomerTemplateNotFoundErr: Label 'Шаблон клієнта %1 не існує.', Comment = '%1 = Customer Template Code';
        VendorTemplateNotFoundErr: Label 'Шаблон постачальника %1 не існує.', Comment = '%1 = Vendor Template Code';
        DuplicateActiveMappingErr: Label 'Для комбінації Тип ролі = %1, Країна/регіон = %2, Статус ПДВ = %3 вже існує активне налаштування шаблону.', Comment = '%1 = Role Type, %2 = Country/Region Code, %3 = VAT Status';
        CannotGenerateCodeErr: Label 'Не вдалося автоматично сформувати технічний код налаштування шаблону.';
}
