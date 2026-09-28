table 57081 "SI Prok Export Request"
{
    Caption = 'Запит API на експорт виробництва Proktek';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Prok Export Requests";
    LookupPageId = "SI Prok Export Requests";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = '№ запису';
            AutoIncrement = true;
        }
        field(10; "Date From"; Date)
        {
            Caption = 'Дата з';
        }
        field(11; "Date To"; Date)
        {
            Caption = 'Дата по';
        }
        field(12; "Connection Code"; Code[50])
        {
            Caption = 'Профіль Proktek';
            Editable = false;
        }
        field(20; Status; Enum "SI Prok Export Req Status")
        {
            Caption = 'Статус';
            Editable = false;
        }
        field(21; "Created At"; DateTime)
        {
            Caption = 'Створено';
            Editable = false;
        }
        field(22; "Created By"; Text[100])
        {
            Caption = 'Створив';
            Editable = false;
        }
        field(23; "Started At"; DateTime)
        {
            Caption = 'Початок виконання';
            Editable = false;
        }
        field(24; "Finished At"; DateTime)
        {
            Caption = 'Завершено';
            Editable = false;
        }
        field(25; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            Editable = false;
        }
        field(30; "Export Entry No."; Integer)
        {
            Caption = '№ архівного експорту';
            Editable = false;
            TableRelation = "SI Prok Production Export"."Entry No.";
        }
        field(31; "Production Count"; Integer)
        {
            Caption = 'Кількість виробництв';
            Editable = false;
        }
        field(32; "Total Volume M3"; Decimal)
        {
            Caption = 'Загальний обсяг, м³';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(40; "Error Message"; Text[2048])
        {
            Caption = 'Текст помилки';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(StatusCreated; Status, "Created At")
        {
        }
    }
}
