codeunit 63000 "SI Geo Test Mgt."
{
    Access = Internal;

    procedure TestForwardGeocoding(
        AddressText: Text;
        var HttpStatus: Integer;
        var ResultText: Text;
        var CorrelationId: Guid;
        var DiagnosticUrl: Text;
        var ResultCount: Integer;
        var FormattedAddress: Text;
        var Latitude: Decimal;
        var Longitude: Decimal;
        var CoordinatesAvailable: Boolean)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Orchestrator: Codeunit "SI EDS Orchestrator";
        Parser: Codeunit "SI Geo Response Parser";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
    begin
        if not EnvironmentInformation.IsSandbox() then
            Error('Тестування Geo Service дозволене лише в Sandbox.');

        if AddressText.Trim() = '' then
            Error('Вкажіть адресу для геокодування.');

        Clear(HttpStatus);
        Clear(ResultText);
        Clear(CorrelationId);
        Clear(DiagnosticUrl);
        Clear(ResultCount);
        Clear(FormattedAddress);
        Clear(Latitude);
        Clear(Longitude);
        Clear(CoordinatesAvailable);

        // Foundation EDS owns routing, credentials and HTTP transport.
        RuntimeParam.Add('ADDRESS', AddressText);

        Orchestrator.Execute(
            'GEO',
            'GEOCODE-FORWARD',
            RuntimeParam,
            ResponseBuffer);

        if not ResponseBuffer.FindFirst() then
            Error('EDS не повернув результат виконання операції.');

        HttpStatus := ResponseBuffer."HTTP Status Code";
        CorrelationId := ResponseBuffer."Correlation ID";
        ResultText := Format(ResponseBuffer."Result Type");

        // Never expose the actual URL: it may contain credentials.
        DiagnosticUrl := '[Приховано: Query Credential]';

        // Parse only successful HTTP responses.
        if (HttpStatus < 200) or (HttpStatus >= 300) then
            exit;

        Parser.ParseForwardResponse(
            ResponseBuffer.GetBodyText(),
            ResultCount,
            FormattedAddress,
            Latitude,
            Longitude,
            CoordinatesAvailable);
    end;
}