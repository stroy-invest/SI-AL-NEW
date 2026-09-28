table 59010 "SI WB Document Creation Queue"
{
    Caption = 'Черга створення операційних документів вагової';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = '№ запису';
            AutoIncrement = true;
        }

        field(10; "Weighing Entry No."; BigInteger)
        {
            Caption = '№ зважування';
            TableRelation = "SI Weighing Record"."Entry No.";
        }

        field(11; "Inbound Entry No."; BigInteger)
        {
            Caption = 'EDS: № вхідної події';
            TableRelation = "SI EDS Inbound Event"."Entry No.";
            DataClassification = SystemMetadata;
        }

        field(20; Status; Enum "SI WB Doc Creation Status")
        {
            Caption = 'Статус';
            DataClassification = SystemMetadata;
        }

        field(21; "Attempt Count"; Integer)
        {
            Caption = 'Кількість спроб';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(22; "Created At"; DateTime)
        {
            Caption = 'Створено в черзі';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(23; "Last Attempt At"; DateTime)
        {
            Caption = 'Остання спроба';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(24; "Completed At"; DateTime)
        {
            Caption = 'Завершено';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(25; "Last Error"; Text[2048])
        {
            Caption = 'Остання помилка';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(30; "Document Entry No."; BigInteger)
        {
            Caption = '№ запису операційного документа';
            TableRelation = "SI Weighbridge Document"."Entry No.";
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(31; "Document No."; Code[20])
        {
            Caption = '№ операційного документа';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(Weighing; "Weighing Entry No.")
        {
            Unique = true;
        }

        key(StatusCreated; Status, "Created At")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Weighing Entry No.");

        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
    end;

    procedure FindByWeighing(
        WeighingEntryNo: BigInteger): Boolean
    begin
        Reset();
        SetRange("Weighing Entry No.", WeighingEntryNo);
        exit(FindFirst());
    end;

    procedure SetLastError(ErrorText: Text)
    begin
        "Last Error" := CopyStr(ErrorText, 1, MaxStrLen("Last Error"));
    end;
}
