codeunit 65000 "SI IW BP Identifier Sync"
{
    // Localization-specific mapping. Canonical identity stays in SI Business Partner.
    procedure ApplyVendor(var Vendor: Record Vendor; BusinessPartnerNo: Code[20])
    var
        BP: Record "SI Business Partner";
    begin
        if not TryGetUALegalEntity(BusinessPartnerNo, BP) then
            exit;

        if BP."Registration No." = '' then
            exit;

        EnsureRegistrationFits(BP."Registration No.");
        Vendor.Validate("IWS Registration No.", BP."Registration No.");
        Vendor.Validate("IWS VT Tax Number Source", Vendor."IWS VT Tax Number Source"::"1");
    end;

    procedure ApplyCustomer(var Customer: Record Customer; BusinessPartnerNo: Code[20])
    var
        BP: Record "SI Business Partner";
    begin
        if not TryGetUALegalEntity(BusinessPartnerNo, BP) then
            exit;

        if BP."Registration No." = '' then
            exit;

        EnsureRegistrationFits(BP."Registration No.");
        Customer.Validate("IWS Registration No.", BP."Registration No.");
        Customer.Validate("IWS VT Tax Number Source", Customer."IWS VT Tax Number Source"::"1");
    end;

    local procedure TryGetUALegalEntity(BusinessPartnerNo: Code[20]; var BP: Record "SI Business Partner"): Boolean
    begin
        if not BP.Get(BusinessPartnerNo) then
            Error('Business Partner %1 не знайдено.', BusinessPartnerNo);

        exit((BP."Country/Region Code" = 'UA') and
             (BP."Entity Type" = BP."Entity Type"::"Legal Entity"));
    end;

    local procedure EnsureRegistrationFits(RegistrationNo: Text)
    begin
        if StrLen(RegistrationNo) > 10 then
            Error('Реєстраційний номер %1 перевищує довжину поля IWS Registration No. (10 символів).', RegistrationNo);
    end;
}
