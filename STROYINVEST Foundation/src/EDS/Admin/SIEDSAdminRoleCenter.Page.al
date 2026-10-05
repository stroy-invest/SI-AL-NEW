page 50471 "SI EDS Admin Role Center"
{
    PageType = RoleCenter;
    Caption = 'EDS — адміністрування';
    ApplicationArea = All;

    layout
    {
        area(RoleCenter)
        {
            part(Activities; "SI EDS Admin Activities") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Sections)
        {
            group(Configuration)
            {
                Caption = 'Налаштування EDS';
                action(Services) { ApplicationArea = All; Caption = '1. Сервіси'; RunObject = page "SI EDS Services"; }
                action(OperationGroups) { ApplicationArea = All; Caption = '2. Групи операцій'; RunObject = page "SI EDS Operation Groups"; }
                action(Operations) { ApplicationArea = All; Caption = '3. Операції'; RunObject = page "SI EDS Operations Tree"; }
                action(Providers) { ApplicationArea = All; Caption = '4. Провайдери'; RunObject = page "SI EDS Providers"; }
                action(Endpoints) { ApplicationArea = All; Caption = '5. Точки підключення'; RunObject = page "SI EDS Endpoints"; }
                action(Credentials) { ApplicationArea = All; Caption = '6. Облікові дані'; RunObject = page "SI EDS Credentials"; }
                action(Routes) { ApplicationArea = All; Caption = '7. Маршрути'; RunObject = page "SI EDS Provider Routes Tree"; }
                action(Parameters) { ApplicationArea = All; Caption = '8. Параметри'; RunObject = page "SI EDS Parameters Tree"; }
                action(RateLimits) { ApplicationArea = All; Caption = '9. Ліміти запитів'; RunObject = page "SI EDS Provider Rate Limits"; }
                action(HealthCheck) { ApplicationArea = All; Caption = 'Перевірка конфігурації'; RunObject = page "SI EDS Health Check"; }
            }
            group(Monitoring)
            {
                Caption = 'Моніторинг';
                action(ExecutionLog) { ApplicationArea = All; Caption = 'Журнал виконання'; RunObject = page "SI EDS Exec. Log"; }
                action(AsyncRequests) { ApplicationArea = All; Caption = 'Асинхронні запити'; RunObject = page "SI EDS Async Requests"; }
                action(InboundEvents) { ApplicationArea = All; Caption = 'Вхідні події'; RunObject = page "SI EDS Inbound Events"; }
            }
        }
        area(Embedding)
        {
            action(ServicesEmbedded) { ApplicationArea = All; Caption = 'Сервіси'; RunObject = page "SI EDS Services"; }
            action(ProvidersEmbedded) { ApplicationArea = All; Caption = 'Провайдери'; RunObject = page "SI EDS Providers"; }
            action(LogEmbedded) { ApplicationArea = All; Caption = 'Журнал EDS'; RunObject = page "SI EDS Exec. Log"; }
            action(AsyncEmbedded) { ApplicationArea = All; Caption = 'Асинхронні запити'; RunObject = page "SI EDS Async Requests"; }
        }
    }
}
