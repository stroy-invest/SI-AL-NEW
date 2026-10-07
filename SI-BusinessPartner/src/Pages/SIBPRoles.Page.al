page 54030 "SI BP Roles"
{
    PageType = List;
    SourceTable = "SI BP Role";

    Caption = 'Ролі контрагентів';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "SI BP Role Card";

    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }

                field("Business Partner Name"; Rec."Business Partner Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Відображає назву контрагента, якому належить роль.';
                }

                field("Role Type"; Rec."Role Type")
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }

                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }

                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                }

                field("Last Changed At"; Rec."Last Changed At")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteDraftRole)
            {
                Caption = 'Видалити роль';
                ApplicationArea = All;
                Image = Delete;
                Enabled = Rec.Status = Rec.Status::Draft;

                trigger OnAction()
                var
                    RoleMgt: Codeunit "SI BP Role Mgt.";
                    RoleCode: Code[30];
                begin
                    if not Confirm(
                        'Видалити роль %1? Цю дію неможливо скасувати.',
                        false,
                        Rec.Code)
                    then
                        exit;

                    RoleCode := Rec.Code;
                    RoleMgt.DeleteDraftRole(Rec);
                    Message('Роль %1 видалено.', RoleCode);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
