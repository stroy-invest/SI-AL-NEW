table 60040 "SI Internal Operation"
{
    Caption = 'Внутрішня операція';
    DataClassification = CustomerContent;
    LookupPageId = "SI Internal Operations";
    DrillDownPageId = "SI Internal Operations";
    fields
    {
        field(1; Code; Code[30]) { Caption = 'Код'; NotBlank = true; }
        field(2; Description; Text[100]) { Caption = 'Опис'; }
    }
    keys { key(PK; Code) { Clustered = true; } }
    trigger OnDelete()
    var
        Setup: Record "SI Internal Operation Purpose";
    begin
        if Setup.Get(Code) then
            Error('Операція %1 використовується в налаштуваннях.', Code);
    end;
    trigger OnRename()
    begin
        Error('Код внутрішньої операції є стабільним ідентифікатором.');
    end;
}
