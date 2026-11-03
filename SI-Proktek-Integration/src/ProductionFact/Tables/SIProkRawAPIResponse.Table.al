table 57094 "SI Prok Raw API Response"
{
    Caption = 'Архів первинних відповідей Proktek';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; Caption = '№ запису'; }
        field(10; "Received At"; DateTime) { Caption = 'Отримано'; Editable = false; }
        field(20; "Connection Code"; Code[50]) { Caption = 'Профіль Proktek'; Editable = false; }
        field(30; "API Operation"; Code[50]) { Caption = 'Операція API'; Editable = false; }
        field(40; "Production UUID"; Text[100]) { Caption = 'Production UUID'; Editable = false; }
        field(50; "Capture Mode"; Enum "SI Prok Capture Mode") { Caption = 'Режим приймання'; Editable = false; }
        field(60; "Processing Status"; Option) { OptionMembers = Received,Processed,Error; OptionCaption = 'Отримано,Оброблено,Помилка'; Caption = 'Обробка'; Editable = false; }
        field(70; "Error Message"; Text[2048]) { Caption = 'Помилка'; Editable = false; }
        field(80; "Raw JSON"; Blob) { Caption = 'Первинна відповідь'; SubType = Memo; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
    trigger OnInsert()
    begin
        if "Received At" = 0DT then
            "Received At" := CurrentDateTime();
    end;
    procedure SetRaw(Value: Text)
    var O: OutStream;
    begin
        "Raw JSON".CreateOutStream(O, TextEncoding::UTF8);
        O.WriteText(Value);
    end;
    procedure GetRaw(): Text
    var I: InStream; S: Text; L: Text;
    begin
        CalcFields("Raw JSON");
        if not "Raw JSON".HasValue() then exit('');
        "Raw JSON".CreateInStream(I, TextEncoding::UTF8);
        while not I.EOS() do begin I.ReadText(L); S += L; end;
        exit(S);
    end;
}
