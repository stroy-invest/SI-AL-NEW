codeunit 57054 "SI Prok Company Info"
{
    procedure Execute(
        var Connection: Record "SI Prok Connection";
        var ResponseText: Text)
    var
        Session: Record "SI Prok Session";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        RequestBody: Text;
    begin
        ValidateConnection(Connection);

        AuthMgt.EnsureSession(
            Connection,
            Session);

        RequestBody :=
            BuildRequestBody(
                Session."Session GUID");

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code",
            GetOperationCode(),
            Connection."EDS Provider Code",
            RuntimeParam,
            RequestBody,
            'application/json-patch+json',
            'text/plain',
            ResponseBuffer);

        Clear(RequestBody);

        ValidateResponse(
            ResponseBuffer);

        ResponseText :=
            ResponseBuffer.GetBodyText();
    end;

    local procedure ValidateConnection(
        Connection: Record "SI Prok Connection")
    begin
        Connection.TestField(Code);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");
    end;

    local procedure BuildRequestBody(
        SessionGuid: Guid): Text
    var
        RequestJson: JsonObject;
        RequestBody: Text;
    begin
        if IsNullGuid(SessionGuid) then
            Error(
                'Неможливо виконати запит Proktek: GUID сеансу відсутній.');

        RequestJson.Add(
            'guid',
            Format(
                SessionGuid,
                0,
                4));

        RequestJson.WriteTo(
            RequestBody);

        exit(
            RequestBody);
    end;

    local procedure ValidateResponse(
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        ResponseBody: Text;
    begin
        if ResponseBuffer."Result Type" =
           ResponseBuffer."Result Type"::Success
        then
            exit;

        ResponseBody :=
            ResponseBuffer.GetBodyText();

        if ResponseBody = '' then
            ResponseBody :=
                '<порожнє тіло відповіді>';

        Error(
            'Запит Proktek CompanyInfo завершився помилкою.\' +
            '\' +
            'HTTP Status = %1\' +
            'HTTP Reason = %2\' +
            'Blocked By BC Environment = %3\' +
            'EDS Result = %4\' +
            'EDS Error = %5\' +
            '\' +
            'Request URL = %6\' +
            'HTTP Method = %7\' +
            'Content-Type = %8\' +
            '\' +
            'Response Body:\' +
            '%9',
            ResponseBuffer."HTTP Status Code",
            ResponseBuffer."HTTP Reason Phrase",
            ResponseBuffer."Blocked By Environment",
            Format(ResponseBuffer."Result Type"),
            ResponseBuffer."Error Message",
            ResponseBuffer."Request URL",
            Format(ResponseBuffer."Request Method"),
            ResponseBuffer."Request Content Type",
            ResponseBody);
    end;

    local procedure GetOperationCode(): Code[50]
    begin
        exit('COMPANY-INFO');
    end;
}