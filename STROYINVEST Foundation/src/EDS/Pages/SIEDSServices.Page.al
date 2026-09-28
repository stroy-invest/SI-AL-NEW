page 50450 "SI EDS Services"
{
    PageType = List;
    SourceTable = "SI EDS Service";
    Caption = 'EDS: сервіси';
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
                    ToolTip = 'Визначає логічний код зовнішнього сервісу.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає опис зовнішнього сервісу.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи дозволено виконувати операції сервісу.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Operations)
            {
                Caption = 'Операції';
                ApplicationArea = All;
                RunObject = page "SI EDS Operations";
                RunPageLink = "Service Code" = field(Code);
            }

            action(Routes)
            {
                Caption = 'Маршрути провайдерів';
                ApplicationArea = All;
                RunObject = page "SI EDS Provider Routes";
                RunPageLink = "Service Code" = field(Code);
            }

            action(Parameters)
            {
                Caption = 'Параметри';
                ApplicationArea = All;
                RunObject = page "SI EDS Parameters";
                RunPageLink = "Service Code" = field(Code);
            }
        }
    }
}
