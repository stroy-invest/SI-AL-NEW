codeunit 54081 "SI BP Template Selector"
{
    procedure SelectTemplate(RoleType: Enum "SI BP Role Type"; var TemplateCode: Code[20]): Boolean
    begin
        Clear(TemplateCode);

        case RoleType of
            RoleType::Customer:
                exit(SelectCustomerTemplate(TemplateCode));
            RoleType::Vendor:
                exit(SelectVendorTemplate(TemplateCode));
        end;

        Error(RoleTypeRequiredErr);
    end;

    local procedure SelectCustomerTemplate(var TemplateCode: Code[20]): Boolean
    var
        CustomerTemplate: Record "Customer Templ.";
        CustomerTemplates: Page "Customer Templ. List";
    begin
        CustomerTemplates.LookupMode(true);
        CustomerTemplates.SetRecord(CustomerTemplate);

        if CustomerTemplates.RunModal() <> Action::LookupOK then
            exit(false);

        CustomerTemplates.GetRecord(CustomerTemplate);
        TemplateCode := CustomerTemplate.Code;
        exit(TemplateCode <> '');
    end;

    local procedure SelectVendorTemplate(var TemplateCode: Code[20]): Boolean
    var
        VendorTemplate: Record "Vendor Templ.";
        VendorTemplates: Page "Vendor Templ. List";
    begin
        VendorTemplates.LookupMode(true);
        VendorTemplates.SetRecord(VendorTemplate);

        if VendorTemplates.RunModal() <> Action::LookupOK then
            exit(false);

        VendorTemplates.GetRecord(VendorTemplate);
        TemplateCode := VendorTemplate.Code;
        exit(TemplateCode <> '');
    end;

    var
        RoleTypeRequiredErr: Label 'Спочатку виберіть тип ролі контрагента.';
}
