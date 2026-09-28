table 50416 "SI EDS Exec. Log"
{
    Caption = 'Журнал виконання EDS';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Номер запису';
            AutoIncrement = true;
        }

        field(2; "Correlation ID"; Guid)
        {
            Caption = 'Correlation ID';
        }

        field(3; "Service Code"; Code[50])
        {
            Caption = 'Код сервісу';
        }

        field(4; "Operation Code"; Code[50])
        {
            Caption = 'Код операції';
        }

        field(5; "Provider Code"; Code[50])
        {
            Caption = 'Код провайдера';
        }

        field(6; "Endpoint Code"; Code[50])
        {
            Caption = 'Код точки під''єднання';
        }

        field(7; "Started At"; DateTime)
        {
            Caption = 'Початок';
        }

        field(8; "Finished At"; DateTime)
        {
            Caption = 'Завершення';
        }

        field(9; "Duration (ms)"; Integer)
        {
            Caption = 'Тривалість, мс';
        }

        field(10; "HTTP Status Code"; Integer)
        {
            Caption = 'HTTP статус';
        }

        field(11; "Result Type"; Enum "SI EDS Result Type")
        {
            Caption = 'Результат';
        }

        field(12; "Error Code"; Text[50])
        {
            Caption = 'Код помилки';
        }

        field(13; "Error Message"; Text[2048])
        {
            Caption = 'Помилка';
        }

        field(14; "Request URL"; Text[2048])
        {
            Caption = 'URL запиту';
        }


        field(15; "Response Body"; Blob)
        {
            Caption = 'Тіло відповіді';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(Correlation; "Correlation ID")
        {
        }

        key(ServiceOperation; "Service Code", "Operation Code", "Started At")
        {
        }

        key(StartedAt; "Started At")
        {
        }
    }

    procedure SetResponseBody(ResponseText: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Response Body");
        if ResponseText = '' then
            exit;

        "Response Body".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(ResponseText);
    end;

    procedure GetResponseBody(): Text
    var
        InStr: InStream;
        BodyBuilder: TextBuilder;
        LineText: Text;
    begin
        CalcFields("Response Body");
        if not "Response Body".HasValue() then
            exit('');

        "Response Body".CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            Clear(LineText);
            InStr.ReadText(LineText);
            BodyBuilder.AppendLine(LineText);
        end;

        exit(BodyBuilder.ToText());
    end;


}
