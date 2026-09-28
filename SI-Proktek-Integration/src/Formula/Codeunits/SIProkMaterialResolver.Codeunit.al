codeunit 57061 "SI Prok Material Resolver"
{
    procedure BuildMaterialIntegrationKey(ItemNo: Code[20]; VariantCode: Code[10]): Text
    begin
        if ItemNo = '' then
            Error(ItemNoRequiredErr);

        if VariantCode = '' then
            exit(ItemNo);

        exit(StrSubstNo('%1|%2', ItemNo, VariantCode));
    end;

    procedure LoadMaterials(var Materials: JsonArray)
    var
        Connection: Record "SI Prok Connection";
        Session: Record "SI Prok Session";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        Token: JsonToken;
        RequestBody: Text;
        ResponseText: Text;
        ResponseStatus: Boolean;
    begin
        Clear(Materials);

        ConnectionMgt.GetActive(Connection);
        AuthMgt.EnsureSession(Connection, Session);
        if IsNullGuid(Session."Session GUID") then
            Error(SessionGuidMissingErr, Connection.Code);

        RequestJson.Add('guid', Format(Session."Session GUID", 0, 4));
        RequestJson.WriteTo(RequestBody);

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code",
            'GET-MATERIALS',
            Connection."EDS Provider Code",
            RuntimeParam,
            RequestBody,
            'application/json-patch+json',
            'text/plain',
            ResponseBuffer);

        if (ResponseBuffer."HTTP Status Code" < 200) or (ResponseBuffer."HTTP Status Code" >= 300) then
            Error(HttpErr, ResponseBuffer."HTTP Status Code", ResponseBuffer.GetBodyText());

        ResponseText := ResponseBuffer.GetBodyText();
        if not ResponseJson.ReadFrom(ResponseText) then
            Error(InvalidJsonErr);

        if ResponseJson.Get('responseStatus', Token) then begin
            ResponseStatus := Token.AsValue().AsBoolean();
            if not ResponseStatus then
                Error(ApiRejectedErr, GetOptionalText(ResponseJson, 'responseMessage'));
        end;

        if not ResponseJson.Get('materials', Token) then
            Error(MaterialsMissingErr);
        if not Token.IsArray() then
            Error(MaterialsNotArrayErr);

        Materials := Token.AsArray();
    end;

    procedure ResolveFromLoadedMaterials(
        Materials: JsonArray;
        ItemNo: Code[20];
        VariantCode: Code[10];
        var ProktekCode: BigInteger;
        var ProktekUUID: Guid;
        var ProktekName: Text;
        var ProktekType: Text)
    var
        MaterialObj: JsonObject;
        Token: JsonToken;
        IntegrationKey: Text;
        CandidateKey: Text;
        CandidateUUIDText: Text;
        MatchCount: Integer;
        I: Integer;
    begin
        Clear(ProktekCode);
        Clear(ProktekUUID);
        Clear(ProktekName);
        Clear(ProktekType);

        IntegrationKey := BuildMaterialIntegrationKey(ItemNo, VariantCode);

        for I := 0 to Materials.Count() - 1 do begin
            Materials.Get(I, Token);
            if Token.IsObject() then begin
                MaterialObj := Token.AsObject();
                CandidateKey := GetOptionalText(MaterialObj, 'malzeme_ent_kod');
                if (CandidateKey = IntegrationKey) and not GetOptionalBoolean(MaterialObj, 'silindi') then begin
                    MatchCount += 1;
                    if MatchCount = 1 then begin
                        ProktekCode := GetRequiredBigInteger(MaterialObj, 'kod');
                        CandidateUUIDText := GetOptionalText(MaterialObj, 'uuid');
                        if (CandidateUUIDText = '') or not Evaluate(ProktekUUID, CandidateUUIDText) then
                            Error(InvalidUuidErr, IntegrationKey, CandidateUUIDText);
                        ProktekName := GetOptionalText(MaterialObj, 'ad');
                        ProktekType := GetOptionalText(MaterialObj, 'type');
                    end;
                end;
            end;
        end;

        if MatchCount = 0 then
            Error(MaterialNotFoundErr, IntegrationKey);
        if MatchCount > 1 then
            Error(MaterialAmbiguousErr, IntegrationKey, MatchCount);
    end;

    local procedure GetOptionalText(Obj: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Obj.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetOptionalBoolean(Obj: JsonObject; PropertyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not Obj.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure GetRequiredBigInteger(Obj: JsonObject; PropertyName: Text): BigInteger
    var
        Token: JsonToken;
        Value: BigInteger;
    begin
        if not Obj.Get(PropertyName, Token) then
            Error(RequiredPropertyErr, PropertyName);
        if not Token.IsValue() or Token.AsValue().IsNull() then
            Error(RequiredPropertyErr, PropertyName);
        Value := Token.AsValue().AsBigInteger();
        exit(Value);
    end;

    var
        ItemNoRequiredErr: Label 'Item No. must be specified.';
        SessionGuidMissingErr: Label 'Proktek session GUID is missing for connection %1.';
        HttpErr: Label 'GET-MATERIALS failed. HTTP %1. Response: %2';
        InvalidJsonErr: Label 'GET-MATERIALS returned invalid JSON.';
        ApiRejectedErr: Label 'GET-MATERIALS returned responseStatus=false. Message: %1';
        MaterialsMissingErr: Label 'GET-MATERIALS response does not contain materials.';
        MaterialsNotArrayErr: Label 'GET-MATERIALS response property materials is not an array.';
        MaterialNotFoundErr: Label 'Active Proktek material with malzeme_ent_kod=%1 was not found.';
        MaterialAmbiguousErr: Label 'Found %2 active Proktek materials with malzeme_ent_kod=%1. Integration key must be unique.';
        InvalidUuidErr: Label 'Proktek material %1 has invalid UUID: %2.';
        RequiredPropertyErr: Label 'Required Proktek material property %1 is missing.';
}
