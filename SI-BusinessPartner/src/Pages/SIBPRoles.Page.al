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

                field("ERP Template Code"; Rec."ERP Template Code")
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
            action(CreateRole)
            {
                Caption = 'Створити роль';
                ApplicationArea = All;
                Image = New;

                trigger OnAction()
                var
                    CreateDialog: Page "SI BP Role Create Dialog";
                    RoleMgt: Codeunit "SI BP Role Mgt.";
                    NewRole: Record "SI BP Role";
                begin
                    if CreateDialog.RunModal() <> Action::OK then
                        exit;

                    RoleMgt.CreateRole(
                        CreateDialog.GetBusinessPartnerNo(),
                        CreateDialog.GetRoleType(),
                        CreateDialog.GetERPTemplateCode(),
                        NewRole);

                    Page.Run(
                        Page::"SI BP Role Card",
                        NewRole);
                end;
            }
        }
    }
}