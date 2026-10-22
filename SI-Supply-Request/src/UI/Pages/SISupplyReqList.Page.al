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
            action(AdminForceDelete)
            {
                ApplicationArea = All;
                Caption = 'Примусово видалити заявку';
                ToolTip = 'Адміністративне видалення без рішення щодо забезпечення. Лише SUPER.';
                Image = Delete;
                Visible = IsSuperUser;
                trigger OnAction()
                var
                    AdminMgt: Codeunit "SI Supply Req Admin Delete";
                begin
                    AdminMgt.CheckSuperPermission();
                    if not Confirm('Безповоротно видалити заявку %1 та її рядки? Дію буде записано до журналу.', false, Rec."No.") then
                        exit;
                    Rec.AdminForceDelete();
                    CurrPage.Update(false);
                end;
            }

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
    trigger OnOpenPage()
    var
        Access: Record "Access Control";
    begin
        IsSuperUser := false;
        Access.SetRange("User Security ID", UserSecurityId());
        Access.SetRange("Role ID", 'SUPER');
        if Access.FindSet() then
            repeat
                if (Access."Company Name" = '') or (Access."Company Name" = CompanyName()) then
                    IsSuperUser := true;
            until Access.Next() = 0;
    end;

    var
        IsSuperUser: Boolean;

}
