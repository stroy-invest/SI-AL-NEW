table 53008 "SI ERP Projection Prev Buffer"
{
    Caption = 'Буфер попереднього перегляду ERP-проєкції';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Номер запису';
            DataClassification = SystemMetadata;
        }

        field(10; "Configuration No."; Code[20])
        {
            Caption = 'Номер конфігурації';
            TableRelation = "SI Product Config."."No.";
        }

        field(20; "Family Code"; Code[30])
        {
            Caption = 'Код сімейства';
            TableRelation = "SI Product Family".Code;
        }

        field(30; "Family Description"; Text[100])
        {
            Caption = 'Сімейство';
            Editable = false;
        }

        field(40; "Item Projection Key"; Text[2048])
        {
            Caption = 'Ключ проєкції товару';
            Editable = false;
        }

        field(50; "Item Projection Key Hash"; Text[64])
        {
            Caption = 'Hash ключа проєкції товару';
            Editable = false;
        }

        field(60; "Item Category Code"; Code[20])
        {
            Caption = 'Категорія товару';
            TableRelation = "Item Category".Code;
            Editable = false;
        }

        field(70; "Item Category Description"; Text[100])
        {
            Caption = 'Назва категорії товару';
            Editable = false;
        }

        field(80; "Item Template Code"; Code[20])
        {
            Caption = 'Шаблон товару';
            TableRelation = "Item Templ.".Code;
            Editable = false;
        }

        field(90; "Item Template Description"; Text[100])
        {
            Caption = 'Назва шаблону товару';
            Editable = false;
        }

        field(100; "Generated Item Code"; Text[250])
        {
            Caption = 'Згенерований код товару';
            Editable = false;
        }

        field(110; "Generated Item Description"; Text[250])
        {
            Caption = 'Згенерована назва товару';
            Editable = false;
        }

        field(120; "Generated Variant Code"; Text[250])
        {
            Caption = 'Згенерований код варіанта';
            Editable = false;
        }

        field(130; "Generated Variant Description"; Text[250])
        {
            Caption = 'Згенерована назва варіанта';
            Editable = false;
        }

        field(140; "Base UoM Code"; Code[10])
        {
            Caption = 'Базова одиниця виміру';
            TableRelation = "Unit of Measure".Code;

            trigger OnValidate()
            begin
                if "Base UoM Code" = '' then begin
                    "Base UoM Source" := "Base UoM Source"::None;
                    exit;
                end;

                if "Base UoM Source" in [
                    "Base UoM Source"::None,
                    "Base UoM Source"::Manual]
                then
                    "Base UoM Source" := "Base UoM Source"::Manual;
            end;
        }

        field(150; "Base UoM Source"; Enum "SI Base UoM Source")
        {
            Caption = 'Джерело базової одиниці виміру';
            Editable = false;
        }

        field(160; "Existing Item Prj. Entry No."; Integer)
        {
            Caption = 'Наявний запис проєкції товару';
            Editable = false;
            TableRelation = "SI Item ERP Projection"."Entry No.";
        }

        field(170; "Existing Item No."; Code[20])
        {
            Caption = 'Наявний товар BC';
            Editable = false;
            TableRelation = Item."No.";
        }

        field(180; "Existing Variant Code"; Code[10])
        {
            Caption = 'Наявний варіант BC';
            Editable = false;
            TableRelation =
                "Item Variant".Code
                where("Item No." = field("Existing Item No."));
        }

        field(190; Status; Enum "SI ERP Projection Status")
        {
            Caption = 'Статус готовності';
            Editable = false;
        }

        field(200; "Is Ready"; Boolean)
        {
            Caption = 'Готово до проєкції';
            Editable = false;
        }

        field(210; "Validation Message"; Text[2048])
        {
            Caption = 'Результат перевірки';
            Editable = false;
        }

        field(220; "Variant Projection Key"; Text[2048])
        {
            Caption = 'Ключ проєкції варіанта';
            Editable = false;
        }

        field(230; "Variant Projection Key Hash"; Text[64])
        {
            Caption = 'Hash ключа проєкції варіанта';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(Configuration; "Configuration No.")
        {
        }

        key(ItemProjection; "Family Code", "Item Projection Key Hash")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;
        "Configuration No.",
            "Family Code",
            "Generated Item Code",
            "Generated Variant Code",
            Status)
        {
        }
    }

    internal procedure Initialize(ConfigurationNo: Code[20])
    begin
        Init();
        "Entry No." := 1;
        "Configuration No." := ConfigurationNo;
        Status := Status::None;
        "Is Ready" := false;
        Clear("Validation Message");
    end;

    internal procedure SetAutomaticBaseUoM(
        BaseUoMCode: Code[10];
        Source: Enum "SI Base UoM Source")
    begin
        if not (Source in [
            Source::"Item Category",
            Source::"Item Template"])
        then
            Error(InvalidAutomaticUoMSourceErr);

        "Base UoM Code" := BaseUoMCode;
        "Base UoM Source" := Source;
    end;

    internal procedure SetManualBaseUoM(BaseUoMCode: Code[10])
    begin
        Validate("Base UoM Code", BaseUoMCode);

        if BaseUoMCode = '' then
            "Base UoM Source" := "Base UoM Source"::None
        else
            "Base UoM Source" := "Base UoM Source"::Manual;
    end;

    internal procedure SetValidationResult(
        NewStatus: Enum "SI ERP Projection Status";
        Ready: Boolean;
        MessageText: Text)
    begin
        Status := NewStatus;
        "Is Ready" := Ready;
        "Validation Message" :=
            CopyStr(
                MessageText,
                1,
                MaxStrLen("Validation Message"));
    end;

    internal procedure ClearResolvedData()
    begin
        Clear("Family Code");
        Clear("Family Description");

        Clear("Item Projection Key");
        Clear("Item Projection Key Hash");

        Clear("Item Category Code");
        Clear("Item Category Description");

        Clear("Item Template Code");
        Clear("Item Template Description");

        Clear("Generated Item Code");
        Clear("Generated Item Description");
        Clear("Generated Variant Code");
        Clear("Generated Variant Description");

        Clear("Base UoM Code");
        Clear("Base UoM Source");

        Clear("Existing Item Prj. Entry No.");
        Clear("Existing Item No.");
        Clear("Existing Variant Code");

        Status := Status::None;
        "Is Ready" := false;
        Clear("Validation Message");
    end;

    var
        InvalidAutomaticUoMSourceErr: Label
            'Автоматичним джерелом базової одиниці виміру може бути лише категорія товару або шаблон товару.';
}