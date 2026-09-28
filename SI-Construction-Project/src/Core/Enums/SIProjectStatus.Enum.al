enum 60001 "SI Project Status"
{
    Extensible = false;
    Caption = 'Статус будівельного проєкту';

    value(0; Preparation) { Caption = 'Підготовка'; }
    value(1; "In Progress") { Caption = 'Виконується'; }
    value(2; Suspended) { Caption = 'Призупинено'; }
    value(3; Completed) { Caption = 'Завершено'; }
    value(4; Closed) { Caption = 'Закрито'; }
}
