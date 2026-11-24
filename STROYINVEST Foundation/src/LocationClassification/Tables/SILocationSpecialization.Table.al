table 50506 "SI Location Specialization"
{
    Caption = 'Спеціалізація складу';
    DataClassification = CustomerContent;
    LookupPageId = "SI Location Specializations";
    DrillDownPageId = "SI Location Specializations";

    fields
    {
        field(1; Code; Code[20]) { Caption = 'Код'; NotBlank = true; }
        field(2; Description; Text[100]) { Caption = 'Назва'; }
        field(3; Active; Boolean) { Caption = 'Активна'; InitValue = true; }
    }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnDelete()
    var
        Location: Record Location;
    begin
        Location.SetRange("SI Location Spec. Code", Code);
        if not Location.IsEmpty() then
            Error('Спеціалізація %1 використовується складами. Спочатку змініть їхні налаштування.', Code);
    end;
}
