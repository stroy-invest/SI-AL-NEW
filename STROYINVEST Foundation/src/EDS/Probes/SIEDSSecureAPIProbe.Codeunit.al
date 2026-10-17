// P0 ONLY. Compile-time API capability probe; never call this codeunit.
// Delete this file after recording compiler results.
codeunit 50990 "SI EDS Secure API Probe"
{
    Access = Internal;

    // URI channel: can the AL runtime assign a secret URI without Text?
    local procedure ProbeSecretUri()
    var
        Request: HttpRequestMessage;
        SecretUri: SecretText;
    begin
        SecretUri := SecretStrSubstNo('https://example.invalid/path?key=%1', SecretStrSubstNo('dummy'));
        Request.SetSecretRequestUri(SecretUri);
    end;

    // Header channel: can HttpHeaders receive SecretText directly?
    local procedure ProbeSecretHeader()
    var
        Request: HttpRequestMessage;
        Headers: HttpHeaders;
        SecretValue: SecretText;
    begin
        SecretValue := SecretStrSubstNo('Bearer %1', SecretStrSubstNo('dummy'));
        Request.GetHeaders(Headers);
        Headers.Add('Authorization', SecretValue);
    end;

    // Body channel: can HttpContent receive SecretText directly?
    local procedure ProbeSecretBody()
    var
        Content: HttpContent;
        SecretBody: SecretText;
    begin
        SecretBody := SecretStrSubstNo('{"token":"%1"}', SecretStrSubstNo('dummy'));
        Content.WriteFrom(SecretBody);
    end;
}
