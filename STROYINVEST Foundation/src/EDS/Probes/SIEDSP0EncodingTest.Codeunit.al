// P0 test-only. BUILD ONLY until explicit Sandbox publish approval.
// Uses a fixed synthetic value; no EDS credential store access.
codeunit 50994 "SI EDS P0 Encoding Test"
{
    Access = Internal;

    procedure RunDeterministicTest(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
        TypeHelper: Codeunit "Type Helper";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        SyntheticValue: SecretText;
        EncodedValue: SecretText;
        RequestUri: SecretText;
        ResponseBody: Text;
        JsonResponse: JsonObject;
        ArgsToken: JsonToken;
        ApiKeyToken: JsonToken;
        UrlToken: JsonToken;
        ArgsObject: JsonObject;
        ReturnedUrl: Text;
    begin
        if not EnvironmentInformation.IsSandbox() then
            Error('P0 encoding probe is restricted to Sandbox.');

        SyntheticValue := SecretStrSubstNo('a+b/c=d&e%f');
        EncodedValue := SyntheticValue;

        // Verify the precise call pattern used by P0-B (including mutation semantics).
        TypeHelper.UrlEncode(EncodedValue);

        RequestUri := SecretStrSubstNo(
            'https://httpbin.org/get?probeMarker=EDS-P0-ENCODING-2026&apiKey=%1',
            EncodedValue);
        Request.Method := 'GET';
        Request.SetSecretRequestUri(RequestUri);

        if not Client.Send(Request, Response) then
            Error('P0 encoding probe: HTTP transport failed.');
        if not Response.IsSuccessStatusCode() then
            Error('P0 encoding probe: HTTP endpoint returned a non-success status.');
        if not Response.Content().ReadAs(ResponseBody) then
            Error('P0 encoding probe: cannot read HTTP response.');
        if not JsonResponse.ReadFrom(ResponseBody) then
            Error('P0 encoding probe: invalid JSON response.');
        if not JsonResponse.Get('args', ArgsToken) then
            Error('P0 encoding probe: missing args in response.');
        if not ArgsToken.IsObject() then
            Error('P0 encoding probe: args is not an object.');
        ArgsObject := ArgsToken.AsObject();
        if not ArgsObject.Get('apiKey', ApiKeyToken) then
            Error('P0 encoding probe: missing apiKey in response.');
        if not ApiKeyToken.IsValue() then
            Error('P0 encoding probe: invalid apiKey type.');
        if ApiKeyToken.AsValue().AsText() <> 'a+b/c=d&e%f' then
            Error('P0 encoding probe: FAIL (decoded query value differs).');

        // httpbin may normalize the returned URL; this is an additional check,
        // not a byte-for-byte verification of the original request target.
        if not JsonResponse.Get('url', UrlToken) then
            Error('P0 encoding probe: missing url in response.');
        if not UrlToken.IsValue() then
            Error('P0 encoding probe: invalid url type.');
        ReturnedUrl := UrlToken.AsValue().AsText();
        // Return representation check separately: httpbin may normalize its URL field.
        exit(StrPos(ReturnedUrl, 'apiKey=a%2Bb%2Fc%3Dd%26e%25f') <> 0);

        // Do not display/log response body or URL: these are test-only synthetic values.
    end;
}
