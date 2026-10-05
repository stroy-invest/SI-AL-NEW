enum 50468 "SI EDS Async Status"
{
    Extensible = false;
    Caption = 'EDS Async Status';

    value(0; Pending) { Caption = 'Очікує'; }
    value(1; Completed) { Caption = 'Завершено'; }
    value(2; "Timed Out") { Caption = 'Час очікування вичерпано'; }
    value(3; Error) { Caption = 'Помилка'; }
}
