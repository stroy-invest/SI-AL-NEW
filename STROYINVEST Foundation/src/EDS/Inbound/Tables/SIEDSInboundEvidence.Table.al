table 50427 "SI EDS Inbound Evidence"
{
    Caption = 'EDS Inbound Evidence';
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

        field(20; "Evidence ID"; Text[250])
        {
            Caption = 'Evidence ID';
        }

        field(30; "Parent Event ID"; Text[250])
        {
            Caption = 'Parent Event ID';
        }

        field(40; "Source System"; Code[50])
        {
            Caption = 'Source System';
        }

        field(50; "Source Evidence ID"; Text[100])
        {
            Caption = 'Source Evidence ID';
        }

        field(60; "Source Slot"; Integer)
        {
            Caption = 'Source Slot';
            MinValue = 0;
        }

        field(70; "Content Type"; Text[100])
        {
            Caption = 'Content Type';
        }

        field(80; "File Size"; BigInteger)
        {
            Caption = 'File Size';
            MinValue = 0;
        }

        field(90; "SHA-256"; Text[64])
        {
            Caption = 'SHA-256';
        }

        field(100; "Captured At"; DateTime)
        {
            Caption = 'Captured At';
        }

        //
        // Physical evidence content.
        //
        // Media is intentionally used instead of Blob:
        // - native Business Central media storage;
        // - suitable for raw binary API transport;
        // - efficient rendering in BC UI;
        // - stored in Tenant Media and referenced by this record.
        //
        field(110; Content; Media)
        {
            Caption = 'Content';
            DataClassification = CustomerContent;
        }

        field(120; "Registered At"; DateTime)
        {
            Caption = 'Registered At';
        }

        field(130; "Received At"; DateTime)
        {
            Caption = 'Received At';
        }

        field(140; Status; Enum "SI EDS Inb. Evidence Status")
        {
            Caption = 'Status';
        }

        field(150; "Processing Started At"; DateTime)
        {
            Caption = 'Processing Started At';
        }

        field(160; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
        }

        field(170; "Processing Attempt Count"; Integer)
        {
            Caption = 'Processing Attempt Count';
            MinValue = 0;
        }

        field(180; "Last Error"; Blob)
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

        //
        // Canonical transport idempotency key.
        //
        key(Idempotency; "Service Code", "Evidence ID")
        {
            Unique = true;
        }

        key(ParentEvent; "Service Code", "Parent Event ID")
        {
        }

        key(ProcessingQueue; Status, "Received At")
        {
        }

        key(Source; "Source System", "Source Evidence ID", "Source Slot")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Registered At" = 0DT then
            "Registered At" := CurrentDateTime();

        TestField("Service Code");
        TestField("Evidence ID");
        TestField("Parent Event ID");
        TestField("Source System");
        TestField("Content Type");
        TestField("SHA-256");

        Status := Status::Registered;
    end;

    procedure HasContent(): Boolean
    begin
        exit(Content.HasValue());
    end;

    procedure GetMediaId(): Guid
    begin
        if not Content.HasValue() then
            exit;

        exit(Content.MediaId());
    end;

    procedure SetLastError(ErrorText: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Last Error");

        if ErrorText = '' then
            exit;

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