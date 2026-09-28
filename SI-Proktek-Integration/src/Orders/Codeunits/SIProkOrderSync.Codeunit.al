codeunit 57069 "SI Prok Order Sync"
{
    procedure SendOrder(var ProdRequest: Record "SI Concrete Prod Request")
    var
        Connection: Record "SI Prok Connection";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
    begin
        ValidateNotAlreadySent(ProdRequest);
        ConnectionMgt.GetActive(Connection);

        if Connection.Environment = Connection.Environment::Production then
            if not Confirm(
                'Буде створено реальний Order у ПРОДУКТИВНОМУ Proktek для заявки #%1. Продовжити?',
                false,
                ProdRequest."Entry No.")
            then
                exit;

        ExecuteSaveOrder(Connection, ProdRequest);
    end;

    procedure SendPreparedOrder(var ProdRequest: Record "SI Concrete Prod Request")
    var
        Connection: Record "SI Prok Connection";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
    begin
        ValidateNotAlreadySent(ProdRequest);
        ConnectionMgt.GetActive(Connection);
        ExecuteSaveOrder(Connection, ProdRequest);
    end;

    local procedure ExecuteSaveOrder(
        var Connection: Record "SI Prok Connection";
        var ProdRequest: Record "SI Concrete Prod Request")
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        OrderProjector: Codeunit "SI Prok Order Projector";
        RequestBody: Text;
        ResponseText: Text;
        SavedOrderUUID: Guid;
        AddOrderNo: Text;
        ResponseMessage: Text;
    begin
        Connection.TestField(Code);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");

        RequestBody := OrderProjector.BuildOrderPayload(ProdRequest);
        AddOrderNo := GetAddOrderNo(RequestBody);
        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code",
            'SAVE-ORDER',
            Connection."EDS Provider Code",
            RuntimeParam,
            RequestBody,
            'application/json-patch+json',
            'text/plain',
            ResponseBuffer);

        ResponseText := GetResponseText(ResponseBuffer, 'SAVE-ORDER');
        ParseSaveOrderResponse(ResponseText, SavedOrderUUID, ResponseMessage);

        // SAVE-ORDER is a remote side effect. Persist the returned UUID before
        // reconciliation so a later GET failure can never cause an accidental CREATE retry.
        ProdRequest."Proktek Order UUID" := SavedOrderUUID;
        ProdRequest."Proktek Last Message" := CopyStr(ResponseMessage, 1, MaxStrLen(ProdRequest."Proktek Last Message"));
        ProdRequest.Modify(false);
        Commit();

        ReconcileOrder(Connection, ProdRequest, SavedOrderUUID, AddOrderNo);
    end;

    local procedure ParseSaveOrderResponse(
        ResponseText: Text;
        var OrderUUID: Guid;
        var ResponseMessage: Text)
    var
        Root: JsonObject;
        OrderJson: JsonObject;
        Token: JsonToken;
        ResponseStatus: Boolean;
        UUIDText: Text;
    begin
        if not Root.ReadFrom(ResponseText) then
            Error('Proktek SAVE-ORDER повернув невалідний JSON: %1', CopyStr(ResponseText, 1, 1000));

        if not Root.Get('responseStatus', Token) then
            Error('У відповіді SAVE-ORDER відсутнє поле responseStatus.');
        ResponseStatus := Token.AsValue().AsBoolean();

        if Root.Get('responseMessage', Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull then
                    ResponseMessage := Token.AsValue().AsText();

        if not ResponseStatus then
            Error('Proktek відхилив SAVE-ORDER. %1', ResponseMessage);

        if not Root.Get('order', Token) then
            Error('SAVE-ORDER успішний, але у відповіді відсутній об''єкт order.');
        OrderJson := Token.AsObject();

        if not OrderJson.Get('uuid', Token) then
            Error('SAVE-ORDER успішний, але order.uuid відсутній.');
        UUIDText := Token.AsValue().AsText();
        if not Evaluate(OrderUUID, UUIDText) then
            Error('Proktek повернув некоректний order.uuid: %1.', UUIDText);
        if IsNullGuid(OrderUUID) then
            Error('SAVE-ORDER повернув порожній order.uuid.');

        // Deliberately ignore order.id here. Proktek currently returns id=0 on a successful CREATE.
    end;

    local procedure ReconcileOrder(
        var Connection: Record "SI Prok Connection";
        var ProdRequest: Record "SI Concrete Prod Request";
        SavedOrderUUID: Guid;
        AddOrderNo: Text)
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        RequestBody: Text;
        ResponseText: Text;
        RealOrderId: BigInteger;
        ReconciledUUID: Guid;
        MatchCount: Integer;
        SearchStart: DateTime;
        SearchEnd: DateTime;
    begin
        // GET-ORDERS filters by Order Date, not by the moment when SAVE-ORDER was called.
        // Search the requested production day and identify the exact Order by UUID + addOrderNo.
        ProdRequest.TestField("Required Date/Time");
        SearchStart := CreateDateTime(DT2Date(ProdRequest."Required Date/Time"), 000000T);
        SearchEnd := CreateDateTime(DT2Date(ProdRequest."Required Date/Time"), 235959T);
        RequestBody := BuildGetOrdersPayload(Connection, SearchStart, SearchEnd);

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code",
            'GET-ORDERS',
            Connection."EDS Provider Code",
            RuntimeParam,
            RequestBody,
            'application/json-patch+json',
            'text/plain',
            ResponseBuffer);

        ResponseText := GetResponseText(ResponseBuffer, 'GET-ORDERS');
        FindOrderInGetResponse(ResponseText, SavedOrderUUID, AddOrderNo, MatchCount, RealOrderId, ReconciledUUID);

        if MatchCount <> 1 then begin
            ProdRequest.Status := ProdRequest.Status::Error;
            ProdRequest."Proktek Last Message" := CopyStr(
                StrSubstNo('SAVE успішний; GET-ORDERS reconciliation: знайдено %1 запис(ів) для UUID %2 + addOrderNo %3.',
                    MatchCount, SavedOrderUUID, AddOrderNo),
                1,
                MaxStrLen(ProdRequest."Proktek Last Message"));
            ProdRequest.Modify(false);
            Commit();
            Error(
                'Proktek SAVE-ORDER повернув UUID %1, але Order ще не підтверджено через GET-ORDERS: знайдено %2 запис(ів) для UUID + addOrderNo %3. Локальний стан залишено як непідтверджений; автоматичний повторний CREATE заблоковано.',
                SavedOrderUUID, MatchCount, AddOrderNo);
        end;

        if RealOrderId = 0 then begin
            ProdRequest.Status := ProdRequest.Status::Error;
            ProdRequest."Proktek Last Message" := CopyStr('GET-ORDERS знайшов Order, але його id = 0.', 1, MaxStrLen(ProdRequest."Proktek Last Message"));
            ProdRequest.Modify(false);
            Commit();
            Error('GET-ORDERS знайшов Order UUID %1 / %2, але повернув id = 0.', SavedOrderUUID, AddOrderNo);
        end;

        ConfirmReconciledOrder(ProdRequest, RealOrderId, ReconciledUUID, AddOrderNo);
    end;

    procedure ReconcilePendingOrder(var ProdRequest: Record "SI Concrete Prod Request"): Boolean
    var
        Connection: Record "SI Prok Connection";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        OrderProjector: Codeunit "SI Prok Order Projector";
        AddOrderNo: Text;
        MatchCount: Integer;
        RealOrderId: BigInteger;
        ReconciledUUID: Guid;
    begin
        if ProdRequest."Proktek Order ID" <> 0 then
            exit(true);
        if IsNullGuid(ProdRequest."Proktek Order UUID") then
            exit(false);

        ConnectionMgt.GetActive(Connection);
        AddOrderNo := OrderProjector.BuildExternalOrderNo(ProdRequest);
        FindPendingOrder(Connection, ProdRequest, ProdRequest."Proktek Order UUID", AddOrderNo, MatchCount, RealOrderId, ReconciledUUID);

        if MatchCount = 0 then begin
            ProdRequest."Proktek Last Message" := CopyStr(
                StrSubstNo('Повторна перевірка GET-ORDERS: Order UUID %1 / %2 не знайдено.', ProdRequest."Proktek Order UUID", AddOrderNo),
                1, MaxStrLen(ProdRequest."Proktek Last Message"));
            ProdRequest.Modify(false);
            exit(false);
        end;

        if MatchCount <> 1 then
            Error('GET-ORDERS знайшов %1 запис(ів) для непідтвердженого Order UUID %2 / %3. Автоматичне відновлення неможливе.',
                MatchCount, ProdRequest."Proktek Order UUID", AddOrderNo);
        if RealOrderId = 0 then
            Error('GET-ORDERS знайшов непідтверджений Order UUID %1 / %2, але повернув id = 0.', ProdRequest."Proktek Order UUID", AddOrderNo);

        ConfirmReconciledOrder(ProdRequest, RealOrderId, ReconciledUUID, AddOrderNo);
        exit(true);
    end;

    procedure GetOrderDiagnostic(
        ProdRequest: Record "SI Concrete Prod Request";
        var BaselineRequestBody: Text;
        var BaselineResponseText: Text;
        var TargetRequestBody: Text;
        var TargetResponseText: Text;
        var AnalysisText: Text)
    var
        OrderProjector: Codeunit "SI Prok Order Projector";
        ExpectedUUID: Guid;
        ReconciledUUID: Guid;
        ExpectedAddOrderNo: Text;
        MatchCount: Integer;
        RealOrderId: BigInteger;
        BaselineDate: Date;
        TargetDate: Date;
    begin
        ProdRequest.TestField("Required Date/Time");

        ExpectedUUID := ProdRequest."Proktek Order UUID";
        ExpectedAddOrderNo := OrderProjector.BuildExternalOrderNo(ProdRequest);
        BaselineDate := Today();
        TargetDate := DT2Date(ProdRequest."Required Date/Time");

        GetOrdersRawForDate(ProdRequest, BaselineDate, BaselineRequestBody, BaselineResponseText);
        GetOrdersRawForDate(ProdRequest, TargetDate, TargetRequestBody, TargetResponseText);

        FindOrderInGetResponse(TargetResponseText, ExpectedUUID, ExpectedAddOrderNo, MatchCount, RealOrderId, ReconciledUUID);

        AnalysisText := StrSubstNo(
            'Baseline date: %1\Target/Required date: %2\Expected UUID: %3\Expected addOrderNo: %4\Target match count: %5\Matched Order ID: %6\Matched UUID: %7',
            BaselineDate, TargetDate, ExpectedUUID, ExpectedAddOrderNo, MatchCount, RealOrderId, ReconciledUUID);
    end;

    local procedure GetOrdersRawForDate(
        ProdRequest: Record "SI Concrete Prod Request";
        SearchDate: Date;
        var RequestBody: Text;
        var ResponseText: Text)
    var
        Connection: Record "SI Prok Connection";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        SearchStart: DateTime;
        SearchEnd: DateTime;
    begin
        ConnectionMgt.GetActive(Connection);
        SearchStart := CreateDateTime(SearchDate, 000000T);
        SearchEnd := CreateDateTime(SearchDate, 235959T);
        RequestBody := BuildGetOrdersPayload(Connection, SearchStart, SearchEnd);

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code",
            'GET-ORDERS',
            Connection."EDS Provider Code",
            RuntimeParam,
            RequestBody,
            'application/json-patch+json',
            'text/plain',
            ResponseBuffer);

        ResponseText := GetResponseText(ResponseBuffer, 'GET-ORDERS');
    end;

    procedure ResetUnconfirmedOrder(var ProdRequest: Record "SI Concrete Prod Request")
    begin
        if ProdRequest."Proktek Order ID" <> 0 then
            Error('Order уже підтверджено в Proktek з ID %1. Скидання заборонено.', ProdRequest."Proktek Order ID");
        if IsNullGuid(ProdRequest."Proktek Order UUID") then
            exit;

        Clear(ProdRequest."Proktek Order UUID");
        Clear(ProdRequest."Proktek Order Synced At");
        ProdRequest."Proktek Last Message" := CopyStr('Непідтверджений SAVE-ORDER скинуто після повторної перевірки GET-ORDERS. Дозволено новий CREATE.', 1, MaxStrLen(ProdRequest."Proktek Last Message"));
        ProdRequest.Modify(false);
    end;

    local procedure FindPendingOrder(
        Connection: Record "SI Prok Connection";
        ProdRequest: Record "SI Concrete Prod Request";
        ExpectedUUID: Guid;
        AddOrderNo: Text;
        var MatchCount: Integer;
        var RealOrderId: BigInteger;
        var ReconciledUUID: Guid)
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        RequestBody: Text;
        ResponseText: Text;
        SearchStart: DateTime;
        SearchEnd: DateTime;
    begin
        ProdRequest.TestField("Required Date/Time");
        SearchStart := CreateDateTime(DT2Date(ProdRequest."Required Date/Time"), 000000T);
        SearchEnd := CreateDateTime(DT2Date(ProdRequest."Required Date/Time"), 235959T);
        RequestBody := BuildGetOrdersPayload(Connection, SearchStart, SearchEnd);

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code",
            'GET-ORDERS',
            Connection."EDS Provider Code",
            RuntimeParam,
            RequestBody,
            'application/json-patch+json',
            'text/plain',
            ResponseBuffer);

        ResponseText := GetResponseText(ResponseBuffer, 'GET-ORDERS');
        FindOrderInGetResponse(ResponseText, ExpectedUUID, AddOrderNo, MatchCount, RealOrderId, ReconciledUUID);
    end;

    local procedure ConfirmReconciledOrder(
        var ProdRequest: Record "SI Concrete Prod Request";
        RealOrderId: BigInteger;
        ReconciledUUID: Guid;
        AddOrderNo: Text)
    begin
        ProdRequest."Proktek Order ID" := RealOrderId;
        ProdRequest."Proktek Order UUID" := ReconciledUUID;
        ProdRequest."Proktek Order Synced At" := CurrentDateTime();
        ProdRequest."Proktek Last Message" := CopyStr('SAVE-ORDER + GET-ORDERS reconciliation: Success', 1, MaxStrLen(ProdRequest."Proktek Last Message"));
        ProdRequest.Status := ProdRequest.Status::"Sent to MES";
        ProdRequest.Modify(false);

        Message(
            'Order підтверджено в Proktek.\Order ID: %1\UUID: %2\addOrderNo: %3',
            RealOrderId,
            ReconciledUUID,
            AddOrderNo);
    end;

    local procedure BuildGetOrdersPayload(
        Connection: Record "SI Prok Connection";
        StartDateTime: DateTime;
        EndDateTime: DateTime): Text
    var
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        Root: JsonObject;
        PlantIds: JsonArray;
        SessionGuid: Guid;
        Payload: Text;
    begin
        SessionGuid := AuthMgt.GetSessionGuid(Connection);
        PlantIds.Add(1);

        Root.Add('guid', Format(SessionGuid, 0, 4));
        Root.Add('startDate', Format(StartDateTime, 0, 9));
        Root.Add('endDate', Format(EndDateTime, 0, 9));
        Root.Add('santral_id', PlantIds);
        Root.WriteTo(Payload);
        exit(Payload);
    end;

    local procedure FindOrderInGetResponse(
        ResponseText: Text;
        ExpectedUUID: Guid;
        ExpectedAddOrderNo: Text;
        var MatchCount: Integer;
        var OrderId: BigInteger;
        var OrderUUID: Guid)
    var
        Root: JsonObject;
        Orders: JsonArray;
        OrderToken: JsonToken;
        Token: JsonToken;
        OrderJson: JsonObject;
        ResponseStatus: Boolean;
        ResponseMessage: Text;
        CandidateUUID: Guid;
        CandidateUUIDText: Text;
        CandidateAddOrderNo: Text;
        I: Integer;
    begin
        if not Root.ReadFrom(ResponseText) then
            Error('Proktek GET-ORDERS повернув невалідний JSON: %1', CopyStr(ResponseText, 1, 1000));

        if not Root.Get('responseStatus', Token) then
            Error('У відповіді GET-ORDERS відсутнє поле responseStatus.');
        ResponseStatus := Token.AsValue().AsBoolean();
        if Root.Get('responseMessage', Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull then
                    ResponseMessage := Token.AsValue().AsText();
        if not ResponseStatus then
            Error('Proktek відхилив GET-ORDERS. %1', ResponseMessage);

        if not Root.Get('orders', Token) then
            Error('GET-ORDERS успішний, але поле orders відсутнє.');
        Orders := Token.AsArray();

        for I := 0 to Orders.Count() - 1 do begin
            Orders.Get(I, OrderToken);
            OrderJson := OrderToken.AsObject();
            Clear(CandidateUUID);
            Clear(CandidateUUIDText);
            Clear(CandidateAddOrderNo);

            if OrderJson.Get('uuid', Token) then
                if Token.IsValue() then
                    if not Token.AsValue().IsNull then begin
                        CandidateUUIDText := Token.AsValue().AsText();
                        Evaluate(CandidateUUID, CandidateUUIDText);
                    end;

            if OrderJson.Get('addOrderNo', Token) then
                if Token.IsValue() then
                    if not Token.AsValue().IsNull then
                        CandidateAddOrderNo := Token.AsValue().AsText();

            if (CandidateUUID = ExpectedUUID) and (CandidateAddOrderNo = ExpectedAddOrderNo) then begin
                MatchCount += 1;
                OrderUUID := CandidateUUID;
                if OrderJson.Get('id', Token) then
                    OrderId := Token.AsValue().AsBigInteger();
            end;
        end;
    end;

    local procedure GetAddOrderNo(RequestBody: Text): Text
    var
        Root: JsonObject;
        OrderJson: JsonObject;
        Token: JsonToken;
    begin
        if not Root.ReadFrom(RequestBody) then
            Error('Не вдалося прочитати сформований SAVE-ORDER payload.');
        if not Root.Get('order', Token) then
            Error('У SAVE-ORDER payload відсутній об''єкт order.');
        OrderJson := Token.AsObject();
        if not OrderJson.Get('addOrderNo', Token) then
            Error('У SAVE-ORDER payload відсутній addOrderNo.');
        exit(Token.AsValue().AsText());
    end;

    local procedure ValidateNotAlreadySent(ProdRequest: Record "SI Concrete Prod Request")
    begin
        if ProdRequest."Proktek Order ID" <> 0 then
            Error(
                'Заявка #%1 уже має Proktek Order ID %2. Повторний CREATE заблоковано, щоб не створити дубль.',
                ProdRequest."Entry No.",
                ProdRequest."Proktek Order ID");

        if not IsNullGuid(ProdRequest."Proktek Order UUID") then
            Error(
                'Заявка #%1 уже має Proktek Order UUID %2. Повторний CREATE заблоковано, щоб не створити дубль.',
                ProdRequest."Entry No.",
                ProdRequest."Proktek Order UUID");
    end;

    local procedure GetResponseText(
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        OperationCode: Code[30]): Text
    begin
        if ResponseBuffer.FindFirst() then
            exit(ResponseBuffer.GetBodyText());
        Error('EDS не повернув response buffer для %1.', OperationCode);
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    var
        EmptyGuid: Guid;
    begin
        exit(Value = EmptyGuid);
    end;
}
