table 53007 "SI Config. ERP Projection"
{
    Caption = 'ERP-проєкція конфігурації';
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
            var
                ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
            begin
                if "Configuration No." = '' then begin
                    ClearDerivedFields();
                    exit;
                end;

                ERPProjectionMgt.PopulateProjectionFromConfiguration(Rec);
            end;
        }

        field(10; "Family Code"; Code[30])
        {
            Caption = 'Код сімейства';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "SI Product Family".Code;
        }

        field(20; "Item Projection Key"; Text[2048])
        {
            Caption = 'Ключ проєкції товару';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(30; "Item Projection Key Hash"; Text[64])
        {
            Caption = 'Hash ключа проєкції товару';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(40; "Item Projection Entry No."; Integer)
        {
            Caption = 'Запис проєкції товару';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "SI Item ERP Projection"."Entry No.";
        }

        field(50; "Item No."; Code[20])
        {
            Caption = 'Номер товару BC';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";

            trigger OnValidate()
            var
                ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
            begin
                Clear("Variant Code");
                Clear("Item Projection Entry No.");

                if "Item No." = '' then
                    exit;

                TestField("Family Code");
                ERPProjectionMgt.ValidateItemForFamily("Family Code", "Item No.");
            end;
        }

        field(60; "Item Description"; Text[100])
        {
            Caption = 'Назва товару';
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Editable = false;
        }

        field(70; "Variant Code"; Code[10])
        {
            Caption = 'Код варіанта BC';
            DataClassification = CustomerContent;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if "Variant Code" = '' then
                    exit;

                TestField("Item No.");
                ItemVariant.Get("Item No.", "Variant Code");
            end;
        }

        field(80; "Variant Description"; Text[100])
        {
            Caption = 'Назва варіанта';
            FieldClass = FlowField;
            CalcFormula = lookup("Item Variant".Description where("Item No." = field("Item No."), Code = field("Variant Code")));
            Editable = false;
        }

        field(90; Status; Enum "SI ERP Projection Status")
        {
            Caption = 'Статус';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(100; "Projected At"; DateTime)
        {
            Caption = 'Спроєктовано';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(110; "Projected By"; Code[50])
        {
            Caption = 'Виконав проєкцію';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }

        field(120; "Last Error"; Text[250])
        {
            Caption = 'Остання помилка';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(130; "Generated Variant Code"; Code[10])
        {
            Caption = 'Згенерований код варіанта';
            DataClassification = CustomerContent;
        }

        field(140; "Generated Variant Description"; Text[100])
        {
            Caption = 'Згенерована назва варіанта';
            DataClassification = CustomerContent;
        }

        field(150; "Item Category Code"; Code[20])
        {
            Caption = 'Категорія товару';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Item Category".Code;
        }

        field(160; "Item Template Code"; Code[20])
        {
            Caption = 'Шаблон товару';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Item Templ.".Code;
        }

        field(170; "Base UoM Code"; Code[10])
        {
            Caption = 'Базова одиниця виміру';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure".Code;
        }

        field(180; "Base UoM Source"; Enum "SI Base UoM Source")
        {
            Caption = 'Джерело базової одиниці виміру';
            DataClassification = CustomerContent;
        }

        field(190; "Variant Projection Key"; Text[2048])
        {
            Caption = 'Ключ проєкції варіанта';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(200; "Variant Projection Key Hash"; Text[64])
        {
            Caption = 'Hash ключа проєкції варіанта';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Configuration No.")
        {
            Clustered = true;
        }

        key(ItemVariant; "Item No.", "Variant Code")
        {
        }

        key(ItemProjection; "Item Projection Entry No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Configuration No.", "Item No.", "Variant Code", Status)
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Configuration No.");

        if "Family Code" = '' then
            Validate("Configuration No.");
    end;

    trigger OnDelete()
    var
        ProductConfig: Record "SI Product Config.";
    begin
        if Status = Status::Projected then
            Error(LinkedProjectionDeleteErr, "Configuration No.");

        if ProductConfig.Get("Configuration No.") then
            if ProductConfig.Status = ProductConfig.Status::Projected then
                Error(ProjectedConfigurationDeleteErr, "Configuration No.");
    end;

    internal procedure SetLinked(ItemProjectionEntryNo: Integer)
    begin
        "Item Projection Entry No." := ItemProjectionEntryNo;
        Status := Status::Projected;
        "Projected At" := CurrentDateTime();
        "Projected By" := CopyStr(UserId(), 1, MaxStrLen("Projected By"));
        Clear("Last Error");
    end;

    internal procedure SetError(ErrorText: Text)
    begin
        Status := Status::Failed;
        "Last Error" := CopyStr(ErrorText, 1, MaxStrLen("Last Error"));
    end;

    internal procedure ClearDerivedFields()
    begin
        Clear("Family Code");
        Clear("Item Projection Key");
        Clear("Item Projection Key Hash");
        Clear("Item Projection Entry No.");

        Clear("Generated Variant Code");
        Clear("Generated Variant Description");
        Clear("Variant Projection Key");
        Clear("Variant Projection Key Hash");

        Clear("Item Category Code");
        Clear("Item Template Code");
        Clear("Base UoM Code");
        Clear("Base UoM Source");

        Clear("Item No.");
        Clear("Variant Code");
        Clear(Status);
        Clear("Projected At");
        Clear("Projected By");
        Clear("Last Error");
    end;

    var
        LinkedProjectionDeleteErr: Label
            //'Прив’язану ERP-проєкцію конфігурації %1 не можна видалити.';
            'Матеріалізовану ERP-проєкцію конфігурації %1 не можна видалити.';

        ProjectedConfigurationDeleteErr: Label
            'Конфігурація %1 уже має статус ERP-проєкції. Спочатку виконайте кероване скасування проєкції.';
}
