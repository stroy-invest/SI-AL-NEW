page 50603 "SI Identity Resolver Test"
{
    PageType = Card;
    Caption = 'Тест визначення ідентичності';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(Input)
            {
                Caption = 'Вхідні дані';

                field(ContextDate; ContextDate)
                {
                    ApplicationArea = All;
                    Caption = 'Дата контексту';
                    ToolTip = 'Дата, на яку виконується визначення організаційної ідентичності.';
                }
                field(UserName; UserName)
                {
                    ApplicationArea = All;
                    Caption = 'Обліковий запис';
                    ToolTip = 'Обліковий запис Business Central для перевірки User + Date → Employee.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(SelectUser(Text));
                    end;
                }
                field(EmployeeName; EmployeeName)
                {
                    ApplicationArea = All;
                    Caption = 'Працівник';
                    ToolTip = 'Працівник для перевірки Employee + Purpose + Date → User.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(SelectEmployee(Text));
                    end;
                }
                field(PurposeCode; PurposeCode)
                {
                    ApplicationArea = All;
                    Caption = 'Функція облікового запису';
                    TableRelation = "SI User Identity Purpose".Code;
                    ToolTip = 'Бізнесова функція для визначення облікового запису працівника.';
                }
            }
            group(Result)
            {
                Caption = 'Результат';

                field(ResultStatus; ResultStatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Статус';
                    Editable = false;
                }
                field(ResolvedEmployee; ResolvedEmployeeName)
                {
                    ApplicationArea = All;
                    Caption = 'Визначений працівник';
                    Editable = false;
                }
                field(ResolvedUser; ResolvedUserName)
                {
                    ApplicationArea = All;
                    Caption = 'Визначений обліковий запис';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ResolveEmployee)
            {
                ApplicationArea = All;
                Caption = 'Визначити працівника';
                Image = Find;
                ToolTip = 'Викликає ResolveEmployee для вибраного облікового запису та дати контексту.';

                trigger OnAction()
                begin
                    RunResolveEmployee();
                end;
            }
            action(ResolveUser)
            {
                ApplicationArea = All;
                Caption = 'Визначити обліковий запис';
                Image = Find;
                ToolTip = 'Викликає ResolveUser для вибраного працівника, функції та дати контексту.';

                trigger OnAction()
                begin
                    RunResolveUser();
                end;
            }
            action(RequireEmployee)
            {
                ApplicationArea = All;
                Caption = 'Require: працівник';
                Image = Check;
                ToolTip = 'Викликає RequireEmployee. Для відсутнього або неоднозначного призначення очікується бізнес-помилка.';

                trigger OnAction()
                var
                    Employee: Record Employee;
                begin
                    EnsureUserInput();
                    IdentityMgt.RequireEmployee(UserSecurityId, ContextDate, Employee);
                    Message('RequireEmployee: OK. Працівник: %1.', Employee.FullName());
                end;
            }
            action(RequireUser)
            {
                ApplicationArea = All;
                Caption = 'Require: обліковий запис';
                Image = Check;
                ToolTip = 'Викликає RequireUser. Для відсутнього або неоднозначного призначення очікується бізнес-помилка.';

                trigger OnAction()
                var
                    UserRecord: Record User;
                begin
                    EnsureEmployeeInput();
                    IdentityMgt.RequireUser(EmployeeNo, PurposeCode, ContextDate, UserRecord);
                    Message('RequireUser: OK. Обліковий запис: %1.', UserRecord."User Name");
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ContextDate := WorkDate();
    end;

    local procedure RunResolveEmployee()
    var
        Employee: Record Employee;
        Status: Enum "SI Identity Resolve Status";
    begin
        EnsureUserInput();
        ClearResult();
        Status := IdentityMgt.ResolveEmployee(UserSecurityId, ContextDate, Employee);
        ResultStatusText := Format(Status);
        if Status = Status::Resolved then
            ResolvedEmployeeName := Employee.FullName();
    end;

    local procedure RunResolveUser()
    var
        UserRecord: Record User;
        Status: Enum "SI Identity Resolve Status";
    begin
        EnsureEmployeeInput();
        ClearResult();
        Status := IdentityMgt.ResolveUser(EmployeeNo, PurposeCode, ContextDate, UserRecord);
        ResultStatusText := Format(Status);
        if Status = Status::Resolved then
            ResolvedUserName := UserRecord."User Name";
    end;

    local procedure SelectUser(var SelectedText: Text): Boolean
    var
        UserRecord: Record User;
    begin
        if Page.RunModal(Page::Users, UserRecord) <> Action::LookupOK then
            exit(false);

        UserSecurityId := UserRecord."User Security ID";
        UserName := UserRecord."User Name";
        SelectedText := UserName;
        ClearResult();
        exit(true);
    end;

    local procedure SelectEmployee(var SelectedText: Text): Boolean
    var
        Employee: Record Employee;
    begin
        if Page.RunModal(Page::"Employee List", Employee) <> Action::LookupOK then
            exit(false);

        EmployeeNo := Employee."No.";
        EmployeeName := Employee.FullName();
        SelectedText := EmployeeName;
        ClearResult();
        exit(true);
    end;

    local procedure EnsureUserInput()
    begin
        if IsNullGuid(UserSecurityId) then
            Error('Виберіть обліковий запис.');
        if ContextDate = 0D then
            Error('Вкажіть дату контексту.');
    end;

    local procedure EnsureEmployeeInput()
    begin
        if EmployeeNo = '' then
            Error('Виберіть працівника.');
        if PurposeCode = '' then
            Error('Виберіть функцію облікового запису.');
        if ContextDate = 0D then
            Error('Вкажіть дату контексту.');
    end;

    local procedure ClearResult()
    begin
        Clear(ResultStatusText);
        Clear(ResolvedEmployeeName);
        Clear(ResolvedUserName);
    end;

    var
        IdentityMgt: Codeunit "SI Org. Identity Mgt.";
        UserSecurityId: Guid;
        UserName: Text[100];
        EmployeeNo: Code[20];
        EmployeeName: Text[100];
        PurposeCode: Code[50];
        ContextDate: Date;
        ResultStatusText: Text[50];
        ResolvedEmployeeName: Text[100];
        ResolvedUserName: Text[100];
}
