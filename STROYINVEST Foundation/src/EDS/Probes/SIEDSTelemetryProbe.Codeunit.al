// P0-C2: isolated synthetic telemetry probe.
// BUILD ONLY during P0. No subscribers, job queue, or automatic invocation.
// Never use real credentials. Runtime invocation requires separate approval.
codeunit 50992 "SI EDS Telemetry Probe"
{
    Access = Internal;

    // Fixed endpoint, no external URL argument. Sandbox only.
    procedure RunSyntheticQueryProbe()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        SyntheticMarker: SecretText;
        SecretUri: SecretText;
        RequestSent: Boolean;
    begin
        if not EnvironmentInformation.IsSandbox() then
            Error('P0-C2 is restricted to Sandbox.');

        SyntheticMarker := SecretStrSubstNo('EDS-P0-C2-SYNTHETIC-2026');
        SecretUri := SecretStrSubstNo('https://httpbin.org/get?probeMarker=%1', SyntheticMarker);

        Request.Method := 'GET';
        Request.SetSecretRequestUri(SecretUri);
        RequestSent := Client.Send(Request, Response);

        // Deliberately do not log URL, headers, response body or secret.
        if not RequestSent then
            Error('P0-C2 synthetic HTTP transport failed.');
        if not Response.IsSuccessStatusCode() then
            Error('P0-C2 synthetic HTTP endpoint returned non-success status.');
    end;
}
