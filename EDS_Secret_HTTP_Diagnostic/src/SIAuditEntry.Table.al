table 70004 "SI Audit Entry"
{
    Caption = 'Кандидат на перевірку';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Batch No."; Code[20]) { Caption = 'Пакет'; TableRelation = "SI Audit Batch"."No."; }
        field(2; "Entry No."; Integer) { Caption = 'Номер запису'; }
        field(3; "Code1C"; Code[8]) { Caption = 'Код 1С'; }
        field(4; "EDRPOU"; Code[8]) { Caption = 'ЄДРПОУ'; }
        field(5; "Source Name"; Text[500]) { Caption = 'Назва з 1С'; }
        field(6; "Source Legal Form"; Text[150]) { Caption = 'ОПФ з 1С'; }
        field(7; "Audit BP No."; Code[60]) { Caption = 'Лабораторний BP'; TableRelation = "SI Audit BP"."No."; }
        field(8; "Processing Status"; Option) { Caption = 'Стан обробки'; OptionMembers = Pending,Skipped,Success,Failed,Review; OptionCaption = 'Очікує,Пропущено,Успішно,Помилка,Перевірити'; }
        field(9; "Result Code"; Code[30]) { Caption = 'Результат'; }
        field(10; "Result Details"; Text[500]) { Caption = 'Пояснення'; }
        field(11; "Last Checked At"; DateTime) { Caption = 'Остання перевірка'; }
        field(12; "Attempt Count"; Integer) { Caption = 'Спроб'; }
        field(13; "Next Attempt At"; DateTime) { Caption = 'Наступна спроба'; }
        field(14; "Source IPN"; Text[50]) { Caption = 'ІПН з 1С'; }
        field(15; "Is FOP"; Boolean) { Caption = 'ФОП — виключено'; }
        field(16; "Source Legal Form Short"; Text[100]) { Caption = 'Скорочена ОПФ 1С'; }
        field(17; "Source Work Name"; Text[500]) { Caption = 'Робоча назва 1С'; }
        field(18; "Source Role"; Text[30]) { Caption = 'Роль 1С'; }
        field(19; "Source Filia Name"; Text[250]) { Caption = 'Філія 1С'; }
        field(20; "Source Group"; Text[100]) { Caption = 'Група 1С'; }
        field(21; "Source VAT Payer"; Text[50]) { Caption = 'Платник ПДВ 1С'; }
        field(22; "Source VAT Rate"; Text[50]) { Caption = 'Ставка ПДВ 1С'; }
        field(23; "Source Excel Row"; Integer) { Caption = 'Рядок Excel'; }
        field(24; "Source EDRPOU Raw"; Text[50]) { Caption = 'ЄДРПОУ 1С (оригінал)'; }
        field(25; "Full Name 1C"; Text[700]) { Caption = 'Повна назва 1С (похідна)'; }
        field(26; "Registry Full Name"; Text[700]) { Caption = 'Юридична назва реєстру'; }
        field(27; "Normalized Name 1C"; Text[700]) { Caption = 'Нормалізована назва 1С'; }
        field(28; "Normalized Registry Name"; Text[700]) { Caption = 'Нормалізована назва реєстру'; }
    }
    keys
    {
        key(PK; "Batch No.", "Entry No.") { Clustered = true; }
        key(EDRPOU; "Batch No.", EDRPOU) { }
        key(Status; "Batch No.", "Processing Status", "Next Attempt At") { }
    }
}
