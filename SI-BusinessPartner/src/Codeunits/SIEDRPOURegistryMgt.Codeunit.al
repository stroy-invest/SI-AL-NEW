codeunit 54013 "SI EDRPOU Registry Mgt."
{
    procedure CheckAndMaterialize(var BusinessPartner: Record "SI Business Partner"): Boolean
    var
        RegistryResult: Record "SI Registry Result" temporary;
        BackgroundRefreshQueued: Boolean;
    begin
        exit(CheckAndMaterialize(BusinessPartner, RegistryResult, BackgroundRefreshQueued));
    end;

    procedure CheckAndMaterialize(
        var BusinessPartner: Record "SI Business Partner";
        var RegistryResult: Record "SI Registry Result" temporary;
        var BackgroundRefreshQueued: Boolean): Boolean
    var
        RegistryMaterializer: Codeunit "SI BP Registry Materializer";
    begin
        if not ResolveViaEDS(BusinessPartner, RegistryResult, BackgroundRefreshQueued) then
            exit(false);
        if not RegistryResult.FindFirst() then
            Error(RegistryResultMissingErr);
        RegistryMaterializer.Materialize(BusinessPartner, RegistryResult);
        exit(true);
    end;

    procedure IsCheckAvailable(BusinessPartner: Record "SI Business Partner"): Boolean
    begin
        if (BusinessPartner.Status <> BusinessPartner.Status::Draft) or
           (UpperCase(BusinessPartner."Country/Region Code") <> UkraineCountryCodeLbl)
        then
            exit(false);

        case BusinessPartner."Entity Type" of
            BusinessPartner."Entity Type"::"Legal Entity":
                exit(BusinessPartner."Registration No." <> '');
            BusinessPartner."Entity Type"::"Individual Entrepreneur":
                exit(BusinessPartner."Tax Registration No." <> '');
        end;
        exit(false);
    end;

    procedure ResolveViaEDS(
        BusinessPartner: Record "SI Business Partner";
        var RegistryResult: Record "SI Registry Result" temporary;
        var BackgroundRefreshQueued: Boolean): Boolean
    var
        RegistryOrchestrator: Codeunit "SI BP Registry Orchestrator";
        IdentifierType: Enum "SI Registry Identifier Type";
        IdentifierValue: Text[50];
    begin
        ValidateRequest(BusinessPartner, IdentifierType, IdentifierValue);
        exit(RegistryOrchestrator.Resolve(
            BusinessPartner."No.",
            BusinessPartner."Country/Region Code",
            BusinessPartner."Entity Type",
            IdentifierType,
            IdentifierValue,
            RegistryResult,
            BackgroundRefreshQueued));
    end;

    local procedure ValidateRequest(BusinessPartner: Record "SI Business Partner"; var IdentifierType: Enum "SI Registry Identifier Type"; var IdentifierValue: Text[50])
    var
        UAIdentifierMgt: Codeunit "SI UA Identifier Mgt.";
    begin
        BusinessPartner.TestField("Entity Type");
        BusinessPartner.TestField("Country/Region Code");
        if UpperCase(BusinessPartner."Country/Region Code") <> UkraineCountryCodeLbl then Error(OnlyUkraineSupportedErr);

        case BusinessPartner."Entity Type" of
            BusinessPartner."Entity Type"::"Legal Entity": begin
                BusinessPartner.TestField("Registration No.");
                IdentifierType := IdentifierType::"Registration No.";
                IdentifierValue := BusinessPartner."Registration No.";
                UAIdentifierMgt.ValidateEDRPOU(IdentifierValue);
            end;
            BusinessPartner."Entity Type"::"Individual Entrepreneur": begin
                BusinessPartner.TestField("Tax Registration No.");
                IdentifierType := IdentifierType::"Tax Registration No.";
                IdentifierValue := BusinessPartner."Tax Registration No.";
                UAIdentifierMgt.ValidateRNOKPP(IdentifierValue);
            end;
            else
                Error(UnsupportedEntityTypeErr, Format(BusinessPartner."Entity Type"));
        end;
    end;

    var
        UkraineCountryCodeLbl: Label 'UA', Locked = true;
        OnlyUkraineSupportedErr: Label 'Registry lookup is currently supported only for business partners registered in Ukraine.';
        UnsupportedEntityTypeErr: Label 'Registry lookup does not support entity type %1.';
        RegistryResultMissingErr: Label 'The registry resolver did not return a result.';
}
