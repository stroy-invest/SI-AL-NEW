page 50472 "SI EDS Admin Activities"
{
    PageType = CardPart;
    SourceTable = "SI EDS Admin Cue";
    Caption = 'EDS — стан і навігація';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            cuegroup(Configuration)
            {
                Caption = 'Налаштування EDS';
                field(Services; Rec.Services) { ApplicationArea = All; Caption = 'Сервіси'; DrillDownPageId = "SI EDS Services"; }
                field(Operations; Rec.Operations) { ApplicationArea = All; Caption = 'Операції'; DrillDownPageId = "SI EDS Operations Tree"; }
                field(Providers; Rec.Providers) { ApplicationArea = All; Caption = 'Провайдери'; DrillDownPageId = "SI EDS Providers"; }
                field(Endpoints; Rec.Endpoints) { ApplicationArea = All; Caption = 'Точки підключення'; DrillDownPageId = "SI EDS Endpoints"; }
            }
            cuegroup(Routing)
            {
                Caption = 'Доступ і маршрутизація';
                field(Credentials; Rec.Credentials) { ApplicationArea = All; Caption = 'Облікові дані'; DrillDownPageId = "SI EDS Credentials"; }
                field(Routes; Rec.Routes) { ApplicationArea = All; Caption = 'Маршрути'; DrillDownPageId = "SI EDS Provider Routes Tree"; }
                field(Parameters; Rec.Parameters) { ApplicationArea = All; Caption = 'Параметри'; DrillDownPageId = "SI EDS Parameters Tree"; }
                field(RateLimits; Rec."Rate Limits") { ApplicationArea = All; Caption = 'Ліміти запитів'; DrillDownPageId = "SI EDS Provider Rate Limits"; }
            }
            cuegroup(Health)
            {
                Caption = 'Готовність EDS';
                field(HealthErrors; Rec."Health Errors")
                {
                    ApplicationArea = All;
                    Caption = 'Помилки конфігурації';
                    StyleExpr = ErrorStyle;
                    trigger OnDrillDown()
                    begin
                        OpenHealthCheck(2);
                    end;
                }
                field(HealthWarnings; Rec."Health Warnings")
                {
                    ApplicationArea = All;
                    Caption = 'Попередження';
                    StyleExpr = WarningStyle;
                    trigger OnDrillDown()
                    begin
                        OpenHealthCheck(1);
                    end;
                }
                field(HealthOK; Rec."Health OK")
                {
                    ApplicationArea = All;
                    Caption = 'Успішні перевірки';
                    trigger OnDrillDown()
                    begin
                        OpenHealthCheck(0);
                    end;
                }
            }
            cuegroup(OperationsState)
            {
                Caption = 'Операційний стан';
                field(AsyncPending; Rec."Async Pending") { ApplicationArea = All; Caption = 'Очікують'; DrillDownPageId = "SI EDS Async Requests"; }
                field(AsyncErrors; Rec."Async Errors") { ApplicationArea = All; Caption = 'Помилки async'; DrillDownPageId = "SI EDS Async Requests"; }
                field(AsyncTimedOut; Rec."Async Timed Out") { ApplicationArea = All; Caption = 'Час вичерпано'; DrillDownPageId = "SI EDS Async Requests"; }
                field(ExecutionLog; Rec."Execution Log") { ApplicationArea = All; Caption = 'Записи журналу'; DrillDownPageId = "SI EDS Exec. Log"; }
                field(TechnicalFailures; Rec."Technical Failures") { ApplicationArea = All; Caption = 'Технічні помилки'; DrillDownPageId = "SI EDS Exec. Log"; }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        HealthCheck: Codeunit "SI EDS Health Check Mgt.";
    begin
        HealthCheck.GetCounts(Rec."Health Errors", Rec."Health Warnings", Rec."Health OK");
        if Rec."Health Errors" > 0 then ErrorStyle := 'Unfavorable' else ErrorStyle := 'Favorable';
        if Rec."Health Warnings" > 0 then WarningStyle := 'Ambiguous' else WarningStyle := 'Favorable';
    end;

    var
        ErrorStyle: Text;
        WarningStyle: Text;

    trigger OnOpenPage()
    begin
        if not Rec.Get('EDS') then begin
            Rec.Init();
            Rec."Primary Key" := 'EDS';
            Rec.Insert();
        end;
    end;
    local procedure OpenHealthCheck(SeverityFilter: Integer)
    var
        HealthCheckPage: Page "SI EDS Health Check";
    begin
        HealthCheckPage.SetSeverityFilter(SeverityFilter);
        HealthCheckPage.RunModal();
    end;

}
