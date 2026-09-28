page 59002 "SI WB Inbound Runner"
{
    PageType = List;
    SourceTable = "SI EDS Inbound Event";

    ApplicationArea = All;
    UsageCategory = Administration;

    Caption = 'Ваги: ручна обробка вхідних подій';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Events)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }

                field("Service Code"; Rec."Service Code")
                {
                    ApplicationArea = All;
                }

                field("Event ID"; Rec."Event ID")
                {
                    ApplicationArea = All;
                }

                field("Event Type"; Rec."Event Type")
                {
                    ApplicationArea = All;
                }

                field("Source System"; Rec."Source System")
                {
                    ApplicationArea = All;
                }

                field("Source Record ID"; Rec."Source Record ID")
                {
                    ApplicationArea = All;
                }

                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }

                field("Processing Started At"; Rec."Processing Started At")
                {
                    ApplicationArea = All;
                }

                field("Processed At"; Rec."Processed At")
                {
                    ApplicationArea = All;
                }

                field("Processing Attempt Count"; Rec."Processing Attempt Count")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProcessSelected)
            {
                ApplicationArea = All;
                Caption = 'Обробити вибрану подію';

                trigger OnAction()
                var
                    Processor: Codeunit "SI WB Inbound Processor";
                begin
                    if Rec.Status <> Rec.Status::Accepted then
                        Error(
                            'Для звичайної обробки подія повинна мати статус Accepted.');

                    Processor.ProcessSingleEvent(
                        Rec."Entry No.");

                    CurrPage.Update(false);
                end;
            }

            action(RetrySelected)
            {
                ApplicationArea = All;
                Caption = 'Повторити помилкову подію';

                trigger OnAction()
                var
                    Processor: Codeunit "SI WB Inbound Processor";
                begin
                    if Rec.Status <> Rec.Status::Error then
                        Error(
                            'Повторна обробка доступна лише для подій зі статусом Error.');

                    Processor.RetrySingleEvent(
                        Rec."Entry No.");

                    CurrPage.Update(false);
                end;
            }

            action(ProcessServiceBacklog)
            {
                ApplicationArea = All;
                Caption = 'Обробити чергу сервісу';

                trigger OnAction()
                var
                    Processor: Codeunit "SI WB Inbound Processor";
                    ServiceCode: Code[50];
                    AttemptedCount: Integer;
                begin
                    ServiceCode := Rec."Service Code";

                    if ServiceCode = '' then
                        Error(
                            'Service Code не визначено.');

                    if not Confirm(
                        'Обробити до 100 необроблених завершених зважувань сервісу %1?',
                        false,
                        ServiceCode)
                    then
                        exit;

                    AttemptedCount :=
                        Processor.ProcessAcceptedEvents(
                            ServiceCode,
                            100);

                    Message(
                        'Обробку завершено. Опрацьовано подій: %1.',
                        AttemptedCount);

                    CurrPage.Update(false);
                end;
            }
        }

        area(Navigation)
        {
            action(OpenWeighingRecords)
            {
                ApplicationArea = All;
                Caption = 'Зважування';

                trigger OnAction()
                begin
                    Page.Run(
                        Page::"SI Weighing Records");
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Manual runner deliberately works only with final weighing events.
        // FIRST_WEIGHING_RECORDED remains untouched in raw EDS storage.

        Rec.SetRange(
            "Event Type",
            'WEIGHING_COMPLETED');

        Rec.SetFilter(
            Status,
            '%1|%2',
            Rec.Status::Accepted,
            Rec.Status::Error);
    end;
}