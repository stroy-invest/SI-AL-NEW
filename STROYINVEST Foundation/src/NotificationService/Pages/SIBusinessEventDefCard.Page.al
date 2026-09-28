page 50251 "SI Business Event Def. Card"
{
    Caption = 'Визначення бізнес-події';
    PageType = Card;
    SourceTable = "SI Business Event Definition";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає унікальний код бізнес-події.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає зрозумілий опис бізнес-події.';
                }

                field("Source Module"; Rec."Source Module")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає прикладний модуль, який публікує бізнес-подію.';
                }

                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи дозволена обробка цієї бізнес-події.';
                }

                field(Severity; Rec.Severity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає стандартний рівень важливості повідомлення.';
                }
            }

            group(Delivery)
            {
                Caption = 'Доставка';

                field("Recipient Group Code"; Rec."Recipient Group Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає групу отримувачів повідомлення.';
                }

                field("Title Template"; Rec."Title Template")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Визначає шаблон заголовка повідомлення.';
                }

                field("Message Template"; Rec."Message Template")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Визначає шаблон тексту повідомлення.';
                }

                field("Action Caption Template"; Rec."Action Caption Template")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Визначає шаблон назви дії для переходу до пов’язаного запису.';
                }

                field("Target Page ID"; Rec."Target Page ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає ID сторінки, яка відкриється для пов’язаного запису.';
                }
            }

            group(Control)
            {
                Caption = 'Керування обробкою';

                field("Throttle Minutes"; Rec."Throttle Minutes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає мінімальний інтервал у хвилинах між однаковими повідомленнями.';
                }

                field("Allow Duplicate"; Rec."Allow Duplicate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи дозволено створювати однакові повідомлення без обмеження частоти.';
                }

                field("Retention Days"; Rec."Retention Days")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає строк зберігання даних події у днях.';
                }

                field("Payload Schema Version"; Rec."Payload Schema Version")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає версію структури додаткових даних бізнес-події.';
                }
            }

            group(Audit)
            {
                Caption = 'Аудит';

                field("Last Modified At"; Rec."Last Modified At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час останньої зміни запису.';
                }

                field("Last Modified By"; Rec."Last Modified By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає користувача, який останнім змінив запис.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EventEntries)
            {
                Caption = 'Журнал подій';
                ApplicationArea = All;
                Image = Log;
                ToolTip = 'Відкриває журнал подій, опублікованих із цим кодом.';

                trigger OnAction()
                var
                    BusinessEventEntry: Record "SI Business Event Entry";
                begin
                    BusinessEventEntry.SetRange("Event Code", Rec.Code);
                    Page.Run(Page::"SI Business Event Entries", BusinessEventEntry);
                end;
            }

            action(PublishTestEvent)
            {
                Caption = 'Опублікувати тестову подію';
                ApplicationArea = All;
                Image = TestReport;
                ToolTip = 'Публікує тестову бізнес-подію для перевірки роботи сервісу повідомлень.';

                trigger OnAction()
                var
                    NotificationTestMgt: Codeunit "SI Notification Test Mgt.";
                begin
                    CurrPage.SaveRecord();

                    NotificationTestMgt.PublishTestEvent(Rec);
                end;
            }
        }

        area(Promoted)
        {
            actionref(EventEntriesPromoted; EventEntries)
            {
            }

            actionref(PublishTestEventPromoted; PublishTestEvent)
            {
            }
        }
    }
}