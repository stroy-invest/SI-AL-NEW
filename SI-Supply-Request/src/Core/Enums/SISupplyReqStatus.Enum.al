enum 61000 "SI Supply Req Status"
{
    Extensible = false;

    value(0; Draft) { Caption = 'Чернетка'; }
    value(10; "Pending Approval") { Caption = 'Очікує погодження'; }
    value(20; Approved) { Caption = 'Погоджено'; }
    value(30; "In Fulfillment") { Caption = 'В забезпеченні'; }
    value(40; "Partially Fulfilled") { Caption = 'Частково забезпечено'; }
    value(50; Fulfilled) { Caption = 'Забезпечено'; }
    value(60; Cancelled) { Caption = 'Скасовано'; }
}
