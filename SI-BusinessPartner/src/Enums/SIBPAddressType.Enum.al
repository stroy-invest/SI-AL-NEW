enum 54021 "SI BP Address Type"
{
    Extensible = true;
    Caption = 'Business Partner Address Type';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(10; Legal)
    {
        Caption = 'Юридична';
    }
    value(20; Mailing)
    {
        Caption = 'Поштова';
    }
    value(30; Shipping)
    {
        Caption = 'Для доставки';
    }
    value(40; Documents)
    {
        Caption = 'Для документів';
    }
    value(50; Physical)
    {
        Caption = 'Фактична';
    }
    value(60; Other)
    {
        Caption = 'Інша';
    }
}
