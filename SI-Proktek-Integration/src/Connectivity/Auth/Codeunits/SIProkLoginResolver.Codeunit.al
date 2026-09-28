codeunit 57052 "SI Prok Login Resolver"
{
    procedure Apply(
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        ConnectionCode: Code[50];
        var Session: Record "SI Prok Session")
    var
        BodyInStream: InStream;
        ResponseJson: JsonObject;
        ResponseStatus: Boolean;
        ResponseMessage: Text;
        SessionGuidText: Text;
        ExpiresAtText: Text;
        LoginUsername: Text;
        SessionGuid: Guid;
        ExpiresAt: DateTime;
    begin
        if ResponseBuffer."Result Type" <> ResponseBuffer."Result Type"::Success then
            RaiseLoginTransportError(ResponseBuffer, ConnectionCode);

        if not ResponseBuffer.GetBodyInStream(BodyInStream) then
            Error('Proktek повернув порожню відповідь під час авторизації.');

        if not ResponseJson.ReadFrom(BodyInStream) then
            Error('Не вдалося прочитати JSON-відповідь Proktek під час авторизації.');

        if not TryGetBoolean(ResponseJson, 'responseStatus', ResponseStatus) then
            Error('У відповіді Proktek відсутнє поле responseStatus.');

        TryGetText(ResponseJson, 'responseMessage', ResponseMessage);

        if not ResponseStatus then begin
            if ResponseMessage = '' then
                ResponseMessage := 'Proktek відхилив запит авторизації.';
            Error('%1', ResponseMessage);
        end;

        if not TryGetText(ResponseJson, 'guid', SessionGuidText) then
            Error('Успішна відповідь Proktek не містить GUID сеансу.');

        if not Evaluate(SessionGuid, SessionGuidText) then
            Error('Proktek повернув некоректний GUID сеансу: %1.', SessionGuidText);

        TryGetText(ResponseJson, 'expires_at', ExpiresAtText);
        TryGetText(ResponseJson, 'username', LoginUsername);

        if not Session.Get(ConnectionCode) then begin
            Session.Init();
            Session."Connection Code" := ConnectionCode;
            Session.Insert();
        end;

        Session."Session GUID" := SessionGuid;
        Session."Expires At Raw" := CopyStr(ExpiresAtText, 1, MaxStrLen(Session."Expires At Raw"));

        if (ExpiresAtText <> '') and Evaluate(ExpiresAt, ExpiresAtText) then
            Session."Expires At" := ExpiresAt
        else
            Session."Expires At" := 0DT;

        Session.Username := CopyStr(LoginUsername, 1, MaxStrLen(Session.Username));
        Session."Plant IDs" := CopyStr(GetIntegerArrayText(ResponseJson, 'santral_id'), 1, MaxStrLen(Session."Plant IDs"));
        Session."Scale IDs" := CopyStr(GetIntegerArrayText(ResponseJson, 'kantar_id'), 1, MaxStrLen(Session."Scale IDs"));
        Session."Logged In At" := CurrentDateTime;
        Session."Response Message" := CopyStr(ResponseMessage, 1, MaxStrLen(Session."Response Message"));
        Session.Modify();
    end;

    local procedure RaiseLoginTransportError(
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        ConnectionCode: Code[50])
    var
        Connection: Record "SI Prok Connection";
        CredentialMgt: Codeunit "SI EDS Credential Mgt.";
        ResponseBody: Text;
        ResponseHeaders: Text;
        PasswordConfigured: Boolean;
        ServiceCode: Code[50];
        ProviderCode: Code[50];
        OperationCode: Code[50];
        CompanyCode: Text;
        Username: Text;
        CredentialCode: Code[50];
    begin
        if Connection.Get(ConnectionCode) then begin
            ServiceCode := Connection."EDS Service Code";
            ProviderCode := Connection."EDS Provider Code";
            OperationCode := Connection."EDS Login Operation";
            CompanyCode := Connection."Company Code";
            Username := Connection.Username;
            CredentialCode := Connection."Password Credential Code";

            if (ProviderCode <> '') and (CredentialCode <> '') then
                PasswordConfigured := CredentialMgt.HasSecret(ProviderCode, CredentialCode);
        end;

        ResponseBody := ResponseBuffer.GetBodyText();
        ResponseHeaders := ResponseBuffer.GetHeadersText();

        if ResponseBody = '' then
            ResponseBody := '<порожнє тіло відповіді>';

        if ResponseHeaders = '' then
            ResponseHeaders := '<заголовки відповіді відсутні>';

        Error(
            'Авторизація Proktek відхилена зовнішнім сервісом.\' +
            '\' +
            'HTTP Status = %1\' +
            'HTTP Reason = %2\' +
            'Blocked By BC Environment = %3\' +
            'EDS Result = %4\' +
            'EDS Error = %5\' +
            '\' +
            'Безпечні параметри запиту:\' +
            'Request URL = %6\' +
            'HTTP Method = %7\' +
            'Content-Type = %8\' +
            'Service Code = %9\' +
            'Operation Code = %10\' +
            'Provider Code = %11\' +
            'Company Code = %12\' +
            'Username = %13\' +
            'Credential Code = %14\' +
            'Password Configured = %15\' +
            '\' +
            'Response Headers:\' +
            '%16\' +
            '\' +
            'Response Body:\' +
            '%17',
            ResponseBuffer."HTTP Status Code",
            ResponseBuffer."HTTP Reason Phrase",
            ResponseBuffer."Blocked By Environment",
            Format(ResponseBuffer."Result Type"),
            ResponseBuffer."Error Message",
            ResponseBuffer."Request URL",
            Format(ResponseBuffer."Request Method"),
            ResponseBuffer."Request Content Type",
            ServiceCode,
            OperationCode,
            ProviderCode,
            CompanyCode,
            Username,
            CredentialCode,
            PasswordConfigured,
            ResponseHeaders,
            ResponseBody);
    end;

    local procedure TryGetText(Json: JsonObject; PropertyName: Text; var Value: Text): Boolean
    var
        Token: JsonToken;
    begin
        Clear(Value);
        if not Json.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);

        Value := Token.AsValue().AsText();
        exit(true);
    end;

    local procedure TryGetBoolean(Json: JsonObject; PropertyName: Text; var Value: Boolean): Boolean
    var
        Token: JsonToken;
    begin
        Clear(Value);
        if not Json.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);

        Value := Token.AsValue().AsBoolean();
        exit(true);
    end;

    local procedure GetIntegerArrayText(Json: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
        ArrayValue: JsonArray;
        ItemToken: JsonToken;
        Result: Text;
        Index: Integer;
    begin
        if not Json.Get(PropertyName, Token) then
            exit('');
        if not Token.IsArray() then
            exit('');

        ArrayValue := Token.AsArray();
        if ArrayValue.Count() = 0 then
            exit('');

        for Index := 0 to ArrayValue.Count() - 1 do begin
            ArrayValue.Get(Index, ItemToken);
            if ItemToken.IsValue() and not ItemToken.AsValue().IsNull() then begin
                if Result <> '' then
                    Result += ',';
                Result += Format(ItemToken.AsValue().AsInteger());
            end;
        end;

        exit(Result);
    end;
}
