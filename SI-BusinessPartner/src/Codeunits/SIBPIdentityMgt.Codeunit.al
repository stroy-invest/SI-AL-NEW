codeunit 54010 "SI BP Identity Mgt."
{
    procedure AssignIdentity(var BusinessPartner: Record "SI Business Partner")
    var
        IdentityNo: Text[50];
    begin
        IdentityNo := GetIdentityNo(BusinessPartner);
        ValidateUniqueIdentity(BusinessPartner, IdentityNo);
        BusinessPartner."No." := BuildBusinessPartnerNo(
            BusinessPartner."Country/Region Code",
            BusinessPartner."Entity Type",
            IdentityNo);
    end;

    procedure SynchronizeIdentity(var BusinessPartner: Record "SI Business Partner")
    var
        BusinessPartnerNo: Code[60];
        IdentityNo: Text[50];
    begin
        if (BusinessPartner."Country/Region Code" = '') or
           (BusinessPartner."Entity Type" = BusinessPartner."Entity Type"::" ")
        then
            exit;

        IdentityNo := GetIdentityNo(BusinessPartner);
        if IdentityNo = '' then
            exit;

        ValidateUkrainianIdentifier(BusinessPartner, IdentityNo);
        ValidateUniqueIdentity(BusinessPartner, IdentityNo);

        BusinessPartnerNo := BuildBusinessPartnerNo(
            BusinessPartner."Country/Region Code",
            BusinessPartner."Entity Type",
            IdentityNo);

        if BusinessPartner."No." = BusinessPartnerNo then
            exit;

        if BusinessPartner."No." = '' then begin
            BusinessPartner."No." := BusinessPartnerNo;
            exit;
        end;

        BusinessPartner.Rename(BusinessPartnerNo);
    end;

    procedure BuildBusinessPartnerNo(CountryRegionCode: Code[10]; EntityType: Enum "SI BP Entity Type"; RegistrationNo: Text[50]): Code[60]
    var
        EntityTypeCode: Code[10];
        NormalizedCountryCode: Text;
        NormalizedRegistrationNo: Text;
        Result: Text;
    begin
        if CountryRegionCode = '' then
            Error(CountryRequiredErr);

        if EntityType = EntityType::" " then
            Error(EntityTypeRequiredErr);

        if RegistrationNo = '' then
            Error(RegistrationNoRequiredErr);

        NormalizedCountryCode := KeepLettersAndDigits(UpperCase(Format(CountryRegionCode)));
        EntityTypeCode := GetEntityTypeCode(EntityType);
        NormalizedRegistrationNo := KeepLettersAndDigits(UpperCase(RegistrationNo));

        if NormalizedCountryCode = '' then
            Error(InvalidCountryCodeErr, CountryRegionCode);

        if NormalizedRegistrationNo = '' then
            Error(InvalidRegistrationNoErr, RegistrationNo);

        Result := NormalizedCountryCode + '-' + EntityTypeCode + '-' + NormalizedRegistrationNo;

        if StrLen(Result) > 60 then
            Error(BusinessPartnerNoTooLongErr, Result, 60);

        exit(CopyStr(Result, 1, 60));
    end;

    local procedure GetIdentityNo(BusinessPartner: Record "SI Business Partner"): Text[50]
    begin
        case BusinessPartner."Entity Type" of
            BusinessPartner."Entity Type"::"Legal Entity":
                exit(BusinessPartner."Registration No.");
            BusinessPartner."Entity Type"::"Individual Entrepreneur":
                exit(BusinessPartner."Tax Registration No.");
        end;

        exit(BusinessPartner."Registration No.");
    end;

    local procedure ValidateUniqueIdentity(BusinessPartner: Record "SI Business Partner"; IdentityNo: Text[50])
    var
        ExistingBusinessPartner: Record "SI Business Partner";
    begin
        if IdentityNo = '' then
            exit;

        ExistingBusinessPartner.SetRange("Country/Region Code", BusinessPartner."Country/Region Code");
        ExistingBusinessPartner.SetRange("Entity Type", BusinessPartner."Entity Type");

        case BusinessPartner."Entity Type" of
            BusinessPartner."Entity Type"::"Legal Entity":
                ExistingBusinessPartner.SetRange("Registration No.", IdentityNo);
            BusinessPartner."Entity Type"::"Individual Entrepreneur":
                ExistingBusinessPartner.SetRange("Tax Registration No.", IdentityNo);
            else
                ExistingBusinessPartner.SetRange("Registration No.", IdentityNo);
        end;

        if BusinessPartner."No." <> '' then
            ExistingBusinessPartner.SetFilter("No.", '<>%1', BusinessPartner."No.");

        if ExistingBusinessPartner.FindFirst() then
            Error(DuplicateIdentityErr, IdentityNo, ExistingBusinessPartner."No.");
    end;

    local procedure ValidateUkrainianIdentifier(BusinessPartner: Record "SI Business Partner"; IdentityNo: Text[50])
    var
        UAIdentifierMgt: Codeunit "SI UA Identifier Mgt.";
    begin
        if UpperCase(BusinessPartner."Country/Region Code") <> UkraineCountryCodeLbl then
            exit;

        case BusinessPartner."Entity Type" of
            BusinessPartner."Entity Type"::"Legal Entity":
                UAIdentifierMgt.ValidateEDRPOU(IdentityNo);
            BusinessPartner."Entity Type"::"Individual Entrepreneur":
                UAIdentifierMgt.ValidateRNOKPP(IdentityNo);
        end;
    end;

    local procedure GetEntityTypeCode(EntityType: Enum "SI BP Entity Type"): Code[10]
    begin
        case EntityType of
            EntityType::"Legal Entity":
                exit('LE');
            EntityType::"Individual Entrepreneur":
                exit('IE');
            EntityType::Individual:
                exit('IND');
        end;

        Error(EntityTypeRequiredErr);
    end;

    local procedure KeepLettersAndDigits(Value: Text): Text
    var
        Result: Text;
        Character: Char;
        Position: Integer;
    begin
        for Position := 1 to StrLen(Value) do begin
            Character := Value[Position];
            if (StrPos('ABCDEFGHIJKLMNOPQRSTUVWXYZ', Format(Character)) > 0) or
               (StrPos('0123456789', Format(Character)) > 0)
            then
                Result += Format(Character);
        end;

        exit(Result);
    end;

    var
        UkraineCountryCodeLbl: Label 'UA', Locked = true;
        BusinessPartnerNoTooLongErr: Label 'The generated Business Partner No. %1 exceeds the maximum length of %2 characters.';
        CountryRequiredErr: Label 'Country/Region Code is required.';
        EntityTypeRequiredErr: Label 'Entity Type is required.';
        InvalidCountryCodeErr: Label 'Country/Region Code %1 does not contain characters that can be used in the Business Partner No.';
        InvalidRegistrationNoErr: Label 'Registration No. %1 does not contain characters that can be used in the Business Partner No.';
        RegistrationNoRequiredErr: Label 'Registration No. is required.';
        DuplicateIdentityErr: Label 'Контрагент з ідентифікатором %1 уже існує (%2).';
}
