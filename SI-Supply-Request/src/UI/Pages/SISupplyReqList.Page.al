page 61003 "SI Supply Req List"
{
    PageType = List;
    SourceTable = "SI Supply Req Header";
    CardPageId = "SI Supply Req Card";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Заявки на забезпечення';

    layout
    {
        area(Content)
        {
            repeater(Requests)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Request Type"; Rec."Request Type") { ApplicationArea = All; }
                field("Request Profile"; Rec."Request Profile") { ApplicationArea = All; }
                field("Project No."; Rec."Project No.") { ApplicationArea = All; }
                field("Project Location Code"; Rec."Project Location Code") { ApplicationArea = All; }
                field("Required on Site At"; Rec."Required on Site At") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Requested By User ID"; Rec."Requested By User ID") { ApplicationArea = All; }
            }
        }
    }


    actions
    {
        area(Processing)
        {
            action(PullSchriftRequests)
            {
                ApplicationArea = All;
                Caption = 'Синхронізувати заявки Schrift';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SchriftIntake: Codeunit "SI Schrift Intake Mgt.";
                    CreatedCount: Integer;
                    UpdatedCount: Integer;
                    UnchangedCount: Integer;
                    SkippedCount: Integer;
                begin
                    SchriftIntake.SynchronizeApprovedRequests(CreatedCount, UpdatedCount, UnchangedCount, SkippedCount);
                    CurrPage.Update(false);
                    Message('Синхронізацію Schrift завершено. Створено: %1. Оновлено/конфліктів: %2. Без змін: %3. Пропущено: %4.', CreatedCount, UpdatedCount, UnchangedCount, SkippedCount);
                end;
            }
        }
    }
}
