codeunit 54016 "SI BP Registry Materializer"
{
    procedure Materialize(
        var BusinessPartner: Record "SI Business Partner";
        var RegistryResult: Record "SI Registry Result" temporary)
    var
        BPAddressMgt: Codeunit "SI BP Address Mgt.";
    begin
        ValidateRequest(BusinessPartner, RegistryResult);

        if RegistryResult."Identity Provided" then
            MaterializeIdentity(BusinessPartner, RegistryResult);

        if RegistryResult."Names Provided" then
            MaterializeNames(BusinessPartner, RegistryResult);

        if RegistryResult."Legal Form Provided" then
            MaterializeLegalForm(BusinessPartner, RegistryResult);

        if RegistryResult."Status Provided" then
            BusinessPartner."Registry Status" :=
                CopyStr(RegistryResult."Registry Status", 1, MaxStrLen(BusinessPartner."Registry Status"));

        if RegistryResult."Manager Provided" then
            MaterializeManager(BusinessPartner, RegistryResult);

        if RegistryResult."Main Activity Provided" then begin
            BusinessPartner."Main KVED No." :=
                CopyStr(RegistryResult."KVED No.", 1, MaxStrLen(BusinessPartner."Main KVED No."));
            BusinessPartner."Main KVED Description" :=
                CopyStr(RegistryResult."KVED Description", 1, MaxStrLen(BusinessPartner."Main KVED Description"));
        end;

        if RegistryResult."Data Actual At" <> 0DT then
            BusinessPartner."Registry Data Actual At" := RegistryResult."Data Actual At";

        BusinessPartner."Registry Provider Code" :=
            CopyStr(RegistryResult."Provider Code", 1, MaxStrLen(BusinessPartner."Registry Provider Code"));

        BusinessPartner.Modify(true);

        if RegistryResult."Address Provided" then
            BPAddressMgt.UpsertCurrentRegistryLegalAddressV2(BusinessPartner, RegistryResult);

        if RegistryResult."Contacts Provided" then
            MaterializeContacts(BusinessPartner, RegistryResult);
    end;

    local procedure ValidateRequest(
        BusinessPartner: Record "SI Business Partner";
        var RegistryResult: Record "SI Registry Result" temporary)
    begin
        BusinessPartner.TestField("No.");

        if BusinessPartner.Status <> BusinessPartner.Status::Draft then
            Error(BusinessPartnerMustBeDraftErr, BusinessPartner."No.");

        if RegistryResult.IsEmpty() then
            Error(RegistryResultRequiredErr);
        if not RegistryResult.FindFirst() then
            Error(RegistryResultRequiredErr);

        RegistryResult.TestField("Country/Region Code");
        RegistryResult.TestField("Identifier Value");

        if BusinessPartner."Country/Region Code" <> RegistryResult."Country/Region Code" then
            Error(CountryMismatchErr, BusinessPartner."Country/Region Code", RegistryResult."Country/Region Code");

        if BusinessPartner."Entity Type" <> RegistryResult."Entity Type" then
            Error(EntityTypeMismatchErr, Format(BusinessPartner."Entity Type"), Format(RegistryResult."Entity Type"));

        case RegistryResult."Identifier Type" of
            Enum::"SI Registry Identifier Type"::"Registration No.":
                if BusinessPartner."Registration No." <> RegistryResult."Identifier Value" then
                    Error(IdentifierMismatchErr, BusinessPartner."Registration No.", RegistryResult."Identifier Value");
            Enum::"SI Registry Identifier Type"::"Tax Registration No.":
                if BusinessPartner."Tax Registration No." <> RegistryResult."Identifier Value" then
                    Error(IdentifierMismatchErr, BusinessPartner."Tax Registration No.", RegistryResult."Identifier Value");
            else
                Error(UnsupportedIdentifierTypeErr, Format(RegistryResult."Identifier Type"));
        end;
    end;

    local procedure MaterializeIdentity(
        var BusinessPartner: Record "SI Business Partner";
        RegistryResult: Record "SI Registry Result" temporary)
    begin
        // Country is validated first because country changes clear country-dependent identity.
        BusinessPartner.Validate("Country/Region Code", RegistryResult."Country/Region Code");

        case RegistryResult."Identifier Type" of
            Enum::"SI Registry Identifier Type"::"Registration No.":
                BusinessPartner.Validate("Registration No.", RegistryResult."Registration No.");
            Enum::"SI Registry Identifier Type"::"Tax Registration No.":
                BusinessPartner.Validate("Tax Registration No.", RegistryResult."Tax Registration No.");
        end;
    end;

    local procedure MaterializeNames(
        var BusinessPartner: Record "SI Business Partner";
        RegistryResult: Record "SI Registry Result" temporary)
    var
        PreferredName: Text;
    begin
        PreferredName := RegistryResult."Core Name";
        if PreferredName = '' then
            PreferredName := RegistryResult."Legal Name";

        if PreferredName <> '' then
            BusinessPartner.Validate(Name, CopyStr(PreferredName, 1, MaxStrLen(BusinessPartner.Name)));

        if BusinessPartner."Entity Type" = BusinessPartner."Entity Type"::"Individual Entrepreneur" then
            MaterializeEntrepreneurWorkingName(BusinessPartner, RegistryResult);

        BusinessPartner."Registry Legal Name" :=
            CopyStr(RegistryResult."Legal Name", 1, MaxStrLen(BusinessPartner."Registry Legal Name"));
        BusinessPartner."Registry Short Name" :=
            CopyStr(RegistryResult."Registry Short Name", 1, MaxStrLen(BusinessPartner."Registry Short Name"));
    end;


    local procedure MaterializeEntrepreneurWorkingName(
        var BusinessPartner: Record "SI Business Partner";
        RegistryResult: Record "SI Registry Result" temporary)
    var
        PersonName: Text;
    begin
        PersonName := RegistryResult.Director;
        if PersonName.StartsWith('Фізична особа-підприємець ') then
            PersonName := CopyStr(PersonName, StrLen('Фізична особа-підприємець ') + 1);

        if PersonName = '' then begin
            PersonName := RegistryResult."Registry Short Name";
            if PersonName.EndsWith(' (ФОП)') then
                PersonName := CopyStr(PersonName, 1, StrLen(PersonName) - StrLen(' (ФОП)'));
        end;

        if PersonName <> '' then
            BusinessPartner."Short Name BK" :=
                CopyStr('ФОП ' + PersonName, 1, MaxStrLen(BusinessPartner."Short Name BK"));
    end;

    local procedure MaterializeLegalForm(
        var BusinessPartner: Record "SI Business Partner";
        RegistryResult: Record "SI Registry Result" temporary)
    var
        CountryLegalForm: Record "SI Country Legal Form";
    begin
        CountryLegalForm.SetRange("Country/Region Code", RegistryResult."Country/Region Code");

        if RegistryResult."Legal Form Short" <> '' then begin
            CountryLegalForm.SetRange("Short Name", RegistryResult."Legal Form Short");
            if CountryLegalForm.FindFirst() then begin
                BusinessPartner.Validate("Local Legal Form Code", CountryLegalForm.Code);
                exit;
            end;
            CountryLegalForm.SetRange("Short Name");
        end;

        if RegistryResult."Legal Form Name" = '' then
            exit;

        CountryLegalForm.SetRange("Country Legal Form Name", RegistryResult."Legal Form Name");
        if CountryLegalForm.FindFirst() then
            BusinessPartner.Validate("Local Legal Form Code", CountryLegalForm.Code);

        // An unresolved provider legal-form value must not clear an existing mapping.
    end;

    local procedure MaterializeManager(
        var BusinessPartner: Record "SI Business Partner";
        RegistryResult: Record "SI Registry Result" temporary)
    begin
        BusinessPartner."Manager Name" := CopyStr(RegistryResult.Director, 1, MaxStrLen(BusinessPartner."Manager Name"));
        BusinessPartner."Manager Role" := CopyStr(RegistryResult."Manager Role", 1, MaxStrLen(BusinessPartner."Manager Role"));
        BusinessPartner."Manager Authority" := CopyStr(RegistryResult."Manager Authority", 1, MaxStrLen(BusinessPartner."Manager Authority"));
        BusinessPartner."Manager Appointed At" := RegistryResult."Manager Appointed At";
    end;

    local procedure MaterializeContacts(
        BusinessPartner: Record "SI Business Partner";
        RegistryResult: Record "SI Registry Result" temporary)
    begin
        // Empty individual values are intentionally ignored. Contacts Provided is
        // group-level metadata and does not prove that an omitted phone/e-mail/site
        // is an authoritative deletion.
        if RegistryResult.Phone <> '' then
            UpsertRegistryContact(BusinessPartner."No.", Enum::"SI BP Contact Point Type"::Phone, RegistryResult.Phone, RegistryResult);
        if RegistryResult.Email <> '' then
            UpsertRegistryContact(BusinessPartner."No.", Enum::"SI BP Contact Point Type"::Email, RegistryResult.Email, RegistryResult);
        if RegistryResult.Website <> '' then
            UpsertRegistryContact(BusinessPartner."No.", Enum::"SI BP Contact Point Type"::Website, RegistryResult.Website, RegistryResult);
    end;

    local procedure UpsertRegistryContact(
        BusinessPartnerNo: Code[60];
        ContactType: Enum "SI BP Contact Point Type";
        ContactValue: Text;
        RegistryResult: Record "SI Registry Result" temporary)
    var
        ContactPoint: Record "SI BP Contact Point";
    begin
        ContactPoint.SetRange("Business Partner No.", BusinessPartnerNo);
        ContactPoint.SetRange(Type, ContactType);
        ContactPoint.SetRange(Active, true);
        ContactPoint.SetRange("Is Primary", true);

        if ContactPoint.FindFirst() then begin
            ContactPoint.Value := CopyStr(ContactValue, 1, MaxStrLen(ContactPoint.Value));
            ContactPoint.Verified := true;
            ContactPoint."Verification Date/Time" := CurrentDateTime();
            ContactPoint.Modify(true);
            exit;
        end;

        ContactPoint.Init();
        ContactPoint."Business Partner No." := BusinessPartnerNo;
        ContactPoint.Type := ContactType;
        ContactPoint.Value := CopyStr(ContactValue, 1, MaxStrLen(ContactPoint.Value));
        ContactPoint.Description := CopyStr(RegistryResult."Provider Code", 1, MaxStrLen(ContactPoint.Description));
        ContactPoint."Is Primary" := true;
        ContactPoint.Active := true;
        ContactPoint.Verified := true;
        ContactPoint."Verification Date/Time" := CurrentDateTime();
        ContactPoint.Insert(true);
    end;

    var
        BusinessPartnerMustBeDraftErr: Label 'Business Partner %1 must be in Draft status to materialize registry data.';
        RegistryResultRequiredErr: Label 'Registry result is required for materialization.';
        CountryMismatchErr: Label 'Business Partner country/region %1 does not match registry country/region %2.';
        EntityTypeMismatchErr: Label 'Business Partner entity type %1 does not match registry entity type %2.';
        IdentifierMismatchErr: Label 'Business Partner identifier %1 does not match registry identifier %2.';
        UnsupportedIdentifierTypeErr: Label 'Registry identifier type %1 is not supported for materialization.';
}
