codeunit 54040 "SI BP Role Config Mgt."
{
    procedure EnsureRoleSetup(Role: Record "SI BP Role")
    begin
        // Compatibility stub for the legacy Role Setup layer.
        // Standard BC Customer/Vendor Templates are now the ERP configuration source.
    end;

    procedure ValidateRoleSetup(Role: Record "SI BP Role")
    begin
        ValidateERPTemplate(Role);
    end;

    procedure ValidateERPTemplate(Role: Record "SI BP Role")
    var
        CustomerTempl: Record "Customer Templ.";
        VendorTempl: Record "Vendor Templ.";
    begin
        Role.TestField("ERP Template Code");

        case Role."Role Type" of
            Role."Role Type"::Customer:
                if not CustomerTempl.Get(Role."ERP Template Code") then
                    Error(
                        'Стандартний шаблон покупця %1 не знайдено.',
                        Role."ERP Template Code");

            Role."Role Type"::Vendor:
                if not VendorTempl.Get(Role."ERP Template Code") then
                    Error(
                        'Стандартний шаблон постачальника %1 не знайдено.',
                        Role."ERP Template Code");
        end;
    end;
}
