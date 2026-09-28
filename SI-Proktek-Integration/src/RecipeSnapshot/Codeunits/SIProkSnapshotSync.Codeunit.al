codeunit 57065 "SI Prok Snapshot Sync"
{
    procedure ExportSnapshot(SnapshotEntryNo: Integer)
    var
        Snapshot: Record "SI Prok Recipe Snapshot";
        Connection: Record "SI Prok Connection";
        Mapping: Record "SI Prok Entity Mapping";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
    begin
        Snapshot.Get(SnapshotEntryNo);
        Snapshot.RefreshBaseData();
        Snapshot.Modify();
        ValidateSnapshot(Snapshot);

        ConnectionMgt.GetActive(Connection);
        if Connection.Environment = Connection.Environment::Production then
            if not Confirm(
                'Буде створено або оновлено derived Formula %1 у ПРОДУКТИВНОМУ Proktek через підключення %2. Продовжити?',
                false,
                Snapshot."Derived Formula Code",
                Connection.Code)
            then
                exit;

        GetOrInitMapping(Connection, Snapshot, Mapping);
        SaveSnapshotFormula(Connection, Snapshot, Mapping);
    end;

    local procedure SaveSnapshotFormula(
        var Connection: Record "SI Prok Connection";
        var Snapshot: Record "SI Prok Recipe Snapshot";
        var Mapping: Record "SI Prok Entity Mapping")
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        SnapshotMgt: Codeunit "SI Prok Recipe Snapshot Mgt.";
        SessionGuid: Guid;
        RequestBody: Text;
        ResponseText: Text;
    begin
        Connection.TestField(Code);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");

        SessionGuid := AuthMgt.GetSessionGuid(Connection);
        RequestBody := SnapshotMgt.BuildDerivedFormulaSaveRequest(
            SessionGuid,
            Snapshot."Entry No.",
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
        ApplySaveResponse(ResponseText, Connection, Snapshot, Mapping);
    end;

    local procedure GetOrInitMapping(
        Connection: Record "SI Prok Connection";
        Snapshot: Record "SI Prok Recipe Snapshot";
        var Mapping: Record "SI Prok Entity Mapping")
    begin
        Clear(Mapping);
        if Mapping.Get(Connection.Code, Mapping."Entity Type"::"Recipe Snapshot", Snapshot.SystemId) then
            exit;

        Mapping.Init();
        Mapping."Connection Code" := Connection.Code;
        Mapping."Entity Type" := Mapping."Entity Type"::"Recipe Snapshot";
        Mapping."BC SystemId" := Snapshot.SystemId;
        Mapping."BC No." := CopyStr(StrSubstNo('RS-%1', Snapshot."Entry No."), 1, MaxStrLen(Mapping."BC No."));
    end;

    local procedure ApplySaveResponse(
        ResponseText: Text;
        Connection: Record "SI Prok Connection";
        var Snapshot: Record "SI Prok Recipe Snapshot";
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
            Error('Proktek відхилив derived Formula %1. %2', Snapshot."Derived Formula Code", ResponseMessage);

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
            FormulaCode := Snapshot."Derived Formula Code";

        Mapping."Connection Code" := Connection.Code;
        Mapping."Entity Type" := Mapping."Entity Type"::"Recipe Snapshot";
        Mapping."BC SystemId" := Snapshot.SystemId;
        Mapping."BC No." := CopyStr(StrSubstNo('RS-%1', Snapshot."Entry No."), 1, MaxStrLen(Mapping."BC No."));
        Mapping."Proktek Internal Code" := FormulaIndex;
        Mapping."Proktek UUID" := FormulaUUID;
        Mapping."Proktek Code" := CopyStr(FormulaCode, 1, MaxStrLen(Mapping."Proktek Code"));
        Mapping."Last Sync At" := CurrentDateTime();
        Mapping."Last Response Message" := CopyStr(ResponseMessage, 1, MaxStrLen(Mapping."Last Response Message"));

        if not Mapping.Insert(false) then
            Mapping.Modify(false);

        Snapshot."Proktek Formula Index" := FormulaIndex;
        Snapshot."Proktek Formula UUID" := FormulaUUID;
        Snapshot.Modify(false);

        Message(
            'Derived Formula успішно синхронізована з Proktek.\Код: %1\recete_index: %2\UUID: %3',
            FormulaCode,
            FormulaIndex,
            FormulaUUID);
    end;

    local procedure ValidateSnapshot(Snapshot: Record "SI Prok Recipe Snapshot")
    begin
        Snapshot.TestField("Item No.");
        Snapshot.TestField("Production BOM No.");
        Snapshot.TestField("Base Formula Code");
        Snapshot.TestField("Derived Formula Code");
    end;

    local procedure GetResponseText(var ResponseBuffer: Record "SI EDS Response Buffer" temporary): Text
    begin
        if ResponseBuffer.FindFirst() then
            exit(ResponseBuffer.GetBodyText());
        Error('EDS не повернув response buffer для SAVE-FORMULA.');
    end;
}
