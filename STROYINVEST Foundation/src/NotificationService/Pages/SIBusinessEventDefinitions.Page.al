page 50250 "SI Business Event Definitions"
{
    Caption = 'Визначення бізнес-подій';
    PageType = List;
    SourceTable = "SI Business Event Definition";
    UsageCategory = Administration;
    ApplicationArea = All;
    CardPageId = "SI Business Event Def. Card";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає унікальний код бізнес-події.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає опис бізнес-події.';
                }

                field("Source Module"; Rec."Source Module")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає прикладний модуль, який публікує бізнес-подію.';
                }

                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи дозволена обробка бізнес-події.';
                }

                field(Severity; Rec.Severity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає рівень важливості повідомлень, створених для бізнес-події.';
                }

                field("Recipient Group Code"; Rec."Recipient Group Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає групу отримувачів повідомлень для бізнес-події.';
                }

                field("Throttle Minutes"; Rec."Throttle Minutes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає мінімальний інтервал між однаковими повідомленнями.';
                }

                field("Allow Duplicate"; Rec."Allow Duplicate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи дозволено створення однакових повідомлень.';
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

                ToolTip = 'Відкриває журнал бізнес-подій для поточного визначення.';

                trigger OnAction()
                var
                    BusinessEventEntry: Record "SI Business Event Entry";
                begin
                    BusinessEventEntry.SetRange("Event Code", Rec.Code);
                    Page.Run(Page::"SI Business Event Entries", BusinessEventEntry);
                end;
            }
        }

        area(Promoted)
        {
            actionref(EventEntriesPromoted; EventEntries)
            {
            }
        }
    }
}