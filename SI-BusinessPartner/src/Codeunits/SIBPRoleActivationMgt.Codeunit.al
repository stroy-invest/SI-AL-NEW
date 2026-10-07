codeunit 54082 "SI BP Role Activation Mgt."
{
    procedure ActivateRole(
        var Role: Record "SI BP Role";
        VATStatus: Enum "SI BP VAT Status")
    var
        BusinessPartner: Record "SI Business Partner";
        Projection: Record "SI BP ERP Projection";
        RoleMgt: Codeunit "SI BP Role Mgt.";
        BPBankMgt: Codeunit "SI BP Bank Mgt.";
        TemplateResolver: Codeunit "SI BP Template Resolver";
        ProjectionMgt: Codeunit "SI BP Projection Mgt.";
        TemplateCode: Code[20];
    begin
        Role.Get(Role.Code);

        if not (Role.Status in [Role.Status::Draft, Role.Status::Configured]) then
            Error(
                'Налаштувати та активувати можна лише роль у стані Чернетка або Налаштована. Поточний стан: %1.',
                Format(Role.Status));

        if (Role."Customer No." <> '') or (Role."Vendor No." <> '') then
            Error(
                'Роль %1 уже пов''язана з ERP-контрагентом. Повторна первинна активація не дозволена.',
                Role.Code);

        if not BusinessPartner.Get(Role."Business Partner No.") then
            Error(
                'Контрагента %1 не знайдено.',
                Role."Business Partner No.");

        BusinessPartner.TestField("Country/Region Code");

        BPBankMgt.ValidateBankingReady(Role);

        TemplateCode :=
            TemplateResolver.ResolveTemplateCode(
                Role."Role Type",
                BusinessPartner."Country/Region Code",
                VATStatus);

        if Role.Status = Role.Status::Draft then
            RoleMgt.SubmitRole(
                Role,
                'Activation Wizard',
                'Роль налаштована під час активації.');

        if Projection.Get(Role.Code) then begin
            if Projection.Status = Projection.Status::Materialized then
                Error(
                    'ERP-проєкція ролі %1 уже матеріалізована.',
                    Role.Code);

            ProjectionMgt.DeleteProjection(Role.Code);
        end;

        ProjectionMgt.CreateProjection(
            Role,
            Projection);

        ProjectionMgt.MaterializeProjection(
            Projection,
            TemplateCode);

        RoleMgt.ActivateRole(
            Role,
            'Materialization completed',
            StrSubstNo(
                'ERP-контрагента створено за стандартним шаблоном %1. Статус ПДВ: %2.',
                TemplateCode,
                Format(VATStatus)));

        // Stage 1 is complete before any optional downstream process is invoked.
        Commit();

        if (Role."Role Type" = Role."Role Type"::Vendor) and
           (Role."Vendor No." <> '')
        then
            OnVendorRoleActivated(Role.Code, Role."Vendor No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendorRoleActivated(RoleCode: Code[50]; VendorNo: Code[20])
    begin
    end;
}
