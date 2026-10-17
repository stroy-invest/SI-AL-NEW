// P0-B ONLY: compile-only capability probe. Do not invoke or publish.
// This intentionally tests whether TypeHelper.UrlEncode accepts SecretText.
// A compiler error is a meaningful NEGATIVE capability result, not a regression.
codeunit 50991 "SI EDS Query Encode Probe"
{
    Access = Internal;

    local procedure ProbeSecretQueryEncoding()
    var
        TypeHelper: Codeunit "Type Helper";
        ApiKey: SecretText;
        EncodedApiKey: SecretText;
        RequestUri: SecretText;
        Request: HttpRequestMessage;
    begin
        ApiKey := SecretStrSubstNo('a+b/c=d&e%f');

        // CAPABILITY UNDER TEST: must not unwrap or cast to Text.
        EncodedApiKey := ApiKey;
        TypeHelper.UrlEncode(EncodedApiKey);

        // CAPABILITY ALREADY SUPPORTED IN P0-A: secret URI composition.
        RequestUri := SecretStrSubstNo(
            'https://example.invalid/search?text=Kyiv&apiKey=%1',
            EncodedApiKey);
        Request.SetSecretRequestUri(RequestUri);
    end;
}
