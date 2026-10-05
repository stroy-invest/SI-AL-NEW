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

    trigger OnOpenPage()
    begin
        if not Rec.Get('EDS') then begin
            Rec.Init();
            Rec."Primary Key" := 'EDS';
            Rec.Insert();
        end;
    end;
}
