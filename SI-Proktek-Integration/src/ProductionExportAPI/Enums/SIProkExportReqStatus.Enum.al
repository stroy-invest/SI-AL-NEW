enum 57081 "SI Prok Export Req Status"
{
    Extensible = false;
    Caption = 'Статус запиту експорту Proktek';

    value(0; Queued)
    {
        Caption = 'Queued';
    }
    value(1; Running)
    {
        Caption = 'Running';
    }
    value(2; Completed)
    {
        Caption = 'Completed';
    }
    value(3; Failed)
    {
        Caption = 'Failed';
    }
}
