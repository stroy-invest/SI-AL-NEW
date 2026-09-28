codeunit 54021 "SI BP Currency Mgt."
{
    procedure HandleCountryChange(
        var BusinessPartner: Record "SI Business Partner";
        OldBusinessPartner: Record "SI Business Partner")
    var
        CountryCurrencyMgt: Codeunit "SI Country Currency Mgt.";
        DefaultCurrencyCode: Code[10];
    begin
        DefaultCurrencyCode :=
            CountryCurrencyMgt.GetDefaultCurrency(
                BusinessPartner."Country/Region Code");

        BusinessPartner.Validate(
            "Currency Code",
            DefaultCurrencyCode);
    end;

    procedure EnsureDefaultCurrency(
        var BusinessPartner: Record "SI Business Partner")
    var
        CountryCurrencyMgt: Codeunit "SI Country Currency Mgt.";
        DefaultCurrencyCode: Code[10];
    begin
        if BusinessPartner."Currency Code" <> '' then
            exit;

        if BusinessPartner."Country/Region Code" = '' then
            exit;

        DefaultCurrencyCode :=
            CountryCurrencyMgt.GetDefaultCurrency(
                BusinessPartner."Country/Region Code");

        if DefaultCurrencyCode = '' then
            exit;

        BusinessPartner.Validate(
            "Currency Code",
            DefaultCurrencyCode);
    end;

    procedure HandleCurrencyChanged(
        var BusinessPartner: Record "SI Business Partner";
        OldBusinessPartner: Record "SI Business Partner")
    begin
        UpdateCustomerCurrency(
            BusinessPartner,
            OldBusinessPartner."Currency Code");

        UpdateVendorCurrency(
            BusinessPartner,
            OldBusinessPartner."Currency Code");
    end;

    local procedure UpdateCustomerCurrency(
        BusinessPartner: Record "SI Business Partner";
        OldCurrencyCode: Code[10])
    var
        CustomerSetup: Record "SI BP Customer Setup";
    begin
        if not CustomerSetup.Get(BusinessPartner."No.") then
            exit;

        if not CanReplaceRoleCurrency(
            CustomerSetup."Currency Code",
            OldCurrencyCode)
        then
            exit;

        CustomerSetup.Validate(
            "Currency Code",
            BusinessPartner."Currency Code");

        CustomerSetup.Modify(true);
    end;

    local procedure UpdateVendorCurrency(
        BusinessPartner: Record "SI Business Partner";
        OldCurrencyCode: Code[10])
    var
        VendorSetup: Record "SI BP Vendor Setup";
    begin
        if not VendorSetup.Get(BusinessPartner."No.") then
            exit;

        if not CanReplaceRoleCurrency(
            VendorSetup."Currency Code",
            OldCurrencyCode)
        then
            exit;

        VendorSetup.Validate(
            "Currency Code",
            BusinessPartner."Currency Code");

        VendorSetup.Modify(true);
    end;

    local procedure CanReplaceRoleCurrency(
        RoleCurrencyCode: Code[10];
        OldBPCurrencyCode: Code[10]): Boolean
    begin
        exit(
            (RoleCurrencyCode = '') or
            (RoleCurrencyCode = OldBPCurrencyCode));
    end;
}