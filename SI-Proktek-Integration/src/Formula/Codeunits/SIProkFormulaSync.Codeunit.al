codeunit 57062 "SI Prok Formula Sync"
{
    procedure ExportFormula(ItemNo: Code[20]; VariantCode: Code[10]; ProductionBOMNo: Code[20])
    var
        Connection: Record "SI Prok Connection";
        Mapping: Record "SI Prok Entity Mapping";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
    begin
        ValidateContext(ItemNo, VariantCode, ProductionBOMNo);
        ConnectionMgt.GetActive(Connection);

        if Connection.Environment = Connection.Environment::Production then
            if not Confirm(
                'Буде створено або оновлено рецептуру %1 у ПРОДУКТИВНОМУ Proktek через підключення %2. Продовжити?',
                false,
                BuildFormulaCode(ItemNo, VariantCode),
                Connection.Code)
            then
                exit;

        GetOrInitMapping(Connection, ItemNo, VariantCode, Mapping);
        SaveFormula(Connection, ItemNo, VariantCode, ProductionBOMNo, Mapping);
    end;

    procedure BuildFormulaSavePayloadPreview(ItemNo: Code[20]; VariantCode: Code[10]; ProductionBOMNo: Code[20]): Text
    var
        Connection: Record "SI Prok Connection";
        Mapping: Record "SI Prok Entity Mapping";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        FormulaProjector: Codeunit "SI Prok Formula Projector";
        SessionGuid: Guid;
    begin
        ValidateContext(ItemNo, VariantCode, ProductionBOMNo);
        ConnectionMgt.GetActive(Connection);
        Connection.TestField(Code);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");

        GetOrInitMapping(Connection, ItemNo, VariantCode, Mapping);
        SessionGuid := AuthMgt.GetSessionGuid(Connection);

        exit(FormulaProjector.BuildFormulaSaveRequest(
            SessionGuid,
            ItemNo,
            VariantCode,
            ProductionBOMNo,
            Mapping."Proktek Internal Code",
            Mapping."Proktek UUID"));
    end;

    local procedure SaveFormula(
        var Connection: Record "SI Prok Connection";
        ItemNo: Code[20];
        VariantCode: Code[10];
        ProductionBOMNo: Code[20];
        var Mapping: Record "SI Prok Entity Mapping")
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        FormulaProjector: Codeunit "SI Prok Formula Projector";
        SessionGuid: Guid;
        RequestBody: Text;
        ResponseText: Text;
    begin
        Connection.TestField(Code);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");

        SessionGuid := AuthMgt.GetSessionGuid(Connection);
        RequestBody := FormulaProjector.BuildFormulaSaveRequest(
            SessionGuid,
            ItemNo,
            VariantCode,
            ProductionBOMNo,
            Mapping."Proktek Internal Code",
            Mapping."Proktek UUID");

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code",
            'SAVE-FORMULA',
            Connection."EDS Provider Code",
            RuntimeParam,
            RequestBody,
            'application/json-patch+json',
            'text/plain',
            ResponseBuffer);

        ResponseText := GetResponseText(ResponseBuffer);
        ApplySaveFormulaResponse(ResponseText, Connection, ItemNo, VariantCode, Mapping);
    end;

    local procedure GetOrInitMapping(
        Connection: Record "SI Prok Connection";
        ItemNo: Code[20];
        VariantCode: Code[10];
        var Mapping: Record "SI Prok Entity Mapping")
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        BCSystemId: Guid;
    begin
        if VariantCode = '' then begin
            Item.Get(ItemNo);
            BCSystemId := Item.SystemId;
        end else begin
            ItemVariant.Get(ItemNo, VariantCode);
            BCSystemId := ItemVariant.SystemId;
        end;

        Clear(Mapping);
        if Mapping.Get(Connection.Code, Mapping."Entity Type"::Formula, BCSystemId) then
            exit;

        Mapping.Init();
        Mapping."Connection Code" := Connection.Code;
        Mapping."Entity Type" := Mapping."Entity Type"::Formula;
        Mapping."BC SystemId" := BCSystemId;
        Mapping."BC No." := ItemNo;
    end;

    local procedure ApplySaveFormulaResponse(
        ResponseText: Text;
        Connection: Record "SI Prok Connection";
        ItemNo: Code[20];
        VariantCode: Code[10];
        var Mapping: Record "SI Prok Entity Mapping")
    var
        Root: JsonObject;
        FormulaJson: JsonObject;
        Token: JsonToken;
        ResponseStatus: Boolean;
        ResponseMessage: Text;
        UUIDText: Text;
        FormulaUUID: Guid;
        FormulaIndex: BigInteger;
        FormulaCode: Text;
    begin
        if not Root.ReadFrom(ResponseText) then
            Error('Proktek SAVE-FORMULA повернув невалідний JSON: %1', CopyStr(ResponseText, 1, 1000));

        if not Root.Get('responseStatus', Token) then
            Error('У відповіді SAVE-FORMULA відсутнє поле responseStatus.');
        ResponseStatus := Token.AsValue().AsBoolean();

        if Root.Get('responseMessage', Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull then
                    ResponseMessage := Token.AsValue().AsText();

        if not ResponseStatus then
            Error('Proktek відхилив SAVE-FORMULA %1. %2', BuildFormulaCode(ItemNo, VariantCode), ResponseMessage);

        if not Root.Get('formula', Token) then
            Error('SAVE-FORMULA успішний, але у відповіді відсутній об''єкт formula.');
        FormulaJson := Token.AsObject();

        if not FormulaJson.Get('recete_index', Token) then
            Error('SAVE-FORMULA успішний, але formula.recete_index відсутній.');
        FormulaIndex := Token.AsValue().AsBigInteger();
        if FormulaIndex = 0 then
            Error('SAVE-FORMULA повернув formula.recete_index = 0.');

        if not FormulaJson.Get('uuid', Token) then
            Error('SAVE-FORMULA успішний, але formula.uuid відсутній.');
        UUIDText := Token.AsValue().AsText();
        if not Evaluate(FormulaUUID, UUIDText) then
            Error('Proktek повернув некоректний formula.uuid: %1.', UUIDText);

        if FormulaJson.Get('recete_kod', Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull then
                    FormulaCode := Token.AsValue().AsText();
        if FormulaCode = '' then
            FormulaCode := BuildFormulaCode(ItemNo, VariantCode);

        Mapping."Connection Code" := Connection.Code;
        Mapping."Entity Type" := Mapping."Entity Type"::Formula;
        Mapping."BC No." := ItemNo;
        Mapping."Proktek Internal Code" := FormulaIndex;
        Mapping."Proktek UUID" := FormulaUUID;
        Mapping."Proktek Code" := CopyStr(FormulaCode, 1, MaxStrLen(Mapping."Proktek Code"));
        Mapping."Last Sync At" := CurrentDateTime();
        Mapping."Last Response Message" := CopyStr(ResponseMessage, 1, MaxStrLen(Mapping."Last Response Message"));

        if not Mapping.Insert(false) then
            Mapping.Modify(false);

        Message(
            'Formula успішно синхронізована з Proktek.\Код: %1\recete_index: %2\UUID: %3',
            FormulaCode,
            FormulaIndex,
            FormulaUUID);
    end;

    local procedure ValidateContext(ItemNo: Code[20]; VariantCode: Code[10]; ProductionBOMNo: Code[20])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        if ItemNo = '' then
            Error('Не вказано товар для Formula.');
        if ProductionBOMNo = '' then
            Error('Не вказано Production BOM для Formula.');

        Item.Get(ItemNo);
        ProductionBOMHeader.Get(ProductionBOMNo);
        if VariantCode <> '' then
            ItemVariant.Get(ItemNo, VariantCode);

        if Item."Production BOM No." <> ProductionBOMNo then
            if not Confirm(
                'У товару %1 Production BOM = %2, а експортується BOM %3. Продовжити?',
                false,
                ItemNo,
                Item."Production BOM No.",
                ProductionBOMNo)
            then
                Error('Експорт скасовано.');
    end;

    local procedure BuildFormulaCode(ItemNo: Code[20]; VariantCode: Code[10]): Text
    var
        FormulaProjector: Codeunit "SI Prok Formula Projector";
    begin
        exit(FormulaProjector.BuildFormulaIntegrationKey(ItemNo, VariantCode));
    end;

    local procedure GetResponseText(var ResponseBuffer: Record "SI EDS Response Buffer" temporary): Text
    begin
        if ResponseBuffer.FindFirst() then
            exit(ResponseBuffer.GetBodyText());
        Error('EDS не повернув response buffer для SAVE-FORMULA.');
    end;
}
