table 57000 "SI Prok Connection"
{
    Caption = 'Профілі підключення Proktek';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Prok Connections";
    LookupPageId = "SI Prok Connections";

    fields
    {
        field(1; Code; Code[50])
        {
            Caption = 'Код';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Опис';
        }
        field(3; Environment; Enum "SI Prok Environment")
        {
            Caption = 'Середовище';
        }
        field(4; Active; Boolean)
        {
            Caption = 'Активний';
            Editable = false;
        }
        field(10; "EDS Service Code"; Code[50])
        {
            Caption = 'Код сервісу EDS';
            TableRelation = "SI EDS Service".Code;
        }
        field(11; "EDS Provider Code"; Code[50])
        {
            Caption = 'Код провайдера EDS';
            TableRelation = "SI EDS Provider".Code;
        }
        field(12; "EDS Login Operation"; Code[50])
        {
            Caption = 'Операція входу EDS';
            TableRelation = "SI EDS Operation".Code where("Service Code" = field("EDS Service Code"));
        }
        field(13; "EDS Prod. Operation"; Code[50])
        {
            Caption = 'Операція виробництва EDS';
            TableRelation = "SI EDS Operation".Code where("Service Code" = field("EDS Service Code"));
        }
        field(14; "Password Credential Code"; Code[50])
        {
            Caption = 'Код пароля EDS';
            TableRelation = "SI EDS Credential".Code where("Provider Code" = field("EDS Provider Code"));
        }
        field(20; "Company Code"; Text[100])
        {
            Caption = 'Код компанії Proktek';
        }
        field(21; Username; Text[100])
        {
            Caption = 'Користувач Proktek';
        }
        field(30; "Last Test At"; DateTime)
        {
            Caption = 'Остання перевірка';
            Editable = false;
        }
        field(31; "Last Test Result"; Text[2048])
        {
            Caption = 'Результат перевірки';
            Editable = false;
        }
        field(40; "Test Payload"; Blob)
        {
            Caption = 'Payload тестової операції';
            DataClassification = CustomerContent;
            SubType = Memo;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
        key(ActiveKey; Active)
        {
        }
    }

    trigger OnInsert()
    begin
        if "EDS Service Code" = '' then
            "EDS Service Code" := 'PROKTEK';
        if "EDS Login Operation" = '' then
            "EDS Login Operation" := 'LOGIN';
        if "EDS Prod. Operation" = '' then
            "EDS Prod. Operation" := 'GET-PRODUCTIONS';
        if "Password Credential Code" = '' then
            "Password Credential Code" := 'LOGIN-PASSWORD';
    end;
    procedure SetTestPayload(Value: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Test Payload");
        "Test Payload".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Value);
    end;

    procedure GetTestPayload(): Text
    var
        InStr: InStream;
        Line: Text;
        Value: Text;
    begin
        CalcFields("Test Payload");
        if not "Test Payload".HasValue() then
            exit('');

        "Test Payload".CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            Clear(Line);
            InStr.ReadText(Line);
            Value += Line;
        end;

        exit(Value);
    end;

}
