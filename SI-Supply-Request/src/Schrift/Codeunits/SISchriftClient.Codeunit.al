codeunit 61020 "SI Schrift Client"
{
    var
        ApiKeyStorageKeyLbl: Label 'SI.SupplyRequest.Schrift.ApiKey', Locked = true;

    procedure SetApiKey(ApiKey: Text)
    begin
        if ApiKey = '' then
            Error('API-ключ Schrift не може бути порожнім.');

        IsolatedStorage.SetEncrypted(ApiKeyStorageKeyLbl, ApiKey, DataScope::Module);
    end;

    procedure HasApiKey(): Boolean
    begin
        exit(IsolatedStorage.Contains(ApiKeyStorageKeyLbl, DataScope::Module));
    end;

    procedure ClearApiKey()
    begin
        if HasApiKey() then
            IsolatedStorage.Delete(ApiKeyStorageKeyLbl, DataScope::Module);
    end;

    procedure GetDocumentsByDocumentType(DocumentTypeId: Integer; var ResponseObject: JsonObject)
    var
        Setup: Record "SI Supply Req Setup";
        RelativeUrl: Text;
    begin
        GetSetup(Setup);
        // Schrift Documents list does not expose TemplateId in summary rows.
        // Request by DocumentTypeId when supported; Intake also filters locally.
        RelativeUrl := StrSubstNo('/Documents?DocumentTypeId=%1', DocumentTypeId);
        GetJson(Setup, RelativeUrl, ResponseObject);
    end;

    procedure GetDocument(DocumentId: Integer; var ResponseObject: JsonObject)
    var
        Setup: Record "SI Supply Req Setup";
        RelativeUrl: Text;
    begin
        GetSetup(Setup);
        RelativeUrl := StrSubstNo('/Documents/%1', DocumentId);
        GetJson(Setup, RelativeUrl, ResponseObject);
    end;


    procedure GetPropertyDefinitions(PropertyIds: List of [Integer]; var ResponseArray: JsonArray)
    var
        Setup: Record "SI Supply Req Setup";
        PropertyId: Integer;
        RelativeUrl: Text;
        Separator: Text;
    begin
        GetSetup(Setup);
        RelativeUrl := '/Dictionaries/Properties';
        Separator := '?';
        foreach PropertyId in PropertyIds do begin
            RelativeUrl += StrSubstNo('%1PropertyId=%2', Separator, PropertyId);
            Separator := '&';
        end;
        GetJsonArray(Setup, RelativeUrl, ResponseArray);
    end;

    procedure GetCustomDictionaryValue(CustomDictionaryId: Integer; CustomDictionaryValueId: Integer; var ResponseArray: JsonArray)
    var
        Setup: Record "SI Supply Req Setup";
        RelativeUrl: Text;
    begin
        GetSetup(Setup);
        RelativeUrl := StrSubstNo('/Dictionaries/CustomDictionaries/%1/Values?CustomDictionaryValueId=%2', CustomDictionaryId, CustomDictionaryValueId);
        GetJsonArray(Setup, RelativeUrl, ResponseArray);
    end;

    local procedure GetJson(Setup: Record "SI Supply Req Setup"; RelativeUrl: Text; var ResponseObject: JsonObject)
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        ApiKey: Text;
        ResponseText: Text;
        Url: Text;
    begin
        GetApiKey(ApiKey);

        Url := DelChr(Setup."Schrift Base URL", '>', '/') + RelativeUrl;
        Request.Method := 'GET';
        Request.SetRequestUri(Url);
        Request.GetHeaders(Headers);
        Headers.Add('X-API-KEY', ApiKey);
        Headers.Add('Accept', 'application/json');

        if not Client.Send(Request, Response) then
            Error('Не вдалося виконати HTTP-запит до Schrift: %1.', Url);

        Response.Content.ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then
            Error('Schrift повернув HTTP %1 %2. Відповідь: %3', Response.HttpStatusCode(), Response.ReasonPhrase(), CopyStr(ResponseText, 1, 1000));

        Clear(ResponseObject);
        if not ResponseObject.ReadFrom(ResponseText) then
            Error('Schrift повернув некоректний JSON. Відповідь: %1', CopyStr(ResponseText, 1, 1000));
    end;

    local procedure GetJsonArray(Setup: Record "SI Supply Req Setup"; RelativeUrl: Text; var ResponseArray: JsonArray)
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        ApiKey: Text;
        ResponseText: Text;
        Url: Text;
    begin
        GetApiKey(ApiKey);
        Url := DelChr(Setup."Schrift Base URL", '>', '/') + RelativeUrl;
        Request.Method := 'GET';
        Request.SetRequestUri(Url);
        Request.GetHeaders(Headers);
        Headers.Add('X-API-KEY', ApiKey);
        Headers.Add('Accept', 'application/json');
        if not Client.Send(Request, Response) then
            Error('Не вдалося виконати HTTP-запит до Schrift: %1.', Url);
        Response.Content.ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then
            Error('Schrift повернув HTTP %1 %2. Відповідь: %3', Response.HttpStatusCode(), Response.ReasonPhrase(), CopyStr(ResponseText, 1, 1000));
        Clear(ResponseArray);
        if ResponseArray.ReadFrom(ResponseText) then
            exit;
        ReadArrayFromEnvelope(ResponseText, ResponseArray);
    end;

    local procedure ReadArrayFromEnvelope(ResponseText: Text; var ResponseArray: JsonArray)
    var
        Envelope: JsonObject;
        Token: JsonToken;
    begin
        if not Envelope.ReadFrom(ResponseText) then
            Error('Schrift повернув некоректний JSON. Відповідь: %1', CopyStr(ResponseText, 1, 1000));
        if Envelope.Get('Data', Token) and Token.IsArray() then begin
            ResponseArray := Token.AsArray();
            exit;
        end;
        if Envelope.Get('Items', Token) and Token.IsArray() then begin
            ResponseArray := Token.AsArray();
            exit;
        end;
        Error('У відповіді Schrift не знайдено JSON-масив Data/Items. Відповідь: %1', CopyStr(ResponseText, 1, 1000));
    end;

    local procedure GetSetup(var Setup: Record "SI Supply Req Setup")
    begin
        if not Setup.Get('') then
            Error('Спочатку відкрийте налаштування заявок на забезпечення та налаштуйте Schrift.');

        Setup.TestField("Schrift Base URL");
        Setup.TestField("Schrift Template ID");
        Setup.TestField("Schrift Document Type ID");
        if not Setup."Schrift Enabled" then
            Error('Інтеграцію Schrift вимкнено в налаштуваннях.');
        if not HasApiKey() then
            Error('API-ключ Schrift не налаштований.');
    end;

    local procedure GetApiKey(var ApiKey: Text)
    begin
        if not IsolatedStorage.Get(ApiKeyStorageKeyLbl, DataScope::Module, ApiKey) then
            Error('API-ключ Schrift не налаштований.');
    end;
}
