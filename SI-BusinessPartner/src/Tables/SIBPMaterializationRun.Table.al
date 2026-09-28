table 54070 "SI BP Materialization Run"
{
    Caption = 'Запуски матеріалізації BP';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = '№';
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
            TableRelation = "SI Business Partner"."No.";
        }

        field(4; "Role Type"; Enum "SI BP Role Type")
        {
            Caption = 'Тип ролі';
        }

        field(5; Status; Enum "SI BP Mat. Run Status")
        {
            Caption = 'Стан';
        }

        field(6; "Current Step"; Enum "SI BP Mat. Step Type")
        {
            Caption = 'Поточний крок';
        }

        field(7; "Last Successful Step"; Enum "SI BP Mat. Step Type")
        {
            Caption = 'Останній успішний крок';
        }

        field(10; "ERP No."; Code[20])
        {
            Caption = 'Номер ERP';
        }

        field(11; "ERP SystemId"; Guid)
        {
            Caption = 'SystemId ERP';
        }

        field(12; "Contact No."; Code[20])
        {
            Caption = 'Контакт компанії';
        }

        field(13; "Contact SystemId"; Guid)
        {
            Caption = 'SystemId контакту';
        }

        field(20; "Error Message"; Text[2048])
        {
            Caption = 'Помилка';
        }

        field(30; "Started At"; DateTime)
        {
            Caption = 'Розпочато';
        }

        field(31; "Completed At"; DateTime)
        {
            Caption = 'Завершено';
        }

        field(32; "Created At"; DateTime)
        {
            Caption = 'Створено';
        }

        field(33; "Created By"; Text[100])
        {
            Caption = 'Створив';
        }

        field(34; "Last Updated At"; DateTime)
        {
            Caption = 'Оновлено';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(RoleStatus; "Role Code", Status)
        {
        }
    }

    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime;

        if "Created By" = '' then
            "Created By" :=
                CopyStr(
                    UserId(),
                    1,
                    MaxStrLen("Created By"));

        "Last Updated At" :=
            CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Last Updated At" :=
            CurrentDateTime;
    end;
}