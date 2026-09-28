codeunit 54010 "SI BP Identity Mgt."
{
    procedure AssignIdentity(var BusinessPartner: Record "SI Business Partner")
    begin
        BusinessPartner."No." := BuildBusinessPartnerNo(
            BusinessPartner."Country/Region Code",
            BusinessPartner."Entity Type",
            BusinessPartner."Registration No.");
    end;

    procedure SynchronizeIdentity(var BusinessPartner: Record "SI Business Partner")
    var
        BusinessPartnerNo: Code[60];
    begin
        if (BusinessPartner."Country/Region Code" = '') or
           (BusinessPartner."Entity Type" = BusinessPartner."Entity Type"::" ") or
           (BusinessPartner."Registration No." = '')
        then
            exit;

        BusinessPartnerNo := BuildBusinessPartnerNo(
            BusinessPartner."Country/Region Code",
            BusinessPartner."Entity Type",
            BusinessPartner."Registration No.");

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
        BusinessPartnerNoTooLongErr: Label 'The generated Business Partner No. %1 exceeds the maximum length of %2 characters.';
        CountryRequiredErr: Label 'Country/Region Code is required.';
        EntityTypeRequiredErr: Label 'Entity Type is required.';
        InvalidCountryCodeErr: Label 'Country/Region Code %1 does not contain characters that can be used in the Business Partner No.';
        InvalidRegistrationNoErr: Label 'Registration No. %1 does not contain characters that can be used in the Business Partner No.';
        RegistrationNoRequiredErr: Label 'Registration No. is required.';
}
