table 59000 "SI Weighing Record"
{
    Caption = 'Зважування';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = '№ запису';
            AutoIncrement = true;
        }

        // ------------------------------------------------------------
        // EDS traceability
        // ------------------------------------------------------------

        field(10; "Inbound Entry No."; BigInteger)
        {
            Caption = 'EDS: № вхідної події';
            DataClassification = SystemMetadata;
            TableRelation = "SI EDS Inbound Event"."Entry No.";
        }

        field(11; "External Event ID"; Text[250])
        {
            Caption = 'Зовнішній ID події';
            DataClassification = SystemMetadata;
        }

        field(12; "Source Event Type"; Code[50])
        {
            Caption = 'Тип події джерела';
            DataClassification = SystemMetadata;
        }

        // ------------------------------------------------------------
        // Source
        // ------------------------------------------------------------

        field(20; "Source System"; Code[50])
        {
            Caption = 'Система-джерело';
            DataClassification = SystemMetadata;
        }

        field(21; "Site Code"; Code[50])
        {
            Caption = 'Майданчик';
            DataClassification = SystemMetadata;
        }

        field(22; "Source Table"; Code[50])
        {
            Caption = 'Таблиця джерела';
            DataClassification = SystemMetadata;
        }

        field(23; "Source Record ID"; BigInteger)
        {
            Caption = 'ID запису джерела';
            DataClassification = SystemMetadata;
        }

        field(24; "Scale No."; Integer)
        {
            Caption = '№ ваг';
            DataClassification = SystemMetadata;
        }

        field(25; "Source Evidence Record ID"; BigInteger)
        {
            Caption = 'ID evidence у джерелі';
            DataClassification = SystemMetadata;
        }

        field(26; "Event Date/Time"; DateTime)
        {
            Caption = 'Дата/час події';
            DataClassification = SystemMetadata;
        }

        field(27; "Source Operation Type"; Integer)
        {
            Caption = 'Тип операції джерела';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(28; "Source Operation Type Present"; Boolean)
        {
            Caption = 'Тип операції джерела передано';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        // ------------------------------------------------------------
        // Physical weighing fact
        // ------------------------------------------------------------

        field(40; "Gross Weight"; Decimal)
        {
            Caption = 'Брутто, кг';
            DecimalPlaces = 0 : 3;
            DataClassification = CustomerContent;
        }

        field(41; "Tare Weight"; Decimal)
        {
            Caption = 'Тара, кг';
            DecimalPlaces = 0 : 3;
            DataClassification = CustomerContent;
        }

        field(42; "Net Weight"; Decimal)
        {
            Caption = 'Нетто, кг';
            DecimalPlaces = 0 : 3;
            DataClassification = CustomerContent;
        }

        // ------------------------------------------------------------
        // Vehicle / trailer
        // ------------------------------------------------------------

        field(50; "Source Vehicle Plate"; Text[50])
        {
            Caption = 'Номер авто від джерела';
            DataClassification = CustomerContent;
        }

        field(51; "Vehicle Plate"; Text[50])
        {
            Caption = 'Номер авто';
            DataClassification = CustomerContent;
        }

        field(52; "Vehicle Plate Source"; Enum "SI WB Plate Source")
        {
            Caption = 'Джерело номера авто';
            DataClassification = SystemMetadata;
        }

        field(53; "Source Trailer Plate"; Text[50])
        {
            Caption = 'Номер причепа від джерела';
            DataClassification = CustomerContent;
        }

        field(54; "Trailer Plate"; Text[50])
        {
            Caption = 'Номер причепа';
            DataClassification = CustomerContent;
        }

        field(55; "Trailer Plate Source"; Enum "SI WB Plate Source")
        {
            Caption = 'Джерело номера причепа';
            DataClassification = SystemMetadata;
        }

        field(56; "Vehicle Plate Corrected At"; DateTime)
        {
            Caption = 'Номер авто виправлено';
            DataClassification = SystemMetadata;
        }

        field(57; "Vehicle Plate Corrected By"; Guid)
        {
            Caption = 'Номер авто виправив';
            DataClassification = SystemMetadata;
        }

        field(58; "Trailer Plate Corrected At"; DateTime)
        {
            Caption = 'Номер причепа виправлено';
            DataClassification = SystemMetadata;
        }

        field(59; "Trailer Plate Corrected By"; Guid)
        {
            Caption = 'Номер причепа виправив';
            DataClassification = SystemMetadata;
        }

        // ------------------------------------------------------------
        // Audit / technical
        // ------------------------------------------------------------

        field(70; "Created At"; DateTime)
        {
            Caption = 'Створено';
            DataClassification = SystemMetadata;
        }

        field(71; "Created By"; Guid)
        {
            Caption = 'Створено користувачем';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(InboundEntry; "Inbound Entry No.")
        {
            Unique = true;
        }

        key(ExternalEvent; "External Event ID")
        {
        }

        key(SourceRecord; "Source System", "Source Table", "Source Record ID")
        {
        }

        key(EventDateTime; "Event Date/Time")
        {
        }

        key(VehiclePlate; "Vehicle Plate", "Event Date/Time")
        {
        }
    }

    trigger OnInsert()
    var
        EmptyGuid: Guid;
    begin
        TestField("Inbound Entry No.");

        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();

        if "Created By" = EmptyGuid then
            "Created By" := UserSecurityId();

        InitEffectivePlateValues();
    end;

    local procedure InitEffectivePlateValues()
    begin
        if ("Vehicle Plate" = '') and ("Source Vehicle Plate" <> '') then begin
            "Vehicle Plate" := "Source Vehicle Plate";
            "Vehicle Plate Source" := "SI WB Plate Source"::Camera;
        end;

        if ("Trailer Plate" = '') and ("Source Trailer Plate" <> '') then begin
            "Trailer Plate" := "Source Trailer Plate";
            "Trailer Plate Source" := "SI WB Plate Source"::Camera;
        end;
    end;
}