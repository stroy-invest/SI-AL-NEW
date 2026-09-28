codeunit 54013 "SI EDRPOU Registry Mgt."
{
    procedure CheckAndMaterialize(
        var BusinessPartner: Record "SI Business Partner")
    var
        RegistryMaterializer: Codeunit "SI BP Registry Materializer";
        RegistryResult: Record "SI Registry Result" temporary;
    begin
        ResolveViaEDS(
            BusinessPartner,
            RegistryResult);

        if not RegistryResult.FindFirst() then
            Error(RegistryResultMissingErr);

        RegistryMaterializer.Materialize(
            BusinessPartner,
            RegistryResult);
    end;

    procedure IsCheckAvailable(
        BusinessPartner: Record "SI Business Partner"): Boolean
    begin
        exit(
            (BusinessPartner."Entity Type" =
                BusinessPartner."Entity Type"::"Legal Entity") and
            (BusinessPartner."Country/Region Code" <> '') and
            (BusinessPartner."Registration No." <> '') and
            (UpperCase(BusinessPartner."Country/Region Code") =
                UkraineCountryCodeLbl));
    end;

    procedure ResolveViaEDS(
        BusinessPartner: Record "SI Business Partner";
        var RegistryResult: Record "SI Registry Result" temporary)
    var
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        AdmToolsResolver: Codeunit "SI AdmTools Reg. Resolver";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        ResponseText: Text;
    begin
        ValidateRequest(BusinessPartner);

        RuntimeParam.Add(
            EDRPOURuntimeKeyLbl,
            BusinessPartner."Registration No.");

        EDSOrchestrator.Execute(
            CompanyRegistryServiceLbl,
            GetCompanyOperationLbl,
            RuntimeParam,
            ResponseBuffer);

        if ResponseBuffer."Result Type" <>
           ResponseBuffer."Result Type"::Success
        then
            Error(
                RegistryRequestFailedErr,
                ResponseBuffer."Provider Code",
                ResponseBuffer."HTTP Status Code",
                ResponseBuffer."Error Message");

        ResponseText := ResponseBuffer.GetBodyText();

        if ResponseText = '' then
            Error(EmptyRegistryResponseErr);

        case UpperCase(ResponseBuffer."Provider Code") of
            AdmToolsProviderLbl:
                AdmToolsResolver.Resolve(
                    ResponseText,
                    ResponseBuffer."Provider Code",
                    BusinessPartner."Country/Region Code",
                    RegistryResult);
            else
                Error(
                    UnsupportedRegistryProviderErr,
                    ResponseBuffer."Provider Code");
        end;
    end;

    local procedure ValidateRequest(
        BusinessPartner: Record "SI Business Partner")
    begin
        BusinessPartner.TestField("Entity Type");
        BusinessPartner.TestField("Country/Region Code");
        BusinessPartner.TestField("Registration No.");

        if BusinessPartner."Entity Type" <>
           BusinessPartner."Entity Type"::"Legal Entity"
        then
            Error(OnlyLegalEntitySupportedErr);

        if UpperCase(BusinessPartner."Country/Region Code") <>
           UkraineCountryCodeLbl
        then
            Error(OnlyUkraineSupportedErr);

        ValidateRegistrationNo(
            BusinessPartner."Registration No.");
    end;

    local procedure ValidateRegistrationNo(
        RegistrationNo: Text)
    var
        Character: Char;
        Position: Integer;
    begin
        for Position := 1 to StrLen(RegistrationNo) do begin
            Character := RegistrationNo[Position];

            if StrPos(
                '0123456789',
                Format(Character)) = 0
            then
                Error(RegistrationNoMustBeNumericErr);
        end;
    end;

    var
        UkraineCountryCodeLbl: Label 'UA', Locked = true;

        CompanyRegistryServiceLbl: Label 'COMPANY-REGISTRY', Locked = true;
        GetCompanyOperationLbl: Label 'GET-COMPANY', Locked = true;
        EDRPOURuntimeKeyLbl: Label 'EDRPOU', Locked = true;
        AdmToolsProviderLbl: Label 'ADM-TOOLS', Locked = true;

        OnlyLegalEntitySupportedErr: Label
            'EDRPOU verification is available only for legal entities.';

        OnlyUkraineSupportedErr: Label
            'EDRPOU verification is available only for business partners registered in Ukraine.';

        RegistrationNoMustBeNumericErr: Label
            'For Ukraine, Registration No. must contain digits only.';

        EmptyRegistryResponseErr: Label
            'The registry provider returned an empty response.';

        RegistryRequestFailedErr: Label
            'Registry request failed. Provider: %1, HTTP status: %2, error: %3.';

        UnsupportedRegistryProviderErr: Label
            'Registry provider %1 is not supported by SI Business Partner.';

        RegistryResultMissingErr: Label
            'The registry resolver did not return a result.';
}