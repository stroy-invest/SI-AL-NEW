codeunit 50477 "SI EDS Setup Wizard Mgt."
{
    procedure FinishSetup(
        CreateService: Boolean; ServiceCode: Code[50]; ServiceDescription: Text[250];
        CreateProvider: Boolean; ProviderCode: Code[50]; ProviderDescription: Text[250];
        CreateEndpoint: Boolean; EndpointCode: Code[50]; EndpointDescription: Text[250]; BaseUrl: Text[250]; EndpointPriority: Integer;
        CreateOperation: Boolean; OperationCode: Code[50]; OperationDescription: Text[250]; HttpMethod: Enum "SI EDS HTTP Method"; RelativePath: Text[250];
        RoutePriority: Integer;
        ConfigureCredential: Boolean; CreateCredential: Boolean; CredentialCode: Code[50]; CredentialDescription: Text[250]; CredentialType: Enum "SI EDS Credential Type"; CredentialSecret: Text; CredentialSecretDefined: Boolean;
        ConfigureParameter: Boolean; ParameterCode: Code[50]; ParameterSequence: Integer; ParameterExternalName: Text[100]; ParameterLocation: Enum "SI EDS Param. Location"; ParameterSource: Enum "SI EDS Param. Source"; ParameterRuntimeKey: Code[50]; ParameterFixedValue: Text[250]; ParameterCredentialCode: Code[50]; ParameterValuePrefix: Text[50]; ParameterRequired: Boolean;
        ConfigureRateLimit: Boolean; RateLimitSequence: Integer; RateLimitWindowSeconds: Integer; RateLimitMaxRequests: Integer; RateLimitSafetyMargin: Decimal; RateLimitDescription: Text[100])
    var
        Service: Record "SI EDS Service";
        Provider: Record "SI EDS Provider";
        Endpoint: Record "SI EDS Endpoint";
        Operation: Record "SI EDS Operation";
        Route: Record "SI EDS Provider Route";
        Credential: Record "SI EDS Credential";
        Parameter: Record "SI EDS Parameter";
        RateLimit: Record "SI EDS Provider Rate Limit";
        CredentialMgt: Codeunit "SI EDS Credential Mgt.";
    begin
        ValidateInput(
            CreateService, ServiceCode,
            CreateProvider, ProviderCode,
            CreateEndpoint, EndpointCode, BaseUrl,
            CreateOperation, OperationCode);

        if CreateService then begin
            Service.Init();
            Service.Code := ServiceCode;
            Service.Description := ServiceDescription;
            Service.Enabled := true;
            Service.Insert(true);
        end else
            Service.Get(ServiceCode);

        if CreateProvider then begin
            Provider.Init();
            Provider.Code := ProviderCode;
            Provider.Description := ProviderDescription;
            Provider.Enabled := true;
            Provider.Insert(true);
        end else
            Provider.Get(ProviderCode);

        if CreateEndpoint then begin
            Endpoint.Init();
            Endpoint."Provider Code" := ProviderCode;
            Endpoint.Code := EndpointCode;
            Endpoint.Description := EndpointDescription;
            Endpoint."Base URL" := BaseUrl;
            Endpoint.Priority := EndpointPriority;
            Endpoint.Enabled := true;
            Endpoint.Insert(true);
        end else
            Endpoint.Get(ProviderCode, EndpointCode);

        if CreateOperation then begin
            Operation.Init();
            Operation."Service Code" := ServiceCode;
            Operation.Code := OperationCode;
            Operation.Description := OperationDescription;
            Operation."HTTP Method" := HttpMethod;
            Operation."Relative Path" := RelativePath;
            Operation.Enabled := true;
            Operation.Insert(true);
        end else
            Operation.Get(ServiceCode, OperationCode);

        ValidateUniqueRoutePriority(ServiceCode, OperationCode, ProviderCode, RoutePriority);

        if not Route.Get(ServiceCode, OperationCode, RoutePriority, ProviderCode) then begin
            Route.Init();
            Route."Service Code" := ServiceCode;
            Route."Operation Code" := OperationCode;
            Route.Priority := RoutePriority;
            Route."Provider Code" := ProviderCode;
            Route.Enabled := true;
            Route.Insert(true);
        end;
        if ConfigureCredential then begin
            if CreateCredential then begin
                Credential.Init();
                Credential."Provider Code" := ProviderCode;
                Credential.Code := CredentialCode;
                Credential.Description := CredentialDescription;
                Credential."Credential Type" := CredentialType;
                Credential.Enabled := true;
                Credential.Insert(true);
            end else
                Credential.Get(ProviderCode, CredentialCode);

            if CredentialSecretDefined then begin
                CredentialMgt.SetSecretText(ProviderCode, CredentialCode, CredentialSecret);
                Credential."Last Changed At" := CurrentDateTime;
                Credential."Last Changed By" := CopyStr(UserId(), 1, MaxStrLen(Credential."Last Changed By"));
                Credential.Modify(false);
            end;
        end;

        if ConfigureParameter then begin
            if Parameter.Get(ServiceCode, OperationCode, ProviderCode, ParameterCode) then
                Error('Параметр %1 уже наявний для %2 / %3 / %4.', ParameterCode, ServiceCode, OperationCode, ProviderCode);
            Parameter.Init();
            Parameter."Service Code" := ServiceCode;
            Parameter."Operation Code" := OperationCode;
            Parameter."Provider Code" := ProviderCode;
            Parameter.Code := ParameterCode;
            Parameter.Sequence := ParameterSequence;
            Parameter."External Name" := ParameterExternalName;
            Parameter.Location := ParameterLocation;
            Parameter.Validate(Source, ParameterSource);
            Parameter."Runtime Key" := ParameterRuntimeKey;
            Parameter.Value := ParameterFixedValue;
            Parameter."Credential Code" := ParameterCredentialCode;
            Parameter."Value Prefix" := ParameterValuePrefix;
            Parameter.Required := ParameterRequired;
            Parameter.Validate(Enabled, true);
            Parameter.Insert(true);
        end;

        if ConfigureRateLimit then begin
            if RateLimit.Get(ProviderCode, RateLimitSequence) then
                Error('Ліміт запитів із порядком %1 уже наявний для провайдера %2.', RateLimitSequence, ProviderCode);
            RateLimit.Init();
            RateLimit."Provider Code" := ProviderCode;
            RateLimit.Sequence := RateLimitSequence;
            RateLimit."Window Seconds" := RateLimitWindowSeconds;
            RateLimit."Max Requests" := RateLimitMaxRequests;
            RateLimit."Safety Margin %" := RateLimitSafetyMargin;
            RateLimit.Description := RateLimitDescription;
            RateLimit.Enabled := true;
            RateLimit.Insert(true);
        end;
    end;

    procedure ValidateExtendedInput(
        ProviderCode: Code[50]; ConfigureCredential: Boolean; CreateCredential: Boolean; CredentialCode: Code[50]; CredentialSecretDefined: Boolean;
        ServiceCode: Code[50]; OperationCode: Code[50]; ConfigureParameter: Boolean; ParameterCode: Code[50]; ParameterExternalName: Text[100]; ParameterLocation: Enum "SI EDS Param. Location"; ParameterSource: Enum "SI EDS Param. Source"; ParameterRuntimeKey: Code[50]; ParameterCredentialCode: Code[50];
        ConfigureRateLimit: Boolean; RateLimitSequence: Integer; RateLimitWindowSeconds: Integer; RateLimitMaxRequests: Integer; RateLimitSafetyMargin: Decimal)
    var
        Credential: Record "SI EDS Credential";
        Parameter: Record "SI EDS Parameter";
        RateLimit: Record "SI EDS Provider Rate Limit";
    begin
        if ConfigureCredential then begin
            if CredentialCode = '' then
                Error('Не вказано код облікових даних.');
            if CreateCredential then begin
                if Credential.Get(ProviderCode, CredentialCode) then
                    Error('Облікові дані %1 / %2 уже наявні. Виберіть наявні.', ProviderCode, CredentialCode);
                if not CredentialSecretDefined then
                    Error('Для нових облікових даних необхідно встановити секрет.');
            end else
                if not Credential.Get(ProviderCode, CredentialCode) then
                    Error('Облікові дані %1 / %2 не знайдено.', ProviderCode, CredentialCode);
        end;

        if ConfigureParameter then begin
            if ParameterCode = '' then Error('Не вказано код параметра.');
            if ParameterExternalName = '' then Error('Не вказано зовнішнє ім''я параметра.');
            if (ParameterSource = ParameterSource::Runtime) and (ParameterRuntimeKey = '') then
                Error('Для runtime-параметра необхідно вказати Runtime key.');
            if ParameterSource = ParameterSource::Credential then begin
                if ParameterLocation <> ParameterLocation::Header then
                    Error('Credential-параметр дозволено використовувати лише в HTTP Header.');
                if ParameterCredentialCode = '' then
                    Error('Для credential-параметра необхідно вказати облікові дані.');
                if ConfigureCredential and (ParameterCredentialCode = CredentialCode) then begin end
                else if not Credential.Get(ProviderCode, ParameterCredentialCode) then
                    Error('Облікові дані %1 / %2 для параметра не знайдено.', ProviderCode, ParameterCredentialCode);
            end;
            if (ParameterLocation = ParameterLocation::Path) and (ParameterSource <> ParameterSource::Runtime) then
                Error('Path-параметр повинен мати джерело Runtime.');
            if Parameter.Get(ServiceCode, OperationCode, ProviderCode, ParameterCode) then
                Error('Параметр %1 уже наявний для вибраної операції та провайдера.', ParameterCode);
        end;

        if ConfigureRateLimit then begin
            if RateLimitSequence < 1 then Error('Порядок ліміту запитів має бути більшим за нуль.');
            if RateLimitWindowSeconds < 1 then Error('Вікно ліміту запитів має бути більшим за нуль.');
            if RateLimitMaxRequests < 1 then Error('Максимальна кількість запитів має бути більшою за нуль.');
            if (RateLimitSafetyMargin < 1) or (RateLimitSafetyMargin > 100) then Error('Безпечне використання має бути від 1 до 100 %.');
            if RateLimit.Get(ProviderCode, RateLimitSequence) then
                Error('Ліміт запитів із порядком %1 уже наявний для провайдера %2.', RateLimitSequence, ProviderCode);
        end;
    end;

    procedure ValidateUniqueRoutePriority(ServiceCode: Code[50]; OperationCode: Code[50]; ProviderCode: Code[50]; RoutePriority: Integer)
    var
        Route: Record "SI EDS Provider Route";
    begin
        Route.SetRange("Service Code", ServiceCode);
        Route.SetRange("Operation Code", OperationCode);
        Route.SetRange(Priority, RoutePriority);
        Route.SetRange(Enabled, true);
        Route.SetFilter("Provider Code", '<>%1', ProviderCode);
        if Route.FindFirst() then
            Error(
                'Пріоритет %1 уже використовується активним провайдером %2 для операції %3 / %4. Для кожного активного маршруту задайте унікальний пріоритет.',
                RoutePriority, Route."Provider Code", ServiceCode, OperationCode);
    end;

    local procedure ValidateInput(
        CreateService: Boolean; ServiceCode: Code[50];
        CreateProvider: Boolean; ProviderCode: Code[50];
        CreateEndpoint: Boolean; EndpointCode: Code[50]; BaseUrl: Text[250];
        CreateOperation: Boolean; OperationCode: Code[50])
    var
        Service: Record "SI EDS Service";
        Provider: Record "SI EDS Provider";
        Endpoint: Record "SI EDS Endpoint";
        Operation: Record "SI EDS Operation";
    begin
        if ServiceCode = '' then
            Error('Не вказано сервіс EDS.');
        if ProviderCode = '' then
            Error('Не вказано провайдера EDS.');
        if EndpointCode = '' then
            Error('Не вказано точку підключення EDS.');
        if OperationCode = '' then
            Error('Не вказано операцію EDS.');

        if CreateService then begin
            if Service.Get(ServiceCode) then
                Error('Сервіс %1 уже наявний. Виберіть «Використати наявний».', ServiceCode);
        end else
            if not Service.Get(ServiceCode) then
                Error('Сервіс %1 не знайдено.', ServiceCode);

        if CreateProvider then begin
            if Provider.Get(ProviderCode) then
                Error('Провайдер %1 уже наявний. Виберіть «Використати наявний».', ProviderCode);
        end else
            if not Provider.Get(ProviderCode) then
                Error('Провайдер %1 не знайдено.', ProviderCode);

        if CreateEndpoint then begin
            if BaseUrl = '' then
                Error('Для нової точки підключення не вказано базову URL-адресу.');
            if Endpoint.Get(ProviderCode, EndpointCode) then
                Error('Точка підключення %1 / %2 уже наявна. Виберіть «Використати наявну».', ProviderCode, EndpointCode);
        end else
            if not Endpoint.Get(ProviderCode, EndpointCode) then
                Error('Точку підключення %1 / %2 не знайдено.', ProviderCode, EndpointCode);

        if CreateOperation then begin
            if Operation.Get(ServiceCode, OperationCode) then
                Error('Операція %1 / %2 уже наявна. Виберіть «Використати наявну».', ServiceCode, OperationCode);
        end else
            if not Operation.Get(ServiceCode, OperationCode) then
                Error('Операцію %1 / %2 не знайдено.', ServiceCode, OperationCode);
    end;
}
