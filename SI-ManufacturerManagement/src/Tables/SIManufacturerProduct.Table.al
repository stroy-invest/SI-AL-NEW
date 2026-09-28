table 55001 "SI Manufacturer Product"
{
    Caption = 'Продукт виробника';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Код';
            DataClassification = CustomerContent;
            NotBlank = true;
        }

        field(2; "Manufacturer Code"; Code[20])
        {
            Caption = 'Код виробника';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "SI Manufacturer".Code;
        }

        field(3; "Manufacturer Item No."; Code[50])
        {
            Caption = 'Артикул виробника';
            DataClassification = CustomerContent;
            NotBlank = true;
        }

        field(4; "Manufacturer Item Variant No."; Code[50])
        {
            Caption = 'Артикул варіанта виробника';
            DataClassification = CustomerContent;
        }

        field(5; Description; Text[100])
        {
            Caption = 'Опис';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()
            begin
                Description := DelChr(Description, '<>', ' ');
            end;
        }

        field(6; Blocked; Boolean)
        {
            Caption = 'Заблоковано';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ManufacturerMgt: Codeunit "SI Manufacturer Mgt.";
            begin
                if not Blocked then
                    exit;

                if xRec.Blocked then
                    exit;

                if not ManufacturerMgt.ConfirmManufacturerProductBlocking(Code) then
                    Blocked := xRec.Blocked;
            end;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }

        key(ManufacturerProduct;
        "Manufacturer Code",
            "Manufacturer Item No.",
            "Manufacturer Item Variant No.")
        {
            Unique = true;
        }

        key(DescriptionKey; Description)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(
            DropDown;
        Code,
            "Manufacturer Code",
            "Manufacturer Item No.",
            "Manufacturer Item Variant No.",
            Description)
        {
        }
    }
}