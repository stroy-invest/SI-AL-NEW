page 50454 "SI EDS Endpoints"
{
    PageType = List;
    SourceTable = "SI EDS Endpoint";
    Caption = 'EDS: точки підключення';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає провайдера точки підключення.';
                }
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає код точки підключення.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає опис точки підключення.';
                }
                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає базову URL-адресу API.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає пріоритет точки підключення.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи активна точка підключення.';
                }
            }
        }
    }
}
