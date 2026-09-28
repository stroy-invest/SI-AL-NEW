codeunit 54015 "SI AdmTools Reg. Resolver"
{
    procedure Resolve(
        ResponseText: Text;
        ProviderCode: Code[50];
        CountryRegionCode: Code[10];
        var RegistryResult: Record "SI Registry Result" temporary)
    var
        CompanyElement: XmlElement;
        ErrorElement: XmlElement;
        RootElement: XmlElement;
        ResponseXml: XmlDocument;
        CompanyNode: XmlNode;
        ErrorNode: XmlNode;
        FullName: Text;
        ShortName: Text;
    begin
        RegistryResult.Reset();
        RegistryResult.DeleteAll();

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

        FullName := GetAttributeValue(CompanyElement, 'name');
        ShortName := GetAttributeValue(CompanyElement, 'name_short');

        RegistryResult.Init();
        RegistryResult."Entry No." := 1;
        RegistryResult."Provider Code" := ProviderCode;
        RegistryResult."Country/Region Code" := CountryRegionCode;

        RegistryResult."Registration No." :=
            CopyStr(
                GetAttributeValue(CompanyElement, 'egrpou'),
                1,
                MaxStrLen(RegistryResult."Registration No."));

        RegistryResult."Tax Registration No." :=
            CopyStr(
                GetAttributeValue(CompanyElement, 'inn'),
                1,
                MaxStrLen(RegistryResult."Tax Registration No."));

        RegistryResult."Legal Name" :=
            CopyStr(
                FullName,
                1,
                MaxStrLen(RegistryResult."Legal Name"));

        RegistryResult."Registry Short Name" :=
            CopyStr(
                ShortName,
                1,
                MaxStrLen(RegistryResult."Registry Short Name"));

        RegistryResult."Core Name" :=
            CopyStr(
                ExtractCoreName(FullName),
                1,
                MaxStrLen(RegistryResult."Core Name"));

        RegistryResult."Legal Form Short" :=
            CopyStr(
                ExtractLegalFormShort(ShortName),
                1,
                MaxStrLen(RegistryResult."Legal Form Short"));

        RegistryResult.Address :=
            CopyStr(
                GetAttributeValue(CompanyElement, 'address'),
                1,
                MaxStrLen(RegistryResult.Address));

        RegistryResult.Director :=
            CopyStr(
                GetAttributeValue(CompanyElement, 'director'),
                1,
                MaxStrLen(RegistryResult.Director));

        RegistryResult."Director Genitive" :=
            CopyStr(
                GetAttributeValue(CompanyElement, 'director_gen'),
                1,
                MaxStrLen(RegistryResult."Director Genitive"));

        RegistryResult."KVED No." :=
            CopyStr(
                GetAttributeValue(CompanyElement, 'kved_number'),
                1,
                MaxStrLen(RegistryResult."KVED No."));

        RegistryResult."KVED Description" :=
            CopyStr(
                GetAttributeValue(CompanyElement, 'kved'),
                1,
                MaxStrLen(RegistryResult."KVED Description"));

        RegistryResult."Registration Date" :=
            CopyStr(
                GetAttributeValue(CompanyElement, 'date_from'),
                1,
                MaxStrLen(RegistryResult."Registration Date"));

        RegistryResult."Tax Registration Date" :=
            CopyStr(
                GetAttributeValue(CompanyElement, 'inn_date'),
                1,
                MaxStrLen(RegistryResult."Tax Registration Date"));

        RegistryResult."Registry Last Update" :=
            CopyStr(
                GetAttributeValue(CompanyElement, 'last_update'),
                1,
                MaxStrLen(RegistryResult."Registry Last Update"));

        RegistryResult.Insert();
    end;

    local procedure ExtractCoreName(FullName: Text): Text
    var
        Apostrophe: Char;
        ClosePos: Integer;
        OpenPos: Integer;
        RemainingText: Text;
    begin
        Apostrophe := 39;

        OpenPos := StrPos(FullName, Format(Apostrophe));
        if OpenPos = 0 then
            exit(FullName.Trim());

        RemainingText :=
            CopyStr(
                FullName,
                OpenPos + 1);

        ClosePos :=
            StrPos(
                RemainingText,
                Format(Apostrophe));

        if ClosePos = 0 then
            exit(RemainingText.Trim());

        exit(
            CopyStr(
                RemainingText,
                1,
                ClosePos - 1).Trim());
    end;

    local procedure ExtractLegalFormShort(ShortName: Text): Text
    var
        SpacePos: Integer;
    begin
        ShortName := ShortName.Trim();

        if ShortName = '' then
            exit('');

        SpacePos := StrPos(ShortName, ' ');

        if SpacePos = 0 then
            exit(ShortName);

        exit(
            CopyStr(
                ShortName,
                1,
                SpacePos - 1));
    end;

    local procedure GetAttributeValue(
        Element: XmlElement;
        AttributeName: Text): Text
    var
        Attribute: XmlAttribute;
    begin
        if Element.Attributes().Get(AttributeName, Attribute) then
            exit(Attribute.Value());

        exit('');
    end;

    var
        CompanyNodeMissingErr: Label 'The registry response does not contain company data.';
        InvalidXmlErr: Label 'The registry service returned an invalid XML response.';
}