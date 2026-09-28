table 52052 "SI Request Inbox Buffer"
{
    Caption = 'Буфер вхідних заявок';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Notification Entry No."; BigInteger)
        {
            Caption = 'Номер повідомлення';
            DataClassification = SystemMetadata;
        }

        field(10; "Event Code"; Code[50])
        {
            Caption = 'Код події';
            DataClassification = SystemMetadata;
        }

        field(20; Message; Text[250])
        {
            Caption = 'Повідомлення';
        }

        field(30; "Request No."; Code[20])
        {
            Caption = 'Заявка';
        }

        field(40; "Request Status"; Enum "SI Request Status")
        {
            Caption = 'Статус';
        }

        field(50; "Execution Date"; Date)
        {
            Caption = 'Дата виконання';
        }

        field(60; "Received At"; DateTime)
        {
            Caption = 'Надійшло';
        }

        field(70; "Requester Name"; Text[100])
        {
            Caption = 'Ініціатор';
        }

        field(80; "Approver Name"; Text[100])
        {
            Caption = 'Погоджувач';
        }

        field(85; "Current Approver Name"; Text[100])
        {
            Caption = 'Поточний погоджувач';
        }

        field(86; "Final Approver Name"; Text[100])
        {
            Caption = 'Остаточний погоджувач';
        }

        field(90; "Is Read"; Boolean)
        {
            Caption = 'Прочитано';
        }

        field(100; "Is Hidden"; Boolean)
        {
            Caption = 'Приховано';
        }

        field(110; "Source Table ID"; Integer)
        {
            Caption = 'ID таблиці-джерела';
            DataClassification = SystemMetadata;
        }

        field(120; "Source Record ID"; RecordId)
        {
            Caption = 'Запис-джерело';
            DataClassification = CustomerContent;
        }

        field(130; "Target Page ID"; Integer)
        {
            Caption = 'ID цільової сторінки';
            DataClassification = SystemMetadata;
        }

        field(140; "Approval Entry No."; Integer)
        {
            Caption = 'Номер запису погодження';
            DataClassification = SystemMetadata;
        }

        field(150; "Approval Due Date"; Date)
        {
            Caption = 'Строк погодження';
        }

        field(160; "Approval Decision At"; DateTime)
        {
            Caption = 'Дата рішення';
        }

        field(170; "Approval Is Open"; Boolean)
        {
            Caption = 'Очікує рішення';
        }
    }

    keys
    {
        key(PK; "Notification Entry No.")
        {
            Clustered = true;
        }

        key(ReceivedAt; "Received At")
        {
        }

        key(RequestStatus; "Request Status")
        {
        }

        key(ExecutionDate; "Execution Date")
        {
        }
    }
}