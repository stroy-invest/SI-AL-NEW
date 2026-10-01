enum 56000 "SI Classification Node Type"
{
    Extensible = true;
    Caption = 'Тип вузла класифікації';

    value(0; Undefined)
    {
        Caption = 'Не визначено';
    }
    value(10; Root)
    {
        Caption = 'Кореневий вузол';
    }
    value(20; Section)
    {
        Caption = 'Секція';
    }
    value(30; Division)
    {
        Caption = 'Розділ';
    }
    value(40; Group)
    {
        Caption = 'Група';
    }
    value(50; Class)
    {
        Caption = 'Клас';
    }
    value(60; Category)
    {
        Caption = 'Категорія';
    }
    value(70; Position)
    {
        Caption = 'Позиція';
    }
}
