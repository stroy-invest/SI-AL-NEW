page 60021 "SI Site Assignments Part"
{
    PageType = ListPart;
    SourceTable = "SI Site Assignment";
    ApplicationArea = All;
    Caption = 'Виконроби';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Foremen)
            {
                field(EmployeeDisplayName; EmployeeDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Виконроб';
                    Lookup = true;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupEmployee(Text));
                    end;
                }
                field("Valid From"; Rec."Valid From") { ApplicationArea = All; }
                field("Valid To"; Rec."Valid To") { ApplicationArea = All; }
                field(Primary; Rec.Primary)
                {
                    ApplicationArea = All;
                    Caption = 'Основний';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Role Code" := 'FOREMAN';
        if Rec."Valid From" = 0D then
            Rec."Valid From" := WorkDate();
        Clear(EmployeeDisplayName);
    end;

    trigger OnAfterGetRecord()
    var
        Employee: Record Employee;
    begin
        Clear(EmployeeDisplayName);
        if (Rec."Employee No." <> '') and Employee.Get(Rec."Employee No.") then
            EmployeeDisplayName := Employee.FullName();
    end;

    local procedure LookupEmployee(var LookupText: Text): Boolean
    var
        Employee: Record Employee;
        EmployeeProjectRole: Record "SI Employee Project Role";
        EmployeeList: Page "Employee List";
        HasEligibleEmployees: Boolean;
    begin
        EmployeeProjectRole.SetRange("Role Code", 'FOREMAN');
        if EmployeeProjectRole.FindSet() then
            repeat
                if Employee.Get(EmployeeProjectRole."Employee No.") then begin
                    Employee.Mark(true);
                    HasEligibleEmployees := true;
                end;
            until EmployeeProjectRole.Next() = 0;

        if not HasEligibleEmployees then
            Error('Для ролі "Виконроб" не налаштовано жодного допустимого працівника.');

        Employee.MarkedOnly(true);
        EmployeeList.SetTableView(Employee);
        EmployeeList.LookupMode(true);
        if EmployeeList.RunModal() <> Action::LookupOK then
            exit(false);

        EmployeeList.GetRecord(Employee);
        Rec.Validate("Employee No.", Employee."No.");
        CurrPage.SaveRecord();
        EmployeeDisplayName := Employee.FullName();
        LookupText := EmployeeDisplayName;
        exit(true);
    end;

    var
        EmployeeDisplayName: Text[100];
}
