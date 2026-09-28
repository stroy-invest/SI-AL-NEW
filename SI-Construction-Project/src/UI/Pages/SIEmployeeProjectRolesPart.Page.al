page 60015 "SI Employee Project Roles Part"
{
    PageType = ListPart;
    SourceTable = "SI Employee Project Role";
    ApplicationArea = All;
    Caption = 'Ролі в будівельних проєктах';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Roles)
            {
                field(RoleDescription; RoleDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Роль';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
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
