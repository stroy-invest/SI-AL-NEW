table 53000 "SI Product Family"
{
    Caption = 'Сімейство продуктів';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Product Families";
    LookupPageId = "SI Product Families";

    fields
    {
        field(1; Code; Code[30])
        {
            Caption = 'Код';
            DataClassification = CustomerContent;
            NotBlank = true;
        }

        field(2; Description; Text[100])
        {
            Caption = 'Назва';
            DataClassification = CustomerContent;
            NotBlank = true;
        }

        field(3; "Description EN"; Text[100])
        {
            Caption = 'Назва англійською';
            DataClassification = CustomerContent;
        }

        field(10; Blocked; Boolean)
        {
            Caption = 'Заблоковано';
            DataClassification = CustomerContent;
        }

        field(20; "Supports Recipes"; Boolean)
        {
            Caption = 'Підтримує рецептури';
            DataClassification = CustomerContent;
        }

        field(30; "Item Category Code"; Code[20])
        {
            Caption = 'Категорія товару';
            DataClassification = CustomerContent;
            TableRelation = "Item Category".Code;

            trigger OnValidate()
            var
                ValidationEngine: Codeunit "SI Validation Engine";
            begin
                if "Item Category Code" = '' then
                    exit;

                ValidationEngine.ValidateCategoryForFamily(
                    "Item Category Code",
                    Code);
            end;
        }

        field(40; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Базова одиниця виміру';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure".Code;
        }

        field(50; "Name Prefix"; Text[50])
        {
            Caption = 'Префікс назви';
            DataClassification = CustomerContent;
        }

        field(60; "Sort Order"; Integer)
        {
            Caption = 'Порядок сортування';
            DataClassification = CustomerContent;
            MinValue = 0;
        }

        field(70; "Item Template Code"; Code[20])
        {
            Caption = 'Шаблон товару';
            DataClassification = CustomerContent;
            TableRelation = "Item Templ.".Code;
            NotBlank = true;
        }

        field(80; "Item Code Prefix"; Code[10])
        {
            Caption = 'Префікс коду товару';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "Item Code Prefix" := UpperCase(DelChr("Item Code Prefix", '=', ' '));
            end;
        }

        field(100; "Family Template Code"; Code[30])
        {
            Caption = 'Шаблон сімейства';
            DataClassification = CustomerContent;
            TableRelation = "SI Product Family Template".Code where(Blocked = const(false));
        }

        field(90; "Variant Code Prefix"; Code[5])
        {
            Caption = 'Префікс коду варіанта';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "Variant Code Prefix" := UpperCase(DelChr("Variant Code Prefix", '=', ' '));
            end;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }

        key(SortOrder; "Sort Order", Description)
        {
        }

        key(ItemCategory; "Item Category Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description, Blocked)
        {
        }

        fieldgroup(Brick; Code, Description)
        {
        }
    }

    trigger OnInsert()
    begin
        NormalizeCode();
    end;

    trigger OnModify()
    begin
        NormalizeCode();
    end;

    internal procedure ValidateSetup()
    var
        ValidationEngine: Codeunit "SI Validation Engine";
    begin
        if "Item Category Code" = '' then
            Error(ItemCategoryRequiredErr, Code);

        ValidationEngine.ValidateCategoryForFamily(
            "Item Category Code",
            Code);

        if "Item Template Code" = '' then
            Error(ItemTemplateRequiredErr, Code);
    end;

    local procedure NormalizeCode()
    begin
        Code := UpperCase(DelChr(Code, '<>', ' '));
    end;

    var
        ItemCategoryRequiredErr: Label
            'Для сімейства %1 не задано категорію товару. Виберіть кінцеву категорію товару.';
        ItemTemplateRequiredErr: Label
            'Для сімейства %1 не задано шаблон товару. Призначте сімейству наявний Item Template.';
}