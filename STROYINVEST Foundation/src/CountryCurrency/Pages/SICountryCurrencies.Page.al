page 50194 "SI Country Currencies"
{
    PageType = List;
    SourceTable = "SI Country Currency";

    Caption = 'Валюти країн';
    ApplicationArea = All;
    UsageCategory = Administration;

    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає країну або регіон, для якого налаштовується валюта.';
                }

                field("Country/Region Name"; Rec."Country/Region Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Відображає назву вибраної країни або регіону.';
                }

                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає валюту, пов’язану з країною або регіоном.';
                }

                field("Currency Description"; Rec."Currency Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Відображає назву вибраної валюти.';
                }

                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає пріоритет валюти для країни. Значення 1 означає найвищий пріоритет.';
                }
            }
        }
    }
}