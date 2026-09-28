codeunit 54020 "SI BP Address Mgt."
{
    procedure EnsureSingleCurrentLegalAddress(BusinessPartnerNo: Code[60]; AsOfDate: Date)
    var
        CurrentCount: Integer;
    begin
        CurrentCount := CountCurrentLegalAddresses(BusinessPartnerNo, AsOfDate);

        if CurrentCount <> 1 then
            Error(CurrentLegalAddressCountErr, BusinessPartnerNo, AsOfDate, CurrentCount);
    end;

    procedure CountCurrentLegalAddresses(BusinessPartnerNo: Code[60]; AsOfDate: Date): Integer
    var
        BPAddress: Record "SI BP Address";
        CurrentCount: Integer;
    begin
        BPAddress.SetRange("Business Partner No.", BusinessPartnerNo);
        BPAddress.SetRange("Address Type", BPAddress."Address Type"::Legal);

        if BPAddress.FindSet() then
            repeat
                if IsCurrent(BPAddress, AsOfDate) then
                    CurrentCount += 1;
            until BPAddress.Next() = 0;

        exit(CurrentCount);
    end;

    procedure GetCurrentLegalAddress(BusinessPartnerNo: Code[60]; AsOfDate: Date; var BPAddress: Record "SI BP Address"): Boolean
    begin
        BPAddress.Reset();
        BPAddress.SetRange("Business Partner No.", BusinessPartnerNo);
        BPAddress.SetRange("Address Type", BPAddress."Address Type"::Legal);

        if BPAddress.FindSet() then
            repeat
                if IsCurrent(BPAddress, AsOfDate) then
                    exit(true);
            until BPAddress.Next() = 0;

        BPAddress.Reset();
        exit(false);
    end;

    procedure UpsertRegistryLegalAddress(
        BusinessPartner: Record "SI Business Partner";
        RegistryAddress: Text;
        VerificationSource: Code[30])
    var
        BPAddress: Record "SI BP Address";
        ParsedAddress: Record "SI Parsed Address Buffer" temporary;
        AddressParserMgt: Codeunit "SI Address Parser Mgt.";
        NormalizedRawAddress: Text;
    begin
        NormalizedRawAddress := RegistryAddress.Trim();
        if NormalizedRawAddress = '' then
            exit;

        AddressParserMgt.ParseAddress(
            NormalizedRawAddress,
            BusinessPartner."Country/Region Code",
            VerificationSource,
            BusinessPartner."No.",
            ParsedAddress);

        if GetCurrentLegalAddress(BusinessPartner."No.", WorkDate(), BPAddress) then begin
            if BPAddress."Raw Address" = CopyStr(NormalizedRawAddress, 1, MaxStrLen(BPAddress."Raw Address")) then begin
                ApplyRegistryAddress(BPAddress, BusinessPartner, NormalizedRawAddress, VerificationSource, ParsedAddress);
                BPAddress.Modify(true);
                exit;
            end;

            if BPAddress."Valid From" = WorkDate() then begin
                ApplyRegistryAddress(BPAddress, BusinessPartner, NormalizedRawAddress, VerificationSource, ParsedAddress);
                BPAddress.Modify(true);
                exit;
            end;

            BPAddress.Validate("Valid To", CalcDate('<-1D>', WorkDate()));
            BPAddress."Is Primary" := false;
            BPAddress.Modify(true);
        end;

        BPAddress.Init();
        BPAddress."Business Partner No." := BusinessPartner."No.";
        BPAddress."Address Type" := BPAddress."Address Type"::Legal;
        BPAddress."Valid From" := WorkDate();
        BPAddress."Is Primary" := true;
        ApplyRegistryAddress(BPAddress, BusinessPartner, NormalizedRawAddress, VerificationSource, ParsedAddress);
        BPAddress.Insert(true);
    end;

    procedure IsCurrent(BPAddress: Record "SI BP Address"; AsOfDate: Date): Boolean
    begin
        exit(
            ((BPAddress."Valid From" = 0D) or (BPAddress."Valid From" <= AsOfDate)) and
            ((BPAddress."Valid To" = 0D) or (BPAddress."Valid To" >= AsOfDate)));
    end;

    local procedure ApplyRegistryAddress(
        var BPAddress: Record "SI BP Address";
        BusinessPartner: Record "SI Business Partner";
        RawAddress: Text;
        VerificationSource: Code[30];
        ParsedAddress: Record "SI Parsed Address Buffer" temporary)
    begin
        BPAddress."Country/Region Code" := BusinessPartner."Country/Region Code";
        BPAddress."Raw Address" := CopyStr(RawAddress, 1, MaxStrLen(BPAddress."Raw Address"));
        BPAddress.Verified := true;
        BPAddress."Verification Source" := VerificationSource;
        BPAddress."Verification Date/Time" := CurrentDateTime();

        ClearStructuredAddress(BPAddress);

        if not ParsedAddress."Parse Successful" then
            exit;

        BPAddress."Post Code" := CopyStr(ParsedAddress."Post Code", 1, MaxStrLen(BPAddress."Post Code"));
        BPAddress."Region/State" := CopyStr(ParsedAddress."Region Name", 1, MaxStrLen(BPAddress."Region/State"));
        BPAddress.District := CopyStr(ParsedAddress."District Name", 1, MaxStrLen(BPAddress.District));
        BPAddress.City := CopyStr(ParsedAddress."City Name", 1, MaxStrLen(BPAddress.City));
        BPAddress.Street := CopyStr(ParsedAddress.Street, 1, MaxStrLen(BPAddress.Street));
        BPAddress."Building No." := CopyStr(ParsedAddress."Building No.", 1, MaxStrLen(BPAddress."Building No."));
        BPAddress."Office/Apartment" :=
            CopyStr(
                ComposeOfficeApartment(ParsedAddress.Office, ParsedAddress.Apartment),
                1,
                MaxStrLen(BPAddress."Office/Apartment"));
    end;

    local procedure ClearStructuredAddress(var BPAddress: Record "SI BP Address")
    begin
        Clear(BPAddress."Region/State");
        Clear(BPAddress.District);
        Clear(BPAddress.City);
        Clear(BPAddress."Post Code");
        Clear(BPAddress.Street);
        Clear(BPAddress."Building No.");
        Clear(BPAddress."Office/Apartment");
        Clear(BPAddress."Address Details");
    end;

    local procedure ComposeOfficeApartment(Office: Text; Apartment: Text): Text
    begin
        Office := Office.Trim();
        Apartment := Apartment.Trim();

        if Office = '' then
            exit(Apartment);

        if Apartment = '' then
            exit(Office);

        exit(StrSubstNo('%1; %2', Office, Apartment));
    end;

    var
        CurrentLegalAddressCountErr: Label 'Business Partner %1 must have exactly one legal address valid on %2. Current count: %3.';
}
