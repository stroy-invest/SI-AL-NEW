codeunit 50477 "SI EDS Setup Wizard Mgt."
{
    procedure FinishSetup(
        CreateService: Boolean; ServiceCode: Code[50]; ServiceDescription: Text[250];
        CreateProvider: Boolean; ProviderCode: Code[50]; ProviderDescription: Text[250];
        CreateEndpoint: Boolean; EndpointCode: Code[50]; EndpointDescription: Text[250]; BaseUrl: Text[250]; EndpointPriority: Integer;
        CreateOperation: Boolean; OperationCode: Code[50]; OperationDescription: Text[250]; HttpMethod: Enum "SI EDS HTTP Method"; RelativePath: Text[250];
        RoutePriority: Integer;
        CreateOperationGroup: Boolean; OperationGroupCode: Code[50]; OperationGroupDescription: Text[250]; OperationGroupPathPrefix: Text[250]; OperationGroupSequence: Integer; OperationGroupEnabled: Boolean;
        ConfigureCredential: Boolean; CreateCredential: Boolean; CredentialCode: Code[50]; CredentialDescription: Text[250]; CredentialType: Enum "SI EDS Credential Type"; CredentialSecret: Text; CredentialSecretDefined: Boolean;
        ConfigureParameter: Boolean; ParameterCode: Code[50]; ParameterSequence: Integer; ParameterExternalName: Text[100]; ParameterLocation: Enum "SI EDS Param. Location"; ParameterSource: Enum "SI EDS Param. Source"; ParameterRuntimeKey: Code[50]; ParameterFixedValue: Text[250]; ParameterCredentialCode: Code[50]; ParameterValuePrefix: Text[50]; ParameterRequired: Boolean;
        ConfigureRateLimit: Boolean; RateLimitSequence: Integer; RateLimitWindowSeconds: Integer; RateLimitMaxRequests: Integer; RateLimitSafetyMargin: Decimal; RateLimitDescription: Text[100])
    var
        Service: Record "SI EDS Service";
        Provider: Record "SI EDS Provider";
        Endpoint: Record "SI EDS Endpoint";
        Operation: Record "SI EDS Operation";
        OperationGroup: Record "SI EDS Operation Group";
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

        if CreateOperationGroup then begin
            if not CreateOperation then
                Error('Нову групу можна створити лише разом із новою операцією.');
            if OperationGroupCode = '' then
                Error('Код групи операцій є обов''язковим.');
            if OperationGroup.Get(ServiceCode, OperationGroupCode) then
                Error('Група операцій %1 уже існує.', OperationGroupCode);
            OperationGroup.Init();
            OperationGroup."Service Code" := ServiceCode;
            OperationGroup.Code := OperationGroupCode;
            OperationGroup.Description := OperationGroupDescription;
            OperationGroup."Path Prefix" := OperationGroupPathPrefix;
            OperationGroup.Sequence := OperationGroupSequence;
            OperationGroup.Enabled := OperationGroupEnabled;
            OperationGroup.Insert(true);
        end else
            if OperationGroupCode <> '' then
                OperationGroup.Get(ServiceCode, OperationGroupCode);

        if CreateOperation then begin
            Operation.Init();
            Operation."Service Code" := ServiceCode;
            Operation.Code := OperationCode;
            Operation.Description := OperationDescription;
            Operation."HTTP Method" := HttpMethod;
            Operation."Relative Path" := RelativePath;
            Operation.Validate("Operation Group Code", OperationGroupCode);
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

    procedure ValidateBatchDrafts(
        ServiceCode: Code[50]; ProviderCode: Code[50]; RoutePriority: Integer;
        LegacyOperationCode: Code[50]; LegacyOperationGroupCode: Code[50];
        var DraftGroups: Record "SI EDS Wiz Group Buffer" temporary;
        var DraftOperations: Record "SI EDS Wiz Operation Buffer" temporary)
    var
        Group: Record "SI EDS Operation Group";
        Operation: Record "SI EDS Operation";
    begin
        if DraftGroups.FindSet() then
            repeat
                if DraftGroups."Service Code" <> ServiceCode then
                    Error('Група %1 належить іншому сервісу.', DraftGroups.Code);
                if DraftGroups.Code = '' then
                    Error('У чернетці є група без коду.');
                if Group.Get(ServiceCode, DraftGroups.Code) then
                    Error('Група %1 вже існує. Не створюйте її повторно.', DraftGroups.Code);
            until DraftGroups.Next() = 0;

        if DraftOperations.FindSet() then
            repeat
                if DraftOperations."Service Code" <> ServiceCode then
                    Error('Операція %1 належить іншому сервісу.', DraftOperations.Code);
                if DraftOperations.Code = '' then
                    Error('У чернетці є операція без коду.');
                if DraftOperations.Code = LegacyOperationCode then begin
                    if DraftOperations."Operation Group Code" <> LegacyOperationGroupCode then
                        Error('Група операції %1 не збігається з основною операцією майстра.', DraftOperations.Code);
                end else begin
                    if Operation.Get(ServiceCode, DraftOperations.Code) then begin
                        if not DraftOperations.Existing then
                            Error('Операція %1 вже існує. Виберіть її як наявну.', DraftOperations.Code);
                        if DraftOperations."Operation Group Code" <> Operation."Operation Group Code" then
                            Error('Група наявної операції %1 не збігається з довідником.', DraftOperations.Code);
                    end else
                        if DraftOperations.Existing then
                            Error('Позначена як наявна операція %1 не існує.', DraftOperations.Code);
                    ValidateUniqueRoutePriority(ServiceCode, DraftOperations.Code, ProviderCode, RoutePriority);
                end;
                if DraftOperations."Operation Group Code" <> '' then
                    if not Group.Get(ServiceCode, DraftOperations."Operation Group Code") then
                        if not DraftGroups.Get(ServiceCode, DraftOperations."Operation Group Code") then
                            if DraftOperations."Operation Group Code" <> LegacyOperationGroupCode then
                                Error('Група %1 для операції %2 не існує в сервісі або чернетці.',
                                    DraftOperations."Operation Group Code", DraftOperations.Code);
            until DraftOperations.Next() = 0;
    end;

    procedure SaveBatchDrafts(
        ServiceCode: Code[50]; ProviderCode: Code[50]; RoutePriority: Integer;
        LegacyOperationCode: Code[50]; LegacyOperationGroupCode: Code[50];
        var DraftGroups: Record "SI EDS Wiz Group Buffer" temporary;
        var DraftOperations: Record "SI EDS Wiz Operation Buffer" temporary)
    var
        Group: Record "SI EDS Operation Group";
        Operation: Record "SI EDS Operation";
        Route: Record "SI EDS Provider Route";
    begin
        // Called after the legacy FinishSetup has created the service and the first operation.
        // The caller must not COMMIT between FinishSetup and this procedure.
        if DraftGroups.FindSet() then
            repeat
                if not Group.Get(ServiceCode, DraftGroups.Code) then begin
                    Group.Init();
                    Group."Service Code" := ServiceCode;
                    Group.Code := DraftGroups.Code;
                    Group.Description := DraftGroups.Description;
                    Group."Path Prefix" := DraftGroups."Path Prefix";
                    Group.Sequence := DraftGroups.Sequence;
                    Group.Enabled := DraftGroups.Enabled;
                    Group.Insert(true);
                end else
                    if DraftGroups.Code <> LegacyOperationGroupCode then
                        Error('Група %1 з''явилася під час завершення майстра.', DraftGroups.Code);
            until DraftGroups.Next() = 0;

        if DraftOperations.FindSet() then
            repeat
                if DraftOperations.Code <> LegacyOperationCode then begin
                    if not Operation.Get(ServiceCode, DraftOperations.Code) then begin
                        Operation.Init();
                        Operation."Service Code" := ServiceCode;
                        Operation.Code := DraftOperations.Code;
                        Operation.Description := DraftOperations.Description;
                        Operation."HTTP Method" := DraftOperations."HTTP Method";
                        Operation."Relative Path" := DraftOperations."Relative Path";
                        Operation.Validate("Operation Group Code", DraftOperations."Operation Group Code");
                        Operation.Enabled := DraftOperations.Enabled;
                        Operation.Insert(true);
                    end;
                    if not Route.Get(ServiceCode, DraftOperations.Code, RoutePriority, ProviderCode) then begin
                        Route.Init();
                        Route."Service Code" := ServiceCode;
                        Route."Operation Code" := DraftOperations.Code;
                        Route.Priority := RoutePriority;
                        Route."Provider Code" := ProviderCode;
                        Route.Enabled := true;
                        Route.Insert(true);
                    end;
                end;
            until DraftOperations.Next() = 0;
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
                if not (ParameterLocation in [ParameterLocation::Header, ParameterLocation::Query]) then
                    Error('Credential-параметр дозволено лише в HTTP Header або Query.');
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
