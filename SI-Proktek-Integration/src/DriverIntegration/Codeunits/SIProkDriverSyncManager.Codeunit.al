codeunit 57147 "SI Prok Driver Sync Manager"
{
    // Driver business identity: Employee.No. -> Driver.aciklama1.
    // Active-state contract: Proktek.driver.aktif = Employee."SI Is Driver".
    // Never delete remote drivers. Inactive employees are synchronized only if already linked.
    procedure SyncAll(ConnectionCode: Code[50])
    var
        Connection: Record "SI Prok Connection";
        Employee: Record Employee;
        Mapping: Record "SI Prok Driver Mapping";
        Remote: JsonArray;
        PreviouslyLinked: List of [Code[20]];
        EmployeeNo: Code[20];
        Created: Integer;
        Updated: Integer;
        Linked: Integer;
        Unchanged: Integer;
    begin
        Connection.Get(ConnectionCode);
        LoadAll(Connection, Remote);
        Employee.SetRange("SI Is Driver", true);
        if Employee.FindSet() then
            repeat
                SyncEmployee(Connection, Employee, Remote, Created, Updated, Linked, Unchanged);
            until Employee.Next() = 0;
        // Include previously synchronized employees even if the flag was cleared.
        Mapping.SetRange("Connection Code", ConnectionCode);
        if Mapping.FindSet() then
            repeat
                if Mapping."Employee No." <> '' then
                    if not PreviouslyLinked.Contains(Mapping."Employee No.") then
                        PreviouslyLinked.Add(Mapping."Employee No.");
            until Mapping.Next() = 0;
        foreach EmployeeNo in PreviouslyLinked do
            if Employee.Get(EmployeeNo) then
                if not Employee."SI Is Driver" then
                    SyncEmployee(Connection, Employee, Remote, Created, Updated, Linked, Unchanged);
        Message('Синхронізація водіїв завершена. Створено: %1; оновлено: %2; відновлено прив’язок: %3; без змін: %4.',
            Created, Updated, Linked, Unchanged);
    end;

    procedure SyncOne(ConnectionCode: Code[50]; EmployeeNo: Code[20]): Boolean
    var
        Connection: Record "SI Prok Connection";
        Employee: Record Employee;
        Remote: JsonArray;
        Created: Integer;
        Updated: Integer;
        Linked: Integer;
        Unchanged: Integer;
    begin
        Connection.Get(ConnectionCode);
        Employee.Get(EmployeeNo);
        LoadAll(Connection, Remote);
        SyncEmployee(Connection, Employee, Remote, Created, Updated, Linked, Unchanged);
        exit((Created + Updated) > 0);
    end;

    local procedure SyncEmployee(var Connection: Record "SI Prok Connection"; Employee: Record Employee; Remote: JsonArray; var Created: Integer; var Updated: Integer; var Linked: Integer; var Unchanged: Integer)
    var
        Mapping: Record "SI Prok Driver Mapping";
        Other: Record "SI Prok Driver Mapping";
        Candidate: JsonObject;
        Payload: JsonObject;
        Result: JsonObject;
        EmployeeName: Text[100];
        Found: Boolean;
        HadMapping: Boolean;
        MappingChanged: Boolean;
        RemoteUuid: Guid;
        RemoteId: Integer;
        EmptyHub: JsonArray;
        NeedsUpdate: Boolean;
    begin
        EmployeeName := CopyStr(Employee.FullName(), 1, 100);
        if EmployeeName = '' then
            Error('Співробітник %1: ПІБ не заповнено.', Employee."No.");
        Found := FindByKey(Remote, Employee."No.", Candidate);
        Mapping.SetRange("Connection Code", Connection.Code);
        Mapping.SetRange("Employee No.", Employee."No.");
        if Mapping.FindSet() then begin
            HadMapping := true;
            if Mapping.Next() <> 0 then
                Error('Для співробітника %1 знайдено кілька Mapping у профілі %2.', Employee."No.", Connection.Code);
            Mapping.FindFirst();
        end;
        if not Employee."SI Is Driver" and not Found then begin
            if HadMapping then
                Error('Водій %1 позначений для деактивації, але його немає у GetDrivers. Перевірте Proktek.', Employee."No.");
            exit; // never create an inactive driver that was not previously synchronized
        end;
        if Found then begin
            RemoteId := GetInt(Candidate, 'kod');
            RemoteUuid := GetGuid(Candidate, 'uuid');
            if (RemoteId <= 0) or IsNullGuid(RemoteUuid) then
                Error('GetDrivers: некоректний kod/uuid для співробітника %1.', Employee."No.");
            Other.Reset();
            Other.SetRange("Connection Code", Connection.Code);
            Other.SetRange("Driver UUID", RemoteUuid);
            if Other.FindFirst() then
                if Other."Employee No." <> Employee."No." then
                    Error('UUID водія Proktek вже належить співробітнику %1.', Other."Employee No.");
            Other.Reset();
            Other.SetRange("Connection Code", Connection.Code);
            Other.SetRange("External Driver ID", RemoteId);
            if Other.FindSet() then
                repeat
                    if (Other."Employee No." <> Employee."No.") then
                        Error('ID водія Proktek %1 вже належить співробітнику %2.', RemoteId, Other."Employee No.");
                until Other.Next() = 0;
            MappingChanged := not HadMapping;
            if HadMapping then
                MappingChanged := (Mapping."Driver UUID" <> RemoteUuid) or (Mapping."External Driver ID" <> RemoteId);
            NeedsUpdate := (GetText(Candidate, 'ad') <> EmployeeName) or
                (GetText(Candidate, 'aciklama2') <> Employee."SI Driver Tax ID") or
                (GetBool(Candidate, 'aktif') <> Employee."SI Is Driver");
            if NeedsUpdate then begin
                Payload := Candidate;
                SetText(Payload, 'ad', EmployeeName);
                SetText(Payload, 'aciklama2', Employee."SI Driver Tax ID");
                SetBool(Payload, 'aktif', Employee."SI Is Driver");
                SaveDriver(Connection, Payload, Result);
                VerifyResult(Result, Employee, RemoteId, RemoteUuid);
                Updated += 1;
            end else
                if MappingChanged then
                    Linked += 1
                else
                    Unchanged += 1;
        end else begin
            Clear(Payload);
            Payload.Add('kod', 0);
            Payload.Add('aktif', Employee."SI Is Driver");
            Payload.Add('ad', EmployeeName);
            Payload.Add('adres', '');
            Payload.Add('telefon', '');
            Payload.Add('aciklama1', Employee."No.");
            Payload.Add('aciklama2', Employee."SI Driver Tax ID");
            Payload.Add('hub', EmptyHub);
            Payload.Add('uuid', '00000000-0000-0000-0000-000000000000');
            SaveDriver(Connection, Payload, Result);
            RemoteId := GetInt(Result, 'kod');
            RemoteUuid := GetGuid(Result, 'uuid');
            if (RemoteId <= 0) or IsNullGuid(RemoteUuid) then
                Error('SaveDriver Create: некоректний kod/uuid для %1. Перевірте GetDrivers перед повтором.', Employee."No.");
            VerifyResult(Result, Employee, RemoteId, RemoteUuid);
            Created += 1;
        end;
        if HadMapping then begin
            if Mapping."Driver UUID" <> RemoteUuid then begin
                // PK includes UUID: migrate mapping without changing any external business identity.
                Mapping.Rename(Connection.Code, RemoteUuid);
            end;
        end else begin
            Mapping.Init();
            Mapping."Connection Code" := Connection.Code;
            Mapping."Driver UUID" := RemoteUuid;
            Mapping.Insert(true);
        end;
        Mapping."Employee No." := Employee."No.";
        Mapping."Driver Name" := EmployeeName;
        Mapping."External Driver ID" := RemoteId;
        Mapping.Modify(true);
    end;

    local procedure LoadAll(var Connection: Record "SI Prok Connection"; var AllDrivers: JsonArray)
    var
        Auth: Codeunit "SI Prok Auth Mgt.";
        EDS: Codeunit "SI EDS Orchestrator";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        Buffer: Record "SI EDS Response Buffer" temporary;
        Request: JsonObject;
        Response: JsonObject;
        Items: JsonArray;
        Token: JsonToken;
        Item: JsonToken;
        Body: Text;
        PageNo: Integer;
        Pages: Integer;
        I: Integer;
        SessionId: Guid;
    begin
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");
        SessionId := Auth.GetSessionGuid(Connection);
        PageNo := 1;
        repeat
            Clear(Request);
            Clear(Response);
            Clear(Buffer);
            Request.Add('guid', Format(SessionId, 0, 4));
            Request.Add('filter', '');
            Request.Add('perpage', 100);
            Request.Add('page', PageNo);
            Request.WriteTo(Body);
            EDS.ExecuteProviderBody(Connection."EDS Service Code", 'GET-DRIVERS', Connection."EDS Provider Code",
                RuntimeParam, Body, 'application/json-patch+json', 'text/plain', Buffer);
            if Buffer."Result Type" <> Buffer."Result Type"::Success then
                Error('GetDrivers page %1: HTTP %2; %3', PageNo, Buffer."HTTP Status Code", Buffer."Error Message");
            if not Response.ReadFrom(Buffer.GetBodyText()) then
                Error('GetDrivers page %1: некоректний JSON.', PageNo);
            if not GetBool(Response, 'responseStatus') then
                Error('GetDrivers page %1: %2', PageNo, GetText(Response, 'responseMessage'));
            if not Response.Get('driver', Token) then
                Error('GetDrivers page %1: відсутній масив driver.', PageNo);
            if not Token.IsArray() then
                Error('GetDrivers page %1: driver не є масивом.', PageNo);
            Items := Token.AsArray();
            for I := 0 to Items.Count() - 1 do begin
                Items.Get(I, Item);
                AllDrivers.Add(Item);
            end;
            Pages := GetInt(Response, 'totalpages');
            if Pages < 1 then
                Pages := 1;
            PageNo += 1;
        until PageNo > Pages;
    end;

    local procedure FindByKey(Drivers: JsonArray; EmployeeNo: Code[20]; var Driver: JsonObject): Boolean
    var
        Token: JsonToken;
        Candidate: JsonObject;
        I: Integer;
        FoundCount: Integer;
    begin
        for I := 0 to Drivers.Count() - 1 do begin
            Drivers.Get(I, Token);
            Candidate := Token.AsObject();
            if GetText(Candidate, 'aciklama1') = EmployeeNo then begin
                Driver := Candidate;
                FoundCount += 1;
            end;
        end;
        if FoundCount > 1 then
            Error('GetDrivers: %1 записів із aciklama1=%2. Синхронізацію заблоковано.', FoundCount, EmployeeNo);
        exit(FoundCount = 1);
    end;

    local procedure SaveDriver(var Connection: Record "SI Prok Connection"; Driver: JsonObject; var Result: JsonObject)
    var
        Auth: Codeunit "SI Prok Auth Mgt.";
        EDS: Codeunit "SI EDS Orchestrator";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        Buffer: Record "SI EDS Response Buffer" temporary;
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
        Body: Text;
    begin
        Request.Add('guid', Format(Auth.GetSessionGuid(Connection), 0, 4));
        Request.Add('driver', Driver);
        Request.WriteTo(Body);
        EDS.ExecuteProviderBody(Connection."EDS Service Code", 'SAVE-DRIVER', Connection."EDS Provider Code",
            RuntimeParam, Body, 'application/json-patch+json', 'text/plain', Buffer);
        if Buffer."Result Type" <> Buffer."Result Type"::Success then
            Error('SaveDriver HTTP %1: %2. Перевірте GetDrivers перед повтором.', Buffer."HTTP Status Code", Buffer."Error Message");
        if not Response.ReadFrom(Buffer.GetBodyText()) then
            Error('SaveDriver: некоректний JSON. Перевірте GetDrivers перед повтором.');
        if not GetBool(Response, 'responseStatus') then
            Error('SaveDriver: %1', GetText(Response, 'responseMessage'));
        if not Response.Get('driver', Token) then
            Error('SaveDriver: відсутній driver. Перевірте GetDrivers перед повтором.');
        Result := Token.AsObject();
    end;

    local procedure VerifyResult(Result: JsonObject; Employee: Record Employee; ExpectedId: Integer; ExpectedUuid: Guid)
    begin
        if (GetInt(Result, 'kod') <> ExpectedId) or (GetGuid(Result, 'uuid') <> ExpectedUuid) or
           (GetText(Result, 'aciklama1') <> Employee."No.") then
            Error('SaveDriver: змінилася ідентичність водія %1. Перевірте GetDrivers.', Employee."No.");
        if (GetText(Result, 'ad') <> CopyStr(Employee.FullName(), 1, 100)) or
           (GetText(Result, 'aciklama2') <> Employee."SI Driver Tax ID") or
           (GetBool(Result, 'aktif') <> Employee."SI Is Driver") then
            Error('SaveDriver: невідповідність атрибутів водія %1. Перевірте GetDrivers.', Employee."No.");
    end;

    local procedure GetText(Obj: JsonObject; KeyName: Text): Text
    var T: JsonToken;
    begin
        if Obj.Get(KeyName, T) then
            if T.IsValue() then
                if not T.AsValue().IsNull() then
                    exit(T.AsValue().AsText());
        exit('');
    end;

    local procedure GetInt(Obj: JsonObject; KeyName: Text): Integer
    var T: JsonToken;
    begin
        if Obj.Get(KeyName, T) then
            if T.IsValue() then
                if not T.AsValue().IsNull() then
                    exit(T.AsValue().AsInteger());
        exit(0);
    end;

    local procedure GetBool(Obj: JsonObject; KeyName: Text): Boolean
    var T: JsonToken;
    begin
        if Obj.Get(KeyName, T) then
            if T.IsValue() then
                if not T.AsValue().IsNull() then
                    exit(T.AsValue().AsBoolean());
        exit(false);
    end;

    local procedure GetGuid(Obj: JsonObject; KeyName: Text): Guid
    var G: Guid;
    begin
        if not Evaluate(G, GetText(Obj, KeyName)) then
            Clear(G);
        exit(G);
    end;

    local procedure SetText(var Obj: JsonObject; KeyName: Text; Value: Text)
    begin
        if Obj.Contains(KeyName) then Obj.Replace(KeyName, Value) else Obj.Add(KeyName, Value);
    end;

    local procedure SetBool(var Obj: JsonObject; KeyName: Text; Value: Boolean)
    begin
        if Obj.Contains(KeyName) then Obj.Replace(KeyName, Value) else Obj.Add(KeyName, Value);
    end;
}
