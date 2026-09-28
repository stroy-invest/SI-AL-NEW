pageextension 60001 "SI Employee Card Ext." extends "Employee Card"
{
    layout
    {
        addlast(FactBoxes)
        {
            part(SIProjectRoles; "SI Employee Project Roles Part")
            {
                ApplicationArea = All;
                Caption = 'Ролі в будівельних проєктах';
                SubPageLink = "Employee No." = field("No.");
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(SIManageProjectRoles)
            {
                ApplicationArea = All;
                Caption = 'Ролі в будівельних проєктах';
                ToolTip = 'Відкриває список допустимих ролей працівника в будівельних проєктах.';
                Image = ResourcePlanning;

                trigger OnAction()
                var
                    EmployeeProjectRole: Record "SI Employee Project Role";
                begin
                    Rec.TestField("No.");
                    EmployeeProjectRole.SetRange("Employee No.", Rec."No.");
                    Page.RunModal(Page::"SI Employee Project Roles", EmployeeProjectRole);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
