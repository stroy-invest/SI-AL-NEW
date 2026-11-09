table 57132 "SI Prok Fact Validation Entry"
{
    Caption = 'Діагностика виробничого факту';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Production Fact Entry No."; Integer) { Caption = 'Факт виробництва'; TableRelation = "SI Prok Production Fact"."Entry No."; }
        field(2; "Entry No."; Integer) { Caption = '№ запису'; }
        field(10; "Rule Code"; Code[10]) { Caption = 'Код правила'; }
        field(20; Severity; Option) { Caption = 'Рівень'; OptionMembers = Error,Warning,Information; OptionCaption = 'Помилка,Попередження,Інформація'; }
        field(30; "Material Line No."; Integer) { Caption = 'Рядок матеріалу'; }
        field(40; "Object Type"; Text[50]) { Caption = 'Об’єкт перевірки'; }
        field(50; "Diagnostic Message"; Text[2048]) { Caption = 'Повідомлення'; }
        field(60; "Checked At"; DateTime) { Caption = 'Перевірено'; }
    }
    keys { key(PK; "Production Fact Entry No.", "Entry No.") { Clustered = true; } }
}
