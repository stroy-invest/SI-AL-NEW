enum 61006 "SI Supply Req Param Value Type"
{
    Extensible = false;
    Caption = 'Тип значення параметра';

    value(0; Code) { Caption = 'Код'; }
    value(10; Decimal) { Caption = 'Число'; }
    value(20; Text) { Caption = 'Текст'; }
    value(30; Boolean) { Caption = 'Так/Ні'; }
    value(40; Date) { Caption = 'Дата'; }
    value(50; DateTime) { Caption = 'Дата й час'; }
}
