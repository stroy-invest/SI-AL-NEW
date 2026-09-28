enum 50202 "SI Notification Status"
{
    Extensible = false;
    Caption = 'Статус повідомлення';

    value(0; Unread)
    {
        Caption = 'Непрочитане';
    }

    value(1; Read)
    {
        Caption = 'Прочитане';
    }

    value(2; Dismissed)
    {
        Caption = 'Приховане';
    }

    value(3; Expired)
    {
        Caption = 'Термін чинності минув';
    }
}