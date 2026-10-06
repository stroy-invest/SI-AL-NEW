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

    procedure UpsertCurrentRegistryLegalAddress(
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

        if GetCurrentLegalAddress(
            BusinessPartner."No.",
            WorkDate(),
            BPAddress)
        then begin
            ApplyRegistryAddress(
                BPAddress,
                BusinessPartner,
                NormalizedRawAddress,
                VerificationSource,
                ParsedAddress);

            BPAddress.Modify(true);
            exit;
        end;

        BPAddress.Init();
        BPAddress."Business Partner No." := BusinessPartner."No.";
        BPAddress."Address Type" := BPAddress."Address Type"::Legal;
        BPAddress."Is Primary" := true;

        ApplyRegistryAddress(
            BPAddress,
            BusinessPartner,
            NormalizedRawAddress,
            VerificationSource,
            ParsedAddress);

        BPAddress.Insert(true);
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

    procedure UpsertCurrentRegistryLegalAddressV2(
        BusinessPartner: Record "SI Business Partner";
        RegistryResult: Record "SI Registry Result" temporary)
    var
        BPAddress: Record "SI BP Address";
    begin
        if not RegistryResult."Address Provided" then
            exit;

        if GetCurrentLegalAddress(BusinessPartner."No.", WorkDate(), BPAddress) then begin
            ApplyNormalizedRegistryAddress(BPAddress, BusinessPartner, RegistryResult);
            BPAddress.Modify(true);
            exit;
        end;

        BPAddress.Init();
        BPAddress."Business Partner No." := BusinessPartner."No.";
        BPAddress."Address Type" := BPAddress."Address Type"::Legal;
        BPAddress."Is Primary" := true;
        ApplyNormalizedRegistryAddress(BPAddress, BusinessPartner, RegistryResult);
        BPAddress.Insert(true);
    end;

    local procedure ApplyNormalizedRegistryAddress(
        var BPAddress: Record "SI BP Address";
        BusinessPartner: Record "SI Business Partner";
        RegistryResult: Record "SI Registry Result" temporary)
    var
        HasStructuredAddress: Boolean;
    begin
        BPAddress."Country/Region Code" := BusinessPartner."Country/Region Code";
        BPAddress.Verified := true;
        BPAddress."Verification Source" :=
            CopyStr(RegistryResult."Provider Code", 1, MaxStrLen(BPAddress."Verification Source"));
        BPAddress."Verification Date/Time" := CurrentDateTime();

        if RegistryResult.Address <> '' then
            BPAddress."Raw Address" :=
                CopyStr(RegistryResult.Address, 1, MaxStrLen(BPAddress."Raw Address"));

        HasStructuredAddress :=
            (RegistryResult."Address Post Code" <> '') or
            (RegistryResult."Address Region" <> '') or
            (RegistryResult."Address District" <> '') or
            (RegistryResult."Address City" <> '') or
            (RegistryResult."Address Street" <> '') or
            (RegistryResult."Address Building" <> '') or
            (RegistryResult."Address Apartment" <> '');

        // A poorer fallback result must never erase richer structured data.
        // Therefore only structured values actually present in the normalized
        // result are applied. Raw-only fallback keeps existing structure intact.
        if not HasStructuredAddress then
            exit;

        if RegistryResult."Address Post Code" <> '' then
            BPAddress."Post Code" := CopyStr(RegistryResult."Address Post Code", 1, MaxStrLen(BPAddress."Post Code"));
        if RegistryResult."Address Region" <> '' then
            BPAddress."Region/State" := CopyStr(RegistryResult."Address Region", 1, MaxStrLen(BPAddress."Region/State"));
        if RegistryResult."Address District" <> '' then
            BPAddress.District := CopyStr(RegistryResult."Address District", 1, MaxStrLen(BPAddress.District));
        if RegistryResult."Address City" <> '' then
            BPAddress.City := CopyStr(RegistryResult."Address City", 1, MaxStrLen(BPAddress.City));
        if RegistryResult."Address Street" <> '' then
            BPAddress.Street := CopyStr(RegistryResult."Address Street", 1, MaxStrLen(BPAddress.Street));
        if RegistryResult."Address Building" <> '' then
            BPAddress."Building No." := CopyStr(RegistryResult."Address Building", 1, MaxStrLen(BPAddress."Building No."));
        if RegistryResult."Address Apartment" <> '' then
            BPAddress."Office/Apartment" := CopyStr(RegistryResult."Address Apartment", 1, MaxStrLen(BPAddress."Office/Apartment"));
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
