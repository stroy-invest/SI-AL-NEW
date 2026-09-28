table 54071 "SI BP Materialization Step"
{
    Caption = 'Кроки матеріалізації BP';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run Entry No."; Integer)
        {
            Caption = 'Запуск';
            TableRelation = "SI BP Materialization Run"."Entry No.";
        }

        field(2; "Step Type"; Enum "SI BP Mat. Step Type")
        {
            Caption = 'Крок';
        }

        field(3; Status; Enum "SI BP Mat. Step Status")
        {
            Caption = 'Стан';
        }

        field(10; "Started At"; DateTime)
        {
            Caption = 'Розпочато';
        }

        field(11; "Completed At"; DateTime)
        {
            Caption = 'Завершено';
        }

        field(12; "Attempt Count"; Integer)
        {
            Caption = 'Спроб';
        }

        field(20; "Error Message"; Text[2048])
        {
            Caption = 'Помилка';
        }

        field(21; Details; Text[2048])
        {
            Caption = 'Деталі';
        }
    }

    keys
    {
        key(PK; "Run Entry No.", "Step Type")
        {
            Clustered = true;
        }
    }
}