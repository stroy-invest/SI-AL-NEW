page 50257 "SI Notification Entry"
{
    Caption = 'Повідомлення користувача';
    PageType = Card;
    SourceTable = "SI Notification Entry";
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
                    ToolTip = 'Визначає номер запису повідомлення.';
                }

                field(Title; Rec.Title)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає заголовок повідомлення.';
                }

                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Визначає текст повідомлення.';
                }

                field(Severity; Rec.Severity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає рівень важливості повідомлення.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає поточний статус повідомлення.';
                }
            }

            group(Recipient)
            {
                Caption = 'Отримувач';

                field("Recipient User Name"; Rec."Recipient User Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає ім’я користувача-отримувача.';
                }

                field("Recipient Security ID"; Rec."Recipient Security ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає системний ідентифікатор користувача-отримувача.';
                }

                field("Recipient Group Code"; Rec."Recipient Group Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає групу, через яку було визначено отримувача.';
                }

                field("Resolver Trace"; Rec."Resolver Trace")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Визначає технічне пояснення того, як було визначено отримувача.';
                }
            }

            group(BusinessEvent)
            {
                Caption = 'Бізнес-подія';

                field("Event Entry No."; Rec."Event Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає номер бізнес-події, яка спричинила створення повідомлення.';
                }

                field("Event Code"; Rec."Event Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає код бізнес-події.';
                }

                field(Fingerprint; Rec.Fingerprint)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає технічний відбиток, що використовується для контролю повторних повідомлень.';
                }
            }

            group(Source)
            {
                Caption = 'Джерело';

                field("Source Table ID"; Rec."Source Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає ID таблиці пов’язаного запису.';
                }

                field("Source Record ID"; Rec."Source Record ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає ідентифікатор пов’язаного запису.';
                }

                field("Source System ID"; Rec."Source System ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає системний ідентифікатор пов’язаного запису.';
                }

                field("Source Record Caption"; Rec."Source Record Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає опис пов’язаного запису.';
                }

                field("Target Page ID"; Rec."Target Page ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає ID сторінки, яку потрібно відкрити для перегляду пов’язаного запису.';
                }

                field("Action Caption"; Rec."Action Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає назву дії переходу до пов’язаного запису.';
                }
            }

            group(Lifecycle)
            {
                Caption = 'Життєвий цикл';

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час створення повідомлення.';
                }

                field("Read At"; Rec."Read At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час прочитання повідомлення.';
                }

                field("Dismissed At"; Rec."Dismissed At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час приховування повідомлення.';
                }

                field("Expires At"; Rec."Expires At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час завершення строку дії повідомлення.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenSourceRecord)
            {
                Caption = 'Відкрити пов’язаний запис';
                ApplicationArea = All;
                Image = Navigate;
                Enabled = Rec."Target Page ID" <> 0;
                ToolTip = 'Відкриває бізнес-об’єкт, пов’язаний із повідомленням.';

                trigger OnAction()
                var
                    NotificationActionMgt: Codeunit "SI Notification Action Mgt.";
                begin
                    NotificationActionMgt.OpenSourceRecord(Rec);
                end;
            }
        }

        area(Promoted)
        {
            actionref(OpenSourceRecordPromoted; OpenSourceRecord)
            {
            }
        }
    }
}