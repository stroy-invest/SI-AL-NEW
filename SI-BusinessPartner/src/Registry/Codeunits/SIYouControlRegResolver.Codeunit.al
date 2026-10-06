codeunit 54017 "SI YouControl Reg. Resolver" implements "SI Registry Resp. Resolver"
{
    procedure ResolveResponse(
        ResponseText: Text;
        ProviderCode: Code[50];
        CountryRegionCode: Code[10];
        EntityType: Enum "SI BP Entity Type";
        IdentifierType: Enum "SI Registry Identifier Type";
        IdentifierValue: Text[50];
        var RegistryResult: Record "SI Registry Result" temporary)
    var
        Root: JsonObject;
    begin
        RegistryResult.Reset();
        RegistryResult.DeleteAll();

        if not Root.ReadFrom(ResponseText) then
            Error(InvalidJsonErr);

        InitResult(ProviderCode, CountryRegionCode, EntityType, IdentifierType, IdentifierValue, RegistryResult);

        case EntityType of
            Enum::"SI BP Entity Type"::"Legal Entity":
                ResolveLegalEntity(Root, RegistryResult);
            Enum::"SI BP Entity Type"::"Individual Entrepreneur":
                ResolveEntrepreneur(Root, RegistryResult);
            else
                Error(UnsupportedEntityTypeErr, Format(EntityType));
        end;

        RegistryResult.Insert();
    end;

    local procedure InitResult(
        ProviderCode: Code[50];
        CountryRegionCode: Code[10];
        EntityType: Enum "SI BP Entity Type";
        IdentifierType: Enum "SI Registry Identifier Type";
        IdentifierValue: Text[50];
        var RegistryResult: Record "SI Registry Result" temporary)
    begin
        RegistryResult.Init();
        RegistryResult."Entry No." := 1;
        RegistryResult."Provider Code" := ProviderCode;
        RegistryResult."Country/Region Code" := CountryRegionCode;
        RegistryResult."Entity Type" := EntityType;
        RegistryResult."Identifier Type" := IdentifierType;
        RegistryResult."Identifier Value" := IdentifierValue;
    end;

    local procedure ResolveLegalEntity(Root: JsonObject; var RegistryResult: Record "SI Registry Result" temporary)
    var
        NameObject: JsonObject;
    begin
        RegistryResult."Registration No." := CopyStr(GetText(Root, 'code'), 1, MaxStrLen(RegistryResult."Registration No."));
        RegistryResult."Identity Provided" := RegistryResult."Registration No." <> '';

        if TryGetObject(Root, 'name', NameObject) then begin
            RegistryResult."Legal Name" := CopyStr(GetText(NameObject, 'fullName'), 1, MaxStrLen(RegistryResult."Legal Name"));
            RegistryResult."Registry Short Name" := CopyStr(GetText(NameObject, 'shortName'), 1, MaxStrLen(RegistryResult."Registry Short Name"));
            RegistryResult."Core Name" := CopyStr(GetText(Root, 'legalPersonName'), 1, MaxStrLen(RegistryResult."Core Name"));
            RegistryResult."Names Provided" := true;
        end;

        RegistryResult."Legal Form Name" := CopyStr(GetText(Root, 'legalForm'), 1, MaxStrLen(RegistryResult."Legal Form Name"));
        RegistryResult."Legal Form Provided" := HasProperty(Root, 'legalForm');

        ResolveCommonFacts(Root, RegistryResult);
        ResolveManager(Root, RegistryResult);
    end;

    local procedure ResolveEntrepreneur(Root: JsonObject; var RegistryResult: Record "SI Registry Result" temporary)
    begin
        // YouControl's FOP response does not return RNOKPP in the supplied payload.
        // The successfully validated lookup identifier is therefore the canonical
        // identity value for this normalized result.
        if RegistryResult."Identifier Type" = Enum::"SI Registry Identifier Type"::"Tax Registration No." then begin
            RegistryResult."Tax Registration No." := RegistryResult."Identifier Value";
            RegistryResult."Identity Provided" := RegistryResult."Tax Registration No." <> '';
        end;

        RegistryResult."Legal Name" := CopyStr(GetText(Root, 'name'), 1, MaxStrLen(RegistryResult."Legal Name"));
        RegistryResult."Core Name" := CopyStr(RegistryResult."Legal Name", 1, MaxStrLen(RegistryResult."Core Name"));
        RegistryResult."Names Provided" := HasProperty(Root, 'name');

        ResolveCommonFacts(Root, RegistryResult);

        // For an individual entrepreneur the entrepreneur themself is the manager.
        RegistryResult.Director := CopyStr(RegistryResult."Legal Name", 1, MaxStrLen(RegistryResult.Director));
        RegistryResult."Manager Role" := CopyStr('ФОП', 1, MaxStrLen(RegistryResult."Manager Role"));
        RegistryResult."Manager Provided" := RegistryResult."Names Provided";
    end;

    local procedure ResolveCommonFacts(Root: JsonObject; var RegistryResult: Record "SI Registry Result" temporary)
    var
        AddressParts: JsonObject;
        Contacts: JsonObject;
        MainActivity: JsonObject;
    begin
        RegistryResult."Registry Status" := CopyStr(GetText(Root, 'status'), 1, MaxStrLen(RegistryResult."Registry Status"));
        RegistryResult."Status Provided" := HasProperty(Root, 'status');

        RegistryResult."Data Actual At" := GetDateTime(Root, 'actualDate');

        RegistryResult.Address := CopyStr(GetText(Root, 'address'), 1, MaxStrLen(RegistryResult.Address));
        if TryGetObject(Root, 'addressParts', AddressParts) then begin
            RegistryResult."Address Post Code" := CopyStr(GetText(AddressParts, 'zip'), 1, MaxStrLen(RegistryResult."Address Post Code"));
            RegistryResult."Address Region" := CopyStr(GetText(AddressParts, 'region'), 1, MaxStrLen(RegistryResult."Address Region"));
            RegistryResult."Address District" := CopyStr(GetText(AddressParts, 'district'), 1, MaxStrLen(RegistryResult."Address District"));
            RegistryResult."Address City" := CopyStr(GetText(AddressParts, 'city'), 1, MaxStrLen(RegistryResult."Address City"));
            RegistryResult."Address Street" := CopyStr(GetText(AddressParts, 'street'), 1, MaxStrLen(RegistryResult."Address Street"));
            RegistryResult."Address Building" := CopyStr(GetText(AddressParts, 'building'), 1, MaxStrLen(RegistryResult."Address Building"));
            RegistryResult."Address Apartment" := CopyStr(GetText(AddressParts, 'apartment'), 1, MaxStrLen(RegistryResult."Address Apartment"));
        end;
        RegistryResult."Address Provided" := HasProperty(Root, 'address') or HasProperty(Root, 'addressParts');

        if TryGetObject(Root, 'mainEconomicActivity', MainActivity) then begin
            RegistryResult."KVED No." := CopyStr(GetText(MainActivity, 'code'), 1, MaxStrLen(RegistryResult."KVED No."));
            RegistryResult."KVED Description" := CopyStr(GetText(MainActivity, 'description'), 1, MaxStrLen(RegistryResult."KVED Description"));
            RegistryResult."Main Activity Provided" := true;
        end;

        if TryGetObject(Root, 'contacts', Contacts) then begin
            RegistryResult.Phone := CopyStr(GetText(Contacts, 'phone'), 1, MaxStrLen(RegistryResult.Phone));
            RegistryResult.Email := CopyStr(GetText(Contacts, 'email'), 1, MaxStrLen(RegistryResult.Email));
            RegistryResult.Website := CopyStr(GetText(Contacts, 'webSite'), 1, MaxStrLen(RegistryResult.Website));
            RegistryResult."Contacts Provided" := true;
        end;
    end;

    local procedure ResolveManager(Root: JsonObject; var RegistryResult: Record "SI Registry Result" temporary)
    var
        Signers: JsonArray;
        Signer: JsonObject;
        Token: JsonToken;
        I: Integer;
        RoleText: Text;
    begin
        if not TryGetArray(Root, 'signers', Signers) then
            exit;

        for I := 0 to Signers.Count() - 1 do begin
            Signers.Get(I, Token);
            if Token.IsObject() then begin
                Signer := Token.AsObject();
                RoleText := LowerCase(GetText(Signer, 'role'));
                if RoleText = 'керівник' then begin
                    RegistryResult.Director := CopyStr(GetText(Signer, 'name'), 1, MaxStrLen(RegistryResult.Director));
                    RegistryResult."Manager Role" := CopyStr(GetText(Signer, 'role'), 1, MaxStrLen(RegistryResult."Manager Role"));
                    RegistryResult."Manager Authority" := CopyStr(GetText(Signer, 'description'), 1, MaxStrLen(RegistryResult."Manager Authority"));
                    RegistryResult."Manager Appointed At" := GetDateTime(Signer, 'appointDate');
                    RegistryResult."Manager Provided" := true;
                    exit;
                end;
            end;
        end;

        // The provider supplied the signers collection, but it contained no manager.
        // This is an authoritative empty manager fact, not an unsupported fact.
        RegistryResult."Manager Provided" := true;
    end;

    local procedure HasProperty(ObjectValue: JsonObject; PropertyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        exit(ObjectValue.Get(PropertyName, Token));
    end;

    local procedure GetText(ObjectValue: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
        Value: JsonValue;
    begin
        if not ObjectValue.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        Value := Token.AsValue();
        if Value.IsNull() or Value.IsUndefined() then
            exit('');
        exit(Value.AsText());
    end;

    local procedure GetDateTime(ObjectValue: JsonObject; PropertyName: Text): DateTime
    var
        Token: JsonToken;
        Value: JsonValue;
    begin
        if not ObjectValue.Get(PropertyName, Token) then
            exit(0DT);
        if not Token.IsValue() then
            exit(0DT);
        Value := Token.AsValue();
        if Value.IsNull() or Value.IsUndefined() then
            exit(0DT);
        exit(Value.AsDateTime());
    end;

    local procedure TryGetObject(ObjectValue: JsonObject; PropertyName: Text; var ChildObject: JsonObject): Boolean
    var
        Token: JsonToken;
    begin
        Clear(ChildObject);
        if not ObjectValue.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsObject() then
            exit(false);
        ChildObject := Token.AsObject();
        exit(true);
    end;

    local procedure TryGetArray(ObjectValue: JsonObject; PropertyName: Text; var ChildArray: JsonArray): Boolean
    var
        Token: JsonToken;
    begin
        Clear(ChildArray);
        if not ObjectValue.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsArray() then
            exit(false);
        ChildArray := Token.AsArray();
        exit(true);
    end;

    var
        InvalidJsonErr: Label 'The registry service returned an invalid JSON response.';
        UnsupportedEntityTypeErr: Label 'YouControl registry resolver does not support entity type %1.';
}
