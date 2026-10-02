page 60013 "SI Project Roles"
{
    PageType = List;
    SourceTable = "SI Project Role";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Ролі будівельних проєктів';

    layout
    {
        area(Content)
        {
            repeater(Roles)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Assignment Cardinality"; Rec."Assignment Cardinality")
                {
                    ApplicationArea = All;
                }
                field("Assignment Scope"; Rec."Assignment Scope")
                {
                    ApplicationArea = All;
                }
                field("Required Capability Code"; Rec."Required Capability Code")
                {
                    ApplicationArea = All;
                }
                field("Require Primary"; Rec."Require Primary")
                {
                    ApplicationArea = All;
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
    begin
        AssignmentMgt.EnsureDefaultRoles();
    end;
}
