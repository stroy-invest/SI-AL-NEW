page 50453 "SI EDS Provider Routes"
{
    PageType = List;
    SourceTable = "SI EDS Provider Route";
    Caption = 'EDS: маршрути провайдерів';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Service Code"; Rec."Service Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає сервіс маршруту.';
                }
                field("Operation Code"; Rec."Operation Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає операцію маршруту.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає порядок використання провайдерів: менше значення має вищий пріоритет.';
                }
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає провайдера маршруту.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи активний маршрут.';
                }
            }
        }
    }
}
