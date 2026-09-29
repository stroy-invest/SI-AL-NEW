codeunit 50431 "SI EDS Orchestrator"
{
    procedure Execute(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
    begin
        Execute(
            ServiceCode,
            OperationCode,
            RuntimeParam,
            ResponseBuffer);
    end;

    procedure Execute(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        var RuntimeParam: Record "SI EDS Runtime Param" temporary;
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    begin
        Execute(
            ServiceCode,
            OperationCode,
            RuntimeParam,
            '',
            '',
            ResponseBuffer);
    end;

    procedure Execute(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        var RuntimeParam: Record "SI EDS Runtime Param" temporary;
        RequestBody: Text;
        ContentType: Text[100];
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        EDSService: Record "SI EDS Service";
        EDSOperation: Record "SI EDS Operation";
        ProviderRoute: Record "SI EDS Provider Route";
        EDSProvider: Record "SI EDS Provider";
        EDSEndpoint: Record "SI EDS Endpoint";
        RequestBuffer: Record "SI EDS Request Buffer" temporary;
        ProviderContext: Codeunit "SI EDS Provider Context";
        ProviderOverrideCode: Code[50];
    begin
        GetService(
            ServiceCode,
            EDSService);

        GetOperation(
            ServiceCode,
            OperationCode,
            EDSOperation);

        ProviderRoute.SetRange(
            "Service Code",
            ServiceCode);

        ProviderRoute.SetRange(
            "Operation Code",
            OperationCode);

        ProviderRoute.SetRange(
            Enabled,
            true);

        if ProviderContext.TryGetProviderOverride(ServiceCode, ProviderOverrideCode) then
            ProviderRoute.SetRange("Provider Code", ProviderOverrideCode);

        ProviderRoute.SetCurrentKey(
            "Service Code",
            "Operation Code",
            Priority,
            "Provider Code");

        if not ProviderRoute.FindSet() then
            Error(
                'Для операції %1 / %2 не налаштовано жодного активного маршруту провайдера.',
                ServiceCode,
                OperationCode);

        repeat
            if EDSProvider.Get(
                ProviderRoute."Provider Code")
            and EDSProvider.Enabled
            then begin
                EDSEndpoint.Reset();

                EDSEndpoint.SetRange(
                    "Provider Code",
                    ProviderRoute."Provider Code");

                EDSEndpoint.SetRange(
                    Enabled,
                    true);

                EDSEndpoint.SetCurrentKey(
                    "Provider Code",
                    Priority);

                if EDSEndpoint.FindSet() then
                    repeat
                        BuildRequest(
                            EDSOperation,
                            EDSProvider,
                            EDSEndpoint,
                            RuntimeParam,
                            RequestBody,
                            ContentType,
                            RequestBuffer);

                        ExecuteRequest(
                            ServiceCode,
                            OperationCode,
                            RequestBuffer,
                            ResponseBuffer);

                        if ResponseBuffer."Result Type" =
                           ResponseBuffer."Result Type"::Success
                        then
                            exit;

                        if not ShouldTryNext(
                            ResponseBuffer)
                        then
                            exit;

                    until EDSEndpoint.Next() = 0;
            end;

        until ProviderRoute.Next() = 0;
    end;

    procedure ExecuteProviderBody(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        ProviderCode: Code[50];
        var RuntimeParam: Record "SI EDS Runtime Param" temporary;
        RequestBody: Text;
        ContentType: Text[100];
        AcceptType: Text[100];
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        EDSService: Record "SI EDS Service";
        EDSOperation: Record "SI EDS Operation";
        ProviderRoute: Record "SI EDS Provider Route";
        EDSProvider: Record "SI EDS Provider";
        EDSEndpoint: Record "SI EDS Endpoint";
        RequestBuffer: Record "SI EDS Request Buffer" temporary;
    begin
        GetService(
            ServiceCode,
            EDSService);

        GetOperation(
            ServiceCode,
            OperationCode,
            EDSOperation);

        if not EDSProvider.Get(ProviderCode) then
            Error(
                'Провайдер EDS %1 не налаштований.',
                ProviderCode);

        if not EDSProvider.Enabled then
            Error(
                'Провайдер EDS %1 вимкнений.',
                ProviderCode);

        ProviderRoute.SetRange(
            "Service Code",
            ServiceCode);

        ProviderRoute.SetRange(
            "Operation Code",
            OperationCode);

        ProviderRoute.SetRange(
            "Provider Code",
            ProviderCode);

        ProviderRoute.SetRange(
            Enabled,
            true);

        if ProviderRoute.IsEmpty() then
            Error(
                'Для операції %1 / %2 не налаштовано активний маршрут через провайдера %3.',
                ServiceCode,
                OperationCode,
                ProviderCode);

        EDSEndpoint.SetRange(
            "Provider Code",
            ProviderCode);

        EDSEndpoint.SetRange(
            Enabled,
            true);

        EDSEndpoint.SetCurrentKey(
            "Provider Code",
            Priority);

        if not EDSEndpoint.FindSet() then
            Error(
                'Для провайдера EDS %1 не налаштовано активної точки підключення.',
                ProviderCode);

        repeat
            BuildRequest(
                EDSOperation,
                EDSProvider,
                EDSEndpoint,
                RuntimeParam,
                RequestBody,
                ContentType,
                RequestBuffer);

            ExecuteProviderRequest(
                ServiceCode,
                OperationCode,
                RequestBuffer,
                AcceptType,
                ResponseBuffer);

            if ResponseBuffer."Result Type" =
            ResponseBuffer."Result Type"::Success
            then
                exit;

            if not ShouldTryNext(
                ResponseBuffer)
            then
                exit;

        until EDSEndpoint.Next() = 0;
    end;

    procedure ExecuteProviderSecretBody(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        ProviderCode: Code[50];
        var RuntimeParam: Record "SI EDS Runtime Param" temporary;
        RequestBody: SecretText;
        ContentType: Text[100];
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    begin
        ExecuteProviderSecretBody(
            ServiceCode,
            OperationCode,
            ProviderCode,
            RuntimeParam,
            RequestBody,
            ContentType,
            '*/*',
            ResponseBuffer);
    end;

    procedure ExecuteProviderSecretBody(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        ProviderCode: Code[50];
        var RuntimeParam: Record "SI EDS Runtime Param" temporary;
        RequestBody: SecretText;
        ContentType: Text[100];
        AcceptType: Text[100];
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        EDSService: Record "SI EDS Service";
        EDSOperation: Record "SI EDS Operation";
        ProviderRoute: Record "SI EDS Provider Route";
        EDSProvider: Record "SI EDS Provider";
        EDSEndpoint: Record "SI EDS Endpoint";
        RequestBuffer: Record "SI EDS Request Buffer" temporary;
    begin
        GetService(
            ServiceCode,
            EDSService);

        GetOperation(
            ServiceCode,
            OperationCode,
            EDSOperation);

        if not EDSProvider.Get(
            ProviderCode)
        then
            Error(
                'Провайдер EDS %1 не налаштований.',
                ProviderCode);

        if not EDSProvider.Enabled then
            Error(
                'Провайдер EDS %1 вимкнений.',
                ProviderCode);

        ProviderRoute.SetRange(
            "Service Code",
            ServiceCode);

        ProviderRoute.SetRange(
            "Operation Code",
            OperationCode);

        ProviderRoute.SetRange(
            "Provider Code",
            ProviderCode);

        ProviderRoute.SetRange(
            Enabled,
            true);

        if ProviderRoute.IsEmpty() then
            Error(
                'Для операції %1 / %2 не налаштовано активний маршрут через провайдера %3.',
                ServiceCode,
                OperationCode,
                ProviderCode);

        EDSEndpoint.SetRange(
            "Provider Code",
            ProviderCode);

        EDSEndpoint.SetRange(
            Enabled,
            true);

        EDSEndpoint.SetCurrentKey(
            "Provider Code",
            Priority);

        if not EDSEndpoint.FindSet() then
            Error(
                'Для провайдера EDS %1 не налаштовано активної точки підключення.',
                ProviderCode);

        repeat
            BuildRequest(
                EDSOperation,
                EDSProvider,
                EDSEndpoint,
                RuntimeParam,
                '',
                ContentType,
                RequestBuffer);

            ExecuteSecretRequest(
                ServiceCode,
                OperationCode,
                RequestBuffer,
                RequestBody,
                AcceptType,
                ResponseBuffer);

            if ResponseBuffer."Result Type" =
               ResponseBuffer."Result Type"::Success
            then
                exit;

            if not ShouldTryNext(
                ResponseBuffer)
            then
                exit;

        until EDSEndpoint.Next() = 0;
    end;

    local procedure GetService(
        ServiceCode: Code[50];
        var EDSService: Record "SI EDS Service")
    begin
        if not EDSService.Get(
            ServiceCode)
        then
            Error(
                'Сервіс EDS %1 не налаштований.',
                ServiceCode);

        if not EDSService.Enabled then
            Error(
                'Сервіс EDS %1 вимкнений.',
                ServiceCode);
    end;

    local procedure GetOperation(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        var EDSOperation: Record "SI EDS Operation")
    begin
        if not EDSOperation.Get(
            ServiceCode,
            OperationCode)
        then
            Error(
                'Операція EDS %1 / %2 не налаштована.',
                ServiceCode,
                OperationCode);

        if not EDSOperation.Enabled then
            Error(
                'Операція EDS %1 / %2 вимкнена.',
                ServiceCode,
                OperationCode);
    end;

    local procedure BuildRequest(
        EDSOperation: Record "SI EDS Operation";
        EDSProvider: Record "SI EDS Provider";
        EDSEndpoint: Record "SI EDS Endpoint";
        var RuntimeParam: Record "SI EDS Runtime Param" temporary;
        RequestBody: Text;
        ContentType: Text[100];
        var RequestBuffer: Record "SI EDS Request Buffer" temporary)
    begin
        RequestBuffer.Reset();
        RequestBuffer.DeleteAll();

        RequestBuffer.Init();

        RequestBuffer."Entry No." :=
            1;

        RequestBuffer."Correlation ID" :=
            CreateGuid();

        RequestBuffer."Service Code" :=
            EDSOperation."Service Code";

        RequestBuffer."Operation Code" :=
            EDSOperation.Code;

        RequestBuffer."Provider Code" :=
            EDSProvider.Code;

        RequestBuffer."Endpoint Code" :=
            EDSEndpoint.Code;

        RequestBuffer."HTTP Method" :=
            EDSOperation."HTTP Method";

        RequestBuffer."Base URL" :=
            EDSEndpoint."Base URL";
        /*
                RequestBuffer."Relative Path" :=
                    EDSOperation."Relative Path";
        */
        RequestBuffer."Relative Path" :=
            ResolveOperationPath(
                EDSOperation);

        RequestBuffer."Query String" :=
            BuildQueryString(
                EDSOperation."Service Code",
                EDSOperation.Code,
                EDSProvider.Code,
                RuntimeParam);

        RequestBuffer."Content Type" :=
            ContentType;

        if (RequestBody <> '') or
           (EDSOperation."HTTP Method" =
            EDSOperation."HTTP Method"::POST)
        then
            RequestBuffer.SetBody(
                RequestBody);

        RequestBuffer.Insert();
    end;

    local procedure ResolveOperationPath(
        EDSOperation: Record "SI EDS Operation"): Text
    var
        OperationGroup: Record "SI EDS Operation Group";
    begin
        if EDSOperation."Operation Group Code" = '' then
            exit(
                NormalizePath(
                    EDSOperation."Relative Path"));

        if not OperationGroup.Get(
            EDSOperation."Service Code",
            EDSOperation."Operation Group Code")
        then
            Error(
                'Для операції EDS %1 / %2 не знайдено групу операцій %3.',
                EDSOperation."Service Code",
                EDSOperation.Code,
                EDSOperation."Operation Group Code");

        if not OperationGroup.Enabled then
            Error(
                'Група операцій EDS %1 / %2 вимкнена.',
                OperationGroup."Service Code",
                OperationGroup.Code);

        exit(
            JoinPath(
                OperationGroup."Path Prefix",
                EDSOperation."Relative Path"));
    end;

    local procedure JoinPath(
        LeftPath: Text;
        RightPath: Text): Text
    begin
        if LeftPath = '' then
            exit(
                NormalizePath(
                    RightPath));

        if RightPath = '' then
            exit(
                NormalizePath(
                    LeftPath));

        exit(
            NormalizePath(LeftPath) +
            NormalizePath(RightPath));
    end;

    local procedure NormalizePath(
        Value: Text): Text
    var
        Result: Text;
    begin
        Result :=
            Value.Trim();

        if Result = '' then
            exit('');

        if not Result.StartsWith('/') then
            Result :=
                '/' +
                Result;

        while Result.EndsWith('/') and
              (StrLen(Result) > 1)
        do
            Result :=
                CopyStr(
                    Result,
                    1,
                    StrLen(Result) - 1);

        exit(Result);
    end;

    local procedure BuildQueryString(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        ProviderCode: Code[50];
        var RuntimeParam: Record "SI EDS Runtime Param" temporary): Text
    var
        EDSParameter: Record "SI EDS Parameter";
        ParameterValue: Text;
        QueryString: Text;
    begin
        EDSParameter.SetRange(
            "Service Code",
            ServiceCode);

        EDSParameter.SetRange(
            "Operation Code",
            OperationCode);

        EDSParameter.SetRange(
            "Provider Code",
            ProviderCode);

        EDSParameter.SetRange(
            Enabled,
            true);

        EDSParameter.SetCurrentKey(
            "Service Code",
            "Operation Code",
            "Provider Code",
            Enabled,
            Sequence);

        if not EDSParameter.FindSet() then
            exit('');

        repeat
            if EDSParameter.Location <>
               EDSParameter.Location::Query
            then
                Error(
                    'EDS parameter %1 / %2 / %3 / %4 використовує location %5, який ще не підтримується runtime v0.1.',
                    ServiceCode,
                    OperationCode,
                    ProviderCode,
                    EDSParameter.Code,
                    Format(EDSParameter.Location));

            ParameterValue :=
                ResolveParameterValue(
                    EDSParameter,
                    RuntimeParam);

            if ShouldIncludeParameter(
                EDSParameter,
                ParameterValue)
            then
                AppendQueryParameter(
                    QueryString,
                    EDSParameter,
                    ParameterValue);

        until EDSParameter.Next() = 0;

        exit(
            QueryString);
    end;

    local procedure ResolveParameterValue(
        EDSParameter: Record "SI EDS Parameter";
        var RuntimeParam: Record "SI EDS Runtime Param" temporary): Text
    var
        ParameterValue: Text;
        Found: Boolean;
    begin
        case EDSParameter.Source of
            EDSParameter.Source::Fixed:
                exit(
                    EDSParameter.Value);

            EDSParameter.Source::Runtime:
                begin
                    Found :=
                        RuntimeParam.TryGetValue(
                            EDSParameter."Runtime Key",
                            ParameterValue);

                    if not Found then begin
                        if EDSParameter.Required then
                            Error(
                                'Для EDS параметра %1 не передано обов''язкове runtime-значення %2.',
                                EDSParameter.Code,
                                EDSParameter."Runtime Key");

                        exit('');
                    end;

                    exit(
                        ParameterValue);
                end;
        end;
    end;

    local procedure ShouldIncludeParameter(
        EDSParameter: Record "SI EDS Parameter";
        ParameterValue: Text): Boolean
    begin
        if EDSParameter.Format =
           EDSParameter.Format::"Name Only"
        then
            exit(true);

        if EDSParameter.Source =
           EDSParameter.Source::Runtime
        then
            exit(
                ParameterValue <> '');

        exit(true);
    end;

    local procedure AppendQueryParameter(
        var QueryString: Text;
        EDSParameter: Record "SI EDS Parameter";
        ParameterValue: Text)
    var
        QueryPart: Text;
    begin
        QueryPart :=
            EDSParameter.GetExternalName();

        if EDSParameter.Format =
           EDSParameter.Format::"Name Value"
        then
            QueryPart +=
                '=' +
                ParameterValue;

        if QueryString = '' then
            QueryString :=
                QueryPart
        else
            QueryString +=
                '&' +
                QueryPart;
    end;

    local procedure ExecuteProviderRequest(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        var RequestBuffer: Record "SI EDS Request Buffer" temporary;
        AcceptType: Text[100];
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        HTTPTransport: Codeunit "SI EDS HTTP Transport";
        StartedAt: DateTime;
        FinishedAt: DateTime;
    begin
        StartedAt :=
            CurrentDateTime;

        ResponseBuffer.Reset();
        ResponseBuffer.DeleteAll();

        HTTPTransport.Execute(
            RequestBuffer,
            AcceptType,
            ResponseBuffer);

        FinishedAt :=
            CurrentDateTime;

        WriteLog(
            ServiceCode,
            OperationCode,
            RequestBuffer,
            ResponseBuffer,
            StartedAt,
            FinishedAt);
    end;

    local procedure ExecuteRequest(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        var RequestBuffer: Record "SI EDS Request Buffer" temporary;
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        HTTPTransport: Codeunit "SI EDS HTTP Transport";
        StartedAt: DateTime;
        FinishedAt: DateTime;
    begin
        StartedAt :=
            CurrentDateTime;

        ResponseBuffer.Reset();
        ResponseBuffer.DeleteAll();

        HTTPTransport.Execute(
            RequestBuffer,
            ResponseBuffer);

        FinishedAt :=
            CurrentDateTime;

        WriteLog(
            ServiceCode,
            OperationCode,
            RequestBuffer,
            ResponseBuffer,
            StartedAt,
            FinishedAt);
    end;

    local procedure ExecuteSecretRequest(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        var RequestBuffer: Record "SI EDS Request Buffer" temporary;
        RequestBody: SecretText;
        AcceptType: Text[100];
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        HTTPTransport: Codeunit "SI EDS HTTP Transport";
        StartedAt: DateTime;
        FinishedAt: DateTime;
    begin
        StartedAt :=
            CurrentDateTime;

        ResponseBuffer.Reset();
        ResponseBuffer.DeleteAll();

        HTTPTransport.ExecuteSecretBody(
            RequestBuffer,
            RequestBody,
            AcceptType,
            ResponseBuffer);

        FinishedAt :=
            CurrentDateTime;

        WriteLog(
            ServiceCode,
            OperationCode,
            RequestBuffer,
            ResponseBuffer,
            StartedAt,
            FinishedAt);
    end;

    local procedure WriteLog(
        ServiceCode: Code[50];
        OperationCode: Code[50];
        var RequestBuffer: Record "SI EDS Request Buffer" temporary;
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        StartedAt: DateTime;
        FinishedAt: DateTime)
    var
        AuditLogger: Codeunit "SI EDS Audit Logger";
        Operation: Record "SI EDS Operation";
        ResponseBody: Text;
        LogResponseBody: Boolean;
    begin
        LogResponseBody :=
            Operation.Get(ServiceCode, OperationCode) and
            Operation."Log Response Body";

        if LogResponseBody then
            ResponseBody := ResponseBuffer.GetBodyText();

        AuditLogger.WriteIsolated(
            RequestBuffer."Correlation ID",
            ServiceCode,
            OperationCode,
            RequestBuffer."Provider Code",
            RequestBuffer."Endpoint Code",
            RequestBuffer."Request URL",
            StartedAt,
            FinishedAt,
            ResponseBuffer."Duration (ms)",
            ResponseBuffer."HTTP Status Code",
            ResponseBuffer."Result Type",
            ResponseBuffer."Error Code",
            ResponseBuffer."Error Message",
            LogResponseBody,
            ResponseBody);
    end;

    local procedure ShouldTryNext(
        ResponseBuffer: Record "SI EDS Response Buffer" temporary): Boolean
    var
        StatusCode: Integer;
    begin
        case ResponseBuffer."Result Type" of
            ResponseBuffer."Result Type"::"Rate Limited":
                exit(true);

            ResponseBuffer."Result Type"::"Invalid Response":
                exit(true);

            ResponseBuffer."Result Type"::"Technical Failure":
                begin
                    StatusCode :=
                        ResponseBuffer."HTTP Status Code";

                    // Transport-level failure:
                    // request не отримав HTTP status.
                    if StatusCode = 0 then
                        exit(true);

                    // Request timeout — transient.
                    if StatusCode = 408 then
                        exit(true);

                    // Server-side failures — transient/failover candidates.
                    if (StatusCode >= 500) and
                       (StatusCode <= 599)
                    then
                        exit(true);

                    // Інші 4xx, зокрема 400/404/405/415/422,
                    // є contract/client errors і не повинні маскуватися failover.
                    exit(false);
                end;

            else
                exit(false);
        end;
    end;
}