table 50448 "SI EDS Async Request"
{
    Caption = 'EDS Async Request';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Service Code"; Code[50]) { }
        field(3; "Operation Code"; Code[50]) { }
        field(4; "Business Key"; Text[250]) { }
        field(5; "Provider Code"; Code[50]) { }
        field(10; Status; Enum "SI EDS Async Status") { }
        field(11; "Started At"; DateTime) { }
        field(12; "Last Attempt At"; DateTime) { }
        field(13; "Next Attempt At"; DateTime) { }
        field(14; "Expires At"; DateTime) { }
        field(15; "Completed At"; DateTime) { }
        field(16; "Attempt Count"; Integer) { }
        field(20; "HTTP Status Code"; Integer) { }
        field(21; "HTTP Reason Phrase"; Text[250]) { }
        field(22; "Error Message"; Text[2048]) { }
        field(30; "Response Body"; Blob) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Due; Status, "Next Attempt At") { }
        key(Business; "Service Code", "Operation Code", "Business Key", Status) { }
    }

    procedure SetResponseBody(Value: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Response Body");
        "Response Body".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Value);
    end;

    procedure GetResponseBody(): Text
    var
        InStr: InStream;
        Builder: TextBuilder;
        LineText: Text;
    begin
        CalcFields("Response Body");
        if not "Response Body".HasValue then
            exit('');
        "Response Body".CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            Clear(LineText);
            InStr.ReadText(LineText);
            Builder.AppendLine(LineText);
        end;
        exit(Builder.ToText());
    end;
}
