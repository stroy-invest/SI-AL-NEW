table 53001 "SI Product Parameter"
{
    Caption = 'Параметр продукту';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Product Parameters";
    LookupPageId = "SI Product Parameters";

    fields
    {
        field(1; Code; Code[30])
        {
            Caption = 'Код';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()
            begin
                NormalizeCode();
            end;
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

        field(10; "Value Type"; Enum "SI Param. Value Type")
        {
            Caption = 'Тип значення';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckValueTypeChange();
                if "Value Type" <> "Value Type"::Reference then
                    Clear("Reference Type");
            end;
        }

        field(20; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Одиниця виміру';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure".Code;
        }

        field(30; "Value Prefix"; Text[100])
        {
            Caption = 'Префікс значення';
            DataClassification = CustomerContent;
        }

        field(40; "Value Suffix"; Text[100])
        {
            Caption = 'Суфікс значення';
            DataClassification = CustomerContent;
        }

        field(50; "Sort Order"; Integer)
        {
            Caption = 'Порядок сортування';
            DataClassification = CustomerContent;
            MinValue = 0;
        }

        field(60; Blocked; Boolean)
        {
            Caption = 'Заблоковано';
            DataClassification = CustomerContent;
        }

        field(70; "Base Item Category Code"; Code[20])
        {
            Caption = 'Базова категорія товару';
            DataClassification = CustomerContent;
            TableRelation = "Item Category".Code;
        }

        field(80; "Reference Type"; Enum "SI Parameter Reference Type")
        {
            Caption = 'Джерело посилання';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Value Type" <> "Value Type"::Reference then
                    TestField("Reference Type", "Reference Type"::None);
            end;
        }

        field(90; "SI Semantic Code"; Code[50])
        {
            Caption = 'Семантика параметра';
            DataClassification = CustomerContent;
            TableRelation = "SI Attribute Semantic".Code;
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

        key(BaseItemCategory; "Base Item Category Code", Code)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description, "Base Item Category Code", "Value Type", Blocked)
        {
        }

        fieldgroup(Brick; Code, Description, "Value Type")
        {
        }
    }

    trigger OnInsert()
    begin
        NormalizeCode();
        ValidateReferenceSetup();
    end;

    trigger OnModify()
    begin
        NormalizeCode();
        ValidateReferenceSetup();
    end;

    trigger OnDelete()
    begin
        CheckDeleteAllowed();
    end;

    local procedure ValidateReferenceSetup()
    begin
        // Reference Type is intentionally allowed to stay None while the user
        // switches Value Type to Reference and then selects the provider.
        // Completeness is enforced when the parameter is assigned to a family
        // and when a reference value is actually used.
        if ("Value Type" <> "Value Type"::Reference) and
           ("Reference Type" <> "Reference Type"::None)
        then
            Error(ReferenceTypeOnlyForReferenceErr);
    end;

    local procedure NormalizeCode()
    begin
        Code := UpperCase(DelChr(Code, '=', ' '));
    end;

    local procedure CheckValueTypeChange()
    var
        ParameterValue: Record "SI Parameter Value";
    begin
        if xRec."Value Type" = "Value Type" then
            exit;

        if xRec.Code = '' then
            exit;

        ParameterValue.SetRange("Parameter Code", Code);

        if not ParameterValue.IsEmpty() then
            Error(ValueTypeChangeErr, Code);
    end;

    local procedure CheckDeleteAllowed()
    var
        ParameterValue: Record "SI Parameter Value";
    begin
        ParameterValue.SetRange("Parameter Code", Code);

        if not ParameterValue.IsEmpty() then
            Error(DeleteParameterErr, Code);
    end;

    var
        ValueTypeChangeErr: Label
            'Не можна змінити тип значення параметра %1, оскільки для нього вже створено допустимі значення.';

        DeleteParameterErr: Label
            'Не можна видалити параметр %1, оскільки для нього вже створено допустимі значення.';
        ReferenceTypeOnlyForReferenceErr: Label 'Джерело посилання можна задавати лише для параметра типу «Кероване посилання».';
}