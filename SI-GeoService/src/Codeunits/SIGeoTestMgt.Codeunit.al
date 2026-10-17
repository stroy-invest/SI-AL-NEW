codeunit 63000 "SI Geo Test Mgt."
{
    Access = Internal;

    procedure TestForwardGeocoding(
        AddressText: Text;
        var HttpStatus: Integer;
        var ResultText: Text;
        var CorrelationId: Guid;
        var DiagnosticUrl: Text)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Orchestrator: Codeunit "SI EDS Orchestrator";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
    begin
        // Do not allow test execution in Production even if the page is reachable.
        if not EnvironmentInformation.IsSandbox() then
            Error('Тестування Geo Service дозволене лише в Sandbox.');

        if AddressText.Trim() = '' then
            Error('Вкажіть адресу для геокодування.');

        // EDS owns provider routing, credential resolution and HTTP transport.
        RuntimeParam.Add('ADDRESS', AddressText);
        Orchestrator.Execute('GEO', 'GEOCODE-FORWARD', RuntimeParam, ResponseBuffer);

        if not ResponseBuffer.FindFirst() then
            Error('EDS не повернув результат виконання операції.');

        HttpStatus := ResponseBuffer."HTTP Status Code";
        CorrelationId := ResponseBuffer."Correlation ID";
        ResultText := Format(ResponseBuffer."Result Type");
        // Do not display a response body or raw error text: a remote service
        // might echo a query-string credential.
        DiagnosticUrl := '[Приховано: Query Credential]';
    end;
}
