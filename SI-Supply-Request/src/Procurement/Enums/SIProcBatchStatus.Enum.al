enum 61016 "SI Proc. Batch Status"
{
    Extensible = true;
    Caption = 'Статус підготовки закупівлі';

    value(0; Draft) { Caption = 'Чернетка'; }
    value(10; "Orders Created") { Caption = 'Замовлення сформовано'; }
    value(20; Cancelled) { Caption = 'Скасовано'; }
}
