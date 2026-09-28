page 54034 "SI BP Role Create Dialog"
{
    PageType = StandardDialog;
    Caption = 'Створення ролі контрагента';

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

                field(ERPTemplateField; ERPTemplateCode)
                {
                    ApplicationArea = All;
                    Caption = 'Шаблон BC';
                    ToolTip = 'Стандартний шаблон Business Central, який буде застосовано під час матеріалізації покупця або постачальника.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CustomerTempl: Record "Customer Templ.";
                        VendorTempl: Record "Vendor Templ.";
                    begin
                        case RoleType of
                            RoleType::Customer:
                                begin
                                    if ERPTemplateCode <> '' then
                                        CustomerTempl.Get(ERPTemplateCode);

                                    if Page.RunModal(Page::"Select Customer Templ. List", CustomerTempl) <> Action::LookupOK then
                                        exit(false);

                                    ERPTemplateCode := CustomerTempl.Code;
                                end;

                            RoleType::Vendor:
                                begin
                                    if ERPTemplateCode <> '' then
                                        VendorTempl.Get(ERPTemplateCode);

                                    if Page.RunModal(Page::"Select Vendor Templ. List", VendorTempl) <> Action::LookupOK then
                                        exit(false);

                                    ERPTemplateCode := VendorTempl.Code;
                                end;
                        end;

                        Text := ERPTemplateCode;
                        exit(true);
                    end;
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CustomerTempl: Record "Customer Templ.";
        VendorTempl: Record "Vendor Templ.";
    begin
        if CloseAction <> Action::OK then
            exit(true);

        if BusinessPartnerNo = '' then
            Error('Не зазначено контрагента.');

        if ERPTemplateCode = '' then
            Error('Не зазначено стандартний шаблон Business Central.');

        case RoleType of
            RoleType::Customer:
                if not CustomerTempl.Get(ERPTemplateCode) then
                    Error('Стандартний шаблон покупця %1 не знайдено.', ERPTemplateCode);

            RoleType::Vendor:
                if not VendorTempl.Get(ERPTemplateCode) then
                    Error('Стандартний шаблон постачальника %1 не знайдено.', ERPTemplateCode);
        end;

        exit(true);
    end;

    procedure SetContext(NewBusinessPartnerNo: Code[20]; NewRoleType: Enum "SI BP Role Type")
    begin
        BusinessPartnerNo := NewBusinessPartnerNo;
        RoleType := NewRoleType;
        ERPTemplateCode := '';
    end;

    procedure GetBusinessPartnerNo(): Code[20]
    begin
        exit(BusinessPartnerNo);
    end;

    procedure GetRoleType(): Enum "SI BP Role Type"
    begin
        exit(RoleType);
    end;

    procedure GetERPTemplateCode(): Code[20]
    begin
        exit(ERPTemplateCode);
    end;

    var
        BusinessPartnerNo: Code[20];
        RoleType: Enum "SI BP Role Type";
        ERPTemplateCode: Code[20];
}
