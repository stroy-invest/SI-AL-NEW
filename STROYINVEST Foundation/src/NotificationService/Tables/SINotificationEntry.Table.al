table 50213 "SI Notification Entry"
{
    Caption = 'Повідомлення користувачів';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Номер запису';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }

        field(10; "Event Entry No."; BigInteger)
        {
            Caption = 'Номер бізнес-події';
            DataClassification = SystemMetadata;
            TableRelation = "SI Business Event Entry"."Entry No.";
        }

        field(20; "Event Code"; Code[50])
        {
            Caption = 'Код бізнес-події';
            TableRelation = "SI Business Event Definition".Code;
        }

        field(30; "Recipient Security ID"; Guid)
        {
            Caption = 'Ідентифікатор отримувача';
            DataClassification = EndUserPseudonymousIdentifiers;
        }

        field(40; "Recipient User Name"; Code[50])
        {
            Caption = 'Користувач-отримувач';
            DataClassification = EndUserIdentifiableInformation;
        }

        field(50; Title; Text[250])
        {
            Caption = 'Заголовок';
        }

        field(60; Message; Text[2048])
        {
            Caption = 'Текст повідомлення';
        }

        field(70; Severity; Enum "SI Notification Severity")
        {
            Caption = 'Рівень важливості';
        }

        field(80; Status; Enum "SI Notification Status")
        {
            Caption = 'Статус';
        }

        field(90; "Created At"; DateTime)
        {
            Caption = 'Створено';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(100; "Read At"; DateTime)
        {
            Caption = 'Прочитано';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(110; "Dismissed At"; DateTime)
        {
            Caption = 'Приховано';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(120; "Expires At"; DateTime)
        {
            Caption = 'Чинний до';
            DataClassification = SystemMetadata;
        }

        field(130; "Source Table ID"; Integer)
        {
            Caption = 'ID таблиці-джерела';
            DataClassification = SystemMetadata;
        }

        field(140; "Source Record ID"; RecordId)
        {
            Caption = 'Ідентифікатор запису-джерела';
            DataClassification = CustomerContent;
        }

        field(150; "Source System ID"; Guid)
        {
            Caption = 'Системний ідентифікатор джерела';
            DataClassification = CustomerContent;
        }

        field(160; "Source Record Caption"; Text[250])
        {
            Caption = 'Опис запису-джерела';
        }

        field(170; "Target Page ID"; Integer)
        {
            Caption = 'ID цільової сторінки';
            DataClassification = SystemMetadata;
            MinValue = 0;
        }

        field(180; "Action Caption"; Text[100])
        {
            Caption = 'Назва дії';
        }

        field(190; Fingerprint; Text[250])
        {
            Caption = 'Відбиток повідомлення';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(200; "Recipient Group Code"; Code[50])
        {
            Caption = 'Код групи отримувачів';
            TableRelation = "SI Recipient Group".Code;
        }

        field(210; "Resolver Trace"; Text[2048])
        {
            Caption = 'Трасування визначення отримувача';
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

        key(RecipientStatus; "Recipient Security ID", Status, "Created At")
        {
        }

        key(RecipientCreatedAt; "Recipient Security ID", "Created At")
        {
        }

        key(EventEntry; "Event Entry No.")
        {
        }

        key(FingerprintCreatedAt; Fingerprint, "Created At")
        {
        }

        key(EventRecipient; "Event Code", "Recipient Security ID", "Created At")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Title, "Recipient User Name", Status, "Created At")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
    end;
}