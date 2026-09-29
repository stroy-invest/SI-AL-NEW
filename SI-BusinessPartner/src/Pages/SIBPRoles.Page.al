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
    }
}
