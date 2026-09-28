table 50414 "SI EDS Request Buffer"
{
    Caption = 'EDS Request Buffer';
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

        field(3; "Service Code"; Code[50])
        {
        }

        field(4; "Operation Code"; Code[50])
        {
        }

        field(5; "Provider Code"; Code[50])
        {
        }

        field(6; "Endpoint Code"; Code[50])
        {
        }

        field(7; "HTTP Method"; Enum "SI EDS HTTP Method")
        {
        }

        field(8; "Base URL"; Text[250])
        {
        }

        field(9; "Relative Path"; Text[250])
        {
        }

        field(10; "Query String"; Text[2048])
        {
        }

        field(11; "Content Type"; Text[100])
        {
        }

        field(12; "Request URL"; Text[2048])
        {
        }

        field(20; "Request Body"; Blob)
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
        Clear("Request Body");
        "Request Body".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Value);
    end;

    procedure GetBody(): Text
    var
        InStr: InStream;
        Value: Text;
    begin
        CalcFields("Request Body");

        if not "Request Body".HasValue then
            exit('');

        "Request Body".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Value);

        exit(Value);
    end;
}
