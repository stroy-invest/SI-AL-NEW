codeunit 57082 "SI Prok Export Request Mgt."
{
    Permissions =
        tabledata "SI Prok Export Request" = RIMD,
        tabledata "Job Queue Entry" = RIMD;

    procedure CreateAndEnqueue(var Request: Record "SI Prok Export Request")
    var
        DateFrom: Date;
        DateTo: Date;
    begin
        DateFrom := Request."Date From";
        DateTo := Request."Date To";

        if DateFrom = 0D then
            DateFrom := Today;
        if DateTo = 0D then
            DateTo := Today;

        ValidatePeriod(DateFrom, DateTo);
        ValidateProdConnection();

        Request.Init();
        Request."Date From" := DateFrom;
        Request."Date To" := DateTo;
        Request."Connection Code" := GetProdConnectionCode();
        Request.Status := Request.Status::Queued;
        Request."Created At" := CurrentDateTime;
        Request."Created By" := CopyStr(UserId(), 1, MaxStrLen(Request."Created By"));
        Request.SystemId := CreateGuid();
        Request.Insert(true, true);

        Enqueue(Request);
    end;

    procedure Requeue(var Request: Record "SI Prok Export Request")
    begin
        if Request.Status = Request.Status::Running then
            Error('Запит %1 зараз виконується.', Request."Entry No.");

        ValidateProdConnection();

        Request.Status := Request.Status::Queued;
        Request."Started At" := 0DT;
        Request."Finished At" := 0DT;
        Clear(Request."Job Queue Entry ID");
        Request."Export Entry No." := 0;
        Request."Production Count" := 0;
        Request."Total Volume M3" := 0;
        Clear(Request."Error Message");
        Request.Modify(true);

        Enqueue(Request);
    end;

    procedure ValidatePeriod(DateFrom: Date; DateTo: Date)
    begin
        if DateFrom = 0D then
            Error('Дата з не може бути порожньою.');
        if DateTo = 0D then
            Error('Дата по не може бути порожньою.');
        if DateTo < DateFrom then
            Error('Дата по не може бути раніше за дату з.');
    end;

    procedure GetProdConnectionCode(): Code[50]
    begin
        exit('PROKTEK-PROD');
    end;

    procedure ValidateProdConnection()
    var
        Connection: Record "SI Prok Connection";
        ConnectionCode: Code[50];
    begin
        ConnectionCode := GetProdConnectionCode();
        if not Connection.Get(ConnectionCode) then
            Error('Профіль підключення Proktek %1 не знайдено.', ConnectionCode);

        if Connection.Environment <> Connection.Environment::Production then
            Error('Профіль %1 має бути налаштований як PROD.', ConnectionCode);

        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");
        if Connection."EDS Provider Code" <> 'PROKTEK-PROD' then
            Error(
                'Для BAF Production Export профіль %1 має використовувати EDS Provider PROKTEK-PROD. Поточний Provider: %2.',
                ConnectionCode,
                Connection."EDS Provider Code");
    end;

    local procedure Enqueue(var Request: Record "SI Prok Export Request")
    var
        JobQueueEntry: Record "Job Queue Entry";
        RequestIdText: Text;
    begin
        RequestIdText := Format(Request.SystemId);

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"SI Prok Export Job";
        JobQueueEntry."Parameter String" := CopyStr(RequestIdText, 1, MaxStrLen(JobQueueEntry."Parameter String"));
        JobQueueEntry.Description :=
            CopyStr(
                StrSubstNo(
                    'BAF Proktek Production Export %1..%2',
                    Format(Request."Date From", 0, '<Year4>-<Month,2>-<Day,2>'),
                    Format(Request."Date To", 0, '<Year4>-<Month,2>-<Day,2>')),
                1,
                MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Maximum No. of Attempts to Run" := 1;
        JobQueueEntry."Rerun Delay (sec.)" := 0;

        if not Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry) then begin
            Request.Status := Request.Status::Failed;
            Request."Finished At" := CurrentDateTime;
            Request."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Request."Error Message"));
            Request.Modify(true);
            Error('Не вдалося поставити Proktek Production Export у Job Queue: %1', GetLastErrorText());
        end;

        Request."Job Queue Entry ID" := JobQueueEntry.ID;
        Request.Modify(true);
    end;
}
