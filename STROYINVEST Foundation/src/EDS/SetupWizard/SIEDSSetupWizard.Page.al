page 50484 "SI EDS Setup Wizard"
{
    PageType = NavigatePage;
    Caption = 'Майстер налаштування EDS';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(WelcomeStep)
            {
                Caption = 'Майстер налаштування EDS';
                Visible = CurrentStep = 1;

                field(WelcomeText; WelcomeText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                }
            }
            group(ServiceStep)
            {
                Caption = '1. Сервіс';
                Visible = CurrentStep = 2;

                field(CreateService; CreateService)
                {
                    ApplicationArea = All;
                    Caption = 'Створити новий сервіс';
                    ToolTip = 'Вимкніть, щоб використати наявний сервіс EDS.';
                    trigger OnValidate()
                    begin
                        Clear(ServiceCode);
                        Clear(ServiceDescription);
                    end;
                }
                field(ServiceCode; ServiceCode)
                {
                    ApplicationArea = All;
                    Caption = 'Сервіс';
                    ToolTip = 'Вкажіть код нового сервісу або виберіть наявний.';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Service: Record "SI EDS Service";
                    begin
                        if CreateService then
                            exit(false);
                        if Page.RunModal(Page::"SI EDS Services", Service) = Action::LookupOK then begin
                            ServiceCode := Service.Code;
                            ServiceDescription := Service.Description;
                            Text := Service.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;
                    trigger OnValidate()
                    var
                        Service: Record "SI EDS Service";
                    begin
                        if CreateService then
                            exit;
                        if ServiceCode = '' then begin
                            Clear(ServiceDescription);
                            exit;
                        end;
                        if not Service.Get(ServiceCode) then
                            Error('Сервіс %1 не знайдено. Виберіть наявний сервіс із переліку.', ServiceCode);
                        ServiceDescription := Service.Description;
                    end;
                }
                field(ServiceDescription; ServiceDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Опис';
                    Editable = CreateService;
                }
            }
            group(ProviderStep)
            {
                Caption = '2. Провайдер';
                Visible = CurrentStep = 3;

                field(CreateProvider; CreateProvider)
                {
                    ApplicationArea = All;
                    Caption = 'Створити нового провайдера';
                    ToolTip = 'Вимкніть, щоб використати наявного провайдера EDS.';
                    trigger OnValidate()
                    begin
                        Clear(ProviderCode);
                        Clear(ProviderDescription);
                    end;
                }
                field(ProviderCode; ProviderCode)
                {
                    ApplicationArea = All;
                    Caption = 'Провайдер';
                    ToolTip = 'Вкажіть код нового провайдера або виберіть наявного.';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Provider: Record "SI EDS Provider";
                    begin
                        if CreateProvider then
                            exit(false);
                        if Page.RunModal(Page::"SI EDS Providers", Provider) = Action::LookupOK then begin
                            ProviderCode := Provider.Code;
                            ProviderDescription := Provider.Description;
                            Text := Provider.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;
                    trigger OnValidate()
                    var
                        Provider: Record "SI EDS Provider";
                    begin
                        if CreateProvider then
                            exit;
                        if ProviderCode = '' then begin
                            Clear(ProviderDescription);
                            exit;
                        end;
                        if not Provider.Get(ProviderCode) then
                            Error('Провайдер %1 не знайдено. Виберіть наявного провайдера з переліку.', ProviderCode);
                        ProviderDescription := Provider.Description;
                    end;
                }
                field(ProviderDescription; ProviderDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Опис';
                    Editable = CreateProvider;
                }
            }
            group(EndpointStep)
            {
                Caption = '3. Точка підключення';
                Visible = CurrentStep = 4;

                field(CreateEndpoint; CreateEndpoint)
                {
                    ApplicationArea = All;
                    Caption = 'Створити нову точку підключення';
                    ToolTip = 'Вимкніть, щоб використати наявну точку підключення вибраного провайдера.';
                    trigger OnValidate()
                    begin
                        Clear(EndpointCode);
                        Clear(EndpointDescription);
                        Clear(BaseUrl);
                        EndpointPriority := 0;
                    end;
                }
                field(EndpointCode; EndpointCode)
                {
                    ApplicationArea = All;
                    Caption = 'Точка підключення';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Endpoint: Record "SI EDS Endpoint";
                    begin
                        if CreateEndpoint then
                            exit(false);
                        Endpoint.SetRange("Provider Code", ProviderCode);
                        if Page.RunModal(Page::"SI EDS Endpoints", Endpoint) = Action::LookupOK then begin
                            EndpointCode := Endpoint.Code;
                            EndpointDescription := Endpoint.Description;
                            BaseUrl := Endpoint."Base URL";
                            EndpointPriority := Endpoint.Priority;
                            Text := Endpoint.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field(EndpointDescription; EndpointDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Опис';
                    Editable = CreateEndpoint;
                }
                field(BaseUrl; BaseUrl)
                {
                    ApplicationArea = All;
                    Caption = 'Базова URL-адреса';
                    Editable = CreateEndpoint;
                }
                field(EndpointPriority; EndpointPriority)
                {
                    ApplicationArea = All;
                    Caption = 'Пріоритет точки підключення';
                    Editable = CreateEndpoint;
                    MinValue = 0;
                    ToolTip = 'Менше значення означає вищий пріоритет точки підключення в межах провайдера.';
                }
            }
            group(OperationStep)
            {
                Caption = '4. Операція і маршрут';
                Visible = CurrentStep = 5;

                group(MultiOperationDraft)
                {
                    Caption = 'Операції та групи сервісу';
                    part(WizardGroupLines; "SI EDS Wiz Group Lines")
                    {
                        ApplicationArea = All;
                    }
                    part(WizardOperationLines; "SI EDS Wiz Operation Lines")
                    {
                        ApplicationArea = All;
                    }
                }
                group(LegacyOperationFields)
                {
                    Caption = 'Поля сумісності (одна операція)';
                    Visible = false;
                field(CreateOperation; CreateOperation)
                {
                    ApplicationArea = All;
                    Caption = 'Створити нову операцію';
                    ToolTip = 'Вимкніть, щоб використати наявну операцію вибраного сервісу.';
                    trigger OnValidate()
                    begin
                        Clear(OperationCode);
                        Clear(OperationDescription);
                        Clear(RelativePath);
                        Clear(OperationGroupCode);
                        CreateOperationGroup := false;
                    end;
                }
                field(CreateOperationGroup; CreateOperationGroup)
                {
                    ApplicationArea = All;
                    Caption = 'Створити нову групу операцій';
                    ToolTip = 'Вимкніть для вибору наявної групи або залиште код порожнім для операції без групи.';
                    trigger OnValidate()
                    begin
                        Clear(OperationGroupCode);
                        Clear(OperationGroupDescription);
                        Clear(OperationGroupPathPrefix);
                        OperationGroupSequence := 0;
                        OperationGroupEnabled := true;
                    end;
                }
                field(OperationGroupCode; OperationGroupCode)
                {
                    ApplicationArea = All;
                    Caption = 'Група операцій';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        OperationGroup: Record "SI EDS Operation Group";
                    begin
                        if CreateOperationGroup then
                            exit(false);
                        OperationGroup.SetRange("Service Code", ServiceCode);
                        if Page.RunModal(Page::"SI EDS Operation Groups", OperationGroup) = Action::LookupOK then begin
                            OperationGroupCode := OperationGroup.Code;
                            OperationGroupDescription := OperationGroup.Description;
                            OperationGroupPathPrefix := OperationGroup."Path Prefix";
                            OperationGroupSequence := OperationGroup.Sequence;
                            OperationGroupEnabled := OperationGroup.Enabled;
                            Text := OperationGroup.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;
                    trigger OnValidate()
                    var
                        OperationGroup: Record "SI EDS Operation Group";
                    begin
                        if CreateOperationGroup or (OperationGroupCode = '') then
                            exit;
                        if not OperationGroup.Get(ServiceCode, OperationGroupCode) then
                            Error('Групу операцій %1 для сервісу %2 не знайдено.', OperationGroupCode, ServiceCode);
                        OperationGroupDescription := OperationGroup.Description;
                        OperationGroupPathPrefix := OperationGroup."Path Prefix";
                        OperationGroupSequence := OperationGroup.Sequence;
                        OperationGroupEnabled := OperationGroup.Enabled;
                    end;
                }
                field(OperationGroupDescription; OperationGroupDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Опис групи';
                    Editable = CreateOperationGroup;
                }
                field(OperationGroupPathPrefix; OperationGroupPathPrefix)
                {
                    ApplicationArea = All;
                    Caption = 'Префікс шляху групи';
                    Editable = CreateOperationGroup;
                }
                field(OperationGroupSequence; OperationGroupSequence)
                {
                    ApplicationArea = All;
                    Caption = 'Послідовність групи';
                    Editable = CreateOperationGroup;
                }
                field(OperationGroupEnabled; OperationGroupEnabled)
                {
                    ApplicationArea = All;
                    Caption = 'Групу увімкнено';
                    Editable = CreateOperationGroup;
                }
                field(OperationCode; OperationCode)
                {
                    ApplicationArea = All;
                    Caption = 'Операція';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Operation: Record "SI EDS Operation";
                    begin
                        if CreateOperation then
                            exit(false);
                        Operation.SetRange("Service Code", ServiceCode);
                        if Page.RunModal(Page::"SI EDS Operations", Operation) = Action::LookupOK then begin
                            OperationCode := Operation.Code;
                            OperationDescription := Operation.Description;
                            HttpMethod := Operation."HTTP Method";
                            RelativePath := Operation."Relative Path";
                            OperationGroupCode := Operation."Operation Group Code";
                            CreateOperationGroup := false;
                            LoadSelectedOperationGroup();
                            Text := Operation.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field(OperationDescription; OperationDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Опис';
                    Editable = CreateOperation;
                }
                field(HttpMethod; HttpMethod)
                {
                    ApplicationArea = All;
                    Caption = 'HTTP метод';
                    Editable = CreateOperation;
                }
                field(RelativePath; RelativePath)
                {
                    ApplicationArea = All;
                    Caption = 'Відносний шлях';
                    Editable = CreateOperation;
                }
                }
                field(RoutePriority; RoutePriority)
                {
                    ApplicationArea = All;
                    Caption = 'Пріоритет провайдера';
                    MinValue = 0;
                    ToolTip = 'Обов''язково задайте пріоритет маршруту. Менше значення означає вищий пріоритет провайдера; наступний провайдер використовується як fallback.';
                    trigger OnValidate()
                    begin
                        RoutePriorityDefined := true;
                    end;
                }
                field(RoutePriorityHint; RoutePriorityHint)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                }
            }
            group(CredentialStep)
            {
                Caption = '5. Облікові дані';
                Visible = CurrentStep = 6;

                field(ConfigureCredential; ConfigureCredential)
                {
                    ApplicationArea = All;
                    Caption = 'Налаштувати облікові дані';
                    trigger OnValidate()
                    begin
                        Clear(CredentialCode);
                        Clear(CredentialDescription);
                        Clear(CredentialSecret);
                        CredentialSecretDefined := false;
                    end;
                }
                field(CreateCredential; CreateCredential)
                {
                    ApplicationArea = All;
                    Caption = 'Створити нові облікові дані';
                    Enabled = ConfigureCredential;
                    trigger OnValidate()
                    begin
                        Clear(CredentialCode);
                        Clear(CredentialDescription);
                        Clear(CredentialSecret);
                        CredentialSecretDefined := false;
                    end;
                }
                field(CredentialCode; CredentialCode)
                {
                    ApplicationArea = All;
                    Caption = 'Облікові дані';
                    Enabled = ConfigureCredential;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Credential: Record "SI EDS Credential";
                    begin
                        if (not ConfigureCredential) or CreateCredential then
                            exit(false);
                        Credential.SetRange("Provider Code", ProviderCode);
                        if Page.RunModal(Page::"SI EDS Credentials", Credential) = Action::LookupOK then begin
                            CredentialCode := Credential.Code;
                            CredentialDescription := Credential.Description;
                            Text := Credential.Code;
                            CredentialType := Credential."Credential Type";
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field(CredentialDescription; CredentialDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Опис';
                    Enabled = ConfigureCredential;
                    Editable = CreateCredential;
                }
                field(CredentialType; CredentialType)
                {
                    ApplicationArea = All;
                    Caption = 'Тип';
                    Enabled = ConfigureCredential;
                    Editable = CreateCredential;
                }
                field(CredentialSecretStatus; CredentialSecretStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Секрет';
                    Editable = false;
                    Enabled = ConfigureCredential;
                }
            }
            group(ParameterStep)
            {
                Caption = '6. Параметри операції';
                Visible = CurrentStep = 7;
                part(ParameterLines; "SI EDS Wiz Param Lines")
                {
                    ApplicationArea = All;
                }
            }
            group(RateLimitStep)
            {
                Caption = '7. Ліміти запитів';
                Visible = CurrentStep = 8;
                part(RateLimitLines; "SI EDS Wiz Rate Lines")
                {
                    ApplicationArea = All;
                }
            }
            group(SummaryStep)
            {
                Caption = '8. Підсумок';
                Visible = CurrentStep = 9;

                field(SummaryText; SummaryText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Back)
            {
                ApplicationArea = All;
                Caption = 'Назад';
                InFooterBar = true;
                Enabled = CurrentStep > 1;
                Image = PreviousRecord;
                trigger OnAction()
                begin
                    if CurrentStep > 1 then
                        CurrentStep -= 1;
                    UpdateStep();
                end;
            }
            action(Next)
            {
                ApplicationArea = All;
                Caption = 'Далі';
                InFooterBar = true;
                Enabled = (CurrentStep < 9) and not ((CurrentStep = 2) and (not CreateService));
                Image = NextRecord;
                trigger OnAction()
                begin
                    ValidateCurrentStep();
                    CurrentStep += 1;
                    if CurrentStep = 9 then
                        BuildSummary();
                    UpdateStep();
                end;
            }
            action(ContinueExistingSetup)
            {
                ApplicationArea = All;
                Caption = 'Продовжити налаштування';
                InFooterBar = true;
                Enabled = (CurrentStep = 2) and (not CreateService) and (ServiceCode <> '');
                Image = NextRecord;
                ToolTip = 'Проаналізувати наявну конфігурацію сервісу, підхопити вже налаштовані елементи та перейти до продовження налаштування.';
                trigger OnAction()
                begin
                    DiscoverExistingSetup();
                    UpdateStep();
                end;
            }
            action(SetCredentialSecret)
            {
                ApplicationArea = All;
                Caption = 'Встановити секрет';
                InFooterBar = true;
                Enabled = (CurrentStep = 6) and ConfigureCredential and CreateCredential;
                Image = Lock;
                trigger OnAction()
                var
                    SecretDialog: Page "SI EDS Secret Dialog";
                begin
                    if SecretDialog.RunModal() <> Action::OK then
                        exit;
                    CredentialSecret := SecretDialog.GetSecretValue();
                    CredentialSecretDefined := CredentialSecret <> '';
                    if CredentialSecretDefined then
                        CredentialSecretStatus := 'Задано'
                    else
                        CredentialSecretStatus := 'Не задано';
                    CurrPage.Update(false);
                end;
            }
            action(Finish)
            {
                ApplicationArea = All;
                Caption = 'Завершити налаштування';
                InFooterBar = true;
                Enabled = CurrentStep = 9;
                Image = Approve;
                trigger OnAction()
                var
                    WizardMgt: Codeunit "SI EDS Setup Wizard Mgt.";
                begin
                    ResolvePrimaryOperationFromDraft();
                    ValidateAll();
                    CurrPage.WizardGroupLines.Page.GetDraftGroups(DraftGroups);
                    CurrPage.WizardOperationLines.Page.GetDraftOperations(DraftOperations);
                    WizardMgt.ValidateBatchDrafts(ServiceCode, ProviderCode, RoutePriority,
                        OperationCode, OperationGroupCode, DraftGroups, DraftOperations);
                    CurrPage.ParameterLines.Page.ValidateOperationReferences(ServiceCode, DraftOperations);
                    // A new credential may be configured now and supplied with a secret later.
                    // Confirm before any persistent EDS records are created.
                    if ConfigureCredential and CreateCredential and not CredentialSecretDefined then
                        if not Confirm(
                            'Секрет для облікових даних %1 не встановлено. Конфігурацію буде збережено без секрету; його можна додати пізніше. Продовжити?',
                            false, CredentialCode)
                        then
                            exit;
                    WizardMgt.FinishSetup(
                        CreateService, ServiceCode, ServiceDescription,
                        CreateProvider, ProviderCode, ProviderDescription,
                        CreateEndpoint, EndpointCode, EndpointDescription, BaseUrl, EndpointPriority,
                        CreateOperation, OperationCode, OperationDescription, HttpMethod, RelativePath,
                        RoutePriority,
                        CreateOperationGroup, OperationGroupCode, OperationGroupDescription, OperationGroupPathPrefix, OperationGroupSequence, OperationGroupEnabled,
                        ConfigureCredential, CreateCredential, CredentialCode, CredentialDescription, CredentialType, CredentialSecret, CredentialSecretDefined,
                        false, '', 0, '', ParameterLocation, ParameterSource, '', '', '', '', false,
                        false, 0, 0, 0, 80, '');
                    WizardMgt.SaveBatchDrafts(ServiceCode, ProviderCode, RoutePriority,
                        OperationCode, OperationGroupCode, DraftGroups, DraftOperations);
                    CurrPage.ParameterLines.Page.FinishToEDS(ServiceCode, ProviderCode);
                    CurrPage.RateLimitLines.Page.FinishToEDS(ProviderCode);
                    // Do not open a modal page after writes in the same transaction.
                    // The health check can be launched separately after the wizard closes.
                    Message('Налаштування EDS успішно збережено. Для перевірки відкрийте сторінку «SI EDS Health Check» окремо.');
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrentStep := 1;
        CreateService := false;
        CreateProvider := false;
        CreateEndpoint := true;
        CreateOperation := false;
        ConfigureCredential := false;
        CreateCredential := true;
        ConfigureParameter := false;
        ConfigureRateLimit := false;
        RateLimitSequence := 10;
        RateLimitSafetyMargin := 80;
        CredentialSecretStatus := 'Не задано';
        WelcomeText := 'Майстер допоможе створити нову або доповнити наявну конфігурацію EDS. На кожному етапі можна використати наявний елемент або створити новий. Зміни записуються лише після завершення майстра.';
        RoutePriorityDefined := true; // Zero is a valid default priority.
        OperationGroupEnabled := true;
        RoutePriorityHint := 'Пріоритет 0 є допустимим і має найвищий пріоритет. Менше значення — вищий пріоритет.';
        UpdateStep();
    end;

    local procedure DiscoverExistingSetup()
    var
        Service: Record "SI EDS Service";
        Route: Record "SI EDS Provider Route";
        Provider: Record "SI EDS Provider";
        Endpoint: Record "SI EDS Endpoint";
        Operation: Record "SI EDS Operation";
        Credential: Record "SI EDS Credential";
        Parameter: Record "SI EDS Parameter";
        RateLimit: Record "SI EDS Provider Rate Limit";
    begin
        if CreateService then
            Error('Продовження налаштування доступне лише для наявного сервісу.');
        if ServiceCode = '' then
            Error('Виберіть наявний сервіс EDS.');
        if not Service.Get(ServiceCode) then
            Error('Сервіс %1 не знайдено.', ServiceCode);

        ServiceDescription := Service.Description;

        // Route is the authoritative link Service/Operation -> Provider.
        Route.SetRange("Service Code", ServiceCode);
        Route.SetRange(Enabled, true);
        Route.SetCurrentKey("Service Code", "Operation Code", Priority, "Provider Code");
        if not Route.FindFirst() then begin
            Clear(ProviderCode);
            Clear(ProviderDescription);
            Clear(OperationCode);
            Clear(OperationDescription);
            RoutePriorityDefined := true;
            CurrentStep := 3;
            exit;
        end;

        ProviderCode := Route."Provider Code";
        CreateProvider := false;
        if Provider.Get(ProviderCode) then
            ProviderDescription := Provider.Description;

        OperationCode := Route."Operation Code";
        CreateOperation := false;
        if Operation.Get(ServiceCode, OperationCode) then begin
            OperationDescription := Operation.Description;
            HttpMethod := Operation."HTTP Method";
            RelativePath := Operation."Relative Path";
            OperationGroupCode := Operation."Operation Group Code";
            CreateOperationGroup := false;
            LoadSelectedOperationGroup();
        end;

        RoutePriority := Route.Priority;
        RoutePriorityDefined := true;

        Endpoint.SetRange("Provider Code", ProviderCode);
        Endpoint.SetRange(Enabled, true);
        Endpoint.SetCurrentKey("Provider Code", Priority);
        if Endpoint.FindFirst() then begin
            CreateEndpoint := false;
            EndpointCode := Endpoint.Code;
            EndpointDescription := Endpoint.Description;
            BaseUrl := Endpoint."Base URL";
            EndpointPriority := Endpoint.Priority;
        end else begin
            CreateEndpoint := true;
            Clear(EndpointCode);
            Clear(EndpointDescription);
            Clear(BaseUrl);
            EndpointPriority := 0;
            CurrentStep := 4;
            exit;
        end;

        Credential.SetRange("Provider Code", ProviderCode);
        Credential.SetRange(Enabled, true);
        if Credential.FindFirst() then begin
            ConfigureCredential := true;
            CreateCredential := false;
            CredentialCode := Credential.Code;
            CredentialDescription := Credential.Description;
            CredentialType := Credential."Credential Type";
            CredentialSecretStatus := 'Наявний';
        end else begin
            ConfigureCredential := false;
            CreateCredential := true;
            Clear(CredentialCode);
            Clear(CredentialDescription);
            CredentialSecretStatus := 'Не задано';
        end;

        CurrPage.ParameterLines.Page.LoadExisting(ServiceCode, OperationCode, ProviderCode);
        CurrPage.RateLimitLines.Page.LoadExisting(ProviderCode);

        // Core route already exists. Continue with optional/extended configuration.
        CurrentStep := 6;
    end;

    local procedure LoadSelectedOperationGroup()
    var
        OperationGroup: Record "SI EDS Operation Group";
    begin
        Clear(OperationGroupDescription);
        Clear(OperationGroupPathPrefix);
        OperationGroupSequence := 0;
        OperationGroupEnabled := true;
        if (OperationGroupCode <> '') and OperationGroup.Get(ServiceCode, OperationGroupCode) then begin
            OperationGroupDescription := OperationGroup.Description;
            OperationGroupPathPrefix := OperationGroup."Path Prefix";
            OperationGroupSequence := OperationGroup.Sequence;
            OperationGroupEnabled := OperationGroup.Enabled;
        end;
    end;

    local procedure ValidateOperationGroupSelection()
    var
        OperationGroup: Record "SI EDS Operation Group";
        Operation: Record "SI EDS Operation";
    begin
        if CreateOperationGroup then begin
            if not CreateOperation then
                Error('Нову групу можна створити лише разом із новою операцією.');
            if OperationGroupCode = '' then
                Error('Вкажіть код нової групи операцій.');
            if OperationGroup.Get(ServiceCode, OperationGroupCode) then
                Error('Група операцій %1 уже існує.', OperationGroupCode);
        end else
            if (OperationGroupCode <> '') and (not OperationGroup.Get(ServiceCode, OperationGroupCode)) then
                Error('Групу операцій %1 не знайдено.', OperationGroupCode);
        if not CreateOperation then begin
            if not Operation.Get(ServiceCode, OperationCode) then
                Error('Операцію %1 не знайдено.', OperationCode);
            if Operation."Operation Group Code" <> OperationGroupCode then
                Error('Для наявної операції групу змінюють у картці операції, а не через майстер.');
        end;
    end;

    local procedure ValidateCurrentStep()
    begin
        case CurrentStep of
            2:
                if ServiceCode = '' then
                    Error('Вкажіть сервіс EDS.');
            3:
                if ProviderCode = '' then
                    Error('Вкажіть провайдера EDS.');
            4:
                begin
                    if EndpointCode = '' then
                        Error('Вкажіть точку підключення EDS.');
                    if CreateEndpoint and (BaseUrl = '') then
                        Error('Для нової точки підключення вкажіть базову URL-адресу.');
                end;
            5:
                begin
                    ResolvePrimaryOperationFromDraft();
                    if OperationCode = '' then
                        Error('Вкажіть операцію EDS.');
                    ValidateOperationGroupSelection();
                end;
            6:
                if ConfigureCredential and (CredentialCode = '') then
                    Error('Вкажіть код облікових даних.');
            7:
                begin
                    CurrPage.ParameterLines.Page.ValidateLines(ProviderCode, CredentialCode, ConfigureCredential and CreateCredential);
                    CurrPage.WizardOperationLines.Page.GetDraftOperations(DraftOperations);
                    CurrPage.ParameterLines.Page.ValidateOperationReferences(ServiceCode, DraftOperations);
                end;
            8:
                CurrPage.RateLimitLines.Page.ValidateLines();
        end;
    end;

    local procedure ResolvePrimaryOperationFromDraft()
    var
        PrimaryDraft: Record "SI EDS Wiz Operation Buffer" temporary;
        GroupDraft: Record "SI EDS Wiz Group Buffer" temporary;
        ExistingGroup: Record "SI EDS Operation Group";
    begin
        // B2 Fix 1: the legacy FinishSetup still requires one primary operation.
        // Select it from the temporary multi-operation list, without writing to EDS.
        // Explicitly selected legacy operation takes precedence for compatibility.
        if OperationCode <> '' then
            exit;

        CurrPage.WizardOperationLines.Page.GetDraftOperations(PrimaryDraft);
        PrimaryDraft.SetRange("Service Code", ServiceCode);
        if not PrimaryDraft.FindFirst() then
            exit;
        if PrimaryDraft.Code = '' then
            Error('Заповніть код першої підготовленої операції.');

        OperationCode := PrimaryDraft.Code;
        OperationDescription := PrimaryDraft.Description;
        HttpMethod := PrimaryDraft."HTTP Method";
        RelativePath := PrimaryDraft."Relative Path";
        OperationGroupCode := PrimaryDraft."Operation Group Code";
        CreateOperation := not PrimaryDraft.Existing;

        CreateOperationGroup := false;
        Clear(OperationGroupDescription);
        Clear(OperationGroupPathPrefix);
        OperationGroupSequence := 0;
        OperationGroupEnabled := true;
        if OperationGroupCode = '' then
            exit;

        CurrPage.WizardGroupLines.Page.GetDraftGroups(GroupDraft);
        if GroupDraft.Get(ServiceCode, OperationGroupCode) then begin
            CreateOperationGroup := true;
            OperationGroupDescription := GroupDraft.Description;
            OperationGroupPathPrefix := GroupDraft."Path Prefix";
            OperationGroupSequence := GroupDraft.Sequence;
            OperationGroupEnabled := GroupDraft.Enabled;
        end else
            if ExistingGroup.Get(ServiceCode, OperationGroupCode) then begin
                OperationGroupDescription := ExistingGroup.Description;
                OperationGroupPathPrefix := ExistingGroup."Path Prefix";
                OperationGroupSequence := ExistingGroup.Sequence;
                OperationGroupEnabled := ExistingGroup.Enabled;
            end;
    end;

    local procedure ValidateAll()
    var
        WizardMgt: Codeunit "SI EDS Setup Wizard Mgt.";
    begin
        if ServiceCode = '' then
            Error('Вкажіть сервіс EDS.');
        if ProviderCode = '' then
            Error('Вкажіть провайдера EDS.');
        if EndpointCode = '' then
            Error('Вкажіть точку підключення EDS.');
        if OperationCode = '' then
            Error('Вкажіть операцію EDS.');
        ValidateOperationGroupSelection();
        WizardMgt.ValidateUniqueRoutePriority(ServiceCode, OperationCode, ProviderCode, RoutePriority);
        WizardMgt.ValidateExtendedInput(
            ProviderCode, ConfigureCredential, CreateCredential, CredentialCode, CredentialSecretDefined,
            ServiceCode, OperationCode, false, '', '', ParameterLocation, ParameterSource, '', '',
            false, 0, 0, 0, 80);
        CurrPage.ParameterLines.Page.ValidateLines(ProviderCode, CredentialCode, ConfigureCredential and CreateCredential);
        CurrPage.WizardOperationLines.Page.GetDraftOperations(DraftOperations);
        CurrPage.ParameterLines.Page.ValidateOperationReferences(ServiceCode, DraftOperations);
        CurrPage.RateLimitLines.Page.ValidateLines();
    end;

    local procedure BuildSummary()
    begin
        SummaryText :=
            StrSubstNo('Сервіс: %1 (%2)\\Провайдер: %3 (%4)\\Точка підключення: %5 (%6)\\Операція: %7 (%8)\\Пріоритет провайдера: %9',
                ServiceCode, StateText(CreateService), ProviderCode, StateText(CreateProvider), EndpointCode, StateText(CreateEndpoint), OperationCode, StateText(CreateOperation), RoutePriority);
        SummaryText += '\\Група операцій: ' + OperationGroupCode;
        SummaryText += '\\Облікові дані: ' + CredentialSummary();
        SummaryText += '\\\\Параметри операції:';
        SummaryText += CurrPage.ParameterLines.Page.BuildSummary();
        SummaryText += '\\\\Ліміти запитів:';
        SummaryText += CurrPage.RateLimitLines.Page.BuildSummary();
        SummaryText += '\\\\Менше значення означає вищий пріоритет. Зміни будуть записані лише після завершення майстра.';
    end;

    local procedure BuildDraftSummary(): Text
    var
        Groups: Record "SI EDS Wiz Group Buffer" temporary;
        Operations: Record "SI EDS Wiz Operation Buffer" temporary;
        ResultText: Text;
        GroupLabel: Text;
    begin
        CurrPage.WizardGroupLines.Page.GetDraftGroups(Groups);
        CurrPage.WizardOperationLines.Page.GetDraftOperations(Operations);
        ResultText := '\\Групи операцій:';
        if Groups.FindSet() then
            repeat
                ResultText += StrSubstNo('\\  %1 — %2', Groups.Code, Groups.Description);
            until Groups.Next() = 0;
        ResultText += '\\Операції:';
        if Operations.FindSet() then
            repeat
                GroupLabel := Operations."Operation Group Code";
                if GroupLabel = '' then
                    GroupLabel := '(без групи)';
                ResultText += StrSubstNo('\\  %1 / %2 / %3 / %4', Operations.Code,
                    GroupLabel, Format(Operations."HTTP Method"), Operations."Relative Path");
            until Operations.Next() = 0;
        exit(ResultText);
    end;

    local procedure StateText(CreateNew: Boolean): Text
    begin
        if CreateNew then
            exit('буде створено');
        exit('наявний');
    end;

    local procedure OptionalState(EnabledValue: Boolean; ValueCode: Code[50]): Text
    begin
        if not EnabledValue then
            exit('не налаштовується');
        exit(ValueCode);
    end;


    local procedure CredentialSummary(): Text
    begin
        if not ConfigureCredential then
            exit('не налаштовується');
        if CreateCredential then
            exit(StrSubstNo('%1 (буде створено)', CredentialCode));
        exit(StrSubstNo('%1 (наявний)', CredentialCode));
    end;

    local procedure OptionalRateState(): Text
    begin
        if not ConfigureRateLimit then
            exit('не налаштовується');
        exit(StrSubstNo('%1 запитів / %2 сек., %3 %', RateLimitMaxRequests, RateLimitWindowSeconds, RateLimitSafetyMargin));
    end;

    local procedure UpdateStep()
    begin
        if CurrentStep = 7 then
            CurrPage.ParameterLines.Page.SetDefaultOperationCode(OperationCode);
        if CurrentStep = 5 then begin
            CurrPage.WizardGroupLines.Page.SetServiceCode(ServiceCode);
            CurrPage.WizardOperationLines.Page.SetServiceCode(ServiceCode);
        end;
        CurrPage.Update(false);
    end;

    var
        DraftGroups: Record "SI EDS Wiz Group Buffer" temporary;
        DraftOperations: Record "SI EDS Wiz Operation Buffer" temporary;
        CurrentStep: Integer;
        WelcomeText: Text[1024];
        CreateService: Boolean;
        ServiceCode: Code[50];
        ServiceDescription: Text[250];
        CreateProvider: Boolean;
        ProviderCode: Code[50];
        ProviderDescription: Text[250];
        CreateEndpoint: Boolean;
        EndpointCode: Code[50];
        EndpointDescription: Text[250];
        BaseUrl: Text[250];
        EndpointPriority: Integer;
        CreateOperation: Boolean;
        OperationCode: Code[50];
        OperationDescription: Text[250];
        HttpMethod: Enum "SI EDS HTTP Method";
        RelativePath: Text[250];
        RoutePriority: Integer;
        CreateOperationGroup: Boolean;
        OperationGroupCode: Code[50];
        OperationGroupDescription: Text[250];
        OperationGroupPathPrefix: Text[250];
        OperationGroupSequence: Integer;
        OperationGroupEnabled: Boolean;
        RoutePriorityDefined: Boolean;
        RoutePriorityHint: Text[500];
        ConfigureCredential: Boolean;
        CreateCredential: Boolean;
        CredentialCode: Code[50];
        CredentialDescription: Text[250];
        CredentialType: Enum "SI EDS Credential Type";
        CredentialSecret: Text;
        CredentialSecretDefined: Boolean;
        CredentialSecretStatus: Text[50];
        ConfigureParameter: Boolean;
        ParameterCode: Code[50];
        ParameterSequence: Integer;
        ParameterExternalName: Text[100];
        ParameterLocation: Enum "SI EDS Param. Location";
        ParameterSource: Enum "SI EDS Param. Source";
        ParameterRuntimeKey: Code[50];
        ParameterFixedValue: Text[250];
        ParameterCredentialCode: Code[50];
        ParameterValuePrefix: Text[50];
        ParameterRequired: Boolean;
        ConfigureRateLimit: Boolean;
        RateLimitSequence: Integer;
        RateLimitWindowSeconds: Integer;
        RateLimitMaxRequests: Integer;
        RateLimitSafetyMargin: Decimal;
        RateLimitDescription: Text[100];
        SummaryText: Text;
}
