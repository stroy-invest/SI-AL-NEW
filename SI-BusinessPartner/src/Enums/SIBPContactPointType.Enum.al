enum 54022 "SI BP Contact Point Type"
{
    Extensible = true;
    Caption = 'Business Partner Contact Point Type';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(10; Phone)
    {
        Caption = 'Телефон';
    }
    value(20; Email)
    {
        Caption = 'Електронна пошта';
    }
    value(30; Messenger)
    {
        Caption = 'Месенджер';
    }
    value(40; Other)
    {
        Caption = 'Інше';
    }
}
