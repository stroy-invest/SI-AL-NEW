page 50451 "SI EDS Operations"
{
    PageType = List;
    SourceTable = "SI EDS Operation";
    Caption = 'EDS: операції';
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
                    ToolTip = 'Визначає сервіс, якому належить операція.';
                }

                field("Operation Group Code"; Rec."Operation Group Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає функціональну групу API та її path prefix.';
                }

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає логічний код операції.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає опис операції.';
                }

                field("HTTP Method"; Rec."HTTP Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає HTTP-метод операції.';
                }

                field("Relative Path"; Rec."Relative Path")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає шлях операції всередині групи. Якщо групу не задано, використовується як повний relative path.';
                }

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи дозволено виконувати операцію.';
                }

                field("Log Response Body"; Rec."Log Response Body")
                {
                    ApplicationArea = All;
                    ToolTip = 'Зберігати сире тіло HTTP-відповіді у записі журналу EDS. Увімкніть лише для операцій, відповіді яких не містять секретів або токенів.';
                }

                field("Async Retry Mode"; Rec."Async Retry Mode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи дозволено фоновому Worker повторювати цю саму операцію після HTTP 202. За замовчуванням повтор заборонений.';
                }

                field("Async Max Attempts"; Rec."Async Max Attempts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Максимальна кількість фонових HTTP-спроб для одного асинхронного запиту. Після досягнення ліміту запит завершується помилкою.';
                }
            }
        }
    }
}