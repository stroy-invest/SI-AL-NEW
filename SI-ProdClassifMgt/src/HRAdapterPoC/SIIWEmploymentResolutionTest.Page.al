page 56203 "SI IW HR - Resolution Test"
{
    PageType = List;
    SourceTable = "SI Employment Resolution";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'SI IW HR - Employment Resolution Test';

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
            }
            repeater(Result)
            {
                Editable = false;
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Context Date"; Rec."Context Date") { ApplicationArea = All; }
                field("Employee No."; Rec."Employee No.") { ApplicationArea = All; }
                field("Employee Name"; Rec."Employee Name") { ApplicationArea = All; }
                field("Active Context Count"; Rec."Active Context Count") { ApplicationArea = All; }
                field("Employment Context ID"; Rec."Employment Context ID") { ApplicationArea = All; }
                field("Employment Type"; Rec."Employment Type") { ApplicationArea = All; }
                field("Department Code"; Rec."Department Code") { ApplicationArea = All; }
                field("Department Name"; Rec."Department Name") { ApplicationArea = All; }
                field("Unit No."; Rec."Unit No.") { ApplicationArea = All; }
                field("Unit Name"; Rec."Unit Name") { ApplicationArea = All; }
                field("Position Code"; Rec."Position Code") { ApplicationArea = All; }
                field("Position Name"; Rec."Position Name") { ApplicationArea = All; }
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
                Caption = 'Resolve Employment';
                Image = Calculate;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ProviderType: Enum "SI Workforce Provider Type";
                    Provider: Interface "SI Workforce Provider";
                begin
                    Rec.Reset();
                    Rec.DeleteAll();
                    Clear(Rec);

                    ProviderType := ProviderType::IW;
                    Provider := ProviderType;
                    Provider.ResolveEmployment(EmployeeNo, ContextDate, Rec);

                    Rec.Reset();
                    Rec.FindFirst();
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
}
