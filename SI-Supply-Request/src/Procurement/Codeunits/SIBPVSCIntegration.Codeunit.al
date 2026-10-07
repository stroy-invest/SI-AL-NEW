codeunit 61045 "SI BP VSC Integration"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SI BP Role Activation Mgt.", 'OnVendorRoleActivated', '', false, false)]
    local procedure OnVendorRoleActivated(RoleCode: Code[50]; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        VSCWizard: Page "SI VSC Wizard";
    begin
        if (VendorNo = '') or (not Vendor.Get(VendorNo)) then
            exit;

        if not Confirm(
            'Постачальника %1 створено та роль активовано. Налаштувати канали й умови постачання?',
            false,
            VendorNo)
        then
            exit;

        VSCWizard.SetVendor(VendorNo);
        VSCWizard.RunModal();
    end;

    procedure OpenVSCForRole(Role: Record "SI BP Role")
    var
        VSCWizard: Page "SI VSC Wizard";
    begin
        if Role."Role Type" <> Role."Role Type"::Vendor then
            Error('Канали та умови постачання доступні лише для ролі постачальника.');

        if Role.Status <> Role.Status::Active then
            Error('Канали та умови постачання доступні лише для активної ролі постачальника.');

        Role.TestField("Vendor No.");
        VSCWizard.SetVendor(Role."Vendor No.");
        VSCWizard.RunModal();
    end;
}
