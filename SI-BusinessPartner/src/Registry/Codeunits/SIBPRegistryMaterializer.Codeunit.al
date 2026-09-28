codeunit 54016 "SI BP Registry Materializer"
{
    procedure Materialize(
        var BusinessPartner: Record "SI Business Partner";
        var RegistryResult: Record "SI Registry Result" temporary)
    var
        BPAddressMgt: Codeunit "SI BP Address Mgt.";
    begin
        ValidateRequest(BusinessPartner, RegistryResult);

        MaterializeIdentity(BusinessPartner, RegistryResult);
        MaterializeLegalForm(BusinessPartner, RegistryResult);

        BusinessPartner.Modify(true);

        BPAddressMgt.UpsertCurrentRegistryLegalAddress(
            BusinessPartner,
            RegistryResult.Address,
            RegistryResult."Provider Code");
    end;

    local procedure ValidateRequest(
        BusinessPartner: Record "SI Business Partner";
        var RegistryResult: Record "SI Registry Result" temporary)
    begin
        BusinessPartner.TestField("No.");

        if BusinessPartner.Status <> BusinessPartner.Status::Draft then
            Error(
                BusinessPartnerMustBeDraftErr,
                BusinessPartner."No.");

        if RegistryResult.IsEmpty() then
            Error(RegistryResultRequiredErr);

        if not RegistryResult.FindFirst() then
            Error(RegistryResultRequiredErr);

        RegistryResult.TestField("Country/Region Code");
        RegistryResult.TestField("Registration No.");

        if BusinessPartner."Country/Region Code" <>
           RegistryResult."Country/Region Code"
        then
            Error(
                CountryMismatchErr,
                BusinessPartner."Country/Region Code",
                RegistryResult."Country/Region Code");

        if BusinessPartner."Registration No." <>
           RegistryResult."Registration No."
        then
            Error(
                RegistrationNoMismatchErr,
                BusinessPartner."Registration No.",
                RegistryResult."Registration No.");
    end;

    local procedure MaterializeIdentity(
        var BusinessPartner: Record "SI Business Partner";
        RegistryResult: Record "SI Registry Result" temporary)
    begin
        // Country must be validated before the rest of legal identity because
        // changing Country/Region Code clears country-dependent legal identity.
        BusinessPartner.Validate(
            "Country/Region Code",
            RegistryResult."Country/Region Code");

        BusinessPartner.Validate(
            "Registration No.",
            RegistryResult."Registration No.");

        BusinessPartner.Validate(
            "Tax Registration No.",
            RegistryResult."Tax Registration No.");

        if RegistryResult."Core Name" <> '' then
            BusinessPartner.Validate(
                Name,
                CopyStr(
                    RegistryResult."Core Name",
                    1,
                    MaxStrLen(BusinessPartner.Name)));
    end;

    local procedure MaterializeLegalForm(
        var BusinessPartner: Record "SI Business Partner";
        RegistryResult: Record "SI Registry Result" temporary)
    var
        CountryLegalForm: Record "SI Country Legal Form";
    begin
        if RegistryResult."Legal Form Short" = '' then begin
            BusinessPartner.Validate(
                "Local Legal Form Code",
                '');
            exit;
        end;

        CountryLegalForm.SetRange(
            "Country/Region Code",
            RegistryResult."Country/Region Code");

        CountryLegalForm.SetRange(
            "Short Name",
            RegistryResult."Legal Form Short");

        if not CountryLegalForm.FindFirst() then begin
            BusinessPartner.Validate(
                "Local Legal Form Code",
                '');
            exit;
        end;

        BusinessPartner.Validate(
            "Local Legal Form Code",
            CountryLegalForm.Code);
    end;

    var
        BusinessPartnerMustBeDraftErr: Label
            'Business Partner %1 must be in Draft status to materialize registry data.';

        RegistryResultRequiredErr: Label
            'Registry result is required for materialization.';

        CountryMismatchErr: Label
            'Business Partner country/region %1 does not match registry country/region %2.';

        RegistrationNoMismatchErr: Label
            'Business Partner registration number %1 does not match registry registration number %2.';
}