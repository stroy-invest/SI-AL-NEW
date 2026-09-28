codeunit 57055 "SI Prok Raw Login Test"
{
    procedure Execute(
        var Connection: Record "SI Prok Connection";
        var ResultText: Text)
    var
        PlainResult: Text;
        SecretResult: Text;
    begin
        ValidateConnection(Connection);

        ClearSession(Connection.Code);

        PlainResult :=
            ExecutePlainTextTest(
                Connection);

        ClearSession(Connection.Code);

        SecretResult :=
            ExecuteSecretTextTest(
                Connection);

        ClearSession(Connection.Code);

        ResultText :=
            '===== TEST 1: PLAIN TEXT BODY =====\' +
            PlainResult +
            '\' +
            '\' +
            '===== TEST 2: SECRET TEXT BODY =====\' +
            SecretResult;
    end;

    local procedure ExecutePlainTextTest(
        Connection: Record "SI Prok Connection"): Text
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        ContentHeaders: HttpHeaders;
        RequestBody: Text;
        ResponseBody: Text;
    begin
        RequestBody :=
            '{"companyCode":"' +
            Connection."Company Code" +
            '",' +
            '"username":"' +
            Connection.Username +
            '",' +
            '"password":"' +
            GetTestPassword() +
            '"}';

        HttpContent.WriteFrom(
            RequestBody);

        HttpContent.GetHeaders(
            ContentHeaders);

        SetContentType(
            ContentHeaders);

        RequestHeaders :=
            HttpClient.DefaultRequestHeaders();

        SetRequestHeaders(
            RequestHeaders);

        HttpRequest.SetRequestUri(
            GetLoginUrl());

        HttpRequest.Method(
            'POST');

        HttpRequest.Content(
            HttpContent);

        if not HttpClient.Send(
            HttpRequest,
            HttpResponse)
        then
            exit(
                'BC HttpClient не зміг відправити запит.');

        HttpResponse.Content.ReadAs(
            ResponseBody);

        exit(
            BuildResultText(
                HttpResponse,
                ResponseBody));
    end;

    local procedure ExecuteSecretTextTest(
        Connection: Record "SI Prok Connection"): Text
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        ContentHeaders: HttpHeaders;
        RequestJson: JsonObject;
        RequestBody: SecretText;
        TestPassword: SecretText;
        ResponseBody: Text;
    begin
        TestPassword :=
            GetTestPassword();

        RequestJson.Add(
            'companyCode',
            Connection."Company Code");

        RequestJson.Add(
            'username',
            Connection.Username);

        RequestJson.Add(
            'password',
            '__SECRET__');

        if not RequestJson.WriteWithSecretsTo(
            '$.password',
            TestPassword,
            RequestBody)
        then
            Error(
                'Не вдалося сформувати SecretText JSON для контрольного тесту.');

        HttpContent.WriteFrom(
            RequestBody);

        HttpContent.GetHeaders(
            ContentHeaders);

        SetContentType(
            ContentHeaders);

        RequestHeaders :=
            HttpClient.DefaultRequestHeaders();

        SetRequestHeaders(
            RequestHeaders);

        HttpRequest.SetRequestUri(
            GetLoginUrl());

        HttpRequest.Method(
            'POST');

        HttpRequest.Content(
            HttpContent);

        if not HttpClient.Send(
            HttpRequest,
            HttpResponse)
        then
            exit(
                'BC HttpClient не зміг відправити SecretText-запит.');

        HttpResponse.Content.ReadAs(
            ResponseBody);

        exit(
            BuildResultText(
                HttpResponse,
                ResponseBody));
    end;

    local procedure SetRequestHeaders(
        var RequestHeaders: HttpHeaders)
    begin
        if RequestHeaders.Contains(
            'Accept')
        then
            RequestHeaders.Remove(
                'Accept');

        if not RequestHeaders.TryAddWithoutValidation(
            'Accept',
            'text/plain')
        then
            Error(
                'Не вдалося встановити HTTP Accept.');

        if RequestHeaders.Contains(
            'User-Agent')
        then
            RequestHeaders.Remove(
                'User-Agent');

        if not RequestHeaders.TryAddWithoutValidation(
            'User-Agent',
            'STROYINVEST-BC-Integration/1.0')
        then
            Error(
                'Не вдалося встановити HTTP User-Agent.');
    end;

    local procedure SetContentType(
        var ContentHeaders: HttpHeaders)
    begin
        if ContentHeaders.Contains(
            'Content-Type')
        then
            ContentHeaders.Remove(
                'Content-Type');

        if not ContentHeaders.TryAddWithoutValidation(
            'Content-Type',
            'application/json-patch+json')
        then
            Error(
                'Не вдалося встановити HTTP Content-Type.');
    end;

    local procedure BuildResultText(
        HttpResponse: HttpResponseMessage;
        ResponseBody: Text): Text
    begin
        exit(
            StrSubstNo(
                'HTTP Status = %1\' +
                'Reason = %2\' +
                'Response Body:\' +
                '%3',
                HttpResponse.HttpStatusCode(),
                HttpResponse.ReasonPhrase(),
                ResponseBody));
    end;

    local procedure ClearSession(
        ConnectionCode: Code[50])
    var
        Session: Record "SI Prok Session";
    begin
        if not Session.Get(
            ConnectionCode)
        then
            exit;

        Session.ClearSession();
    end;

    local procedure ValidateConnection(
        Connection: Record "SI Prok Connection")
    begin
        Connection.TestField(Code);
        Connection.TestField("Company Code");
        Connection.TestField(Username);
    end;

    local procedure GetLoginUrl(): Text
    begin
        exit(
            'https://api.webizleme.net/Authentication/Login');
    end;

    local procedure GetTestPassword(): Text
    begin
        exit(
            'THIS_PASSWORD_IS_INTENTIONALLY_WRONG');
    end;
}