page 60016 "SI Employee Project Roles"
{
    PageType = List;
    SourceTable = "SI Employee Project Role";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Ролі працівника в будівельних проєктах';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Roles)
            {
                field("Role Code"; Rec."Role Code")
                {
                    ApplicationArea = All;
                    Caption = 'Код ролі';
                    ToolTip = 'Визначає допустиму роль працівника в будівельних проєктах.';
                }
                field(RoleDescription; RoleDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Назва ролі';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RefreshRoleDescription();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(RoleDescription);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        RefreshRoleDescription();
    end;

    local procedure RefreshRoleDescription()
    var
        ProjectRole: Record "SI Project Role";
    begin
        Clear(RoleDescription);
        if (Rec."Role Code" <> '') and ProjectRole.Get(Rec."Role Code") then
            RoleDescription := ProjectRole.Description;
    end;

    var
        RoleDescription: Text[100];
}
