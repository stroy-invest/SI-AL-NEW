page 50254 "SI Business Event Entries"
{
    Caption = 'Журнал бізнес-подій';
    PageType = List;
    SourceTable = "SI Business Event Entry";
    UsageCategory = History;
    ApplicationArea = All;
    Editable = false;
    CardPageId = "SI Business Event Entry";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає номер запису бізнес-події.';
                }

                field("Event Code"; Rec."Event Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає код опублікованої бізнес-події.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає поточний статус обробки бізнес-події.';
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час створення бізнес-події.';
                }

                field("Created By User ID"; Rec."Created By User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає користувача, який опублікував бізнес-подію.';
                }

                field("Source Module"; Rec."Source Module")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає модуль, із якого було опубліковано бізнес-подію.';
                }

                field("Source Record Caption"; Rec."Source Record Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає опис запису, для якого було опубліковано бізнес-подію.';
                }

                field("Notification Count"; Rec."Notification Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає кількість повідомлень, створених у результаті обробки події.';
                }

                field("Skipped Count"; Rec."Skipped Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає кількість отримувачів або повідомлень, пропущених під час обробки.';
                }

                field("Completed At"; Rec."Completed At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час завершення обробки бізнес-події.';
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
                ToolTip = 'Відкриває повідомлення, створені для вибраної бізнес-події.';

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