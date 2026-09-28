enum 61012 "SI Supply Alloc Status"
{
    Extensible = false;

    value(0; Planned) { Caption = 'Заплановано'; }
    value(10; Released) { Caption = 'Передано у виконання'; }
    value(20; "In Progress") { Caption = 'Виконується'; }
    value(30; Fulfilled) { Caption = 'Виконано'; }
    value(40; Cancelled) { Caption = 'Скасовано'; }
    value(50; Error) { Caption = 'Помилка'; }
}
