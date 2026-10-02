page 50601 "SI User Identity Assignments"
{
    PageType = List;
    SourceTable = "SI User Identity Assignment";
    Caption = 'Призначення облікових записів';
    ApplicationArea = All;
    UsageCategory = Administration;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(EmployeeName; EmployeeName)
                {
                    ApplicationArea = All;
                    Caption = 'Працівник';
                    ToolTip = 'Працівник, якому призначено обліковий запис Business Central.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(SelectEmployee(Text));
                    end;
                }
                field(UserName; UserName)
                {
                    ApplicationArea = All;
                    Caption = 'Обліковий запис';
                    ToolTip = 'Обліковий запис Business Central, який у визначений період представляє працівника.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(SelectUser(Text));
                    end;
                }
                field("Purpose Code"; Rec."Purpose Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Бізнесова функція, для якої використовується цей зв''язок працівника з обліковим записом.';

                    trigger OnValidate()
                    begin
                        LoadPurposeDescription();
                    end;
                }
                field(PurposeDescription; PurposeDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Назва функції';
                    Editable = false;
                    ToolTip = 'Назва бізнесової функції облікового запису.';
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = All;
                    ToolTip = 'Перший день чинності призначення.';
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = All;
                    ToolTip = 'Останній день чинності призначення. Порожнє значення означає безстрокове призначення.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Технічний номер запису призначення.';
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
        Clear(EmployeeName);
        Clear(UserName);
        Clear(PurposeDescription);
    end;

    local procedure SelectEmployee(var SelectedText: Text): Boolean
    var
        Employee: Record Employee;
    begin
        if Page.RunModal(Page::"Employee List", Employee) <> Action::LookupOK then
            exit(false);

        Rec.Validate("Employee No.", Employee."No.");
        EmployeeName := Employee.FullName();
        SelectedText := EmployeeName;
        exit(true);
    end;

    local procedure SelectUser(var SelectedText: Text): Boolean
    var
        UserRecord: Record User;
    begin
        if Page.RunModal(Page::Users, UserRecord) <> Action::LookupOK then
            exit(false);

        Rec.Validate("User Security ID", UserRecord."User Security ID");
        UserName := UserRecord."User Name";
        SelectedText := UserName;
        exit(true);
    end;

    local procedure LoadDisplayValues()
    var
        Employee: Record Employee;
        UserRecord: Record User;
    begin
        Clear(EmployeeName);
        Clear(UserName);
        Clear(PurposeDescription);

        if Rec."Employee No." <> '' then
            if Employee.Get(Rec."Employee No.") then
                EmployeeName := Employee.FullName();

        if not IsNullGuid(Rec."User Security ID") then
            if UserRecord.Get(Rec."User Security ID") then
                UserName := UserRecord."User Name";

        LoadPurposeDescription();
    end;

    local procedure LoadPurposeDescription()
    var
        Purpose: Record "SI User Identity Purpose";
    begin
        Clear(PurposeDescription);

        if Rec."Purpose Code" <> '' then
            if Purpose.Get(Rec."Purpose Code") then
                PurposeDescription := Purpose.Description;
    end;

    var
        EmployeeName: Text[100];
        UserName: Text[100];
        PurposeDescription: Text[100];
}
