table 53038 "SI SKU Location Buffer"
{
    Caption = 'Вибір місць зберігання';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Код складу';
        }
        field(2; "Location Name"; Text[100])
        {
            Caption = 'Склад';
        }
        field(3; "Location Type Code"; Code[20])
        {
            Caption = 'Тип складу';
        }
        field(4; "Location Type Name"; Text[100])
        {
            Caption = 'Тип складу';
        }
        field(5; Selected; Boolean)
        {
            Caption = 'Вибрати';
        }
        field(6; "SKU Exists"; Boolean)
        {
            Caption = 'SKU вже існує';
        }
    }

    keys
    {
        key(PK; "Location Code")
        {
            Clustered = true;
        }
    }
}
