codeunit 54011 "SI BP Validator"
{
    procedure ValidateBeforeInsert(var BusinessPartner: Record "SI Business Partner")
    begin
        ValidateIdentityFields(BusinessPartner);
    end;

    procedure ValidateIdentityFields(var BusinessPartner: Record "SI Business Partner")
    begin
        BusinessPartner.TestField("Entity Type");
        BusinessPartner.TestField("Country/Region Code");

        case BusinessPartner."Entity Type" of
            BusinessPartner."Entity Type"::"Legal Entity":
                BusinessPartner.TestField("Registration No.");
            BusinessPartner."Entity Type"::"Individual Entrepreneur":
                BusinessPartner.TestField("Tax Registration No.");
        end;
    end;

    procedure ValidateForActivation(var BusinessPartner: Record "SI Business Partner")
    begin
        ValidateIdentityFields(BusinessPartner);
        if BusinessPartner."Entity Type" = BusinessPartner."Entity Type"::"Legal Entity" then begin
            BusinessPartner.TestField("Local Legal Form Code");
            BusinessPartner.TestField("Legal Form Code");
        end;
        BusinessPartner.TestField(Name);
    end;

    procedure ValidateRequiredFields(var BusinessPartner: Record "SI Business Partner")
    begin
        // Compatibility wrapper for existing callers.
        // Full business completeness is required only when the BP is activated.
        ValidateForActivation(BusinessPartner);
    end;

    procedure ValidateCriticalFieldsUnchanged(BusinessPartner: Record "SI Business Partner"; OldBusinessPartner: Record "SI Business Partner")
    begin
        if OldBusinessPartner."No." = '' then
            exit;

        if OldBusinessPartner.Status = OldBusinessPartner.Status::Draft then
            exit;

        if BusinessPartner."Entity Type" <> OldBusinessPartner."Entity Type" then
            Error(CriticalFieldChangeNotAllowedErr, BusinessPartner.FieldCaption("Entity Type"));

        if BusinessPartner."Country/Region Code" <> OldBusinessPartner."Country/Region Code" then
            Error(CriticalFieldChangeNotAllowedErr, BusinessPartner.FieldCaption("Country/Region Code"));

        if BusinessPartner."Registration No." <> OldBusinessPartner."Registration No." then
            Error(CriticalFieldChangeNotAllowedErr, BusinessPartner.FieldCaption("Registration No."));

        if BusinessPartner."Tax Registration No." <> OldBusinessPartner."Tax Registration No." then
            Error(CriticalFieldChangeNotAllowedErr, BusinessPartner.FieldCaption("Tax Registration No."));

        if BusinessPartner."Local Legal Form Code" <> OldBusinessPartner."Local Legal Form Code" then
            Error(CriticalFieldChangeNotAllowedErr, BusinessPartner.FieldCaption("Local Legal Form Code"));

        if BusinessPartner."Legal Form Code" <> OldBusinessPartner."Legal Form Code" then
            Error(CriticalFieldChangeNotAllowedErr, BusinessPartner.FieldCaption("Legal Form Code"));

        if BusinessPartner.Name <> OldBusinessPartner.Name then
            Error(CriticalFieldChangeNotAllowedErr, BusinessPartner.FieldCaption(Name));

        if BusinessPartner."Is Customer" <> OldBusinessPartner."Is Customer" then
            Error(CriticalFieldChangeNotAllowedErr, BusinessPartner.FieldCaption("Is Customer"));

        if BusinessPartner."Is Vendor" <> OldBusinessPartner."Is Vendor" then
            Error(CriticalFieldChangeNotAllowedErr, BusinessPartner.FieldCaption("Is Vendor"));
    end;

    procedure CheckCriticalFieldCanBeChanged(BusinessPartner: Record "SI Business Partner"; OldBusinessPartner: Record "SI Business Partner"; FieldCaption: Text)
    begin
        if OldBusinessPartner."No." = '' then
            exit;

        if OldBusinessPartner.Status <> OldBusinessPartner.Status::Draft then
            Error(CriticalFieldChangeNotAllowedErr, FieldCaption);
    end;

    var
        CriticalFieldChangeNotAllowedErr: Label 'The field %1 cannot be changed after the Business Partner leaves Draft status. Archive the incorrect Business Partner and create a new one.';
}
