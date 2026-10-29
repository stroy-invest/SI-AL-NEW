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
        area(Processing)
        {
            action(SetupWizardTop)
            {
                ApplicationArea = All;
                Caption = 'Майстер налаштування EDS';
                ToolTip = 'Запустити майстер налаштування EDS';
                Image = Setup;
                RunObject = page "SI EDS Setup Wizard";
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
            }
        }
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
                action(SetupWizard) { ApplicationArea = All; Caption = 'Майстер налаштування'; RunObject = page "SI EDS Setup Wizard"; }
                action(HealthCheck) { ApplicationArea = All; Caption = 'Перевірка конфігурації'; RunObject = page "SI EDS Health Check"; }
            }
            group(UserAccess)
            {
                Caption = 'Користувачі та доступ';
                action(AdminUsers) { ApplicationArea = All; Caption = 'Користувачі'; RunObject = page Users; }
                action(AdminUserSettings) { ApplicationArea = All; Caption = 'Параметри користувачів'; RunObject = page "User Settings"; }
                action(AdminUserSetup) { ApplicationArea = All; Caption = 'Налаштування користувачів (облік)'; RunObject = page "User Setup"; }
                action(AdminPermissionSets) { ApplicationArea = All; Caption = 'Набори дозволів'; RunObject = page "Permission Sets"; }
                action(AdminProfiles) { ApplicationArea = All; Caption = 'Профілі (ролі)'; RunObject = page "Profile List"; }
                action(AdminSecurityGroups) { ApplicationArea = All; Caption = 'Групи безпеки'; RunObject = page "Security Groups"; }
            }
            group(BackgroundJobs)
            {
                Caption = 'Фонові завдання';
                action(SystemJobQueue) { ApplicationArea = All; Caption = 'Черга завдань'; RunObject = page "Job Queue Entries"; }
                action(SystemJobQueueLog) { ApplicationArea = All; Caption = 'Журнал виконання завдань'; RunObject = page "Job Queue Log Entries"; }
                action(ServiceEmailQueue) { ApplicationArea = All; Caption = 'Черга службової пошти'; RunObject = page "Service Email Queue"; }
            }
            group(ExtensionsAdministration)
            {
                Caption = 'Розширення';
                action(AdminExtensionManagement) { ApplicationArea = All; Caption = 'Керування розширеннями'; RunObject = page "Extension Management"; }
                action(ApplicationRegistry) { ApplicationArea = All; Caption = 'Додатки та залежності SI'; RunObject = page "SI Application Registry"; }
            }
            group(SecurityAudit)
            {
                Caption = 'Безпека та аудит';
                action(AdminChangeLogEntries) { ApplicationArea = All; Caption = 'Журнал змін'; RunObject = page "Change Log Entries"; }
                action(AdminChangeLogSetup) { ApplicationArea = All; Caption = 'Налаштування журналу змін'; RunObject = page "Change Log Setup"; }
            }
            group(SystemSettings)
            {
                Caption = 'Система';
                action(AdminCompanies) { ApplicationArea = All; Caption = 'Компанії'; RunObject = page "Companies"; }
                action(AdminCompanyInformation) { ApplicationArea = All; Caption = 'Відомості про компанію'; RunObject = page "Company Information"; }
                action(AdminFeatureManagement) { ApplicationArea = All; Caption = 'Керування функціями'; RunObject = page "Feature Management"; }
            }
            group(Monitoring)
            {
                Caption = 'Моніторинг';
                action(ExecutionLog) { ApplicationArea = All; Caption = 'Журнал виконання'; RunObject = page "SI EDS Exec. Log"; }
                action(AsyncRequests) { ApplicationArea = All; Caption = 'Асинхронні запити'; RunObject = page "SI EDS Async Requests"; }
                action(InboundEvents) { ApplicationArea = All; Caption = 'Вхідні події'; RunObject = page "SI EDS Inbound Events"; }
            }
        }
        // System administration: read-only application diagnostics.
        area(Embedding)
        {
            action(ServicesEmbedded) { ApplicationArea = All; Caption = 'Сервіси'; RunObject = page "SI EDS Services"; }
            action(ProvidersEmbedded) { ApplicationArea = All; Caption = 'Провайдери'; RunObject = page "SI EDS Providers"; }
            action(LogEmbedded) { ApplicationArea = All; Caption = 'Журнал EDS'; RunObject = page "SI EDS Exec. Log"; }
            action(AsyncEmbedded) { ApplicationArea = All; Caption = 'Асинхронні запити'; RunObject = page "SI EDS Async Requests"; }
        }
    }
}
