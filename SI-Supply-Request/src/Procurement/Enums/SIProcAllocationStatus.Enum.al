enum 61020 "SI Proc. Allocation Status"
{
    Extensible = true;
    Caption = 'Статус розподілу закупівлі';

    value(0; Draft) { Caption = 'Чернетка'; }
    value(1; Confirmed) { Caption = 'Підтверджено'; }
    value(2; Cancelled) { Caption = 'Скасовано'; }
    value(3; "Sent to PO") { Caption = 'Передано в замовлення'; }
}
