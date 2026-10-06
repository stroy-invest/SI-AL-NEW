table 50486 "SI EDS Wiz Rate Buffer"
{
    TableType = Temporary;
    Caption = 'Ліміти запитів майстра EDS';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№'; }
        field(2; Sequence; Integer) { Caption = 'Порядок'; MinValue = 1; }
        field(3; "Window Seconds"; Integer) { Caption = 'Вікно, сек.'; MinValue = 1; }
        field(4; "Max Requests"; Integer) { Caption = 'Макс. запитів'; MinValue = 1; }
        field(5; "Safety Margin %"; Decimal) { Caption = 'Безпечне використання, %'; MinValue = 1; MaxValue = 100; InitValue = 80; }
        field(6; Description; Text[100]) { Caption = 'Опис'; }
        field(7; "Existing"; Boolean) { Caption = 'Наявний'; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } key(SequenceKey; Sequence) { } }
}
