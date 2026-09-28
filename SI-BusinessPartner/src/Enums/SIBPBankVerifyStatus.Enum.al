enum 54050 "SI BP Bank Verify Status"
{
    Extensible = false;
    Caption = 'Статус перевірки банку контрагента';

    value(0; "Not Verified")
    {
        Caption = 'Не перевірено';
    }

    value(1; Verified)
    {
        Caption = 'Перевірено';
    }

    value(2; "Verification Failed")
    {
        Caption = 'Помилка перевірки';
    }
}