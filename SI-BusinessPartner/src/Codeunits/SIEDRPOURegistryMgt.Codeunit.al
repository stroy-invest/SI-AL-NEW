codeunit 54013 "SI EDRPOU Registry Mgt."
{
    procedure CheckAndShow(var BusinessPartner: Record "SI Business Partner")
    var
        ResultBuffer: Record "SI EDRPOU Check Buffer" temporary;
        ResultPage: Page "SI EDRPOU Check Result";
    begin
        ValidateRequest(BusinessPartner);
        RequestRegistryData(BusinessPartner."Registration No.", ResultBuffer);
        CompareWithBusinessPartner(BusinessPartner, ResultBuffer);

        ResultPage.SetResult(ResultBuffer);

        // Diagnostic transaction boundary:
        // registry/compare processing may start a write transaction.
        // Finish it before opening the modal result page.
        Commit();
        ResultPage.RunModal();

        if ResultPage.GetApplyRequested() then
            ApplyRegistryCorrections(BusinessPartner, ResultBuffer);
    end;

    procedure IsCheckAvailable(BusinessPartner: Record "SI Business Partner"): Boolean
    begin
        exit(
            (BusinessPartner."Entity Type" = BusinessPartner."Entity Type"::"Legal Entity") and
            (BusinessPartner."Country/Region Code" <> '') and
            (BusinessPartner."Registration No." <> '') and
            (UpperCase(BusinessPartner."Country/Region Code") = UkraineCountryCodeLbl));
    end;

    local procedure ValidateRequest(BusinessPartner: Record "SI Business Partner")
    begin
        BusinessPartner.TestField("Entity Type");
        BusinessPartner.TestField("Country/Region Code");
        BusinessPartner.TestField("Registration No.");

        if BusinessPartner."Entity Type" <> BusinessPartner."Entity Type"::"Legal Entity" then
            Error(OnlyLegalEntitySupportedErr);

        if UpperCase(BusinessPartner."Country/Region Code") <> UkraineCountryCodeLbl then
            Error(OnlyUkraineSupportedErr);

        ValidateRegistrationNo(BusinessPartner."Registration No.");
    end;

    local procedure RequestRegistryData(RegistrationNo: Text; var ResultBuffer: Record "SI EDRPOU Check Buffer" temporary)
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        ResponseText: Text;
        RequestUrl: Text;
    begin
        RequestUrl := RegistryUrlLbl + RegistrationNo;

        if not HttpClient.Get(RequestUrl, HttpResponse) then
            Error(HttpRequestFailedErr);

        if not HttpResponse.IsSuccessStatusCode() then
            Error(HttpStatusErr, HttpResponse.HttpStatusCode(), HttpResponse.ReasonPhrase());

        if not HttpResponse.Content.ReadAs(ResponseText) then
            Error(ResponseReadFailedErr);

        ParseResponse(ResponseText, ResultBuffer);
    end;

    local procedure ParseResponse(ResponseText: Text; var ResultBuffer: Record "SI EDRPOU Check Buffer" temporary)
    var
        CompanyElement: XmlElement;
        ErrorElement: XmlElement;
        RootElement: XmlElement;
        ResponseXml: XmlDocument;
        CompanyNode: XmlNode;
        ErrorNode: XmlNode;
    begin
        if not XmlDocument.ReadFrom(ResponseText, ResponseXml) then
            Error(InvalidXmlErr);

        ResponseXml.GetRoot(RootElement);

        if LowerCase(RootElement.Name()) = 'error' then
            Error('%1', RootElement.InnerText());

        if RootElement.SelectSingleNode('error', ErrorNode) then begin
            ErrorElement := ErrorNode.AsXmlElement();
            Error('%1', ErrorElement.InnerText());
        end;

        if not RootElement.SelectSingleNode('company', CompanyNode) then
            Error(CompanyNodeMissingErr);

        CompanyElement := CompanyNode.AsXmlElement();
        FillResultBuffer(CompanyElement, ResultBuffer);
    end;

    local procedure FillResultBuffer(CompanyElement: XmlElement; var ResultBuffer: Record "SI EDRPOU Check Buffer" temporary)
    begin
        ResultBuffer.Init();
        ResultBuffer."Entry No." := 1;
        ResultBuffer."Registration No." := CopyStr(GetAttributeValue(CompanyElement, 'egrpou'), 1, MaxStrLen(ResultBuffer."Registration No."));
        ResultBuffer."Full Name" := CopyStr(GetAttributeValue(CompanyElement, 'name'), 1, MaxStrLen(ResultBuffer."Full Name"));
        ResultBuffer."Short Name" := CopyStr(GetAttributeValue(CompanyElement, 'name_short'), 1, MaxStrLen(ResultBuffer."Short Name"));
        ResultBuffer.Address := CopyStr(GetAttributeValue(CompanyElement, 'address'), 1, MaxStrLen(ResultBuffer.Address));
        ResultBuffer.Director := CopyStr(GetAttributeValue(CompanyElement, 'director'), 1, MaxStrLen(ResultBuffer.Director));
        ResultBuffer."Director Genitive" := CopyStr(GetAttributeValue(CompanyElement, 'director_gen'), 1, MaxStrLen(ResultBuffer."Director Genitive"));
        ResultBuffer."KVED Description" := CopyStr(GetAttributeValue(CompanyElement, 'kved'), 1, MaxStrLen(ResultBuffer."KVED Description"));
        ResultBuffer."KVED No." := CopyStr(GetAttributeValue(CompanyElement, 'kved_number'), 1, MaxStrLen(ResultBuffer."KVED No."));
        ResultBuffer."Tax Registration No." := CopyStr(GetAttributeValue(CompanyElement, 'inn'), 1, MaxStrLen(ResultBuffer."Tax Registration No."));
        ResultBuffer."Registration Date" := CopyStr(GetAttributeValue(CompanyElement, 'date_from'), 1, MaxStrLen(ResultBuffer."Registration Date"));
        ResultBuffer."Tax Registration Date" := CopyStr(GetAttributeValue(CompanyElement, 'inn_date'), 1, MaxStrLen(ResultBuffer."Tax Registration Date"));
        ResultBuffer."Last Update" := CopyStr(GetAttributeValue(CompanyElement, 'last_update'), 1, MaxStrLen(ResultBuffer."Last Update"));
        ResultBuffer.Insert();
    end;

    local procedure CompareWithBusinessPartner(BusinessPartner: Record "SI Business Partner"; var ResultBuffer: Record "SI EDRPOU Check Buffer" temporary)
    var
        BusinessPartnerLegalForm: Record "SI Country Legal Form";
        RegistryLegalForm: Record "SI Country Legal Form";
        LegalFormResolved: Boolean;
    begin
        ResultBuffer.Get(1);

        ResultBuffer."BP Tax Registration No." :=
            CopyStr(BusinessPartner."Tax Registration No.", 1, MaxStrLen(ResultBuffer."BP Tax Registration No."));
        ResultBuffer."BP Legal Form Code" := BusinessPartner."Local Legal Form Code";
        ResultBuffer."BP Name" := CopyStr(BusinessPartner.Name, 1, MaxStrLen(ResultBuffer."BP Name"));

        if BusinessPartnerLegalForm.Get(
            BusinessPartner."Country/Region Code",
            BusinessPartner."Local Legal Form Code")
        then
            ResultBuffer."BP Legal Form Name" :=
                CopyStr(
                    BusinessPartnerLegalForm."Country Legal Form Name",
                    1,
                    MaxStrLen(ResultBuffer."BP Legal Form Name"));

        LegalFormResolved := ResolveRegistryLegalForm(
            BusinessPartner."Country/Region Code",
            ResultBuffer."Full Name",
            RegistryLegalForm);

        if LegalFormResolved then begin
            ResultBuffer."Registry Legal Form Code" := RegistryLegalForm.Code;
            ResultBuffer."Registry Legal Form Name" :=
                CopyStr(
                    RegistryLegalForm."Country Legal Form Name",
                    1,
                    MaxStrLen(ResultBuffer."Registry Legal Form Name"));
            ResultBuffer."Registry Business Name" :=
                CopyStr(
                    ExtractRegistryBusinessName(
                        ResultBuffer."Full Name",
                        RegistryLegalForm."Country Legal Form Name"),
                    1,
                    MaxStrLen(ResultBuffer."Registry Business Name"));
        end else
            ResultBuffer."Registry Legal Form Name" := LegalFormNotResolvedTxt;

        ResultBuffer."VAT Matches" :=
            NormalizeComparisonText(ResultBuffer."BP Tax Registration No.") =
            NormalizeComparisonText(ResultBuffer."Tax Registration No.");

        ResultBuffer."Legal Form Matches" :=
            LegalFormResolved and
            (BusinessPartner."Local Legal Form Code" = RegistryLegalForm.Code);

        ResultBuffer."Name Needs Fill" :=
            (BusinessPartner.Name = '') and
            (ResultBuffer."Registry Business Name" <> '');

        ResultBuffer."Has Differences" :=
            not ResultBuffer."VAT Matches" or
            not ResultBuffer."Legal Form Matches" or
            ResultBuffer."Name Needs Fill";

        ResultBuffer."Can Apply Corrections" :=
            (BusinessPartner.Status = BusinessPartner.Status::Draft) and
            ResultBuffer."Has Differences" and
            LegalFormResolved;

        if ResultBuffer."Has Differences" then begin
            if BusinessPartner.Status = BusinessPartner.Status::Draft then
                ResultBuffer."Comparison Result" := DifferencesDraftTxt
            else
                ResultBuffer."Comparison Result" := DifferencesReadOnlyTxt;
        end else
            ResultBuffer."Comparison Result" := DataMatchesTxt;

        ResultBuffer.Modify();
    end;

    local procedure ResolveRegistryLegalForm(CountryRegionCode: Code[10]; RegistryFullName: Text; var ResolvedLegalForm: Record "SI Country Legal Form"): Boolean
    var
        CountryLegalForm: Record "SI Country Legal Form";
        BestMatchLength: Integer;
        CandidateName: Text;
        NormalizedRegistryName: Text;
    begin
        Clear(ResolvedLegalForm);
        BestMatchLength := 0;
        NormalizedRegistryName := NormalizeComparisonText(RegistryFullName);

        CountryLegalForm.SetRange("Country/Region Code", CountryRegionCode);
        CountryLegalForm.SetFilter("Country Legal Form Name", '<>%1', '');

        if CountryLegalForm.FindSet() then
            repeat
                CandidateName := NormalizeComparisonText(CountryLegalForm."Country Legal Form Name");

                if (CandidateName <> '') and
                   (StrPos(NormalizedRegistryName, CandidateName) = 1) and
                   (StrLen(CandidateName) > BestMatchLength)
                then begin
                    ResolvedLegalForm := CountryLegalForm;
                    BestMatchLength := StrLen(CandidateName);
                end;
            until CountryLegalForm.Next() = 0;

        exit(BestMatchLength > 0);
    end;

    local procedure ExtractRegistryBusinessName(RegistryFullName: Text; RegistryLegalFormName: Text): Text
    var
        BPNamingMgt: Codeunit "SI BP Naming Mgt.";
        Apostrophe: Char;
        BusinessName: Text;
    begin
        BusinessName := RegistryFullName;

        if (RegistryLegalFormName <> '') and
           (StrPos(UpperCase(BusinessName), UpperCase(RegistryLegalFormName)) = 1)
        then
            BusinessName := CopyStr(BusinessName, StrLen(RegistryLegalFormName) + 1);

        Apostrophe := 39;
        BusinessName := BusinessName.Replace(Format(Apostrophe), ' ');
        BusinessName := BPNamingMgt.CleanBusinessName(BusinessName);

        exit(BusinessName);
    end;

    local procedure ApplyRegistryCorrections(var BusinessPartner: Record "SI Business Partner"; var ResultBuffer: Record "SI EDRPOU Check Buffer" temporary)
    var
        BPAddressMgt: Codeunit "SI BP Address Mgt.";
    begin
        if BusinessPartner.Status <> BusinessPartner.Status::Draft then
            Error(CorrectionsDraftOnlyErr);

        ResultBuffer.Get(1);

        if ResultBuffer."Registry Legal Form Code" = '' then
            Error(LegalFormCannotBeAppliedErr);

        if not ResultBuffer."VAT Matches" then
            BusinessPartner.Validate("Tax Registration No.", ResultBuffer."Tax Registration No.");

        if not ResultBuffer."Legal Form Matches" then
            BusinessPartner.Validate("Local Legal Form Code", ResultBuffer."Registry Legal Form Code");

        if ResultBuffer."Name Needs Fill" then
            BusinessPartner.Validate(Name, ResultBuffer."Registry Business Name");

        if BusinessPartner."No." <> '' then
            BusinessPartner.Modify(true);

        BPAddressMgt.UpsertRegistryLegalAddress(
            BusinessPartner,
            ResultBuffer.Address,
            EDRPOUVerificationSourceLbl);
    end;

    local procedure NormalizeComparisonText(Value: Text): Text
    begin
        Value := DelChr(Value, '=', ' ');
        exit(UpperCase(Value));
    end;

    local procedure GetAttributeValue(Element: XmlElement; AttributeName: Text): Text
    var
        Attribute: XmlAttribute;
    begin
        if Element.Attributes().Get(AttributeName, Attribute) then
            exit(Attribute.Value());

        exit('');
    end;

    local procedure ValidateRegistrationNo(RegistrationNo: Text)
    var
        Character: Char;
        Position: Integer;
    begin
        for Position := 1 to StrLen(RegistrationNo) do begin
            Character := RegistrationNo[Position];
            if StrPos('0123456789', Format(Character)) = 0 then
                Error(RegistrationNoMustBeNumericErr);
        end;
    end;

    var
        CompanyNodeMissingErr: Label 'The registry response does not contain company data.';
        CorrectionsDraftOnlyErr: Label 'Automatic registry corrections are allowed only for a Business Partner in Draft status.';
        EDRPOUVerificationSourceLbl: Label 'EDRPOU', Locked = true;
        DataMatchesTxt: Label 'Дані Business Partner відповідають інформації державного реєстру.';
        DifferencesDraftTxt: Label 'Виявлено розбіжності даних з інформацією державного реєстру. Для Business Partner у статусі Draft доступне автоматичне виправлення.';
        DifferencesReadOnlyTxt: Label 'Виявлено розбіжності даних з інформацією державного реєстру. Автоматичне виправлення заборонене, оскільки Business Partner не перебуває у статусі Draft.';
        HttpRequestFailedErr: Label 'The request to the EDRPOU registry service could not be sent.';
        HttpStatusErr: Label 'The EDRPOU registry service returned HTTP %1 (%2).';
        InvalidXmlErr: Label 'The EDRPOU registry service returned an invalid XML response.';
        LegalFormCannotBeAppliedErr: Label 'The country legal form returned by the registry could not be resolved in the SI Country Legal Form dictionary.';
        LegalFormNotResolvedTxt: Label 'Не визначено за довідником';
        OnlyLegalEntitySupportedErr: Label 'EDRPOU verification is available only for legal entities.';
        OnlyUkraineSupportedErr: Label 'EDRPOU verification is available only for business partners registered in Ukraine.';
        RegistrationNoMustBeNumericErr: Label 'For Ukraine, Registration No. must contain digits only.';
        RegistryUrlLbl: Label 'https://adm.tools/action/gov/api/?egrpou=', Locked = true;
        ResponseReadFailedErr: Label 'The response from the EDRPOU registry service could not be read.';
        UkraineCountryCodeLbl: Label 'UA', Locked = true;
}
