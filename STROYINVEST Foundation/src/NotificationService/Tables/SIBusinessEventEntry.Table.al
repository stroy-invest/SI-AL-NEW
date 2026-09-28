table 50212 "SI Business Event Entry"
{
    Caption = 'Журнал бізнес-подій';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Номер запису';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }

        field(10; "Event Code"; Code[50])
        {
            Caption = 'Код бізнес-події';
            TableRelation = "SI Business Event Definition".Code;
        }

        field(20; Status; Enum "SI Business Event Status")
        {
            Caption = 'Статус';
        }

        field(30; "Created At"; DateTime)
        {
            Caption = 'Створено';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(40; "Created By User ID"; Code[50])
        {
            Caption = 'Створив';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }

        field(50; "Created By Security ID"; Guid)
        {
            Caption = 'Ідентифікатор користувача';
            DataClassification = EndUserPseudonymousIdentifiers;
            Editable = false;
        }

        field(60; "Company Name"; Text[30])
        {
            Caption = 'Компанія';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
        }

        field(70; "Source Module"; Code[50])
        {
            Caption = 'Модуль-джерело';
        }

        field(80; "Source Table ID"; Integer)
        {
            Caption = 'ID таблиці-джерела';
            DataClassification = SystemMetadata;
        }

        field(90; "Source Record ID"; RecordId)
        {
            Caption = 'Ідентифікатор запису-джерела';
            DataClassification = CustomerContent;
        }

        field(100; "Source System ID"; Guid)
        {
            Caption = 'Системний ідентифікатор джерела';
            DataClassification = CustomerContent;
        }

        field(110; "Source Record Caption"; Text[250])
        {
            Caption = 'Опис запису-джерела';
        }

        field(120; "Correlation ID"; Guid)
        {
            Caption = 'Ідентифікатор кореляції';
            DataClassification = SystemMetadata;
        }

        field(130; "Parent Event Entry No."; BigInteger)
        {
            Caption = 'Номер батьківської події';
            DataClassification = SystemMetadata;
            TableRelation = "SI Business Event Entry"."Entry No.";
        }

        field(140; "Payload Schema Version"; Integer)
        {
            Caption = 'Версія схеми даних';
            InitValue = 1;
            MinValue = 1;
        }

        field(150; Payload; Blob)
        {
            Caption = 'Дані події';
            DataClassification = CustomerContent;
            SubType = Memo;
        }

        field(160; "Processing Started At"; DateTime)
        {
            Caption = 'Обробку розпочато';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(170; "Completed At"; DateTime)
        {
            Caption = 'Обробку завершено';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(180; "Notification Count"; Integer)
        {
            Caption = 'Кількість повідомлень';
            DataClassification = SystemMetadata;
            Editable = false;
            MinValue = 0;
        }

        field(190; "Skipped Count"; Integer)
        {
            Caption = 'Кількість пропущених';
            DataClassification = SystemMetadata;
            Editable = false;
            MinValue = 0;
        }

        field(200; "Error Message"; Text[2048])
        {
            Caption = 'Повідомлення про помилку';
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

        key(EventStatus; "Event Code", Status, "Created At")
        {
        }

        key(StatusCreatedAt; Status, "Created At")
        {
        }

        key(Correlation; "Correlation ID")
        {
        }

        key(ParentEvent; "Parent Event Entry No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Event Code", Status, "Created At", "Source Record Caption")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();

        if "Created By User ID" = '' then
            "Created By User ID" := CopyStr(UserId(), 1, MaxStrLen("Created By User ID"));

        if IsNullGuid("Created By Security ID") then
            "Created By Security ID" := UserSecurityId();

        if "Company Name" = '' then
            "Company Name" := CopyStr(CompanyName(), 1, MaxStrLen("Company Name"));

        if IsNullGuid("Correlation ID") then
            "Correlation ID" := CreateGuid();
    end;
}