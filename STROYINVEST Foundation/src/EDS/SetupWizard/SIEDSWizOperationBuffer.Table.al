table 50488 "SI EDS Wiz Operation Buffer"
{
    TableType = Temporary;
    Caption = 'Операції (чернетка)';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Service Code"; Code[50]) { Caption = 'Сервіс'; }
        field(2; Code; Code[50]) { Caption = 'Операція'; NotBlank = true; }
        field(3; Description; Text[250]) { Caption = 'Опис'; }
        field(4; "HTTP Method"; Enum "SI EDS HTTP Method") { Caption = 'HTTP метод'; }
        field(5; "Relative Path"; Text[250]) { Caption = 'Відносний шлях'; }
        field(6; "Operation Group Code"; Code[50]) { Caption = 'Група операцій'; }
        field(7; "Existing"; Boolean) { Caption = 'Наявна операція'; Editable = false; }
        field(8; Enabled; Boolean) { Caption = 'Увімкнено'; InitValue = true; }
    }
    keys { key(PK; "Service Code", Code) { Clustered = true; } }
}
