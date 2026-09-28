table 54007 "SI BP Partner Tree Buffer"
{
    Caption = 'Дерево контрагентів';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Номер запису'; }
        field(2; Indentation; Integer) { Caption = 'Рівень'; }
        field(3; "Node Caption"; Text[250]) { Caption = 'Контрагент'; }
        field(4; "Business Partner No."; Code[60]) { Caption = 'Код контрагента'; }
        field(5; "Registration No."; Text[50]) { Caption = 'Реєстраційний номер'; }
        field(6; "Role Type"; Enum "SI BP Role Type") { Caption = 'Тип ролі'; }
        field(7; "Is Group"; Boolean) { Caption = 'Група'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
