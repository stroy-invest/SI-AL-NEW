table 50415 "SI EDS Response Buffer"
{
    Caption = 'EDS Response Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
        }

        field(2; "Correlation ID"; Guid)
        {
        }

        field(3; "Provider Code"; Code[50])
        {
        }

        field(4; "Endpoint Code"; Code[50])
        {
        }

        field(5; "HTTP Status Code"; Integer)
        {
        }

        field(6; "Result Type"; Enum "SI EDS Result Type")
        {
        }

        field(7; "Duration (ms)"; Integer)
        {
        }

        field(8; "Error Code"; Text[50])
        {
        }

        field(9; "Error Message"; Text[2048])
        {
        }

        field(10; "Request URL"; Text[2048])
        {
        }

        field(11; "Request Method"; Enum "SI EDS HTTP Method")
        {
        }

        field(12; "Request Content Type"; Text[100])
        {
        }

        field(13; "HTTP Reason Phrase"; Text[250])
        {
        }

        field(14; "Blocked By Environment"; Boolean)
        {
        }

        field(20; "Response Body"; Blob)
        {
        }

        field(21; "Response Headers"; Blob)
        {
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure SetBody(Value: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Response Body");
        "Response Body".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Value);
    end;

    procedure GetBodyInStream(var BodyInStream: InStream): Boolean
    begin
        CalcFields("Response Body");

        if not "Response Body".HasValue then
            exit(false);

        "Response Body".CreateInStream(BodyInStream, TextEncoding::UTF8);
        exit(true);
    end;

    procedure GetBodyText(): Text
    var
        BodyInStream: InStream;
        BodyTextBuilder: TextBuilder;
        LineText: Text;
    begin
        if not GetBodyInStream(BodyInStream) then
            exit('');

        while not BodyInStream.EOS() do begin
            Clear(LineText);
            BodyInStream.ReadText(LineText);
            BodyTextBuilder.AppendLine(LineText);
        end;

        exit(BodyTextBuilder.ToText());
    end;

    procedure SetHeaders(Value: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Response Headers");
        "Response Headers".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Value);
    end;

    procedure GetHeadersText(): Text
    var
        HeadersInStream: InStream;
        HeadersText: Text;
    begin
        CalcFields("Response Headers");

        if not "Response Headers".HasValue then
            exit('');

        "Response Headers".CreateInStream(HeadersInStream, TextEncoding::UTF8);
        HeadersInStream.ReadText(HeadersText);
        exit(HeadersText);
    end;
}
