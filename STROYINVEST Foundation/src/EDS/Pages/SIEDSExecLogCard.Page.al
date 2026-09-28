page 50458 "SI EDS Exec. Log Card"
{
    PageType = Card;
    SourceTable = "SI EDS Exec. Log";
    Caption = 'EDS: запис журналу виконання';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Execution)
            {
                Caption = 'Виконання';
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Started At"; Rec."Started At") { ApplicationArea = All; }
                field("Finished At"; Rec."Finished At") { ApplicationArea = All; }
                field("Duration (ms)"; Rec."Duration (ms)") { ApplicationArea = All; }
                field("Result Type"; Rec."Result Type") { ApplicationArea = All; }
                field("HTTP Status Code"; Rec."HTTP Status Code") { ApplicationArea = All; }
                field("Correlation ID"; Rec."Correlation ID") { ApplicationArea = All; }
            }

            group(Routing)
            {
                Caption = 'Маршрутизація';
                field("Service Code"; Rec."Service Code") { ApplicationArea = All; }
                field("Operation Code"; Rec."Operation Code") { ApplicationArea = All; }
                field("Provider Code"; Rec."Provider Code") { ApplicationArea = All; }
                field("Endpoint Code"; Rec."Endpoint Code") { ApplicationArea = All; }
                field("Request URL"; Rec."Request URL") { ApplicationArea = All; MultiLine = true; }
            }

            group(ErrorDetails)
            {
                Caption = 'Помилка';
                field("Error Code"; Rec."Error Code") { ApplicationArea = All; }
                field("Error Message"; Rec."Error Message") { ApplicationArea = All; MultiLine = true; }
            }

            group(Response)
            {
                Caption = 'HTTP response';
                field(ResponseBodyText; ResponseBodyText)
                {
                    ApplicationArea = All;
                    Caption = 'Тіло відповіді';
                    MultiLine = true;
                    Editable = false;
                    ToolTip = 'Сире тіло HTTP-відповіді. Зберігається лише для операцій, у яких увімкнено параметр «Зберігати тіло відповіді в журналі».';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ResponseBodyText := Rec.GetResponseBody();
    end;

    var
        ResponseBodyText: Text;
}
