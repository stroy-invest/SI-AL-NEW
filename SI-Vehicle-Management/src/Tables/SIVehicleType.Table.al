table 63201 "SI Vehicle Type"
{
    Caption = 'Тип транспорту';
    DataClassification = CustomerContent;
    LookupPageId = "SI Vehicle Types";
    fields
    {
        field(1; Code; Code[20]) { Caption = 'Код'; NotBlank = true; }
        field(2; Description; Text[100]) { Caption = 'Найменування'; }
        field(3; Blocked; Boolean) { Caption = 'Заблоковано'; }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
