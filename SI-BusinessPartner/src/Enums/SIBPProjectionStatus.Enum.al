enum 54060 "SI BP Projection Status"
{
    Extensible = false;
    Caption = 'BP ERP Projection Status';

    value(0; Ready)
    {
        Caption = 'Готова';
    }

    value(1; Error)
    {
        Caption = 'Помилка';
    }

    value(2; Materialized)
    {
        Caption = 'Матеріалізована';
    }
}