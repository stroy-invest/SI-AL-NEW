using STROYINVEST.ConcreteRecipeEngine;

codeunit 57090 "SI Prok Recipe Formula Mgt."
{
    procedure Publish(RecipeRevision: Record "SI Concrete Recipe Revision")
    var
        Connection: Record "SI Prok Connection";
        Mapping: Record "SI Prok Entity Mapping";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
    begin
        ValidateRevision(RecipeRevision);
        ConnectionMgt.GetActive(Connection);
        GetOrInitMapping(Connection, RecipeRevision, Mapping);

        if Connection.Environment = Connection.Environment::Production then
            if not Confirm(
                'Буде опубліковано або оновлено ревізію %1 рецептури %2 у ПРОДУКТИВНОМУ Proktek через підключення %3. Після передачі можна буде одразу активувати Formula. Продовжити?',
                false, RecipeRevision."Revision No.", RecipeRevision."Recipe No.", Connection.Code)
            then
                exit;

        SaveRevisionFormula(Connection, RecipeRevision, Mapping, false);

        if Confirm('Активувати цю рецептуру в Proktek?', false) then begin
            ActivateCore(RecipeRevision, true);
            exit;
        end;

        Message('Ревізію %1 рецептури %2 успішно передано в Proktek. Formula Index: %3. Formula залишена неактивною.',
            RecipeRevision."Revision No.", RecipeRevision."Recipe No.", Mapping."Proktek Internal Code");
    end;

    procedure Activate(RecipeRevision: Record "SI Concrete Recipe Revision")
    begin
        ActivateCore(RecipeRevision, false);
    end;

    local procedure ActivateCore(RecipeRevision: Record "SI Concrete Recipe Revision"; SkipProductionConfirmation: Boolean)
    var
        Connection: Record "SI Prok Connection";
        Mapping: Record "SI Prok Entity Mapping";
        PreviousMapping: Record "SI Prok Entity Mapping";
        PreviousRevision: Record "SI Concrete Recipe Revision";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
    begin
        ValidateRevision(RecipeRevision);
        ConnectionMgt.GetActive(Connection);
        GetPublishedMapping(Connection, RecipeRevision, Mapping);
        if Mapping."SI Proktek Active" then
            exit;

        FindOtherActiveMapping(Connection.Code, RecipeRevision, PreviousMapping);
        if not IsNullGuid(PreviousMapping."BC SystemId") then begin
            if not Confirm(
                'Для рецептури %1 у Proktek вже активна ревізія %2 (Formula %3). Деактивувати її та активувати ревізію %4?',
                false,
                RecipeRevision."Recipe No.",
                PreviousMapping."SI Recipe Revision No.",
                PreviousMapping."Proktek Internal Code",
                RecipeRevision."Revision No.")
            then
                exit;

            if not PreviousRevision.Get(PreviousMapping."SI Recipe No.", PreviousMapping."SI Recipe Revision No.") then
                Error('Не знайдено BC ревізію %1/%2 для активної Formula %3.',
                    PreviousMapping."SI Recipe No.", PreviousMapping."SI Recipe Revision No.", PreviousMapping."Proktek Internal Code");
            SaveRevisionFormula(Connection, PreviousRevision, PreviousMapping, false);
        end else
            if (Connection.Environment = Connection.Environment::Production) and (not SkipProductionConfirmation) then
                if not Confirm('Активувати Formula для ревізії %1 рецептури %2 у ПРОДУКТИВНОМУ Proktek?', false,
                    RecipeRevision."Revision No.", RecipeRevision."Recipe No.") then
                    exit;

        SaveRevisionFormula(Connection, RecipeRevision, Mapping, true);
        Message('Formula %1 для ревізії %2 активована в Proktek.', Mapping."Proktek Internal Code", RecipeRevision."Revision No.");
    end;

    procedure Deactivate(RecipeRevision: Record "SI Concrete Recipe Revision")
    var
        Connection: Record "SI Prok Connection";
        Mapping: Record "SI Prok Entity Mapping";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
    begin
        ConnectionMgt.GetActive(Connection);
        GetPublishedMapping(Connection, RecipeRevision, Mapping);
        if not Mapping."SI Proktek Active" then
            exit;

        if not Confirm('Деактивувати Formula %1 для ревізії %2 рецептури %3 у Proktek?', false,
            Mapping."Proktek Internal Code", RecipeRevision."Revision No.", RecipeRevision."Recipe No.") then
            exit;

        SaveRevisionFormula(Connection, RecipeRevision, Mapping, false);
        Message('Formula %1 деактивована в Proktek.', Mapping."Proktek Internal Code");
    end;

    procedure GetProjectionState(
        RecipeRevision: Record "SI Concrete Recipe Revision";
        var FormulaIndex: BigInteger;
        var FormulaUUID: Guid;
        var Published: Boolean;
        var ProktekActive: Boolean;
        var LastSyncAt: DateTime;
        var StatusText: Text)
    var
        Connection: Record "SI Prok Connection";
        Mapping: Record "SI Prok Entity Mapping";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
    begin
        Clear(FormulaIndex);
        Clear(FormulaUUID);
        Clear(Published);
        Clear(ProktekActive);
        Clear(LastSyncAt);
        StatusText := 'Не опубліковано';

        if not ConnectionMgt.TryGetActive(Connection) then
            exit;
        if not Mapping.Get(Connection.Code, Mapping."Entity Type"::Formula, RecipeRevision.SystemId) then
            exit;

        FormulaIndex := Mapping."Proktek Internal Code";
        FormulaUUID := Mapping."Proktek UUID";
        Published := (FormulaIndex > 0) and (not IsNullGuid(FormulaUUID));
        ProktekActive := Mapping."SI Proktek Active";
        LastSyncAt := Mapping."Last Sync At";
        StatusText := Format(Mapping."SI Formula Proj. Status");
    end;

    procedure OpenSyncStatus(RecipeRevision: Record "SI Concrete Recipe Revision")
    var
        Connection: Record "SI Prok Connection";
        Mapping: Record "SI Prok Entity Mapping";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
    begin
        ConnectionMgt.GetActive(Connection);
        GetPublishedMapping(Connection, RecipeRevision, Mapping);
        Page.Run(Page::"SI Prok Formula Sync Status", Mapping);
    end;

    local procedure SaveRevisionFormula(
        Connection: Record "SI Prok Connection";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        var Mapping: Record "SI Prok Entity Mapping";
        FormulaActive: Boolean)
    var
        Recipe: Record "SI Concrete Recipe";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        FormulaProjector: Codeunit "SI Prok Formula Projector";
        SessionGuid: Guid;
        RequestBody: Text;
        ResponseText: Text;
    begin
        Recipe.Get(RecipeRevision."Recipe No.");
        Connection.TestField(Code);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");

        SessionGuid := AuthMgt.GetSessionGuid(Connection);
        RequestBody := FormulaProjector.BuildRecipeFormulaSaveRequest(
            SessionGuid, Recipe, RecipeRevision,
            Mapping."Proktek Internal Code", Mapping."Proktek UUID", FormulaActive);

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code", 'SAVE-FORMULA', Connection."EDS Provider Code",
            RuntimeParam, RequestBody, 'application/json-patch+json', 'text/plain', ResponseBuffer);

        ResponseText := GetResponseText(ResponseBuffer);
        ApplySaveResponse(ResponseText, Connection, RecipeRevision, Mapping, FormulaActive);
    end;

    local procedure ApplySaveResponse(
        ResponseText: Text;
        Connection: Record "SI Prok Connection";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        var Mapping: Record "SI Prok Entity Mapping";
        FormulaActive: Boolean)
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
        if Root.Get('responseMessage', Token) and Token.IsValue() then
            if not Token.AsValue().IsNull then
                ResponseMessage := Token.AsValue().AsText();
        if not ResponseStatus then
            Error('Proktek відхилив SAVE-FORMULA. %1', ResponseMessage);

        if not Root.Get('formula', Token) then
            Error('SAVE-FORMULA успішний, але у відповіді відсутній об''єкт formula.');
        FormulaJson := Token.AsObject();
        if not FormulaJson.Get('recete_index', Token) then
            Error('SAVE-FORMULA успішний, але formula.recete_index відсутній.');
        FormulaIndex := Token.AsValue().AsBigInteger();
        if FormulaIndex <= 0 then
            Error('SAVE-FORMULA повернув некоректний formula.recete_index: %1.', FormulaIndex);
        if not FormulaJson.Get('uuid', Token) then
            Error('SAVE-FORMULA успішний, але formula.uuid відсутній.');
        UUIDText := Token.AsValue().AsText();
        if not Evaluate(FormulaUUID, UUIDText) then
            Error('Proktek повернув некоректний formula.uuid: %1.', UUIDText);
        if FormulaJson.Get('recete_kod', Token) and Token.IsValue() then
            if not Token.AsValue().IsNull then
                FormulaCode := Token.AsValue().AsText();

        Mapping."Connection Code" := Connection.Code;
        Mapping."Entity Type" := Mapping."Entity Type"::Formula;
        Mapping."BC SystemId" := RecipeRevision.SystemId;
        Mapping."BC No." := CopyStr(RecipeRevision."Recipe No.", 1, MaxStrLen(Mapping."BC No."));
        Mapping."SI Recipe No." := RecipeRevision."Recipe No.";
        Mapping."SI Recipe Revision No." := RecipeRevision."Revision No.";
        Mapping."Proktek Internal Code" := FormulaIndex;
        Mapping."Proktek UUID" := FormulaUUID;
        Mapping."Proktek Code" := CopyStr(FormulaCode, 1, MaxStrLen(Mapping."Proktek Code"));
        Mapping."SI Formula Proj. Status" := Mapping."SI Formula Proj. Status"::Published;
        Mapping."SI Proktek Active" := FormulaActive;
        Mapping."Last Sync At" := CurrentDateTime();
        Mapping."SI Last Sync By" := UserSecurityId();
        Clear(Mapping."SI Last Error");
        Mapping."Last Response Message" := CopyStr(ResponseMessage, 1, MaxStrLen(Mapping."Last Response Message"));

        if not Mapping.Insert(false) then
            Mapping.Modify(false);
    end;

    local procedure ValidateRevision(RecipeRevision: Record "SI Concrete Recipe Revision")
    var
        Recipe: Record "SI Concrete Recipe";
        RecipeLine: Record "SI Concrete Recipe Line";
    begin
        if RecipeRevision.Status <> RecipeRevision.Status::Certified then
            Error('У Proktek можна публікувати лише сертифіковану ревізію.');
        if RecipeRevision."Administrative Status" <> RecipeRevision."Administrative Status"::Active then
            Error('Ревізія %1 адміністративно неактивна в BC.', RecipeRevision."Revision No.");
        if RecipeRevision."Projection Status" <> RecipeRevision."Projection Status"::Projected then
            Error('Ревізія %1 ще не спроєктована у виробничу специфікацію BC.', RecipeRevision."Revision No.");
        RecipeRevision.TestField("Production BOM Version Code");
        Recipe.Get(RecipeRevision."Recipe No.");
        Recipe.TestField("Production BOM No.");
        RecipeLine.SetRange("Recipe No.", RecipeRevision."Recipe No.");
        RecipeLine.SetRange("Revision No.", RecipeRevision."Revision No.");
        if RecipeLine.IsEmpty() then
            Error('Ревізія %1 рецептури %2 не містить рядків.', RecipeRevision."Revision No.", RecipeRevision."Recipe No.");
    end;

    local procedure GetOrInitMapping(Connection: Record "SI Prok Connection"; RecipeRevision: Record "SI Concrete Recipe Revision"; var Mapping: Record "SI Prok Entity Mapping")
    begin
        Clear(Mapping);
        if Mapping.Get(Connection.Code, Mapping."Entity Type"::Formula, RecipeRevision.SystemId) then
            exit;
        Mapping.Init();
        Mapping."Connection Code" := Connection.Code;
        Mapping."Entity Type" := Mapping."Entity Type"::Formula;
        Mapping."BC SystemId" := RecipeRevision.SystemId;
        Mapping."BC No." := CopyStr(RecipeRevision."Recipe No.", 1, MaxStrLen(Mapping."BC No."));
        Mapping."SI Recipe No." := RecipeRevision."Recipe No.";
        Mapping."SI Recipe Revision No." := RecipeRevision."Revision No.";
        Mapping."SI Formula Proj. Status" := Mapping."SI Formula Proj. Status"::"Not Published";
    end;

    local procedure GetPublishedMapping(Connection: Record "SI Prok Connection"; RecipeRevision: Record "SI Concrete Recipe Revision"; var Mapping: Record "SI Prok Entity Mapping")
    begin
        if not Mapping.Get(Connection.Code, Mapping."Entity Type"::Formula, RecipeRevision.SystemId) then
            Error('Ревізію %1 рецептури %2 ще не опубліковано в Proktek.', RecipeRevision."Revision No.", RecipeRevision."Recipe No.");
        if (Mapping."Proktek Internal Code" <= 0) or IsNullGuid(Mapping."Proktek UUID") then
            Error('Mapping ревізії %1 не містить валідних recete_index/UUID.', RecipeRevision."Revision No.");
    end;

    local procedure FindOtherActiveMapping(ConnectionCode: Code[50]; RecipeRevision: Record "SI Concrete Recipe Revision"; var Mapping: Record "SI Prok Entity Mapping")
    begin
        Clear(Mapping);
        Mapping.SetRange("Connection Code", ConnectionCode);
        Mapping.SetRange("Entity Type", Mapping."Entity Type"::Formula);
        Mapping.SetRange("SI Recipe No.", RecipeRevision."Recipe No.");
        Mapping.SetRange("SI Proktek Active", true);
        Mapping.SetFilter("BC SystemId", '<>%1', RecipeRevision.SystemId);
        if not Mapping.FindFirst() then
            Clear(Mapping);
    end;

    local procedure GetResponseText(var ResponseBuffer: Record "SI EDS Response Buffer" temporary): Text
    begin
        if ResponseBuffer.FindFirst() then
            exit(ResponseBuffer.GetBodyText());
        Error('EDS не повернув response buffer для SAVE-FORMULA.');
    end;
}
