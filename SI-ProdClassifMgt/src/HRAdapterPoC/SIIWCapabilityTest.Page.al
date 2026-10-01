page 56205 "SI IW Capability Test"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'SI IW HR - Capability Test';

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
                field(RoleCode; RoleCode)
                {
                    ApplicationArea = All;
                    Caption = 'SI Project Role';
                    TableRelation = "SI Project Role".Code where(Active = const(true));
                }
            }
            group(Result)
            {
                Caption = 'Result';

                field(ResultStatus; ResultStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Capability Status';
                    Editable = false;
                }
                field(Granted; Granted)
                {
                    ApplicationArea = All;
                    Caption = 'Granted';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Resolve)
            {
                ApplicationArea = All;
                Caption = 'Resolve Capability';
                Image = Calculate;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    CapabilityResolver: Codeunit "SI IW Capability Resolver";
                begin
                    ResultStatus := CapabilityResolver.ResolveProjectRole(EmployeeNo, ContextDate, RoleCode);
                    Granted := ResultStatus = ResultStatus::Granted;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ContextDate := WorkDate();
    end;

    var
        EmployeeNo: Code[20];
        ContextDate: Date;
        RoleCode: Code[20];
        ResultStatus: Enum "SI Capability Resolve Status";
        Granted: Boolean;
}
