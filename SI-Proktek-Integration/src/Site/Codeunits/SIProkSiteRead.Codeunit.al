codeunit 57074 "SI Prok Site Read"
{
    procedure ResolveSiteIdentity(
        var Connection: Record "SI Prok Connection";
        CustomerUUID: Guid;
        SiteCode: Code[20];
        var InternalCode: BigInteger;
        var ProktekUUID: Guid;
        var ProktekCode: Text): Boolean
    var
        ResponseText: Text;
    begin
        ResponseText := GetSiteRaw(Connection, CustomerUUID, SiteCode);
        exit(TryParseSiteIdentity(CustomerUUID, SiteCode, ResponseText, InternalCode, ProktekUUID, ProktekCode));
    end;

    procedure GetSiteRaw(var Connection: Record "SI Prok Connection"; CustomerUUID: Guid; SiteCode: Code[20]): Text
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        SessionGuid: Guid;
        RequestBody: Text;
    begin
        Connection.TestField(Code);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");
        if IsNullGuid(CustomerUUID) then
            Error('Для GET-SITES не визначено UUID клієнта Proktek.');
        if SiteCode = '' then
            Error('Для GET-SITES не визначено код будмайданчика BC.');

        SessionGuid := AuthMgt.GetSessionGuid(Connection);
        RequestBody := BuildSiteListRequest(SessionGuid, CustomerUUID, SiteCode);

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code", 'GET-SITES', Connection."EDS Provider Code",
            RuntimeParam, RequestBody, 'application/json-patch+json', 'text/plain', ResponseBuffer);

        if ResponseBuffer.FindFirst() then
            exit(ResponseBuffer.GetBodyText());
        Error('EDS не повернув response buffer для GET-SITES.');
    end;

    local procedure BuildSiteListRequest(SessionGuid: Guid; CustomerUUID: Guid; SiteCode: Code[20]): Text
    var
        Root: JsonObject;
        Result: Text;
    begin
        Root.Add('guid', Format(SessionGuid, 0, 4));
        Root.Add('musteri_uuid', Format(CustomerUUID, 0, 4));
        Root.Add('filter_santiye_kod', SiteCode);
        Root.Add('perpage', 10);
        Root.Add('page', 1);
        Root.WriteTo(Result);
        exit(Result);
    end;

    local procedure TryParseSiteIdentity(
        ExpectedCustomerUUID: Guid;
        SiteCode: Code[20];
        ResponseText: Text;
        var InternalCode: BigInteger;
        var ProktekUUID: Guid;
        var ProktekCode: Text): Boolean
    var
        Root: JsonObject;
        Sites: JsonArray;
        SiteJson: JsonObject;
        Token: JsonToken;
        SiteToken: JsonToken;
        ResponseStatus: Boolean;
        CandidateSiteCode: Text;
        CustomerUUIDText: Text;
        CandidateCustomerUUID: Guid;
        UUIDText: Text;
        I: Integer;
        MatchCount: Integer;
    begin
        Clear(InternalCode);
        Clear(ProktekUUID);
        Clear(ProktekCode);

        if not Root.ReadFrom(ResponseText) then
            Error('Proktek GET-SITES повернув невалідний JSON: %1', CopyStr(ResponseText, 1, 1000));
        if not Root.Get('responseStatus', Token) then
            Error('У відповіді GET-SITES відсутнє поле responseStatus.');
        ResponseStatus := Token.AsValue().AsBoolean();
        if not ResponseStatus then
            Error('Proktek відхилив GET-SITES для будмайданчика %1.', SiteCode);
        if not Root.Get('site', Token) then
            exit(false);
        if not Token.IsArray() then
            exit(false);

        Sites := Token.AsArray();
        for I := 0 to Sites.Count() - 1 do begin
            Sites.Get(I, SiteToken);
            SiteJson := SiteToken.AsObject();
            Clear(CandidateSiteCode);
            Clear(CandidateCustomerUUID);

            if SiteJson.Get('santiye_kod', Token) and Token.IsValue() and (not Token.AsValue().IsNull) then
                CandidateSiteCode := Token.AsValue().AsText();
            if SiteJson.Get('musteri_uuid', Token) and Token.IsValue() and (not Token.AsValue().IsNull) then begin
                CustomerUUIDText := Token.AsValue().AsText();
                Evaluate(CandidateCustomerUUID, CustomerUUIDText);
            end;

            if (CandidateSiteCode = SiteCode) and (CandidateCustomerUUID = ExpectedCustomerUUID) then begin
                MatchCount += 1;
                if SiteJson.Get('kod', Token) and Token.IsValue() and (not Token.AsValue().IsNull) then
                    InternalCode := Token.AsValue().AsBigInteger();
                if SiteJson.Get('uuid', Token) and Token.IsValue() and (not Token.AsValue().IsNull) then begin
                    UUIDText := Token.AsValue().AsText();
                    if not Evaluate(ProktekUUID, UUIDText) then
                        Clear(ProktekUUID);
                end;
                ProktekCode := CandidateSiteCode;
            end;
        end;

        if MatchCount > 1 then
            Error('GET-SITES повернув %1 будмайданчики з кодом %2 для одного клієнта. Потрібне ручне виправлення даних Proktek.', MatchCount, SiteCode);

        exit((MatchCount = 1) and (InternalCode <> 0) and (not IsNullGuid(ProktekUUID)));
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    var
        EmptyGuid: Guid;
    begin
        exit(Value = EmptyGuid);
    end;
}
