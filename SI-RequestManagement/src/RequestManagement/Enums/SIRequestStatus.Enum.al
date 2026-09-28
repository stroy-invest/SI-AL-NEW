enum 52001 "SI Request Status"
{
    Extensible = true;

    value(0; Draft)
    {
        Caption = 'Чернетка';
    }

    value(1; "Pending Approval")
    {
        Caption = 'На погодженні';
    }

    value(2; Approved)
    {
        Caption = 'Погоджено';
    }

    value(3; Rejected)
    {
        Caption = 'Відхилено';
    }

    value(4; Returned)
    {
        Caption = 'Повернено на доопрацювання';
    }

    value(5; Cancelled)
    {
        Caption = 'Скасовано';
    }
}