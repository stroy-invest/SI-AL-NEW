codeunit 57059 "SI Prok Customer Read"
{
    procedure ReadProjectCustomer(var Project: Record Job)
    var
        Connection: Record "SI Prok Connection";
        Customer: Record Customer;
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        ResponseText: Text;
    begin
        Project.TestField("No.");
        Project.TestField("SI Internal Customer No.");

        Customer.Get(Project."SI Internal Customer No.");
        ConnectionMgt.GetActive(Connection);

        ResponseText := GetCustomerRaw(Connection, Customer."No.");
        ShowCustomerResult(Customer."No.", ResponseText);
    end;

    procedure ResolveCustomerIdentity(
        var Connection: Record "SI Prok Connection";
        CustomerNo: Code[20];
        var InternalCode: BigInteger;
        var ProktekUUID: Guid;
        var ProktekCode: Text): Boolean
    var
        ResponseText: Text;
    begin
        ResponseText := GetCustomerRaw(Connection, CustomerNo);
        exit(
            TryParseCustomerIdentity(
                CustomerNo,
                ResponseText,
                InternalCode,
                ProktekUUID,
                ProktekCode));
    end;

    procedure GetCustomerRaw(
        var Connection: Record "SI Prok Connection";
        CustomerNo: Code[20]): Text
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        RequestBody: Text;
        SessionGuid: Guid;
    begin
        Connection.TestField(Code);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");

        SessionGuid := AuthMgt.GetSessionGuid(Connection);
        RequestBody := BuildCustomerListRequest(SessionGuid, CustomerNo);

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code",
            'GET-CUSTOMERS',
            Connection."EDS Provider Code",
            RuntimeParam,
            RequestBody,
            'application/json-patch+json',
            'text/plain',
            ResponseBuffer);

        if ResponseBuffer.FindFirst() then
            exit(ResponseBuffer.GetBodyText());

        Error('EDS не повернув response buffer для GET-CUSTOMERS.');
    end;

    local procedure BuildCustomerListRequest(
        SessionGuid: Guid;
        CustomerNo: Code[20]): Text
    var
        Root: JsonObject;
        Result: Text;
    begin
        Root.Add('guid', Format(SessionGuid, 0, 4));
        Root.Add('musteri_kod', CustomerNo);
        Root.Add('perpage', 10);
        Root.Add('page', 1);
        Root.WriteTo(Result);
        exit(Result);
    end;

    local procedure TryParseCustomerIdentity(
        BCNo: Code[20];
        ResponseText: Text;
        var InternalCode: BigInteger;
        var ProktekUUID: Guid;
        var ProktekCode: Text): Boolean
    var
        Root: JsonObject;
        CustomerArray: JsonArray;
        CustomerJson: JsonObject;
        Token: JsonToken;
        CustomerToken: JsonToken;
        ResponseStatus: Boolean;
        UUIDText: Text;
        IntegrationCode: Text;
        Index: Integer;
    begin
        Clear(InternalCode);
        Clear(ProktekUUID);
        Clear(ProktekCode);

        if not Root.ReadFrom(ResponseText) then
            exit(false);

        if Root.Get('responseStatus', Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull then
                    ResponseStatus := Token.AsValue().AsBoolean();

        if not ResponseStatus then
            exit(false);

        if not Root.Get('customer', Token) then
            exit(false);

        CustomerArray := Token.AsArray();

        for Index := 0 to CustomerArray.Count() - 1 do begin
            CustomerArray.Get(Index, CustomerToken);
            CustomerJson := CustomerToken.AsObject();

            IntegrationCode := '';
            if CustomerJson.Get('musteri_kod', Token) then
                if Token.IsValue() then
                    if not Token.AsValue().IsNull then
                        IntegrationCode := Token.AsValue().AsText();

            if IntegrationCode = BCNo then begin
                ProktekCode := IntegrationCode;

                if CustomerJson.Get('kod', Token) then
                    if Token.IsValue() then
                        if not Token.AsValue().IsNull then
                            InternalCode := Token.AsValue().AsBigInteger();

                if CustomerJson.Get('uuid', Token) then
                    if Token.IsValue() then
                        if not Token.AsValue().IsNull then begin
                            UUIDText := Token.AsValue().AsText();
                            if not Evaluate(ProktekUUID, UUIDText) then
                                Clear(ProktekUUID);
                        end;

                exit(InternalCode <> 0);
            end;
        end;

        exit(false);
    end;

    local procedure ShowCustomerResult(
        BCNo: Code[20];
        ResponseText: Text)
    var
        Root: JsonObject;
        Token: JsonToken;
        ResponseStatus: Boolean;
        ResponseMessage: Text;
        InternalCode: BigInteger;
        ProktekUUID: Guid;
        ProktekCode: Text;
        CustomerName: Text;
    begin
        if not Root.ReadFrom(ResponseText) then
            Error(
                'GET-CUSTOMERS повернув невалідний JSON:\%1',
                CopyStr(ResponseText, 1, 2000));

        if Root.Get('responseStatus', Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull then
                    ResponseStatus := Token.AsValue().AsBoolean();

        if Root.Get('responseMessage', Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull then
                    ResponseMessage := Token.AsValue().AsText();

        if not ResponseStatus then
            Error(
                'Proktek відхилив GET-CUSTOMERS для %1. %2\Raw response:\%3',
                BCNo,
                ResponseMessage,
                CopyStr(ResponseText, 1, 2000));

        if not TryParseCustomerIdentity(
            BCNo,
            ResponseText,
            InternalCode,
            ProktekUUID,
            ProktekCode)
        then
            Error(
                'GET-CUSTOMERS успішний, але клієнта %1 або його internal kod не знайдено.\Raw response:\%2',
                BCNo,
                CopyStr(ResponseText, 1, 2000));

        CustomerName := GetCustomerName(BCNo, ResponseText);

        Message(
            'GET-CUSTOMERS успішно.\' +
            'BC / musteri_kod: %1\' +
            'Proktek internal kod: %2\' +
            'Proktek UUID: %3\' +
            'Name: %4\\' +
            'Raw response:\%5',
            ProktekCode,
            InternalCode,
            ProktekUUID,
            CustomerName,
            CopyStr(ResponseText, 1, 2000));
    end;

    local procedure GetCustomerName(
        BCNo: Code[20];
        ResponseText: Text): Text
    var
        Root: JsonObject;
        CustomerArray: JsonArray;
        CustomerJson: JsonObject;
        Token: JsonToken;
        CustomerToken: JsonToken;
        IntegrationCode: Text;
        Index: Integer;
    begin
        if not Root.ReadFrom(ResponseText) then
            exit('');

        if not Root.Get('customer', Token) then
            exit('');

        CustomerArray := Token.AsArray();

        for Index := 0 to CustomerArray.Count() - 1 do begin
            CustomerArray.Get(Index, CustomerToken);
            CustomerJson := CustomerToken.AsObject();

            IntegrationCode := '';
            if CustomerJson.Get('musteri_kod', Token) then
                if Token.IsValue() then
                    if not Token.AsValue().IsNull then
                        IntegrationCode := Token.AsValue().AsText();

            if IntegrationCode = BCNo then begin
                if CustomerJson.Get('ad', Token) then
                    if Token.IsValue() then
                        if not Token.AsValue().IsNull then
                            exit(Token.AsValue().AsText());

                exit('');
            end;
        end;

        exit('');
    end;
}
