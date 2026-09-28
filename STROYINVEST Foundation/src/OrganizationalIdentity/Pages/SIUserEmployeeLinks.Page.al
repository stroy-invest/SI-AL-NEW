page 50601 "SI User Employee Links"
{
    PageType = List;
    SourceTable = "SI User Employee Link";
    Caption = 'Зв''язки користувачів і працівників';
    ApplicationArea = All;
    UsageCategory = Administration;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(UserName; UserName)
                {
                    ApplicationArea = All;
                    Caption = 'Користувач';
                    ToolTip = 'Користувач Business Central, пов''язаний із працівником. Можна вибрати зі списку або ввести точне ім''я користувача.';

                    trigger OnValidate()
                    begin
                        ValidateUserName();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(SelectUser(Text));
                    end;
                }
                field(UserFullName; UserFullName)
                {
                    ApplicationArea = All;
                    Caption = 'ПІБ користувача';
                    Editable = false;
                    ToolTip = 'Повне ім''я користувача Business Central.';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Працівник, який є бізнесовою ідентичністю вибраного користувача Business Central.';
                }
                field(EmployeeName; EmployeeName)
                {
                    ApplicationArea = All;
                    Caption = 'Працівник';
                    Editable = false;
                    ToolTip = 'Повне ім''я працівника.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadDisplayValues();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(UserName);
        Clear(UserFullName);
        Clear(EmployeeName);
    end;

    local procedure SelectUser(var SelectedText: Text): Boolean
    var
        UserRecord: Record User;
    begin
        if Page.RunModal(Page::Users, UserRecord) <> Action::LookupOK then
            exit(false);

        Rec.Validate("User Security ID", UserRecord."User Security ID");
        UserName := UserRecord."User Name";
        UserFullName := UserRecord."Full Name";
        SelectedText := UserName;
        CurrPage.Update(false);
        exit(true);
    end;


    local procedure ValidateUserName()
    var
        UserRecord: Record User;
    begin
        if UserName = '' then begin
            Clear(Rec."User Security ID");
            Clear(UserFullName);
            exit;
        end;

        UserRecord.SetRange("User Name", UserName);
        if not UserRecord.FindFirst() then
            Error(UserNameNotFoundErr, UserName);

        Rec.Validate("User Security ID", UserRecord."User Security ID");
        UserName := UserRecord."User Name";
        UserFullName := UserRecord."Full Name";
    end;

    local procedure LoadDisplayValues()
    var
        UserRecord: Record User;
        Employee: Record Employee;
    begin
        Clear(UserName);
        Clear(UserFullName);
        Clear(EmployeeName);

        if not IsNullGuid(Rec."User Security ID") then
            if UserRecord.Get(Rec."User Security ID") then begin
                UserName := UserRecord."User Name";
                UserFullName := UserRecord."Full Name";
            end;

        if Rec."Employee No." <> '' then
            if Employee.Get(Rec."Employee No.") then
                EmployeeName := Employee.FullName();
    end;

    var
        UserName: Text[100];
        UserFullName: Text[100];
        EmployeeName: Text[100];
        UserNameNotFoundErr: Label 'Користувача Business Central з ім''ям %1 не знайдено.', Comment = '%1 = User Name';
}
