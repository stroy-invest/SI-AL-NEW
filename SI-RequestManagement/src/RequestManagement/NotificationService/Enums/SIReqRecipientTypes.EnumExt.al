enumextension 52035 "SI Req. Recipient Types"
    extends "SI Recipient Resolver Type"
{
    value(52000; Requester)
    {
        Caption = 'Заявник';
    }

    value(52001; CurrentApprover)
    {
        Caption = 'Поточний погоджувач';
    }

    value(52002; NextApprover)
    {
        Caption = 'Наступний погоджувач';
    }

    value(52003; AssignedApprover)
    {
        Caption = 'Призначений погоджувач';
    }
}