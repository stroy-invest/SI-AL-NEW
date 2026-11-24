enum 60000 "SI Customer Type"
{
    Extensible = false;
    Caption = 'Тип клієнта SI';

    value(0; External)
    {
        Caption = 'Зовнішній клієнт';
    }

    value(2; "Internal Operations")
    {
        Caption = 'Внутрішні операції';
    }

    value(1; "Internal Project")
    {
        Caption = 'Внутрішній проєкт';
    }
}
