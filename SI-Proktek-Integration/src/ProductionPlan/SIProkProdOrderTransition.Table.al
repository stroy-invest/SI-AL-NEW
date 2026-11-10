table 57118 "SI Prok Prod Order Transition"
{
    Caption = 'Історія переходів виробничих замовлень Proktek';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; Caption = '№ запису'; }
        field(10; "Prod. Request Entry No."; Integer) { Caption = '№ виробничої заявки'; }
        field(20; "From Status"; Enum "Production Order Status") { Caption = 'Попередній статус'; }
        field(30; "From Order No."; Code[20]) { Caption = 'Попередній номер'; }
        field(40; "To Status"; Enum "Production Order Status") { Caption = 'Новий статус'; }
        field(50; "To Order No."; Code[20]) { Caption = 'Новий номер'; }
        field(60; "Recorded At"; DateTime) { Caption = 'Дата реєстрації'; }
        field(70; Recovered; Boolean) { Caption = 'Відновлено з історичних даних BC'; }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(FromOrder; "Prod. Request Entry No.", "From Status", "From Order No.") { }
    }
}
