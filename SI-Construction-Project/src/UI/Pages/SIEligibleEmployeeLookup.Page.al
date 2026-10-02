page 60023 "SI Eligible Employee Lookup"
{
    PageType = List;
    SourceTable = "SI Eligible Employee";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Caption = 'Виберіть співробітника';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Employees)
            {
                field("Last Name"; Rec."Last Name") { ApplicationArea = All; }
                field("First Name"; Rec."First Name") { ApplicationArea = All; }
                field("Middle Name"; Rec."Middle Name") { ApplicationArea = All; }
                field("Position Name"; Rec."Position Name") { ApplicationArea = All; }
            }
        }
    }

    procedure LoadEligible(RoleCode: Code[20]; ContextDate: Date)
    var
        Employee: Record Employee;
        Resolution: Record "SI Employment Resolution" temporary;
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
        WorkforceMgt: Codeunit "SI Workforce Mgt.";
        ResolveStatus: Enum "SI Employment Resolve Status";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if ContextDate = 0D then
            ContextDate := WorkDate();

        if not AssignmentMgt.CollectEligibleEmployees(RoleCode, ContextDate, Employee) then
            exit;

        if Employee.FindSet() then
            repeat
                Rec.Init();
                Rec."Employee No." := Employee."No.";
                Rec."Last Name" := Employee."Last Name";
                Rec."First Name" := Employee."First Name";
                Rec."Middle Name" := Employee."Middle Name";

                Clear(Resolution);
                ResolveStatus := WorkforceMgt.ResolveEmployment(Employee."No.", ContextDate, Resolution);
                if ResolveStatus = ResolveStatus::Resolved then begin
                    Resolution.FindFirst();
                    Rec."Position Name" := Resolution."Position Name";
                end;

                Rec.Insert();
            until Employee.Next() = 0;

        Rec.SetCurrentKey("Last Name", "First Name", "Middle Name");
        if Rec.FindFirst() then;
    end;

    procedure GetSelectedEmployeeNo(): Code[20]
    begin
        exit(Rec."Employee No.");
    end;
}
