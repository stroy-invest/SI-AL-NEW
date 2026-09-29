table 54029 "SI BP Tree Buffer"
{
    Caption = 'Дерево контрагентів';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = '№ запису';
        }

        field(2; "Parent Entry No."; Integer)
        {
            Caption = '№ батьківського запису';
        }

        field(3; Indentation; Integer)
        {
            Caption = 'Рівень';
        }

        field(4; "Business Partner No."; Code[60])
        {
            Caption = 'Код контрагента';
        }

        field(5; Name; Text[150])
        {
            Caption = 'Контрагент';
        }

        field(6; "Registration No."; Text[50])
        {
            Caption = 'Реєстраційний номер';
        }

        field(7; "Tax Registration No."; Text[50])
        {
            Caption = 'Податковий реєстраційний номер';
        }

        field(8; "Country/Region Code"; Code[10])
        {
            Caption = 'Код країни/регіону';
        }

        field(9; Status; Text[50])
        {
            Caption = 'Статус';
        }

        field(10; Style; Text[30])
        {
            Caption = 'Стиль';
        }

        field(11; "Role Type"; Enum "SI BP Role Type")
        {
            Caption = 'Тип ролі';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(NameKey; Name, "Business Partner No.")
        {
        }
    }
}