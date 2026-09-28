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
        // Compatibility hook intentionally kept while the BP field contract is stable.
        // Role-specific ERP configuration is owned by SI BP Role + standard BC templates.
        // Legacy SI BP Customer/Vendor Setup records are no longer synchronized.
    end;
}
