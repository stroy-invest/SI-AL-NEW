page 57210 "SI Prok Operations Setup"
{
    PageType = Card;
    SourceTable = "SI Prok Operations Setup";
    Caption = 'Операційні налаштування Proktek';
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Профіль';
                field("Connection Code"; Rec."Connection Code") { ApplicationArea = All; Editable = false; }
            }
            group(Synchronization)
            {
                Caption = 'Автоматичне отримання фактів';
                field("Sync Enabled"; Rec."Sync Enabled") { ApplicationArea = All; }
                field("Sync Interval Minutes"; Rec."Sync Interval Minutes") { ApplicationArea = All; }
                field("Sync Lookback Days"; Rec."Sync Lookback Days") { ApplicationArea = All; }
            }
            group(Processing)
            {
                Caption = 'Облік після фіксації відвантаження';
                Visible = false; // PROD-safe: Processing Mode is ignored while accounting is fenced.
                field("Processing Mode"; Rec."Processing Mode") { ApplicationArea = All; Editable = true; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ApplyJobQueue)
            {
                Caption = 'Налаштувати Job Queue';
                ApplicationArea = All;
                Image = Setup;
                trigger OnAction()
                var
                    Schedule: Codeunit "SI Prok Sync Schedule";
                begin
                    CurrPage.SaveRecord();
                    Schedule.Apply(Rec."Connection Code");
                    Message('Job Queue налаштовано. Отримання фактів використовує стандартний SI Prok Capture Mgt.');
                end;
            }
        }
    }
}
