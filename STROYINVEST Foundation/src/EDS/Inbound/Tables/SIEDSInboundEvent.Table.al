table 50421 "SI EDS Inbound Event"
{
    Caption = 'EDS Inbound Event';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }

        field(10; "Service Code"; Code[50])
        {
            Caption = 'Service Code';
            TableRelation = "SI EDS Service".Code;
        }

        field(20; "Event ID"; Text[250])
        {
            Caption = 'Event ID';
        }

        field(30; "Event Type"; Code[50])
        {
            Caption = 'Event Type';
        }

        field(40; "Source System"; Code[50])
        {
            Caption = 'Source System';
        }

        field(50; "Source Record ID"; Text[100])
        {
            Caption = 'Source Record ID';
        }

        field(60; Payload; Blob)
        {
            Caption = 'Payload';
            SubType = Memo;
        }

        field(70; "Received At"; DateTime)
        {
            Caption = 'Received At';
        }

        field(80; Status; Enum "SI EDS Inbound Status")
        {
            Caption = 'Status';
        }

        field(90; "Processing Started At"; DateTime)
        {
            Caption = 'Processing Started At';
        }

        field(100; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
        }

        field(110; "Processing Attempt Count"; Integer)
        {
            Caption = 'Processing Attempt Count';
            MinValue = 0;
        }

        field(120; "Last Error"; Blob)
        {
            Caption = 'Last Error';
            SubType = Memo;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(Idempotency; "Service Code", "Event ID")
        {
            Unique = true;
        }

        key(ProcessingQueue; Status, "Received At")
        {
        }

        key(Source; "Source System", "Event Type", "Received At")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Received At" = 0DT then
            "Received At" := CurrentDateTime();

        TestField("Service Code");
        TestField("Event ID");
        TestField("Event Type");
        TestField("Source System");
    end;

    procedure SetPayload(PayloadText: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Payload);
        Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(PayloadText);
    end;

    procedure GetPayload(): Text
    var
        InStr: InStream;
        PayloadText: Text;
    begin
        CalcFields(Payload);

        if not Payload.HasValue() then
            exit('');

        Payload.CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(PayloadText);

        exit(PayloadText);
    end;

    procedure SetLastError(ErrorText: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Last Error");
        "Last Error".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(ErrorText);
    end;

    procedure GetLastError(): Text
    var
        InStr: InStream;
        ErrorText: Text;
    begin
        CalcFields("Last Error");

        if not "Last Error".HasValue() then
            exit('');

        "Last Error".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(ErrorText);

        exit(ErrorText);
    end;
}