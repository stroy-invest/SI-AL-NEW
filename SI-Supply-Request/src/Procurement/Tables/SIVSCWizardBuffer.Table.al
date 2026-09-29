table 61060 "SI VSC Wizard Buffer"
{
    Caption = 'Буфер майстра каналів постачання';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№'; }
        field(2; "Category Code"; Code[20]) { Caption = 'Код категорії'; }
        field(3; "Category Name"; Text[100]) { Caption = 'Категорія'; }
        field(4; "Default UoM Code"; Code[10]) { Caption = 'Од. виміру за замовчуванням'; }
        field(5; "Condition Count"; Integer) { Caption = 'Кількість умов'; }
        field(6; "Conditions Summary"; Text[2048]) { Caption = 'Умови постачання'; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } key(Category; "Category Code") { } }
}
