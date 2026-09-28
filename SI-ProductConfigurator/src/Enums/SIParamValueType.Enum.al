enum 53001 "SI Param. Value Type"
{
    Extensible = false;
    Caption = 'Тип значення параметра';

    value(0; "Controlled Value")
    {
        Caption = 'Контрольоване значення';
    }

    value(10; Decimal)
    {
        Caption = 'Десяткове число';
    }

    value(20; Integer)
    {
        Caption = 'Ціле число';
    }

    value(30; Text)
    {
        Caption = 'Текст';
    }

    value(40; Boolean)
    {
        Caption = 'Так/Ні';
    }

    value(50; Date)
    {
        Caption = 'Дата';
    }

    value(60; Reference)
    {
        Caption = 'Кероване посилання';
    }
}