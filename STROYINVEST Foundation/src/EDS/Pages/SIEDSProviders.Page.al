page 50452 "SI EDS Providers"
{
    PageType = List;
    SourceTable = "SI EDS Provider";
    Caption = 'EDS: провайдери';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає код провайдера.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає опис провайдера.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи дозволено використовувати провайдера.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Endpoints)
            {
                Caption = 'Точки підключення';
                ApplicationArea = All;
                RunObject = page "SI EDS Endpoints";
                RunPageLink = "Provider Code" = field(Code);
            }
            action(Credentials)
            {
                Caption = 'Облікові дані';
                ApplicationArea = All;
                RunObject = page "SI EDS Credentials";
                RunPageLink = "Provider Code" = field(Code);
            }
            action(RateLimits)
            {
                Caption = 'Ліміти запитів';
                ApplicationArea = All;
                RunObject = page "SI EDS Provider Rate Limits";
                RunPageLink = "Provider Code" = field(Code);
            }
        }
    }
}
