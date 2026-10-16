codeunit 50430 "SI EDS HTTP Transport"
{
    procedure Execute(
        var RequestBuffer: Record "SI EDS Request Buffer" temporary;
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    begin
        Execute(
            RequestBuffer,
            '*/*',
            ResponseBuffer);
    end;

    procedure Execute(
        var RequestBuffer: Record "SI EDS Request Buffer" temporary;
        AcceptType: Text;
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        RequestBody: Text;
        ResponseText: Text;
        RequestUrl: Text;
        StartedAt: DateTime;
        FinishedAt: DateTime;
        RateLimitMgt: Codeunit "SI EDS Rate Limit Mgt.";
    begin
        InitializeResponseBuffer(
            RequestBuffer,
            ResponseBuffer);

        SetStandardRequestHeaders(
            HttpClient,
            AcceptType);

        ApplyConfiguredRequestHeaders(
            RequestBuffer,
            HttpClient);

        RequestUrl :=
            BuildUrl(RequestBuffer);

        // Diagnostic URL is set before credential resolution.
        SetRequestUrl(
            RequestBuffer,
            ResponseBuffer,
            BuildDiagnosticUrl(RequestBuffer, RequestUrl));

        // 79-C2 is compile-only. 79-C3 must audit all error/log paths
        // before allowing an HTTP request containing query credentials.
        RequestUrl := AppendCredentialQueryParameters(RequestBuffer, RequestUrl);

        RateLimitMgt.WaitForSlot(RequestBuffer."Provider Code");

        StartedAt :=
            CurrentDateTime;

        case RequestBuffer."HTTP Method" of
            RequestBuffer."HTTP Method"::GET:
                begin
                    if HasEnabledQueryCredential(RequestBuffer) then begin
                        if not TryGetWithQueryCredential(
                            HttpClient, RequestUrl, HttpResponse)
                        then begin
                            FinishedAt := CurrentDateTime;
                            SetTransportFailure(
                                ResponseBuffer, StartedAt, FinishedAt,
                                'HTTP_SEND_FAILED',
                                'Не вдалося виконати HTTP-запит до зовнішнього сервісу.');
                            ResponseBuffer.Insert();
                            exit;
                        end;
                    end else
                    if not HttpClient.Get(
                        RequestUrl,
                        HttpResponse)
                    then begin
                        FinishedAt :=
                            CurrentDateTime;

                        SetTransportFailure(
                            ResponseBuffer,
                            StartedAt,
                            FinishedAt,
                            'HTTP_SEND_FAILED',
                            'Не вдалося виконати HTTP-запит до зовнішнього сервісу.');

                        ResponseBuffer.Insert();
                        exit;
                    end;
                end;

            RequestBuffer."HTTP Method"::POST:
                begin
                    RequestBody :=
                        RequestBuffer.GetBody();

                    HttpContent.WriteFrom(
                        RequestBody);

                    SetContentType(
                        HttpContent,
                        RequestBuffer."Content Type");

                    if HasEnabledQueryCredential(RequestBuffer) then begin
                        if not TryPostWithQueryCredential(
                            HttpClient, HttpRequest, HttpContent,
                            RequestUrl, HttpResponse)
                        then begin
                            FinishedAt := CurrentDateTime;
                            SetTransportFailure(
                                ResponseBuffer, StartedAt, FinishedAt,
                                'HTTP_SEND_FAILED',
                                'Не вдалося виконати HTTP-запит до зовнішнього сервісу.');
                            ResponseBuffer.Insert();
                            exit;
                        end;
                    end else begin
                        HttpRequest.SetRequestUri(RequestUrl);
                        HttpRequest.Method('POST');
                        HttpRequest.Content(HttpContent);

                        if not HttpClient.Send(
                            HttpRequest,
                            HttpResponse)
                        then begin
                            FinishedAt := CurrentDateTime;
                            SetTransportFailure(
                                ResponseBuffer, StartedAt, FinishedAt,
                                'HTTP_SEND_FAILED',
                                'Не вдалося виконати HTTP-запит до зовнішнього сервісу.');
                            ResponseBuffer.Insert();
                            exit;
                        end;
                    end;
                end;

            else begin
                FinishedAt :=
                    CurrentDateTime;

                SetTransportFailure(
                    ResponseBuffer,
                    StartedAt,
                    FinishedAt,
                    'METHOD_NOT_SUPPORTED',
                    StrSubstNo(
                        'HTTP метод %1 ще не підтримується транспортом EDS.',
                        Format(RequestBuffer."HTTP Method")));

                ResponseBuffer.Insert();
                exit;
            end;
        end;

        FinishResponse(
            HttpResponse,
            StartedAt,
            ResponseBuffer,
            ResponseText,
            HasEnabledQueryCredential(RequestBuffer));
    end;

    procedure ExecuteSecretBody(
        var RequestBuffer: Record "SI EDS Request Buffer" temporary;
        RequestBody: SecretText;
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    begin
        ExecuteSecretBody(
            RequestBuffer,
            RequestBody,
            '*/*',
            ResponseBuffer);
    end;

    procedure ExecuteSecretBody(
        var RequestBuffer: Record "SI EDS Request Buffer" temporary;
        RequestBody: SecretText;
        AcceptType: Text;
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        ResponseText: Text;
        RequestUrl: Text;
        StartedAt: DateTime;
        FinishedAt: DateTime;
        RateLimitMgt: Codeunit "SI EDS Rate Limit Mgt.";
    begin
        InitializeResponseBuffer(
            RequestBuffer,
            ResponseBuffer);

        SetStandardRequestHeaders(
            HttpClient,
            AcceptType);

        ApplyConfiguredRequestHeaders(
            RequestBuffer,
            HttpClient);

        RequestUrl :=
            BuildUrl(RequestBuffer);

        // Diagnostic URL is set before credential resolution.
        SetRequestUrl(
            RequestBuffer,
            ResponseBuffer,
            BuildDiagnosticUrl(RequestBuffer, RequestUrl));

        // 79-C2 is compile-only. 79-C3 must audit all error/log paths
        // before allowing an HTTP request containing query credentials.
        RequestUrl := AppendCredentialQueryParameters(RequestBuffer, RequestUrl);

        RateLimitMgt.WaitForSlot(RequestBuffer."Provider Code");

        StartedAt :=
            CurrentDateTime;

        if RequestBuffer."HTTP Method" <>
           RequestBuffer."HTTP Method"::POST
        then begin
            FinishedAt :=
                CurrentDateTime;

            SetTransportFailure(
                ResponseBuffer,
                StartedAt,
                FinishedAt,
                'SECRET_BODY_REQUIRES_POST',
                'Секретне тіло запиту підтримується лише для HTTP POST.');

            ResponseBuffer.Insert();
            exit;
        end;

        HttpContent.WriteFrom(
            RequestBody);

        SetContentType(
            HttpContent,
            RequestBuffer."Content Type");

        if HasEnabledQueryCredential(RequestBuffer) then begin
            if not TryPostWithQueryCredential(
                HttpClient, HttpRequest, HttpContent,
                RequestUrl, HttpResponse)
            then begin
                FinishedAt := CurrentDateTime;
                SetTransportFailure(
                    ResponseBuffer, StartedAt, FinishedAt,
                    'HTTP_SEND_FAILED',
                    'Не вдалося виконати HTTP-запит до зовнішнього сервісу.');
                ResponseBuffer.Insert();
                exit;
            end;
        end else begin
            HttpRequest.SetRequestUri(RequestUrl);
            HttpRequest.Method('POST');
            HttpRequest.Content(HttpContent);

            if not HttpClient.Send(HttpRequest, HttpResponse) then begin
                FinishedAt := CurrentDateTime;
                SetTransportFailure(
                    ResponseBuffer, StartedAt, FinishedAt,
                    'HTTP_SEND_FAILED',
                    'Не вдалося виконати HTTP-запит до зовнішнього сервісу.');
                ResponseBuffer.Insert();
                exit;
            end;
        end;

        FinishResponse(
            HttpResponse,
            StartedAt,
            ResponseBuffer,
            ResponseText,
            HasEnabledQueryCredential(RequestBuffer));
    end;

    // Fix 5: a narrow exception boundary for query-credential HTTP calls.
    // Never propagate GetLastErrorText() or a raw request URI to EDS buffers.
    // This does not control internal Business Central platform telemetry.
    [TryFunction]
    [NonDebuggable]
    local procedure TryGetWithQueryCredential(
        var Client: HttpClient;
        RequestUrl: Text;
        var Response: HttpResponseMessage)
    begin
        if not Client.Get(RequestUrl, Response) then
            Error('EDS HTTP request failed.');
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TryPostWithQueryCredential(
        var Client: HttpClient;
        var Request: HttpRequestMessage;
        var Content: HttpContent;
        RequestUrl: Text;
        var Response: HttpResponseMessage)
    begin
        Request.SetRequestUri(RequestUrl);
        Request.Method('POST');
        Request.Content(Content);
        if not Client.Send(Request, Response) then
            Error('EDS HTTP request failed.');
    end;

    local procedure InitializeResponseBuffer(
        var RequestBuffer: Record "SI EDS Request Buffer" temporary;
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    begin
        ResponseBuffer.Reset();
        ResponseBuffer.DeleteAll();

        ResponseBuffer.Init();
        ResponseBuffer."Entry No." := 1;
        ResponseBuffer."Correlation ID" :=
            RequestBuffer."Correlation ID";
        ResponseBuffer."Provider Code" :=
            RequestBuffer."Provider Code";
        ResponseBuffer."Endpoint Code" :=
            RequestBuffer."Endpoint Code";
        ResponseBuffer."Request Method" :=
            RequestBuffer."HTTP Method";

        ResponseBuffer."Request Content Type" :=
            CopyStr(
                GetEffectiveContentType(
                    RequestBuffer."Content Type"),
                1,
                MaxStrLen(
                    ResponseBuffer."Request Content Type"));
    end;

    local procedure SetRequestUrl(
        var RequestBuffer: Record "SI EDS Request Buffer" temporary;
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        RequestUrl: Text)
    begin
        RequestBuffer."Request URL" :=
            CopyStr(
                RequestUrl,
                1,
                MaxStrLen(
                    RequestBuffer."Request URL"));

        ResponseBuffer."Request URL" :=
            CopyStr(
                RequestUrl,
                1,
                MaxStrLen(
                    ResponseBuffer."Request URL"));
    end;

    local procedure FinishResponse(
        var HttpResponse: HttpResponseMessage;
        StartedAt: DateTime;
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        var ResponseText: Text;
        HasQueryCredential: Boolean)
    var
        FinishedAt: DateTime;
        RateLimitMgt: Codeunit "SI EDS Rate Limit Mgt.";
    begin
        FinishedAt :=
            CurrentDateTime;

        ResponseBuffer."Duration (ms)" :=
            GetDurationMs(
                StartedAt,
                FinishedAt);

        ResponseBuffer."HTTP Status Code" :=
            HttpResponse.HttpStatusCode();

        // C7 Fix 1: upstream reason phrases are untrusted and may echo
        // the requested URI, including query credentials.
        if HasQueryCredential then
            ResponseBuffer."HTTP Reason Phrase" := 'REDACTED'
        else
            ResponseBuffer."HTTP Reason Phrase" :=
                CopyStr(
                    HttpResponse.ReasonPhrase(),
                    1,
                    MaxStrLen(ResponseBuffer."HTTP Reason Phrase"));

        ResponseBuffer."Blocked By Environment" :=
            HttpResponse.IsBlockedByEnvironment();

        if HttpResponse.Content.ReadAs(
            ResponseText)
        then;

        ClassifyResponse(
            HttpResponse,
            ResponseBuffer);

        // Persist the temporary buffer record first. BLOB fields written only
        // to the record variable before Insert() are not reliably retained
        // in the inserted temporary-table row.
        ResponseBuffer.Insert();

        // C7 Fix 1: never persist raw response headers for an operation
        // that sends a credential in the query string (e.g. Location).
        if HasQueryCredential then
            ResponseBuffer.SetHeaders('REDACTED: Query Credential operation')
        else
            ResponseBuffer.SetHeaders(
                BuildResponseHeadersText(
                    HttpResponse));

        if ResponseText <> '' then
            ResponseBuffer.SetBody(
                ResponseText);

        ResponseBuffer.Modify(false);
    end;

    local procedure SetStandardRequestHeaders(
        var HttpClient: HttpClient;
        AcceptType: Text)
    var
        RequestHeaders: HttpHeaders;
        EffectiveAcceptType: Text;
    begin
        EffectiveAcceptType :=
            AcceptType;

        if EffectiveAcceptType = '' then
            EffectiveAcceptType :=
                '*/*';

        RequestHeaders :=
            HttpClient.DefaultRequestHeaders();

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

        if RequestHeaders.Contains(
            'Accept')
        then
            RequestHeaders.Remove(
                'Accept');

        if not RequestHeaders.TryAddWithoutValidation(
            'Accept',
            EffectiveAcceptType)
        then
            Error(
                'Не вдалося встановити HTTP Accept. Значення: %1',
                EffectiveAcceptType);
    end;

    [NonDebuggable]
    local procedure ApplyConfiguredRequestHeaders(
        RequestBuffer: Record "SI EDS Request Buffer" temporary;
        var HttpClient: HttpClient)
    var
        EDSParameter: Record "SI EDS Parameter";
        CredentialMgt: Codeunit "SI EDS Credential Mgt.";
        RequestHeaders: HttpHeaders;
        HeaderName: Text;
        HeaderValue: Text;
    begin
        EDSParameter.SetRange("Service Code", RequestBuffer."Service Code");
        EDSParameter.SetRange("Operation Code", RequestBuffer."Operation Code");
        EDSParameter.SetRange("Provider Code", RequestBuffer."Provider Code");
        EDSParameter.SetRange(Location, EDSParameter.Location::Header);
        EDSParameter.SetRange(Enabled, true);
        EDSParameter.SetCurrentKey(
            "Service Code", "Operation Code", "Provider Code", Enabled, Sequence);

        if not EDSParameter.FindSet() then
            exit;

        RequestHeaders := HttpClient.DefaultRequestHeaders();

        repeat
            HeaderName := EDSParameter.GetExternalName();

            case EDSParameter.Source of
                EDSParameter.Source::Fixed:
                    HeaderValue :=
                        EDSParameter."Value Prefix" + EDSParameter.Value;

                EDSParameter.Source::Credential:
                    HeaderValue :=
                        EDSParameter."Value Prefix" +
                        CredentialMgt.GetSecretText(
                            RequestBuffer."Provider Code",
                            EDSParameter."Credential Code");

                EDSParameter.Source::Runtime:
                    Error(
                        'Runtime HTTP headers ще не підтримуються EDS. Параметр: %1.',
                        EDSParameter.Code);
            end;

            if EDSParameter.Required and (HeaderValue = '') then
                Error(
                    'HTTP header %1 має порожнє обов''язкове значення.',
                    HeaderName);

            if HeaderValue <> '' then begin
                if RequestHeaders.Contains(HeaderName) then
                    RequestHeaders.Remove(HeaderName);

                if not RequestHeaders.TryAddWithoutValidation(
                    HeaderName,
                    HeaderValue)
                then
                    Error(
                        'Не вдалося встановити HTTP header %1.',
                        HeaderName);
            end;

            Clear(HeaderValue);
        until EDSParameter.Next() = 0;
    end;

    local procedure SetContentType(
        var HttpContent: HttpContent;
        ContentType: Text)
    var
        ContentHeaders: HttpHeaders;
        EffectiveContentType: Text;
    begin
        EffectiveContentType :=
            GetEffectiveContentType(
                ContentType);

        HttpContent.GetHeaders(
            ContentHeaders);

        if ContentHeaders.Contains(
            'Content-Type')
        then
            ContentHeaders.Remove(
                'Content-Type');

        if not ContentHeaders.TryAddWithoutValidation(
            'Content-Type',
            EffectiveContentType)
        then
            Error(
                'Не вдалося встановити HTTP Content-Type. Значення: %1',
                EffectiveContentType);
    end;

    local procedure GetEffectiveContentType(
        ContentType: Text): Text
    begin
        if ContentType = '' then
            exit(
                'application/json');

        exit(
            ContentType);
    end;

    local procedure BuildResponseHeadersText(
        HttpResponse: HttpResponseMessage): Text
    var
        ResponseHeaders: HttpHeaders;
        ContentHeaders: HttpHeaders;
        Result: Text;
    begin
        ResponseHeaders :=
            HttpResponse.Headers();

        Result :=
            SerializeHeaders(
                'Response Headers',
                ResponseHeaders);

        if HttpResponse.Content.GetHeaders(
            ContentHeaders)
        then begin
            if Result <> '' then
                Result += '\\';

            Result +=
                SerializeHeaders(
                    'Content Headers',
                    ContentHeaders);
        end;

        exit(Result);
    end;

    local procedure SerializeHeaders(
        SectionName: Text;
        Headers: HttpHeaders): Text
    var
        HeaderKeys: List of [Text];
        HeaderValues: List of [Text];
        HeaderKey: Text;
        HeaderValue: Text;
        Result: Text;
    begin
        HeaderKeys :=
            Headers.Keys();

        Result :=
            SectionName + ':';

        foreach HeaderKey in HeaderKeys do begin
            Clear(
                HeaderValues);

            if IsSensitiveHeader(
                HeaderKey)
            then begin
                Result +=
                    StrSubstNo(
                        '\\%1: <masked>',
                        HeaderKey);

                continue;
            end;

            if Headers.GetValues(
                HeaderKey,
                HeaderValues)
            then
                foreach HeaderValue in HeaderValues do
                    Result +=
                        StrSubstNo(
                            '\\%1: %2',
                            HeaderKey,
                            HeaderValue);
        end;

        exit(Result);
    end;

    local procedure IsSensitiveHeader(
        HeaderName: Text): Boolean
    var
        NormalizedName: Text;
    begin
        NormalizedName :=
            HeaderName.ToUpper();

        exit(
            (NormalizedName = 'AUTHORIZATION') or
            (NormalizedName = 'PROXY-AUTHORIZATION') or
            (NormalizedName = 'SET-COOKIE') or
            (NormalizedName = 'COOKIE'));
    end;

    local procedure HasEnabledQueryCredential(
        RequestBuffer: Record "SI EDS Request Buffer" temporary): Boolean
    var
        EDSParameter: Record "SI EDS Parameter";
    begin
        EDSParameter.SetRange("Service Code", RequestBuffer."Service Code");
        EDSParameter.SetRange("Operation Code", RequestBuffer."Operation Code");
        EDSParameter.SetRange("Provider Code", RequestBuffer."Provider Code");
        EDSParameter.SetRange(Location, EDSParameter.Location::Query);
        EDSParameter.SetRange(Source, EDSParameter.Source::Credential);
        EDSParameter.SetRange(Enabled, true);
        exit(not EDSParameter.IsEmpty());
    end;

    local procedure BuildDiagnosticUrl(
        RequestBuffer: Record "SI EDS Request Buffer" temporary;
        BaseRequestUrl: Text): Text
    var
        EDSParameter: Record "SI EDS Parameter";
        QueryPosition: Integer;
    begin
        EDSParameter.SetRange("Service Code", RequestBuffer."Service Code");
        EDSParameter.SetRange("Operation Code", RequestBuffer."Operation Code");
        EDSParameter.SetRange("Provider Code", RequestBuffer."Provider Code");
        EDSParameter.SetRange(Location, EDSParameter.Location::Query);
        EDSParameter.SetRange(Source, EDSParameter.Source::Credential);
        EDSParameter.SetRange(Enabled, true);
        if EDSParameter.IsEmpty() then
            exit(BaseRequestUrl);

        // C3: redact the entire query, including runtime/fixed values.
        // Never use the actual URI in request/response buffers or EDS logs.
        QueryPosition := StrPos(BaseRequestUrl, '?');
        if QueryPosition > 0 then
            exit(CopyStr(BaseRequestUrl, 1, QueryPosition - 1) + '?[REDACTED]');

        exit(BaseRequestUrl + '?[REDACTED]');
    end;

    [NonDebuggable]
    local procedure AppendCredentialQueryParameters(
        RequestBuffer: Record "SI EDS Request Buffer" temporary;
        BaseRequestUrl: Text): Text
    var
        EDSParameter: Record "SI EDS Parameter";
        CredentialMgt: Codeunit "SI EDS Credential Mgt.";
        TypeHelper: Codeunit "Type Helper";
        ActualUrl: Text;
        CredentialValue: Text;
        EncodedName: Text;
        EncodedValue: Text;
    begin
        EDSParameter.SetRange("Service Code", RequestBuffer."Service Code");
        EDSParameter.SetRange("Operation Code", RequestBuffer."Operation Code");
        EDSParameter.SetRange("Provider Code", RequestBuffer."Provider Code");
        EDSParameter.SetRange(Location, EDSParameter.Location::Query);
        EDSParameter.SetRange(Source, EDSParameter.Source::Credential);
        EDSParameter.SetRange(Enabled, true);
        if not EDSParameter.FindSet() then
            exit(BaseRequestUrl);

        // C4 controlled enablement gate: fail closed until explicit approval.
        // HTTPS is mandatory for every Query Credential operation.
        if not BaseRequestUrl.StartsWith('https://') then
            Error('EDS Query Credential вимагає HTTPS endpoint.');

        // C7: compile-time opt-in, disabled in ordinary builds.
        // NEVER define EDS_C7_SANDBOX_ENABLE for production builds.
#if EDS_C7_SANDBOX_ENABLE
        if not IsSandboxEnvironment() then
            Error('EDS Query Credentials: дозволено лише в Sandbox.');
#else
        Error('EDS Query Credentials: C7 validation disabled in this build.');
#endif

        // The plaintext URL exists transiently in this NonDebuggable procedure.
        // Enabling C7 requires an explicit security decision and canary tests.
        ActualUrl := BaseRequestUrl;
        repeat
            if EDSParameter.Format <> EDSParameter.Format::"Name Value" then
                Error('Credential Query %1 повинен мати формат Name=Value.', EDSParameter.Code);
            CredentialValue := CredentialMgt.GetSecretText(
                RequestBuffer."Provider Code", EDSParameter."Credential Code");
            if EDSParameter.Required and (CredentialValue = '') then
                Error('Credential Query %1 не має значення.', EDSParameter.Code);
            if StrPos(ActualUrl, '?') = 0 then
                ActualUrl += '?'
            else
                ActualUrl += '&';
            EncodedName := EDSParameter.GetExternalName();
            EncodedValue := EDSParameter."Value Prefix" + CredentialValue;
            TypeHelper.UrlEncode(EncodedName);
            TypeHelper.UrlEncode(EncodedValue);
            ActualUrl += EncodedName + '=' + EncodedValue;
            Clear(CredentialValue);
            Clear(EncodedValue);
        until EDSParameter.Next() = 0;
        exit(ActualUrl);
    end;

#if EDS_C7_SANDBOX_ENABLE
    local procedure IsSandboxEnvironment(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsSandbox());
    end;
#endif

    local procedure BuildUrl(
        RequestBuffer: Record "SI EDS Request Buffer" temporary): Text
    var
        Url: Text;
    begin
        Url :=
            RequestBuffer."Base URL";

        if RequestBuffer."Relative Path" <> '' then begin
            if Url.EndsWith('/') and
               RequestBuffer."Relative Path".StartsWith('/')
            then
                Url :=
                    Url.Substring(
                        1,
                        StrLen(Url) - 1);

            Url +=
                RequestBuffer."Relative Path";
        end;

        if RequestBuffer."Query String" <> '' then
            Url +=
                '?' +
                RequestBuffer."Query String";

        exit(Url);
    end;

    local procedure ClassifyResponse(
        HttpResponse: HttpResponseMessage;
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        StatusCode: Integer;
    begin
        StatusCode :=
            HttpResponse.HttpStatusCode();

        if (StatusCode >= 200) and
           (StatusCode < 300)
        then begin
            ResponseBuffer."Result Type" :=
                ResponseBuffer."Result Type"::Success;

            exit;
        end;

        case StatusCode of
            401,
            403:
                ResponseBuffer."Result Type" :=
                    ResponseBuffer."Result Type"::"Authentication Failure";

            429:
                ResponseBuffer."Result Type" :=
                    ResponseBuffer."Result Type"::"Rate Limited";

            else
                ResponseBuffer."Result Type" :=
                    ResponseBuffer."Result Type"::"Technical Failure";
        end;

        ResponseBuffer."Error Code" :=
            CopyStr(
                StrSubstNo(
                    'HTTP_%1',
                    StatusCode),
                1,
                MaxStrLen(
                    ResponseBuffer."Error Code"));

        ResponseBuffer."Error Message" :=
            CopyStr(
                StrSubstNo(
                    'Зовнішній сервіс повернув HTTP статус %1.',
                    StatusCode),
                1,
                MaxStrLen(
                    ResponseBuffer."Error Message"));
    end;

    local procedure SetTransportFailure(
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        StartedAt: DateTime;
        FinishedAt: DateTime;
        ErrorCode: Text;
        ErrorMessage: Text)
    begin
        ResponseBuffer."Duration (ms)" :=
            GetDurationMs(
                StartedAt,
                FinishedAt);

        ResponseBuffer."Result Type" :=
            ResponseBuffer."Result Type"::"Technical Failure";

        ResponseBuffer."Error Code" :=
            CopyStr(
                ErrorCode,
                1,
                MaxStrLen(
                    ResponseBuffer."Error Code"));

        ResponseBuffer."Error Message" :=
            CopyStr(
                ErrorMessage,
                1,
                MaxStrLen(
                    ResponseBuffer."Error Message"));
    end;

    local procedure GetDurationMs(
        StartedAt: DateTime;
        FinishedAt: DateTime): Integer
    var
        DurationValue: Duration;
    begin
        DurationValue :=
            FinishedAt -
            StartedAt;

        exit(
            Round(
                DurationValue / 1,
                1));
    end;
}