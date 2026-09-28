page 50255 "SI Business Event Entry"
{
    Caption = 'Бізнес-подія';
    PageType = Card;
    SourceTable = "SI Business Event Entry";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає номер запису бізнес-події.';
                }

                field("Event Code"; Rec."Event Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає код бізнес-події.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає статус обробки бізнес-події.';
                }

                field("Source Module"; Rec."Source Module")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає модуль-джерело бізнес-події.';
                }

                field("Payload Schema Version"; Rec."Payload Schema Version")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає версію структури додаткових даних події.';
                }
            }

            group(Source)
            {
                Caption = 'Джерело';

                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає компанію, у якій було створено бізнес-подію.';
                }

                field("Source Table ID"; Rec."Source Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає ID таблиці запису-джерела.';
                }

                field("Source Record ID"; Rec."Source Record ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає ідентифікатор запису-джерела.';
                }

                field("Source System ID"; Rec."Source System ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає системний ідентифікатор запису-джерела.';
                }

                field("Source Record Caption"; Rec."Source Record Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає опис запису-джерела.';
                }
            }

            group(Correlation)
            {
                Caption = 'Кореляція';

                field("Correlation ID"; Rec."Correlation ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає ідентифікатор, що об’єднує пов’язані операції та події.';
                }

                field("Parent Event Entry No."; Rec."Parent Event Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає номер батьківської бізнес-події.';
                }
            }

            group(Processing)
            {
                Caption = 'Обробка';

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час створення бізнес-події.';
                }

                field("Created By User ID"; Rec."Created By User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає користувача, який створив бізнес-подію.';
                }

                field("Created By Security ID"; Rec."Created By Security ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає системний ідентифікатор користувача, який створив подію.';
                }

                field("Processing Started At"; Rec."Processing Started At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час початку обробки бізнес-події.';
                }

                field("Completed At"; Rec."Completed At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час завершення обробки бізнес-події.';
                }

                field("Notification Count"; Rec."Notification Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає кількість створених повідомлень.';
                }

                field("Skipped Count"; Rec."Skipped Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає кількість пропущених отримувачів або повідомлень.';
                }

                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Визначає повідомлення про помилку обробки бізнес-події.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NotificationEntries)
            {
                Caption = 'Створені повідомлення';
                ApplicationArea = All;
                Image = Alerts;
                ToolTip = 'Відкриває повідомлення, створені для цієї бізнес-події.';

                trigger OnAction()
                var
                    NotificationEntry: Record "SI Notification Entry";
                begin
                    NotificationEntry.SetRange(
                        "Event Entry No.",
                        Rec."Entry No.");

                    Page.Run(
                        Page::"SI Notification Entries",
                        NotificationEntry);
                end;
            }
        }

        area(Promoted)
        {
            actionref(NotificationEntriesPromoted; NotificationEntries)
            {
            }
        }
    }
}