table 50210 "SI Business Event Definition"
{
    Caption = 'Визначення бізнес-подій';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[50])
        {
            Caption = 'Код';
            NotBlank = true;
        }

        field(10; Description; Text[250])
        {
            Caption = 'Опис';
        }

        field(20; "Source Module"; Code[50])
        {
            Caption = 'Модуль-джерело';
        }

        field(30; Active; Boolean)
        {
            Caption = 'Активна';
            InitValue = true;
        }

        field(40; Severity; Enum "SI Notification Severity")
        {
            Caption = 'Рівень важливості';
        }

        field(50; "Recipient Group Code"; Code[50])
        {
            Caption = 'Код групи отримувачів';
            TableRelation = "SI Recipient Group".Code where(Active = const(true));
        }

        field(60; "Title Template"; Text[250])
        {
            Caption = 'Шаблон заголовка';
        }

        field(70; "Message Template"; Text[2048])
        {
            Caption = 'Шаблон повідомлення';
        }

        field(80; "Throttle Minutes"; Integer)
        {
            Caption = 'Інтервал обмеження, хв.';
            MinValue = 0;
        }

        field(90; "Allow Duplicate"; Boolean)
        {
            Caption = 'Дозволити дублювання';
        }

        field(100; "Retention Days"; Integer)
        {
            Caption = 'Строк зберігання, днів';
            MinValue = 0;
        }

        field(110; "Payload Schema Version"; Integer)
        {
            Caption = 'Версія схеми даних';
            InitValue = 1;
            MinValue = 1;
        }

        field(115; "Target Page ID"; Integer)
        {
            Caption = 'ID цільової сторінки';
            DataClassification = SystemMetadata;
            MinValue = 0;
        }

        field(116; "Action Caption Template"; Text[100])
        {
            Caption = 'Шаблон назви дії';
        }

        field(120; "Last Modified At"; DateTime)
        {
            Caption = 'Змінено';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(130; "Last Modified By"; Code[50])
        {
            Caption = 'Змінив';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }

        key(ActiveEvents; Active, "Source Module")
        {
        }
    }

    trigger OnInsert()
    begin
        SetModificationData();
    end;

    trigger OnModify()
    begin
        SetModificationData();
    end;

    local procedure SetModificationData()
    begin
        "Last Modified At" := CurrentDateTime();
        "Last Modified By" :=
            CopyStr(
                UserId(),
                1,
                MaxStrLen("Last Modified By"));
    end;
}