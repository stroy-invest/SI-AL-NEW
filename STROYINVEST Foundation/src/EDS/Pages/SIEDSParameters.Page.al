page 50455 "SI EDS Parameters"
{
    PageType = List;
    SourceTable = "SI EDS Parameter";
    Caption = 'EDS: параметри';
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
                    ToolTip = 'Визначає сервіс параметра.';
                }

                field("Operation Code"; Rec."Operation Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає операцію параметра.';
                }

                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає провайдера, для якого використовується параметр.';
                }

                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає порядок формування параметрів.';
                }

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає внутрішній код метадата-сеттингу параметра.';
                }

                field("External Name"; Rec."External Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає точне зовнішнє ім''я параметра API з урахуванням регістру символів.';
                }

                field(Location; Rec.Location)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає розташування параметра у HTTP-запиті.';
                }

                field(Source; Rec.Source)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи значення фіксоване в метадата-сеттингах, чи передається під час виконання.';
                }

                field(Format; Rec.Format)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає формат параметра у запиті.';
                }

                field("Runtime Key"; Rec."Runtime Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає канонічний ключ runtime-значення.';
                }

                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає фіксоване значення параметра.';
                }

                field(Required; Rec.Required)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи runtime-параметр обов''язковий.';
                }

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи параметр активний. Перед увімкненням система перевіряє обов''язкові налаштування.';
                }
            }
        }
    }
}