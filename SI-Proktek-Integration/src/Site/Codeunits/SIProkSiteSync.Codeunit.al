codeunit 57073 "SI Prok Site Sync"
{
    procedure SyncProjectSite(var Project: Record Job; var Mapping: Record "SI Prok Entity Mapping")
    var
        Connection: Record "SI Prok Connection";
        Customer: Record Customer;
        CustomerMapping: Record "SI Prok Entity Mapping";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
    begin
        Project.TestField("No.");
        Project.TestField("SI Internal Customer No.");

        Customer.Get(Project."SI Internal Customer No.");
        if Customer."SI Customer Type" <> Customer."SI Customer Type"::"Internal Project" then
            Error(
                'Клієнт %1, прив''язаний до проєкту %2, не має типу Internal Project.',
                Customer."No.",
                Project."No.");

        ConnectionMgt.GetActive(Connection);
        EnsureCustomerMapping(Connection, Customer, CustomerMapping);

        if Connection.Environment = Connection.Environment::Production then
            if not Confirm(
                'Буде створено або оновлено будмайданчик проєкту %1 у ПРОДУКТИВНОМУ Proktek через підключення %2. Продовжити?',
                false,
                Project."No.",
                Connection.Code)
            then
                exit;

        SyncSite(Connection, Project, CustomerMapping, Mapping);
    end;

    procedure SyncSite(
        var Connection: Record "SI Prok Connection";
        var Project: Record Job;
        CustomerMapping: Record "SI Prok Entity Mapping";
        var Mapping: Record "SI Prok Entity Mapping")
    var
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        EDSOrchestrator: Codeunit "SI EDS Orchestrator";
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        RequestBody: Text;
        ResponseText: Text;
        SessionGuid: Guid;
    begin
        Connection.TestField(Code);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");
        Project.TestField("No.");

        SessionGuid := AuthMgt.GetSessionGuid(Connection);
        GetOrInitMapping(Connection, Project, Mapping);
        RequestBody := BuildSaveSiteRequest(SessionGuid, Project, CustomerMapping, Mapping);

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code",
            'SAVE-SITE',
            Connection."EDS Provider Code",
            RuntimeParam,
            RequestBody,
            'application/json-patch+json',
            'text/plain',
            ResponseBuffer);

        ResponseText := GetResponseText(ResponseBuffer);
        ApplySaveSiteResponse(ResponseText, Connection, Project, Mapping);
    end;

    local procedure EnsureCustomerMapping(
        Connection: Record "SI Prok Connection";
        Customer: Record Customer;
        var CustomerMapping: Record "SI Prok Entity Mapping")
    begin
        if not CustomerMapping.Get(
            Connection.Code,
            CustomerMapping."Entity Type"::Customer,
            Customer.SystemId)
        then
            Error(
                'Спочатку синхронізуйте інтеграційного клієнта %1 з Proktek.',
                Customer."No.");

        if CustomerMapping."Proktek Internal Code" = 0 then
            Error(
                'Для клієнта %1 у mapping відсутній Proktek kod.',
                Customer."No.");

        if IsNullGuid(CustomerMapping."Proktek UUID") then
            Error(
                'Для клієнта %1 у mapping відсутній Proktek UUID.',
                Customer."No.");
    end;

    local procedure GetOrInitMapping(
        Connection: Record "SI Prok Connection";
        Project: Record Job;
        var Mapping: Record "SI Prok Entity Mapping")
    begin
        Clear(Mapping);
        if Mapping.Get(
            Connection.Code,
            Mapping."Entity Type"::Site,
            Project.SystemId)
        then
            exit;

        Mapping.Init();
        Mapping."Connection Code" := Connection.Code;
        Mapping."Entity Type" := Mapping."Entity Type"::Site;
        Mapping."BC SystemId" := Project.SystemId;
        Mapping."BC No." := Project."No.";
    end;

    local procedure BuildSaveSiteRequest(
        SessionGuid: Guid;
        Project: Record Job;
        CustomerMapping: Record "SI Prok Entity Mapping";
        Mapping: Record "SI Prok Entity Mapping"): Text
    var
        Root: JsonObject;
        SiteJson: JsonObject;
        NamingMgt: Codeunit "SI Prok Naming Mgt.";
        Result: Text;
    begin
        Root.Add('guid', Format(SessionGuid, 0, 4));

        if Mapping."Proktek Internal Code" <> 0 then
            SiteJson.Add('kod', Mapping."Proktek Internal Code");

        if not IsNullGuid(Mapping."Proktek UUID") then
            SiteJson.Add('uuid', Format(Mapping."Proktek UUID", 0, 4));

        SiteJson.Add('aktif', true);
        SiteJson.Add('ad', NamingMgt.BuildProjectSiteName(Project));
        SiteJson.Add('santiye_kod', Project."No.");
        SiteJson.Add('musteri_kod', CustomerMapping."Proktek Internal Code");
        SiteJson.Add('musteri_uuid', Format(CustomerMapping."Proktek UUID", 0, 4));

        Root.Add('site', SiteJson);
        Root.WriteTo(Result);
        exit(Result);
    end;

    local procedure ApplySaveSiteResponse(
        ResponseText: Text;
        Connection: Record "SI Prok Connection";
        Project: Record Job;
        var Mapping: Record "SI Prok Entity Mapping")
    var
        Root: JsonObject;
        SiteJson: JsonObject;
        Token: JsonToken;
        ResponseStatus: Boolean;
        ResponseMessage: Text;
        UUIDText: Text;
        ProktekUUID: Guid;
        ProktekCode: Text;
        InternalCode: BigInteger;
    begin
        if not Root.ReadFrom(ResponseText) then
            Error(
                'Proktek SAVE-SITE повернув невалідний JSON: %1',
                CopyStr(ResponseText, 1, 1000));

        if not Root.Get('responseStatus', Token) then
            Error('У відповіді SAVE-SITE відсутнє поле responseStatus.');

        ResponseStatus := Token.AsValue().AsBoolean();

        if Root.Get('responseMessage', Token) then
            if not Token.AsValue().IsNull then
                ResponseMessage := Token.AsValue().AsText();

        if not ResponseStatus then
            Error(
                'Proktek відхилив SAVE-SITE для BC Project %1. %2',
                Project."No.",
                ResponseMessage);

        if not Root.Get('site', Token) then
            Error(
                'SAVE-SITE успішний, але у відповіді відсутній об''єкт site.');

        SiteJson := Token.AsObject();

        if SiteJson.Get('kod', Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull then
                    InternalCode := Token.AsValue().AsBigInteger();

        if not SiteJson.Get('uuid', Token) then
            Error(
                'SAVE-SITE успішний, але site.uuid у відповіді відсутній.');

        UUIDText := Token.AsValue().AsText();
        if not Evaluate(ProktekUUID, UUIDText) then
            Error(
                'Proktek повернув некоректний site.uuid: %1.',
                UUIDText);

        if SiteJson.Get('santiye_kod', Token) then
            if not Token.AsValue().IsNull then
                ProktekCode := Token.AsValue().AsText();

        Mapping."Connection Code" := Connection.Code;
        Mapping."Entity Type" := Mapping."Entity Type"::Site;
        Mapping."BC SystemId" := Project.SystemId;
        Mapping."BC No." := Project."No.";
        Mapping."Proktek UUID" := ProktekUUID;

        if InternalCode <> 0 then
            Mapping."Proktek Internal Code" := InternalCode;

        Mapping."Proktek Code" :=
            CopyStr(ProktekCode, 1, MaxStrLen(Mapping."Proktek Code"));
        Mapping."Last Sync At" := CurrentDateTime();
        Mapping."Last Response Message" :=
            CopyStr(
                ResponseMessage,
                1,
                MaxStrLen(Mapping."Last Response Message"));

        if Mapping.Insert(false) then
            exit;

        Mapping.Modify(false);
    end;

    local procedure GetResponseText(
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary): Text
    begin
        if ResponseBuffer.FindFirst() then
            exit(ResponseBuffer.GetBodyText());

        Error('EDS не повернув response buffer для SAVE-SITE.');
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    var
        NullGuid: Guid;
    begin
        exit(Value = NullGuid);
    end;
}
