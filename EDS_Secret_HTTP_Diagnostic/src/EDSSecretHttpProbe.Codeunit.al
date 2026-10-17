
codeunit 70990 "EDS Secret HTTP Probe"
{
    [NonDebuggable]
    procedure RunProbe(Password: SecretText)
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Body: SecretText;
        ResponseBody: Text;
        CompanyValue: JsonValue;
        UsernameValue: JsonValue;
        CompanyJson: Text;
        UsernameJson: Text;
        Sent: Boolean;
    begin
        if Password.IsEmpty() then
            Error('Enter a synthetic test password.');

        // Build JSON with non-secret values.
        CompanyValue.SetValue('PR1234');
        CompanyValue.WriteTo(CompanyJson);

        UsernameValue.SetValue('DEMO');
        UsernameValue.WriteTo(UsernameJson);

        // Inject the password without converting
        // SecretText back to Text.
        Body := SecretStrSubstNo(
            '{"companyCode":%1,"username":%2,"password":"%3"}',
            CompanyJson,
            UsernameJson,
            Password);

        // Write the secret JSON body.
        Content.WriteFrom(Body);

        // Replace the default Content-Type.
        Content.GetHeaders(ContentHeaders);

        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');

        // Prepare HTTP POST request.
        Request.SetRequestUri('https://httpbin.org/post');
        Request.Method('POST');
        Request.Content(Content);

        // Execute request.
        Sent := Client.Send(Request, Response);

        if not Sent then
            Error(
                'HTTP send failed. Check Allow HttpClient Requests in Extension Management.');

        Response.Content.ReadAs(ResponseBody);

        // httpbin echoes the submitted password.
        // Use synthetic test values only.
        Message(
            'HTTP %1\Echo response (synthetic values only):\%2',
            Response.HttpStatusCode(),
            ResponseBody);
    end;
}
