table 54031 "SI BP Role Status Entry"
{
    Caption = 'Історія станів ролі';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Номер запису';
            AutoIncrement = true;
        }

        field(2; "Role Code"; Code[30])
        {
            Caption = 'Код ролі';
            TableRelation = "SI BP Role".Code;
        }

        field(3; "Business Partner No."; Code[20])
        {
            Caption = 'Контрагент';
        }

        field(4; "Role Type"; Enum "SI BP Role Type")
        {
            Caption = 'Тип ролі';
        }

        field(5; "Old Status"; Enum "SI BP Role Status")
        {
            Caption = 'Попередній стан';
        }

        field(6; "New Status"; Enum "SI BP Role Status")
        {
            Caption = 'Новий стан';
        }

        field(10; "Changed At"; DateTime)
        {
            Caption = 'Дата та час';
        }

        field(11; "Changed By"; Text[100])
        {
            Caption = 'Користувач';
        }

        field(12; Reason; Text[100])
        {
            Caption = 'Причина';
        }

        field(13; Comment; Text[250])
        {
            Caption = 'Коментар';
        }

        field(14; Source; Enum "SI BP Role Chg. Source")
        {
            Caption = 'Джерело зміни';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(RoleHistory; "Role Code", "Changed At")
        {
        }

        key(BPHistory; "Business Partner No.", "Changed At")
        {
        }
    }
}