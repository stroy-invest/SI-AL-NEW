enum 61011 "SI Supply Decision Status"
{
    Extensible = false;

    value(0; Draft) { Caption = 'Чернетка'; }
    value(10; Ready) { Caption = 'Розподіл готовий'; }
    value(20; "In Fulfillment") { Caption = 'У виконанні'; }
    value(30; Completed) { Caption = 'Виконано'; }
    value(40; Cancelled) { Caption = 'Скасовано'; }
}
