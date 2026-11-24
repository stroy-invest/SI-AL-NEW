table 57961 "SI Prok Sim Fact Del Audit"
{
    Caption = 'Аудит видалення симуляцій Proktek';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; Caption = '№ запису'; }
        field(10; "Fact Entry No."; Integer) { Caption = '№ видаленого факту'; }
        field(20; "Production UUID"; Guid) { Caption = 'Production UUID'; }
        field(30; "Production ID"; BigInteger) { Caption = 'Production ID'; }
        field(40; "Connection Code"; Code[50]) { Caption = 'Підключення'; }
        field(50; "Deleted At"; DateTime) { Caption = 'Час видалення'; }
        field(60; "Deleted By"; Code[50]) { Caption = 'Користувач'; }
        field(70; "Material Lines Deleted"; Integer) { Caption = 'Видалено рядків матеріалів'; }
        field(80; "Validation Lines Deleted"; Integer) { Caption = 'Видалено рядків перевірок'; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
    trigger OnModify() begin Error('Аудит видалення не можна змінювати.'); end;
    trigger OnDelete() begin Error('Аудит видалення не можна видаляти.'); end;
    trigger OnRename() begin Error('Аудит видалення не можна перейменовувати.'); end;
}
