codeunit 54018 "SI BP Registry Orchestrator"
{
    procedure Resolve(
        BusinessPartnerNo: Code[60];
        CountryRegionCode: Code[10];
        EntityType: Enum "SI BP Entity Type";
        IdentifierType: Enum "SI Registry Identifier Type";
        IdentifierValue: Text[50];
        var RegistryResult: Record "SI Registry Result" temporary;
        var BackgroundRefreshQueued: Boolean): Boolean
    var
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        First202At: DateTime;
        RetryNo: Integer;
        RegistrySource: Record "SI BP Registry Source";
    begin
        RegistryResult.Reset();
        RegistryResult.DeleteAll();
        BackgroundRefreshQueued := false;

        ValidateContext(CountryRegionCode, EntityType, IdentifierType, IdentifierValue);

        RegistrySource.SetRange("Entity Type", EntityType);
        RegistrySource.SetRange(Enabled, true);
        RegistrySource.SetCurrentKey("Entity Type", Priority);
        if not RegistrySource.FindFirst() then
            Error(NoRegistrySourceErr, Format(EntityType));

        if StrPos(UpperCase(RegistrySource."Source Code"), YouScoreProviderPrefixLbl) = 1 then begin
            // Preserve the proven YouScore 202 / current-data / async chain.
            if (RegistrySource."EDS Service Code" <> UARegistryServiceLbl) or
               (RegistrySource."EDS Operation Code" <> GetUSR_OperationLbl) then
                Error(UnsupportedYouScoreRouteErr, RegistrySource."EDS Service Code", RegistrySource."EDS Operation Code");

            ExecuteUsrForProvider(IdentifierValue, RegistrySource."Source Code", ResponseBuffer);
            if ResponseBuffer."HTTP Status Code" = 202 then begin
                First202At := CurrentDateTime;
                for RetryNo := 1 to 3 do begin
                    Sleep(5000);
                    ExecuteUsrForProvider(IdentifierValue, RegistrySource."Source Code", ResponseBuffer);
                    if ResponseBuffer."HTTP Status Code" <> 202 then
                        break;
                end;

                if ResponseBuffer."HTTP Status Code" = 202 then begin
                    ExecuteUsrCurrentForProvider(IdentifierValue, RegistrySource."Source Code", ResponseBuffer);
                    EnsureSuccessfulResponse(ResponseBuffer, GetUSRCurrentOperationLbl);
                    EnqueueUsrRefresh(BusinessPartnerNo, IdentifierValue, First202At);
                    BackgroundRefreshQueued := true;
                end;
            end;
            EnsureSuccessfulResponse(ResponseBuffer, GetUSR_OperationLbl);
        end else begin
            ExecuteConfiguredSource(RegistrySource, IdentifierValue, ResponseBuffer);
            EnsureConfiguredSuccessfulResponse(ResponseBuffer, RegistrySource);
        end;

        ResolveProviderResponse(
            ResponseBuffer,
            CountryRegionCode,
            EntityType,
            IdentifierType,
            IdentifierValue,
            RegistryResult);

        StampOutcome(RegistryResult, ResponseBuffer."Provider Code");
        exit(true);
    end;

    procedure ResolveCompletedAsyncResponse(
        BusinessPartner: Record "SI Business Partner";
        AsyncRequest: Record "SI EDS Async Request";
        var RegistryResult: Record "SI Registry Result" temporary)
    var
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        IdentifierType: Enum "SI Registry Identifier Type";
        IdentifierValue: Text[50];
    begin
        RegistryResult.Reset();
        RegistryResult.DeleteAll();

        GetBusinessPartnerIdentifier(BusinessPartner, IdentifierType, IdentifierValue);
        ValidateContext(
            BusinessPartner."Country/Region Code",
            BusinessPartner."Entity Type",
            IdentifierType,
            IdentifierValue);

        ResponseBuffer.Init();
        ResponseBuffer."Provider Code" := AsyncRequest."Provider Code";
        ResponseBuffer."HTTP Status Code" := AsyncRequest."HTTP Status Code";
        ResponseBuffer."HTTP Reason Phrase" := AsyncRequest."HTTP Reason Phrase";
        ResponseBuffer."Result Type" := ResponseBuffer."Result Type"::Success;
        ResponseBuffer.SetBody(AsyncRequest.GetResponseBody());
        ResponseBuffer.Insert();

        EnsureSuccessfulResponse(ResponseBuffer, AsyncRequest."Operation Code");
        ResolveProviderResponse(
            ResponseBuffer,
            BusinessPartner."Country/Region Code",
            BusinessPartner."Entity Type",
            IdentifierType,
            IdentifierValue,
            RegistryResult);
        StampOutcome(RegistryResult, ResponseBuffer."Provider Code");
    end;

    local procedure ExecuteUsrForProvider(
        IdentifierValue: Text[50]; ProviderCode: Code[50];
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
    begin
        RuntimeParam.Add(ContractorCodeRuntimeKeyLbl, IdentifierValue);
        ExecuteEDSForProvider(UARegistryServiceLbl, GetUSR_OperationLbl, ProviderCode, RuntimeParam, ResponseBuffer);
    end;

    local procedure ExecuteUsrCurrentForProvider(
        IdentifierValue: Text[50]; ProviderCode: Code[50];
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
    begin
        RuntimeParam.Add(ContractorCodeRuntimeKeyLbl, IdentifierValue);
        ExecuteEDSForProvider(UARegistryServiceLbl, GetUSRCurrentOperationLbl, ProviderCode, RuntimeParam, ResponseBuffer);
    end;

    local procedure ExecuteConfiguredSource(
        RegistrySource: Record "SI BP Registry Source";
        IdentifierValue: Text[50];
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
    begin
        RuntimeParam.Add(ResolveIdentifierRuntimeKey(RegistrySource), IdentifierValue);
        ExecuteEDSForProvider(RegistrySource."EDS Service Code", RegistrySource."EDS Operation Code",
            RegistrySource."Source Code", RuntimeParam, ResponseBuffer);
    end;

    local procedure ResolveIdentifierRuntimeKey(RegistrySource: Record "SI BP Registry Source"): Code[50]
    var
        EDSParameter: Record "SI EDS Parameter";
        IdentifierRuntimeKey: Code[50];
    begin
        EDSParameter.SetRange("Service Code", RegistrySource."EDS Service Code");
        EDSParameter.SetRange("Operation Code", RegistrySource."EDS Operation Code");
        EDSParameter.SetRange("Provider Code", RegistrySource."Source Code");
        EDSParameter.SetRange(Enabled, true);
        EDSParameter.SetRange(Source, EDSParameter.Source::Runtime);
        EDSParameter.SetRange(Required, true);
        if EDSParameter.FindSet() then
            repeat
                EDSParameter.TestField("Runtime Key");
                if IdentifierRuntimeKey <> '' then
                    Error(AmbiguousIdentifierRuntimeKeyErr,
                        RegistrySource."EDS Service Code", RegistrySource."EDS Operation Code",
                        RegistrySource."Source Code");
                IdentifierRuntimeKey := EDSParameter."Runtime Key";
            until EDSParameter.Next() = 0;

        if IdentifierRuntimeKey = '' then
            Error(MissingIdentifierRuntimeKeyErr,
                RegistrySource."EDS Service Code", RegistrySource."EDS Operation Code",
                RegistrySource."Source Code");
        exit(IdentifierRuntimeKey);
    end;

    local procedure ExecuteEDSForProvider(
        ServiceCode: Code[50]; OperationCode: Code[50]; ProviderCode: Code[50];
        var RuntimeParam: Record "SI EDS Runtime Param" temporary;
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        ProviderContext: Codeunit "SI EDS Provider Context";
        ScopeToken: Guid;
        FailureText: Text;
    begin
        ResponseBuffer.Reset();
        ResponseBuffer.DeleteAll();
        ProviderContext.BeginScope(ServiceCode, ProviderCode, ScopeToken);
        if not TryExecuteEDS(ServiceCode, OperationCode, RuntimeParam, ResponseBuffer) then begin
            FailureText := GetLastErrorText();
            ProviderContext.EndScope(ScopeToken);
            Error('%1', FailureText);
        end;
        ProviderContext.EndScope(ScopeToken);
        if not ResponseBuffer.FindFirst() then
            Error(EDSResponseMissingErr);
        if ResponseBuffer."Provider Code" <> ProviderCode then
            Error(ProviderMismatchErr, ProviderCode, ResponseBuffer."Provider Code");
    end;

    [TryFunction]
    local procedure TryExecuteEDS(
        ServiceCode: Code[50]; OperationCode: Code[50];
        var RuntimeParam: Record "SI EDS Runtime Param" temporary;
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary)
    var
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
    begin
        EDSOrchestrator.Execute(ServiceCode, OperationCode, RuntimeParam, ResponseBuffer);
    end;

    local procedure EnsureConfiguredSuccessfulResponse(
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        RegistrySource: Record "SI BP Registry Source")
    begin
        if (ResponseBuffer."HTTP Status Code" <> 200) or
           (ResponseBuffer."Result Type" <> ResponseBuffer."Result Type"::Success) then
            Error(RegistryRequestFailedErr, RegistrySource."EDS Service Code",
                RegistrySource."EDS Operation Code", ResponseBuffer."Provider Code", BuildFailureReason(ResponseBuffer));
    end;

    local procedure EnqueueUsrRefresh(
        BusinessPartnerNo: Code[60];
        IdentifierValue: Text[50];
        StartedAt: DateTime)
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        EDSAsyncMgt: Codeunit "SI EDS Async Mgt.";
    begin
        RuntimeParam.Add(ContractorCodeRuntimeKeyLbl, IdentifierValue);
        EDSAsyncMgt.Enqueue(
            UARegistryServiceLbl,
            GetUSR_OperationLbl,
            BusinessPartnerNo,
            StartedAt,
            RuntimeParam);
    end;

    local procedure GetBusinessPartnerIdentifier(
        BusinessPartner: Record "SI Business Partner";
        var IdentifierType: Enum "SI Registry Identifier Type";
        var IdentifierValue: Text[50])
    begin
        case BusinessPartner."Entity Type" of
            BusinessPartner."Entity Type"::"Legal Entity":
                begin
                    IdentifierType := IdentifierType::"Registration No.";
                    IdentifierValue := BusinessPartner."Registration No.";
                end;
            BusinessPartner."Entity Type"::"Individual Entrepreneur":
                begin
                    IdentifierType := IdentifierType::"Tax Registration No.";
                    IdentifierValue := BusinessPartner."Tax Registration No.";
                end;
            else
                Error(UnsupportedEntityTypeErr, Format(BusinessPartner."Entity Type"));
        end;
    end;

    local procedure ValidateContext(
        CountryRegionCode: Code[10];
        EntityType: Enum "SI BP Entity Type";
        IdentifierType: Enum "SI Registry Identifier Type";
        IdentifierValue: Text[50])
    var
        UAIdentifierMgt: Codeunit "SI UA Identifier Mgt.";
    begin
        if UpperCase(CountryRegionCode) <> UkraineCountryCodeLbl then
            Error(OnlyUkraineSupportedErr);

        case EntityType of
            Enum::"SI BP Entity Type"::"Legal Entity":
                begin
                    if IdentifierType <> Enum::"SI Registry Identifier Type"::"Registration No." then
                        Error(InvalidIdentifierTypeErr, Format(EntityType), Format(IdentifierType));
                    UAIdentifierMgt.ValidateEDRPOU(IdentifierValue);
                end;
            Enum::"SI BP Entity Type"::"Individual Entrepreneur":
                begin
                    if IdentifierType <> Enum::"SI Registry Identifier Type"::"Tax Registration No." then
                        Error(InvalidIdentifierTypeErr, Format(EntityType), Format(IdentifierType));
                    UAIdentifierMgt.ValidateRNOKPP(IdentifierValue);
                end;
            else
                Error(UnsupportedEntityTypeErr, Format(EntityType));
        end;
    end;

    local procedure EnsureSuccessfulResponse(
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        OperationCode: Code[50])
    begin
        if (ResponseBuffer."HTTP Status Code" <> 200) or
           (ResponseBuffer."Result Type" <> ResponseBuffer."Result Type"::Success)
        then
            Error(
                RegistryRequestFailedErr,
                UARegistryServiceLbl,
                OperationCode,
                ResponseBuffer."Provider Code",
                BuildFailureReason(ResponseBuffer));
    end;

    local procedure ResolveProviderResponse(
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        CountryRegionCode: Code[10];
        EntityType: Enum "SI BP Entity Type";
        IdentifierType: Enum "SI Registry Identifier Type";
        IdentifierValue: Text[50];
        var RegistryResult: Record "SI Registry Result" temporary)
    var
        AdmToolsResolver: Codeunit "SI AdmTools Reg. Resolver";
        YouControlResolver: Codeunit "SI YouControl Reg. Resolver";
        ResponseText: Text;
        ProviderCodeUpper: Text;
    begin
        ResponseText := ResponseBuffer.GetBodyText();
        if ResponseText = '' then
            Error(EmptyRegistryResponseErr, ResponseBuffer."Provider Code");

        ProviderCodeUpper := UpperCase(ResponseBuffer."Provider Code");
        if StrPos(ProviderCodeUpper, YouScoreProviderPrefixLbl) = 1 then begin
            YouControlResolver.ResolveResponse(
                ResponseText,
                ResponseBuffer."Provider Code",
                CountryRegionCode,
                EntityType,
                IdentifierType,
                IdentifierValue,
                RegistryResult);
            exit;
        end;

        if StrPos(ProviderCodeUpper, AdmToolsProviderPrefixLbl) = 1 then begin
            AdmToolsResolver.ResolveResponse(
                ResponseText,
                ResponseBuffer."Provider Code",
                CountryRegionCode,
                EntityType,
                IdentifierType,
                IdentifierValue,
                RegistryResult);
            exit;
        end;

        Error(UnsupportedRegistryProviderErr, ResponseBuffer."Provider Code");
    end;

    local procedure StampOutcome(
        var RegistryResult: Record "SI Registry Result" temporary;
        ActualProviderCode: Code[50])
    begin
        if not RegistryResult.FindFirst() then
            Error(RegistryResultMissingErr);

        RegistryResult."Sync Outcome" := Enum::"SI Registry Sync Outcome"::Success;
        RegistryResult."Primary Provider Code" := ActualProviderCode;
        RegistryResult."Fallback Used" := false;
        Clear(RegistryResult."Primary Failure Reason");
        RegistryResult.Modify();
    end;

    local procedure BuildFailureReason(
        ResponseBuffer: Record "SI EDS Response Buffer" temporary): Text
    var
        ReasonText: Text;
    begin
        ReasonText := Format(ResponseBuffer."Result Type");
        if ResponseBuffer."HTTP Status Code" <> 0 then
            ReasonText += StrSubstNo(', HTTP %1', ResponseBuffer."HTTP Status Code");
        if ResponseBuffer."Error Message" <> '' then
            ReasonText += ': ' + ResponseBuffer."Error Message";
        exit(CopyStr(ReasonText, 1, 250));
    end;

    var
        UkraineCountryCodeLbl: Label 'UA', Locked = true;
        UARegistryServiceLbl: Label 'UA-REGISTRY', Locked = true;
        GetUSR_OperationLbl: Label 'GET-USR', Locked = true;
        GetUSRCurrentOperationLbl: Label 'GET-USR-CURRENT', Locked = true;
        MissingIdentifierRuntimeKeyErr: Label 'No enabled required runtime identifier parameter for EDS %1 / %2 / %3.';
        AmbiguousIdentifierRuntimeKeyErr: Label 'Multiple enabled required runtime parameters for EDS %1 / %2 / %3. Cannot identify contractor code safely.';
        ContractorCodeRuntimeKeyLbl: Label 'CONTRACTOR-CODE', Locked = true;
        YouScoreProviderPrefixLbl: Label 'YOUSCORE', Locked = true;
        AdmToolsProviderPrefixLbl: Label 'ADM-TOOLS', Locked = true;

        OnlyUkraineSupportedErr: Label 'Registry lookup is currently supported only for business partners registered in Ukraine.';
        UnsupportedEntityTypeErr: Label 'Registry lookup does not support entity type %1.';
        InvalidIdentifierTypeErr: Label 'Entity type %1 cannot be looked up by identifier type %2.';
        EDSResponseMissingErr: Label 'EDS did not return Response Buffer.';
        EmptyRegistryResponseErr: Label 'Registry provider %1 returned an empty response.';
        UnsupportedRegistryProviderErr: Label 'Registry provider %1 returned a response, but SI Business Partner has no resolver for its response contract.';
        RegistryResultMissingErr: Label 'The registry resolver did not return a result.';
        NoRegistrySourceErr: Label 'No enabled registry source is configured for entity type %1.';
        UnsupportedYouScoreRouteErr: Label 'YouScore async flow requires UA-REGISTRY / GET-USR; configured %1 / %2.';
        ProviderMismatchErr: Label 'Expected EDS provider %1, but response was returned by %2.';
        RegistryRequestFailedErr: Label 'Registry lookup failed. EDS service %1, operation %2, provider %3. %4';
}
