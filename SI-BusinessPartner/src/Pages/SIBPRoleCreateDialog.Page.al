page 54034 "SI BP Role Create Dialog"
{
    PageType = StandardDialog;
    Caption = 'Створення ролі контрагента';
    ObsoleteState = Pending;
    ObsoleteReason = 'Role creation no longer requires a standard BC Customer/Vendor Template.';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Роль';

                field(BusinessPartnerField; BusinessPartnerNo)
                {
                    ApplicationArea = All;
                    Caption = 'Контрагент';
                    TableRelation = "SI Business Partner"."No.";
                    Editable = false;
                }
            }
        }
    }

    procedure SetContext(NewBusinessPartnerNo: Code[20]; NewRoleType: Enum "SI BP Role Type")
    begin
        BusinessPartnerNo := NewBusinessPartnerNo;
        RoleType := NewRoleType;
    end;

    procedure GetBusinessPartnerNo(): Code[20]
    begin
        exit(BusinessPartnerNo);
    end;

    procedure GetRoleType(): Enum "SI BP Role Type"
    begin
        exit(RoleType);
    end;

    var
        BusinessPartnerNo: Code[20];
        RoleType: Enum "SI BP Role Type";
}
