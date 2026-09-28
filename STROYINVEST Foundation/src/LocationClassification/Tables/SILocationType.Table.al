table 50500 "SI Location Type"
{
    Caption = 'Тип складу';
    DataClassification = CustomerContent;
    LookupPageId = "SI Location Types";
    DrillDownPageId = "SI Location Types";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Код';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Назва';
        }
        field(3; Active; Boolean)
        {
            Caption = 'Активний';
            InitValue = true;
        }
        field(4; "Sort Order"; Integer)
        {
            Caption = 'Порядок сортування';
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
        key(Sort; "Sort Order", Code) { }
    }

    trigger OnDelete()
    var
        Location: Record Location;
        LocationSetup: Record "SI Location Setup";
    begin
        Location.SetRange("SI Location Type Code", Code);
        if not Location.IsEmpty() then
            Error('Тип складу %1 використовується у складах і не може бути видалений. Деактивуйте його замість видалення.', Code);

        if LocationSetup.Get() then
            if LocationSetup.UsesLocationType(Code) then
                Error('Тип складу %1 використовується в налаштуваннях типів складів і не може бути видалений.', Code);
    end;
}
