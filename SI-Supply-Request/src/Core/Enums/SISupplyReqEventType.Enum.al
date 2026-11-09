enum 61022 "SI Supply Req Event Type"
{
    Extensible = true;
    Caption = 'Тип події заявки';

    value(0; "Request Created") { Caption = 'Створено заявку'; }
    value(10; "Request Status Changed") { Caption = 'Змінено статус заявки'; }
    value(20; "Request Approved") { Caption = 'Погоджено заявку'; }
    value(30; "Marked Overdue") { Caption = 'Заявка задавнена'; }
    value(40; "Required Date Changed") { Caption = 'Перенесено дату потреби'; }
    value(50; "Request Reset to Draft") { Caption = 'Повернено заявку до чернетки'; }
    value(60; "Approval Reset") { Caption = 'Скинуто погодження'; }
    value(70; "Allocation Cancelled") { Caption = 'Скасовано розподіл'; }
    value(80; "Allocation Recalculated") { Caption = 'Перераховано розподіл'; }
}
