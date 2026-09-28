table 53006 "SI Item ERP Projection"
{
    Caption = 'ERP-проєкція товару';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Номер запису';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }

        field(10; "Family Code"; Code[30])
        {
            Caption = 'Код сімейства';
            DataClassification = CustomerContent;
            NotBlank = true;
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

        field(40; "Item No."; Code[20])
        {
            Caption = 'Номер товару BC';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = Item."No.";

            trigger OnValidate()
            var
                ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
            begin
                if "Item No." = '' then
                    exit;

                TestField("Family Code");
                ERPProjectionMgt.ValidateItemForFamily("Family Code", "Item No.");
            end;
        }

        field(50; "Item Description"; Text[100])
        {
            Caption = 'Назва товару';
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Editable = false;
        }

        field(60; Status; Enum "SI ERP Projection Status")
        {
            Caption = 'Статус';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70; "Created At"; DateTime)
        {
            Caption = 'Створено';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(80; "Created By"; Code[50])
        {
            Caption = 'Створив';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }

        field(90; "Last Modified At"; DateTime)
        {
            Caption = 'Остання зміна';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(100; "Last Modified By"; Code[50])
        {
            Caption = 'Змінив';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }

        field(110; "Item Category Code"; Code[20])
        {
            Caption = 'Категорія товару';
            DataClassification = CustomerContent;
            TableRelation = "Item Category".Code;
        }

        field(120; "Item Template Code"; Code[20])
        {
            Caption = 'Шаблон товару';
            DataClassification = CustomerContent;
            TableRelation = "Item Templ.".Code;
        }

        field(130; "Generated Item Code"; Code[20])
        {
            Caption = 'Згенерований код товару';
            DataClassification = CustomerContent;
        }

        field(140; "Generated Item Description"; Text[100])
        {
            Caption = 'Згенерована назва товару';
            DataClassification = CustomerContent;
        }

        field(150; "Base UoM Code"; Code[10])
        {
            Caption = 'Базова одиниця виміру';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure".Code;
        }

        field(160; "Base UoM Source"; Enum "SI Base UoM Source")
        {
            Caption = 'Джерело базової одиниці виміру';
            DataClassification = CustomerContent;
        }

        field(170; "Projected At"; DateTime)
        {
            Caption = 'Спроєктовано';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(180; "Projected By"; Code[50])
        {
            Caption = 'Виконав проєкцію';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }

        field(190; "Last Error"; Text[250])
        {
            Caption = 'Остання помилка';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(ProjectionKey; "Family Code", "Item Projection Key Hash")
        {
            Unique = true;
        }

        key(Item; "Item No.", Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Family Code", "Item No.", "Item Description")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Family Code");
        TestField("Item Projection Key");
        TestField("Item Projection Key Hash");
        TestField("Item No.");

        Status := Status::Projected;
        "Created At" := CurrentDateTime();
        "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
        SetModifiedMetadata();
    end;

    trigger OnModify()
    begin
        TestField("Family Code");
        TestField("Item Projection Key");
        TestField("Item Projection Key Hash");
        TestField("Item No.");
        SetModifiedMetadata();
    end;

    local procedure SetModifiedMetadata()
    begin
        "Last Modified At" := CurrentDateTime();
        "Last Modified By" := CopyStr(UserId(), 1, MaxStrLen("Last Modified By"));
    end;
}
