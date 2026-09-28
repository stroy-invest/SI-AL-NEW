table 55000 "SI Manufacturer"
{
    Caption = 'Виробник';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Код';
            DataClassification = CustomerContent;
            NotBlank = true;
        }

        field(2; Name; Text[100])
        {
            Caption = 'Назва';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()
            begin
                Name := DelChr(Name, '<>', ' ');
            end;
        }

        field(3; "Country/Region Code"; Code[10])
        {
            Caption = 'Країна/Регіон';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region".Code;
        }

        field(4; Blocked; Boolean)
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

                if not ManufacturerMgt.ConfirmManufacturerBlocking(Code) then
                    Error('');
            end;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }

        key(NameKey; Name)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Name, "Country/Region Code", Blocked)
        {
        }
    }
    /*
        trigger OnInsert()
        begin
            TestField(Code);
            TestField(Name);
        end;

        trigger OnModify()
        begin
            TestField(Code);
            TestField(Name);
        end;
    */
}