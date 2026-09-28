codeunit 57058 "SI Prok Customer Sync"
{
    procedure SyncProjectCustomer(var Project: Record Job; var Mapping: Record "SI Prok Entity Mapping")
    var
        Connection: Record "SI Prok Connection";
        Customer: Record Customer;
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        NamingMgt: Codeunit "SI Prok Naming Mgt.";
    begin
        Project.TestField("No.");
        Project.TestField("Location Code");
        Project.TestField("SI Internal Customer No.");

        Customer.Get(Project."SI Internal Customer No.");
        if Customer."SI Customer Type" <> Customer."SI Customer Type"::"Internal Project" then
            Error(
                'Клієнт %1, прив''язаний до проєкту %2, не має типу Internal Project.',
                Customer."No.",
                Project."No.");

        ConnectionMgt.GetActive(Connection);

        if Connection.Environment = Connection.Environment::Production then
            if not Confirm(
                'Буде створено або оновлено клієнта %1 (%2) у ПРОДУКТИВНОМУ Proktek через підключення %3. Продовжити?',
                false,
                Customer."No.",
                Customer.Name,
                Connection.Code)
            then
                exit;

        SyncCustomerNamed(
            Connection,
            Customer,
            NamingMgt.BuildProjectCustomerName(Project),
            Mapping);
    end;

    procedure SyncProjectCustomerForConnection(
        var Connection: Record "SI Prok Connection";
        var Project: Record Job;
        var Mapping: Record "SI Prok Entity Mapping")
    var
        Customer: Record Customer;
        NamingMgt: Codeunit "SI Prok Naming Mgt.";
    begin
        Project.TestField("No.");
        Project.TestField("SI Internal Customer No.");
        Customer.Get(Project."SI Internal Customer No.");
        if Customer."SI Customer Type" <> Customer."SI Customer Type"::"Internal Project" then
            Error('Клієнт %1, прив''язаний до проєкту %2, не має типу Internal Project.', Customer."No.", Project."No.");
        SyncCustomerNamed(Connection, Customer, NamingMgt.BuildProjectCustomerName(Project), Mapping);
    end;

    procedure SyncCustomer(
        var Connection: Record "SI Prok Connection";
        var Customer: Record Customer;
        var Mapping: Record "SI Prok Entity Mapping")
    begin
        SyncCustomerNamed(Connection, Customer, Customer.Name, Mapping);
    end;

    local procedure SyncCustomerNamed(
        var Connection: Record "SI Prok Connection";
        var Customer: Record Customer;
        DisplayName: Text;
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

        SessionGuid := AuthMgt.GetSessionGuid(Connection);

        GetOrInitMapping(Connection, Customer, Mapping);
        EnsureUpdateIdentity(Connection, Customer, Mapping);

        RequestBody := BuildSaveCustomerRequest(SessionGuid, Customer, DisplayName, Mapping);

        EDSOrchestrator.ExecuteProviderBody(
            Connection."EDS Service Code",
            'SAVE-CUSTOMER',
            Connection."EDS Provider Code",
            RuntimeParam,
            RequestBody,
            'application/json-patch+json',
            'text/plain',
            ResponseBuffer);

        ResponseText := GetResponseText(ResponseBuffer);
        ApplySaveCustomerResponse(ResponseText, Connection, Customer, Mapping);
    end;

    local procedure GetOrInitMapping(
        Connection: Record "SI Prok Connection";
        Customer: Record Customer;
        var Mapping: Record "SI Prok Entity Mapping")
    begin
        Clear(Mapping);
        if Mapping.Get(
            Connection.Code,
            Mapping."Entity Type"::Customer,
            Customer.SystemId)
        then
            exit;

        Mapping.Init();
        Mapping."Connection Code" := Connection.Code;
        Mapping."Entity Type" := Mapping."Entity Type"::Customer;
        Mapping."BC SystemId" := Customer.SystemId;
        Mapping."BC No." := Customer."No.";
    end;

    local procedure EnsureUpdateIdentity(
        var Connection: Record "SI Prok Connection";
        Customer: Record Customer;
        var Mapping: Record "SI Prok Entity Mapping")
    var
        CustomerRead: Codeunit "SI Prok Customer Read";
        InternalCode: BigInteger;
        ResolvedUUID: Guid;
        ResolvedCode: Text;
    begin
        if IsNullGuid(Mapping."Proktek UUID") then
            exit;

        if Mapping."Proktek Internal Code" <> 0 then
            exit;

        if not CustomerRead.ResolveCustomerIdentity(
            Connection,
            Customer."No.",
            InternalCode,
            ResolvedUUID,
            ResolvedCode)
        then
            Error(
                'Для існуючого Proktek Customer %1 не вдалося визначити внутрішній kod через GET-CUSTOMERS.',
                Customer."No.");

        if (not IsNullGuid(ResolvedUUID)) and
           (ResolvedUUID <> Mapping."Proktek UUID")
        then
            Error(
                'GET-CUSTOMERS повернув інший UUID для %1. Mapping UUID: %2, Proktek UUID: %3.',
                Customer."No.",
                Mapping."Proktek UUID",
                ResolvedUUID);

        Mapping."Proktek Internal Code" := InternalCode;

        if ResolvedCode <> '' then
            Mapping."Proktek Code" :=
                CopyStr(ResolvedCode, 1, MaxStrLen(Mapping."Proktek Code"));

        if Mapping.Insert(false) then
            exit;

        Mapping.Modify(false);
    end;

    local procedure BuildSaveCustomerRequest(
        SessionGuid: Guid;
        Customer: Record Customer;
        DisplayName: Text;
        Mapping: Record "SI Prok Entity Mapping"): Text
    var
        Root: JsonObject;
        CustomerJson: JsonObject;
        Result: Text;
        AddressText: Text;
    begin
        Root.Add('guid', Format(SessionGuid, 0, 4));

        if Mapping."Proktek Internal Code" <> 0 then
            CustomerJson.Add('kod', Mapping."Proktek Internal Code");

        if not IsNullGuid(Mapping."Proktek UUID") then
            CustomerJson.Add('uuid', Format(Mapping."Proktek UUID", 0, 4));

        CustomerJson.Add('musteri_kod', Customer."No.");
        CustomerJson.Add('aktif', true);
        CustomerJson.Add('ad', DisplayName);

        if Customer."Phone No." <> '' then
            CustomerJson.Add('telefon', Customer."Phone No.");

        AddressText := Customer.Address;
        if Customer."Address 2" <> '' then begin
            if AddressText <> '' then
                AddressText += ', ';
            AddressText += Customer."Address 2";
        end;
        if AddressText <> '' then
            CustomerJson.Add('adres', AddressText);

        if Customer.City <> '' then
            CustomerJson.Add('sehir', Customer.City);

        if Customer."Post Code" <> '' then
            CustomerJson.Add('posta_kodu', Customer."Post Code");

        if Customer."E-Mail" <> '' then
            CustomerJson.Add('eposta', Customer."E-Mail");

        if Customer."VAT Registration No." <> '' then
            CustomerJson.Add('vergi_no', Customer."VAT Registration No.");

        Root.Add('customer', CustomerJson);
        Root.WriteTo(Result);
        exit(Result);
    end;

    local procedure ApplySaveCustomerResponse(
        ResponseText: Text;
        Connection: Record "SI Prok Connection";
        Customer: Record Customer;
        var Mapping: Record "SI Prok Entity Mapping")
    var
        Root: JsonObject;
        CustomerJson: JsonObject;
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
                'Proktek SAVE-CUSTOMER повернув невалідний JSON: %1',
                CopyStr(ResponseText, 1, 1000));

        if not Root.Get('responseStatus', Token) then
            Error('У відповіді SAVE-CUSTOMER відсутнє поле responseStatus.');

        ResponseStatus := Token.AsValue().AsBoolean();

        if Root.Get('responseMessage', Token) then
            if not Token.AsValue().IsNull then
                ResponseMessage := Token.AsValue().AsText();

        if not ResponseStatus then
            Error(
                'Proktek відхилив SAVE-CUSTOMER для BC Customer %1. %2',
                Customer."No.",
                ResponseMessage);

        if not Root.Get('customer', Token) then
            Error(
                'SAVE-CUSTOMER успішний, але у відповіді відсутній об''єкт customer.');

        CustomerJson := Token.AsObject();

        if CustomerJson.Get('kod', Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull then
                    InternalCode := Token.AsValue().AsBigInteger();

        if not CustomerJson.Get('uuid', Token) then
            Error(
                'SAVE-CUSTOMER успішний, але customer.uuid у відповіді відсутній.');

        UUIDText := Token.AsValue().AsText();
        if not Evaluate(ProktekUUID, UUIDText) then
            Error(
                'Proktek повернув некоректний customer.uuid: %1.',
                UUIDText);

        if CustomerJson.Get('musteri_kod', Token) then
            if not Token.AsValue().IsNull then
                ProktekCode := Token.AsValue().AsText();

        Mapping."Connection Code" := Connection.Code;
        Mapping."Entity Type" := Mapping."Entity Type"::Customer;
        Mapping."BC SystemId" := Customer.SystemId;
        Mapping."BC No." := Customer."No.";
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

        Error('EDS не повернув response buffer для SAVE-CUSTOMER.');
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    var
        NullGuid: Guid;
    begin
        exit(Value = NullGuid);
    end;
}
