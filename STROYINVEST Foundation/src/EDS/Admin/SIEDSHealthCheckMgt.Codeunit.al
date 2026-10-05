codeunit 50476 "SI EDS Health Check Mgt."
{
    procedure Run(var Buffer: Record "SI EDS Health Check Buffer" temporary)
    begin
        Buffer.Reset();
        Buffer.DeleteAll();
        CheckServices(Buffer);
        CheckOperations(Buffer);
        CheckProviders(Buffer);
        CheckRoutes(Buffer);
        CheckParameters(Buffer);
        CheckRateLimits(Buffer);
        CheckAsyncWorker(Buffer);
    end;

    procedure GetCounts(var ErrorCount: Integer; var WarningCount: Integer; var OkCount: Integer)
    var
        Buffer: Record "SI EDS Health Check Buffer" temporary;
    begin
        Run(Buffer);
        Buffer.SetRange(Severity, Buffer.Severity::Error); ErrorCount := Buffer.Count();
        Buffer.SetRange(Severity, Buffer.Severity::Warning); WarningCount := Buffer.Count();
        Buffer.SetRange(Severity, Buffer.Severity::OK); OkCount := Buffer.Count();
    end;

    local procedure CheckServices(var Buffer: Record "SI EDS Health Check Buffer" temporary)
    var
        Service: Record "SI EDS Service";
    begin
        if not Service.FindSet() then begin
            Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Service, '', 'Наявність сервісів', 'Не налаштовано жодного сервісу EDS.');
            exit;
        end;
        repeat
            if Service.Enabled then
                Add(Buffer, Buffer.Severity::OK, Buffer."Check Area"::Service, Service.Code, 'Стан сервісу', 'Сервіс увімкнено.')
            else
                Add(Buffer, Buffer.Severity::Warning, Buffer."Check Area"::Service, Service.Code, 'Стан сервісу', 'Сервіс вимкнено.');
        until Service.Next() = 0;
    end;

    local procedure CheckOperations(var Buffer: Record "SI EDS Health Check Buffer" temporary)
    var
        Operation: Record "SI EDS Operation";
        Service: Record "SI EDS Service";
        Route: Record "SI EDS Provider Route";
        Group: Record "SI EDS Operation Group";
        ObjectCode: Text[150];
    begin
        if not Operation.FindSet() then begin
            Add(Buffer, Buffer.Severity::Warning, Buffer."Check Area"::Operation, '', 'Наявність операцій', 'Не налаштовано жодної операції EDS.');
            exit;
        end;
        repeat
            ObjectCode := Operation."Service Code" + ' / ' + Operation.Code;
            if not Service.Get(Operation."Service Code") then
                Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Operation, ObjectCode, 'Сервіс операції', 'Сервіс не існує.')
            else begin
                if (Operation."Operation Group Code" <> '') and not Group.Get(Operation."Service Code", Operation."Operation Group Code") then
                    Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Operation, ObjectCode, 'Група операцій', 'Вказана група операцій не існує.');

                if Operation.Enabled and Service.Enabled then begin
                    Route.Reset();
                    Route.SetRange("Service Code", Operation."Service Code");
                    Route.SetRange("Operation Code", Operation.Code);
                    Route.SetRange(Enabled, true);
                    if Route.IsEmpty() then
                        Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Operation, ObjectCode, 'Активний маршрут', 'Для активної операції немає увімкненого маршруту.')
                    else
                        Add(Buffer, Buffer.Severity::OK, Buffer."Check Area"::Operation, ObjectCode, 'Активний маршрут', 'Маршрут налаштовано.');
                end else
                    Add(Buffer, Buffer.Severity::Warning, Buffer."Check Area"::Operation, ObjectCode, 'Стан операції', 'Операція або її сервіс вимкнені.');
            end;
        until Operation.Next() = 0;
    end;

    local procedure CheckProviders(var Buffer: Record "SI EDS Health Check Buffer" temporary)
    var
        Provider: Record "SI EDS Provider";
        Endpoint: Record "SI EDS Endpoint";
    begin
        if not Provider.FindSet() then begin
            Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Provider, '', 'Наявність провайдерів', 'Не налаштовано жодного провайдера EDS.');
            exit;
        end;
        repeat
            if Provider.Enabled then begin
                Endpoint.Reset();
                Endpoint.SetRange("Provider Code", Provider.Code);
                Endpoint.SetRange(Enabled, true);
                if Endpoint.IsEmpty() then
                    Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Endpoint, Provider.Code, 'Активна точка підключення', 'Для активного провайдера немає увімкненої точки підключення.')
                else begin
                    Endpoint.SetRange("Base URL", '');
                    if not Endpoint.IsEmpty() then
                        Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Endpoint, Provider.Code, 'Base URL', 'Є активна точка підключення без Base URL.')
                    else
                        Add(Buffer, Buffer.Severity::OK, Buffer."Check Area"::Endpoint, Provider.Code, 'Активна точка підключення', 'Точку підключення налаштовано.');
                end;
            end else
                Add(Buffer, Buffer.Severity::Warning, Buffer."Check Area"::Provider, Provider.Code, 'Стан провайдера', 'Провайдер вимкнено.');
        until Provider.Next() = 0;
    end;

    local procedure CheckRoutes(var Buffer: Record "SI EDS Health Check Buffer" temporary)
    var
        Route: Record "SI EDS Provider Route";
        Service: Record "SI EDS Service";
        Operation: Record "SI EDS Operation";
        Provider: Record "SI EDS Provider";
        ObjectCode: Text[150];
    begin
        if not Route.FindSet() then
            exit;
        repeat
            ObjectCode := Route."Service Code" + ' / ' + Route."Operation Code" + ' / ' + Route."Provider Code";
            if not Service.Get(Route."Service Code") then
                Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Route, ObjectCode, 'Сервіс маршруту', 'Сервіс не існує.')
            else if not Operation.Get(Route."Service Code", Route."Operation Code") then
                Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Route, ObjectCode, 'Операція маршруту', 'Операція не існує.')
            else if not Provider.Get(Route."Provider Code") then
                Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Route, ObjectCode, 'Провайдер маршруту', 'Провайдер не існує.')
            else if Route.Enabled and not Provider.Enabled then
                Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Route, ObjectCode, 'Стан провайдера', 'Маршрут увімкнено, але провайдер вимкнений.')
            else if Route.Enabled then
                Add(Buffer, Buffer.Severity::OK, Buffer."Check Area"::Route, ObjectCode, 'Цілісність маршруту', 'Маршрут коректний.')
            else
                Add(Buffer, Buffer.Severity::Warning, Buffer."Check Area"::Route, ObjectCode, 'Стан маршруту', 'Маршрут вимкнено.');
        until Route.Next() = 0;
    end;

    local procedure CheckParameters(var Buffer: Record "SI EDS Health Check Buffer" temporary)
    var
        Parameter: Record "SI EDS Parameter";
        Provider: Record "SI EDS Provider";
        Credential: Record "SI EDS Credential";
        CredentialMgt: Codeunit "SI EDS Credential Mgt.";
        ObjectCode: Text[150];
    begin
        if not Parameter.FindSet() then
            exit;
        repeat
            ObjectCode := Parameter."Service Code" + ' / ' + Parameter."Operation Code" + ' / ' + Parameter."Provider Code" + ' / ' + Parameter.Code;
            if not Parameter.Enabled then
                Add(Buffer, Buffer.Severity::Warning, Buffer."Check Area"::Parameter, ObjectCode, 'Стан параметра', 'Параметр вимкнено.')
            else begin
                if Parameter."External Name" = '' then
                    Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Parameter, ObjectCode, 'Зовнішнє ім''я', 'Не задано зовнішнє ім''я параметра.');

                case Parameter.Source of
                    Parameter.Source::Runtime:
                        if Parameter."Runtime Key" = '' then
                            Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Parameter, ObjectCode, 'Runtime key', 'Для Runtime-параметра не задано Runtime key.');
                    Parameter.Source::Credential:
                        begin
                            if Parameter."Credential Code" = '' then
                                Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Credential, ObjectCode, 'Облікові дані', 'Для Credential-параметра не задано код облікових даних.')
                            else if not Credential.Get(Parameter."Provider Code", Parameter."Credential Code") then
                                Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Credential, ObjectCode, 'Облікові дані', 'Вказані облікові дані не існують.')
                            else if not Credential.Enabled then
                                Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Credential, ObjectCode, 'Облікові дані', 'Вказані облікові дані вимкнені.')
                            else if not CredentialMgt.HasSecret(Parameter."Provider Code", Parameter."Credential Code") then
                                Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Credential, ObjectCode, 'Secret', 'Для облікових даних не встановлено secret.')
                            else
                                Add(Buffer, Buffer.Severity::OK, Buffer."Check Area"::Credential, ObjectCode, 'Secret', 'Облікові дані та secret налаштовані.');
                        end;
                    Parameter.Source::Fixed:
                        if Parameter.Required and (Parameter.Value = '') then
                            Add(Buffer, Buffer.Severity::Warning, Buffer."Check Area"::Parameter, ObjectCode, 'Фіксоване значення', 'Обов''язковий Fixed-параметр має порожнє значення.');
                end;

                if not Provider.Get(Parameter."Provider Code") then
                    Add(Buffer, Buffer.Severity::Error, Buffer."Check Area"::Parameter, ObjectCode, 'Провайдер параметра', 'Провайдер не існує.');
            end;
        until Parameter.Next() = 0;
    end;

    local procedure CheckRateLimits(var Buffer: Record "SI EDS Health Check Buffer" temporary)
    var
        Provider: Record "SI EDS Provider";
        Limit: Record "SI EDS Provider Rate Limit";
    begin
        Limit.SetRange("Provider Code", 'OTHER-PROVIDER');
        Limit.SetRange(Enabled, true);
        if Limit.IsEmpty() then
            Add(Buffer, Buffer.Severity::Warning, Buffer."Check Area"::RateLimit, 'OTHER-PROVIDER', 'Fallback policy', 'Не налаштовано активний fallback rate-limit profile.')
        else
            Add(Buffer, Buffer.Severity::OK, Buffer."Check Area"::RateLimit, 'OTHER-PROVIDER', 'Fallback policy', 'Fallback rate-limit profile налаштовано.');

        Provider.SetRange(Enabled, true);
        if Provider.FindSet() then
            repeat
                Limit.Reset();
                Limit.SetRange("Provider Code", Provider.Code);
                Limit.SetRange(Enabled, true);
                if Limit.IsEmpty() then
                    Add(Buffer, Buffer.Severity::OK, Buffer."Check Area"::RateLimit, Provider.Code, 'Rate limit policy', 'Власних правил немає; застосовується fallback OTHER-PROVIDER.')
                else
                    Add(Buffer, Buffer.Severity::OK, Buffer."Check Area"::RateLimit, Provider.Code, 'Rate limit policy', 'Налаштовано provider-specific правила.');
            until Provider.Next() = 0;
    end;

    local procedure CheckAsyncWorker(var Buffer: Record "SI EDS Health Check Buffer" temporary)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"SI EDS Async Worker");
        if JobQueueEntry.IsEmpty() then
            Add(Buffer, Buffer.Severity::Warning, Buffer."Check Area"::AsyncWorker, '50467', 'Job Queue', 'Для SI EDS Async Worker не знайдено Job Queue Entry.')
        else
            Add(Buffer, Buffer.Severity::OK, Buffer."Check Area"::AsyncWorker, '50467', 'Job Queue', 'Job Queue Entry для Async Worker існує.');
    end;

    local procedure Add(var Buffer: Record "SI EDS Health Check Buffer" temporary; Severity: Option OK,Warning,Error; CheckArea: Option Service,Operation,Provider,Endpoint,Credential,Route,Parameter,RateLimit,AsyncWorker; ObjectCode: Text; CheckText: Text; ResultText: Text)
    begin
        Buffer.Init();
        Buffer."Entry No." := Buffer.Count() + 1;
        Buffer.Severity := Severity;
        Buffer."Check Area" := CheckArea;
        Buffer."Object Code" := CopyStr(ObjectCode, 1, MaxStrLen(Buffer."Object Code"));
        Buffer.Check := CopyStr(CheckText, 1, MaxStrLen(Buffer.Check));
        Buffer.Result := CopyStr(ResultText, 1, MaxStrLen(Buffer.Result));
        Buffer.Insert();
    end;
}
