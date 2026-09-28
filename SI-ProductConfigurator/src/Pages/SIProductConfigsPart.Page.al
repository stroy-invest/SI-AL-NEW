page 53012 "SI Product Configs Part"
{
    PageType = ListPart;
    SourceTable = "SI Product Config.";
    ApplicationArea = All;
    Caption = 'Конфігурації продуктів';
    DelayedInsert = true;
    PopulateAllFields = true;

    SourceTableView =
        sorting(
            "Family Code",
            Status,
            "No.");

    layout
    {
        area(Content)
        {
            repeater(Configs)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає номер конфігурації продукту.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає згенеровану назву продукту.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає статус конфігурації.';
                }

                field("Validation Message"; Rec."Validation Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає результат останньої перевірки.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заблоковано конфігурацію.';
                }
            }
        }
    }

    procedure GetCurrentConfigurationNo(): Code[20]
    begin
        exit(Rec."No.");
    end;

    procedure RefreshPart()
    begin
        CurrPage.Update(false);
    end;
}