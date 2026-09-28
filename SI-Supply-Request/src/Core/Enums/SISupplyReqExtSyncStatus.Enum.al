enum 61009 "SI Supply Req Ext Sync Status"
{
    Extensible = true;
    Caption = 'Статус зовнішньої синхронізації';

    value(0; "Not Synced") { Caption = 'Не синхронізовано'; }
    value(1; Synchronized) { Caption = 'Синхронізовано'; }
    value(2; Changed) { Caption = 'Є зовнішні зміни'; }
    value(3; Error) { Caption = 'Помилка'; }
}
