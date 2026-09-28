enum 59101 "SI WB Document Status"
{
    Extensible = false;
    Caption = 'Статус вагового документа';

    value(0; New)
    {
        Caption = 'Новий';
    }

    value(10; "In Progress")
    {
        Caption = 'В роботі';
    }

    value(20; Ready)
    {
        Caption = 'Готовий';
    }

    value(30; Processed)
    {
        Caption = 'Оброблений';
    }

    value(40; Error)
    {
        Caption = 'Помилка';
    }

    // Manager-stage lifecycle. Existing numeric values above are kept
    // intact for schema/backward compatibility.
    value(50; Submitted)
    {
        Caption = 'Передано менеджеру';
    }

    value(60; "Documents Created")
    {
        Caption = 'Передано до бухгалтерії';
    }
}