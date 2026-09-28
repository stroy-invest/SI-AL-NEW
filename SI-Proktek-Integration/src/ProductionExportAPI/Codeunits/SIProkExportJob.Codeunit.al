codeunit 57083 "SI Prok Export Job"
{
    TableNo = "Job Queue Entry";
    Permissions =
        tabledata "SI Prok Export Request" = RIMD;

    trigger OnRun()
    var
        Request: Record "SI Prok Export Request";
        RequestId: Guid;
        ErrorText: Text;
    begin
        if Rec."Parameter String" = '' then
            Error('Для Job Queue не передано ID запиту Production Export.');

        if not Evaluate(RequestId, Rec."Parameter String") then
            Error('Некоректний ID запиту Production Export: %1.', Rec."Parameter String");

        Request.SetRange(SystemId, RequestId);
        if not Request.FindFirst() then
            Error('Запит Production Export %1 не знайдено.', RequestId);

        if Request.Status = Request.Status::Completed then
            exit;

        Request.Status := Request.Status::Running;
        Request."Started At" := CurrentDateTime;
        Request."Finished At" := 0DT;
        Request."Job Queue Entry ID" := Rec.ID;
        Clear(Request."Error Message");
        Request.Modify(true);
        Commit();

        ClearLastError();
        if Codeunit.Run(Codeunit::"SI Prok Export Execute", Request) then
            exit;

        ErrorText := GetLastErrorText();
        if ErrorText = '' then
            ErrorText := 'Невідома помилка фонового Production Export.';

        Request.Reset();
        Request.SetRange(SystemId, RequestId);
        if Request.FindFirst() then begin
            Request.Status := Request.Status::Failed;
            Request."Finished At" := CurrentDateTime;
            Request."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(Request."Error Message"));
            Request.Modify(true);
            Commit();
        end;

        Error(ErrorText);
    end;
}
