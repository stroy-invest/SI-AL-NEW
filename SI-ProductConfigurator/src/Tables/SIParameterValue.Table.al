table 53002 "SI Parameter Value"
{
    Caption = 'Значення параметра';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Parameter Values";
    LookupPageId = "SI Parameter Values";

    fields
    {
        field(1; "Parameter Code"; Code[30])
        {
            Caption = 'Код параметра';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "SI Product Parameter".Code;

            trigger OnValidate()
            var
                ProductParameter: Record "SI Product Parameter";
            begin
                if "Parameter Code" = '' then
                    exit;

                ProductParameter.Get("Parameter Code");
                ProductParameter.TestField(
                    "Value Type",
                    ProductParameter."Value Type"::"Controlled Value");

                if ProductParameter.Blocked then
                    Error(
                        BlockedParameterErr,
                        ProductParameter.Code);
            end;
        }

        field(2; Code; Code[30])
        {
            Caption = 'Код значення';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()
            begin
                NormalizeCode();
            end;
        }

        field(3; Description; Text[100])
        {
            Caption = 'Назва';
            DataClassification = CustomerContent;
            NotBlank = true;
        }

        field(4; "Description EN"; Text[100])
        {
            Caption = 'Назва англійською';
            DataClassification = CustomerContent;
        }

        field(10; "Display Value"; Text[50])
        {
            Caption = 'Відображуване значення';
            DataClassification = CustomerContent;
            NotBlank = true;
        }

        field(20; "Numeric Value"; Decimal)
        {
            Caption = 'Числове значення';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
		// Додано 11.08.2026
		field(21; "Numeric UoM Code"; Code[10])
		{
			Caption = 'Одиниця виміру';
			TableRelation = "Unit of Measure".Code;
			DataClassification = CustomerContent;
		}

		field(22; "Numeric Meaning"; Text[100])
		{
			Caption = 'Зміст числового значення';
			FieldClass = FlowField;
			CalcFormula =
				lookup("Unit of Measure"."SI Describe"
					where(Code = field("Numeric UoM Code")));
			Editable = false;
		}
		//-------
        field(30; "Sort Order"; Integer)
        {
            Caption = 'Порядок сортування';
            DataClassification = CustomerContent;
            MinValue = 0;
        }

        field(40; Blocked; Boolean)
        {
            Caption = 'Заблоковано';
            DataClassification = CustomerContent;
        }

        field(41; "Ever Used"; Boolean)
        {
            Caption = 'Використовувалося';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50; "ERP Code"; Code[20])
        {
            Caption = 'Скорочений код ERP';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "ERP Code" := UpperCase(DelChr("ERP Code", '=', ' '));
            end;
        }
    }

    keys
    {
        key(PK; "Parameter Code", Code)
        {
            Clustered = true;
        }

        key(DisplayOrder; "Parameter Code", "Sort Order", Code)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, "Display Value", Description, Blocked)
        {
        }

        fieldgroup(Brick; Code, "Display Value", Description)
        {
        }
    }

    trigger OnInsert()
    begin
        NormalizeCode();
        ValidateParameter();
        CheckStaticSource();
    end;

    local procedure CheckStaticSource()
    var P: Record "SI Product Parameter";
    begin
        P.Get("Parameter Code");
        P.TestField("Value Source", P."Value Source"::Static);
    end;

    trigger OnModify()
    begin
        if xRec."Ever Used" then
            "Ever Used" := true;
        NormalizeCode();
        ValidateParameter();
    end;

    trigger OnDelete()
    var
        Attr: Record "SI Parameter Value Attr.";
    begin
        CheckRemovalAllowed();
        Attr.SetRange("Parameter Code", "Parameter Code");
        Attr.SetRange("Value Code", Code);
        Attr.DeleteAll(true);
    end;

    trigger OnRename()
    var
        Attr: Record "SI Parameter Value Attr.";
    begin
        xRec.CheckRemovalAllowed();
        Attr.SetRange("Parameter Code", xRec."Parameter Code");
        Attr.SetRange("Value Code", xRec.Code);
        if not Attr.IsEmpty() then
            Error('Спочатку видаліть додаткові характеристики.');
    end;

    procedure CheckRemovalAllowed()
    var
        ConfigValue: Record "SI Product Config. Value";
        FamilyParameter: Record "SI Family Parameter";
        TemplateParameter: Record "SI Family Template Parameter";
    begin
        if "Ever Used" then
            Error(UsedValueErr, "Parameter Code", Code);
        ConfigValue.SetRange("Parameter Code", "Parameter Code");
        ConfigValue.SetRange("Parameter Value Code", Code);
        if not ConfigValue.IsEmpty() then
            Error(ReferencedValueErr, "Parameter Code", Code);
        FamilyParameter.SetRange("Parameter Code", "Parameter Code");
        FamilyParameter.SetRange("Default Value Code", Code);
        if not FamilyParameter.IsEmpty() then
            Error(ReferencedValueErr, "Parameter Code", Code);
        TemplateParameter.SetRange("Parameter Code", "Parameter Code");
        TemplateParameter.SetRange("Default Value Code", Code);
        if not TemplateParameter.IsEmpty() then
            Error(ReferencedValueErr, "Parameter Code", Code);
    end;

    local procedure NormalizeCode()
    begin
        Code := UpperCase(DelChr(Code, '=', ' '));
    end;

    local procedure ValidateParameter()
    var
        ProductParameter: Record "SI Product Parameter";
    begin
        if "Parameter Code" = '' then
            exit;

        ProductParameter.Get("Parameter Code");

        if ProductParameter."Value Type" <>
           ProductParameter."Value Type"::"Controlled Value"
        then
            Error(
                InvalidParameterTypeErr,
                ProductParameter.Code);

        if ProductParameter.Blocked then
            Error(
                BlockedParameterErr,
                ProductParameter.Code);
    end;

    var
        UsedValueErr: Label 'Значення %2 параметра %1 вже використовувалося. Його можна лише заблокувати.';
        ReferencedValueErr: Label 'Значення %2 параметра %1 має залежні записи. Спочатку усуньте посилання.';
        InvalidParameterTypeErr: Label
            'Допустимі значення можна створювати лише для параметрів із типом «Контрольоване значення». Параметр: %1.';
        BlockedParameterErr: Label
            'Не можна створювати або змінювати значення заблокованого параметра %1.';
}