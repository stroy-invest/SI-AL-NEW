table 57080 "SI Prok Production Export"
{
    Caption = 'Експорт виробництва Proktek';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Prok Production Exports";
    LookupPageId = "SI Prok Production Exports";

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
            TableRelation = "SI Prok Connection".Code;
        }
        field(20; "Created At"; DateTime)
        {
            Caption = 'Створено';
            Editable = false;
        }
        field(21; "Created By"; Text[100])
        {
            Caption = 'Створив';
            Editable = false;
        }
        field(30; Status; Enum "SI Prok Export Status")
        {
            Caption = 'Статус';
            Editable = false;
        }
        field(31; "File Name"; Text[250])
        {
            Caption = 'Ім’я файлу';
            Editable = false;
        }
        field(40; "Production Count"; Integer)
        {
            Caption = 'Кількість виробництв';
            Editable = false;
        }
        field(41; "Total Volume M3"; Decimal)
        {
            Caption = 'Загальний обсяг, м³';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(50; "JSON Payload"; Blob)
        {
            Caption = 'JSON';
            DataClassification = CustomerContent;
            SubType = Memo;
        }
        field(60; "Error Message"; Text[2048])
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
        key(CreatedAt; "Created At")
        {
        }
    }

    procedure SetPayload(Value: Text)
    var
        OutStr: OutStream;
    begin
        Clear("JSON Payload");
        "JSON Payload".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Value);
    end;

    procedure GetPayload(): Text
    var
        InStr: InStream;
        Line: Text;
        Value: Text;
    begin
        CalcFields("JSON Payload");
        if not "JSON Payload".HasValue() then
            exit('');

        "JSON Payload".CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            Clear(Line);
            InStr.ReadText(Line);
            Value += Line;
        end;

        exit(Value);
    end;
}
