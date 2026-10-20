table 70005 "SI Audit Request Log"
{
    Caption = 'Журнал реєстрових запитів';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Номер запису'; AutoIncrement = true; }
        field(2; "Batch No."; Code[20]) { Caption = 'Пакет'; TableRelation = "SI Audit Batch"."No."; }
        field(3; "Audit Entry No."; Integer) { Caption = 'Запис пакета'; }
        field(4; EDRPOU; Code[8]) { Caption = 'ЄДРПОУ'; }
        field(5; "Code1C"; Code[8]) { Caption = 'Код 1С'; }
        field(6; "Requested At"; DateTime) { Caption = 'Дата/час запиту'; }
        field(7; "Completed At"; DateTime) { Caption = 'Дата/час завершення'; }
        field(8; "EDS Provider Code"; Code[50]) { Caption = 'Провайдер EDS'; }
        field(9; "EDS Operation Code"; Code[50]) { Caption = 'Операція EDS'; }
        field(10; "HTTP Status Code"; Integer) { Caption = 'HTTP статус'; }
        field(11; "Retrieval Result"; Code[30]) { Caption = 'Результат отримання'; }
        field(12; "Verification Result"; Code[30]) { Caption = 'Результат зіставлення'; }
        field(13; "Response Message"; Text[500]) { Caption = 'Повідомлення'; }
        field(14; "Raw Response"; Blob) { Caption = 'Оригінальна відповідь'; SubType = Memo; }
        field(15; "Attempt No."; Integer) { Caption = 'Номер спроби'; }
        field(16; "Response Content Type"; Text[100]) { Caption = 'Content-Type'; }
        field(17; "Request Correlation ID"; Text[100]) { Caption = 'Correlation ID'; }
        field(18; "Raw HTTP Bytes"; Blob) { Caption = 'Сирі байти HTTP'; }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(EDRPOU; "Batch No.", EDRPOU, "Requested At") { }
    }
}
