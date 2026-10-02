page 51003 "SI IW Workforce Test"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'SI IW HR - Workforce Test';

    layout
    {
        area(Content)
        {
            group(TestParameters)
            {
                Caption = 'Test Parameters';
                field(EmployeeNo; EmployeeNo)
                {
                    ApplicationArea = All;
                    Caption = 'BC Employee No.';
                    TableRelation = Employee."No.";
                }
                field(ContextDate; ContextDate)
                {
                    ApplicationArea = All;
                    Caption = 'Context Date';
                }
                field(CapabilityCode; CapabilityCode)
                {
                    ApplicationArea = All;
                    Caption = 'Workforce Capability';
                    TableRelation = "SI Workforce Capability".Code where(Active = const(true));
                }
            }
            group(EmploymentResult)
            {
                Caption = 'Employment Resolution';
                field(EmploymentStatus; EmploymentStatus) { ApplicationArea = All; Editable = false; }
                field(ActiveContextCount; ActiveContextCount) { ApplicationArea = All; Editable = false; }
                field(EmploymentContextID; EmploymentContextID) { ApplicationArea = All; Editable = false; }
                field(DepartmentName; DepartmentName) { ApplicationArea = All; Editable = false; }
                field(UnitName; UnitName) { ApplicationArea = All; Editable = false; }
                field(PositionName; PositionName) { ApplicationArea = All; Editable = false; }
            }
            group(CapabilityResult)
            {
                Caption = 'Capability Resolution';
                field(CapabilityStatus; CapabilityStatus) { ApplicationArea = All; Editable = false; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ResolveEmployment)
            {
                ApplicationArea = All;
                Caption = 'Resolve Employment';
                Image = Calculate;
                trigger OnAction()
                var
                    WorkforceMgt: Codeunit "SI Workforce Mgt.";
                    Resolution: Record "SI Employment Resolution" temporary;
                begin
                    ClearEmploymentResult();
                    EmploymentStatus := WorkforceMgt.ResolveEmployment(EmployeeNo, ContextDate, Resolution);
                    if Resolution.FindFirst() then begin
                        ActiveContextCount := Resolution."Active Context Count";
                        EmploymentContextID := Resolution."Employment Context ID";
                        DepartmentName := Resolution."Department Name";
                        UnitName := Resolution."Unit Name";
                        PositionName := Resolution."Position Name";
                    end;
                    CurrPage.Update(false);
                end;
            }
            action(ResolveCapability)
            {
                ApplicationArea = All;
                Caption = 'Resolve Capability';
                Image = Calculate;
                trigger OnAction()
                var
                    WorkforceMgt: Codeunit "SI Workforce Mgt.";
                begin
                    CapabilityStatus := WorkforceMgt.ResolveCapability(EmployeeNo, ContextDate, CapabilityCode);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ContextDate := WorkDate();
    end;

    local procedure ClearEmploymentResult()
    begin
        Clear(ActiveContextCount);
        Clear(EmploymentContextID);
        Clear(DepartmentName);
        Clear(UnitName);
        Clear(PositionName);
    end;

    var
        EmployeeNo: Code[20];
        ContextDate: Date;
        CapabilityCode: Code[20];
        EmploymentStatus: Enum "SI Employment Resolve Status";
        CapabilityStatus: Enum "SI Capability Resolve Status";
        ActiveContextCount: Integer;
        EmploymentContextID: Code[20];
        DepartmentName: Text[100];
        UnitName: Text[250];
        PositionName: Text[250];
}
