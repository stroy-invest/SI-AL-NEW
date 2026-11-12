codeunit 57113 "SI Prok Mixer Sync Manager"
{
    // Mixer upsert. BC Vehicle No. <-> Proktek kamyon_kod.
    // The remote directory is fetched completely BEFORE any mutation.
    procedure SyncAll(ConnectionCode: Code[50])
    var
        Connection: Record "SI Prok Connection";
        Vehicle: Record "SI Vehicle Profile";
        Remote: JsonArray;
        Created: Integer;
        Updated: Integer;
        Linked: Integer;
        Unchanged: Integer;
    begin
        Connection.Get(ConnectionCode);
        LoadAllMixers(Connection, Remote);
        Vehicle.SetRange("Vehicle Type Code", 'CONCRETE-MIXER');
        if Vehicle.FindSet() then
            repeat
                SyncVehicle(Connection, Vehicle, Remote, Created, Updated, Linked, Unchanged);
            until Vehicle.Next() = 0;
        Message('Синхронізація міксерів завершена. Створено: %1; оновлено: %2; відновлено прив’язок: %3; без змін: %4.',
            Created, Updated, Linked, Unchanged);
    end;

    // Single-vehicle upsert uses exactly the same comparison and SaveMixer logic as SyncAll.
    procedure SyncOne(ConnectionCode: Code[50]; VehicleNo: Code[20]): Boolean
    var
        Connection: Record "SI Prok Connection";
        Vehicle: Record "SI Vehicle Profile";
        Remote: JsonArray;
        Created: Integer;
        Updated: Integer;
        Linked: Integer;
        Unchanged: Integer;
    begin
        Connection.Get(ConnectionCode);
        Vehicle.Get(VehicleNo);
        Vehicle.TestField("Vehicle Type Code", 'CONCRETE-MIXER');
        LoadAllMixers(Connection, Remote);
        SyncVehicle(Connection, Vehicle, Remote, Created, Updated, Linked, Unchanged);
        exit((Created + Updated) > 0);
    end;

    local procedure SyncVehicle(var Connection: Record "SI Prok Connection"; var Vehicle: Record "SI Vehicle Profile"; Remote: JsonArray; var Created: Integer; var Updated: Integer; var Linked: Integer; var Unchanged: Integer)
    var
        Mapping: Record "SI Prok Vehicle Mapping";
        Candidate: JsonObject;
        Existing: JsonObject;
        Result: JsonObject;
        Found: Boolean;
        Capacity: Decimal;
        RemoteId: Integer;
        RemoteUuid: Guid;
        NeedsUpdate: Boolean;
        HadMapping: Boolean;
        IdentityChanged: Boolean;
        EmptyHub: JsonArray;
    begin
        Vehicle.TestField("Registration No.");
        Capacity := GetCapacity(Vehicle."No.");
        Found := FindByBusinessKey(Remote, Vehicle."No.", Candidate);
        HadMapping := Mapping.Get(Connection.Code, Vehicle."No.");
        if Found then begin
            RemoteId := GetInt(Candidate, 'kod');
            RemoteUuid := GetGuid(Candidate, 'uuid');
            if (RemoteId <= 0) or IsNullGuid(RemoteUuid) then
                Error('Proktek повернув некоректну ідентичність міксера %1.', Vehicle."No.");
            CheckIdentity(Connection.Code, Vehicle."No.", RemoteId, RemoteUuid);
            IdentityChanged := (not HadMapping) or (Mapping."External Mixer ID" <> RemoteId) or
                (Mapping."External Mixer UUID" <> RemoteUuid) or (Mapping."External Mixer Code" <> Vehicle."No.");
            NeedsUpdate := (GetText(Candidate, 'plaka') <> Vehicle."Registration No.") or
                (GetText(Candidate, 'aciklama1') <> Vehicle."VIN") or
                (GetDecimal(Candidate, 'kapasite') <> Capacity) or
                (GetBool(Candidate, 'aktif') <> (not Vehicle.Blocked));
            // TEMP DIAGNOSTICS: remove after the VECHICLE-0003 discrepancy is resolved.
            //if Vehicle."No." = 'VECHICLE-0003' then
            //    Message(
            //        'MIXER DIAG\Vehicle: %1\BC actual DRUM-VOLUME: %2\Proktek kapasite: %3\NeedsUpdate: %4\Mapping exists: %5\Mapping changed: %6\BC VIN: %7\Proktek VIN: %8',
            //        Vehicle."No.", Capacity, GetDecimal(Candidate, 'kapasite'), NeedsUpdate,
            //       HadMapping, IdentityChanged, Vehicle."VIN", GetText(Candidate, 'aciklama1'));
            if NeedsUpdate then begin
                Existing := Candidate;
                SetValue(Existing, 'plaka', Vehicle."Registration No.");
                SetValue(Existing, 'aciklama1', Vehicle."VIN");
                SetValue(Existing, 'kapasite', Capacity);
                SetValue(Existing, 'aktif', not Vehicle.Blocked);
                SaveMixer(Connection, Existing, Result);
                if (GetInt(Result, 'kod') <> RemoteId) or (GetGuid(Result, 'uuid') <> RemoteUuid) or
                   (GetText(Result, 'kamyon_kod') <> Vehicle."No.") then
                    Error('SaveMixer повернув іншу ідентичність для %1. Перевірте Proktek.', Vehicle."No.");
                VerifySavedValues(Result, Vehicle, Capacity);
                Updated += 1;
            end else
                if IdentityChanged then
                    Linked += 1
                else
                    Unchanged += 1;
        end else begin
            // TEMP DIAGNOSTICS: a missing remote business key would trigger Create.
            //if Vehicle."No." = 'VECHICLE-0003' then
            //    Message('MIXER DIAG\Vehicle: %1\BC actual DRUM-VOLUME: %2\Remote match: NOT FOUND\Next action: CREATE', Vehicle."No.", Capacity);
            Clear(Existing);
            Existing.Add('kod', 0);
            Existing.Add('kamyon_kod', Vehicle."No.");
            Existing.Add('aktif', not Vehicle.Blocked);
            Existing.Add('plaka', Vehicle."Registration No.");
            Existing.Add('kapasite', Capacity);
            Existing.Add('aciklama1', Vehicle."VIN");
            Existing.Add('aciklama2', '');
            Existing.Add('surucu_kod', 0);
            Existing.Add('surucu_uuid', '00000000-0000-0000-0000-000000000000');
            Existing.Add('hub', EmptyHub);
            Existing.Add('uuid', '00000000-0000-0000-0000-000000000000');
            SaveMixer(Connection, Existing, Result);
            RemoteId := GetInt(Result, 'kod');
            RemoteUuid := GetGuid(Result, 'uuid');
            if (RemoteId <= 0) or IsNullGuid(RemoteUuid) or (GetText(Result, 'kamyon_kod') <> Vehicle."No.") then
                Error('SaveMixer Create повернув некоректну ідентичність для %1. Повторно перевірте GetMixers.', Vehicle."No.");
            CheckIdentity(Connection.Code, Vehicle."No.", RemoteId, RemoteUuid);
            VerifySavedValues(Result, Vehicle, Capacity);
            Created += 1;
        end;
        if not HadMapping then begin
            Mapping.Init();
            Mapping."Connection Code" := Connection.Code;
            Mapping."Vehicle No." := Vehicle."No.";
            Mapping.Insert(true);
        end;
        Mapping."External Mixer Code" := Vehicle."No.";
        Mapping."External Mixer ID" := RemoteId;
        Mapping."External Mixer UUID" := RemoteUuid;
        Mapping."Sync Status" := Mapping."Sync Status"::Synced;
        Mapping."Last Synced At" := CurrentDateTime;
        Mapping."Last Error" := '';
        Mapping.Modify(true);
    end;

    local procedure LoadAllMixers(var Connection: Record "SI Prok Connection"; var AllMixers: JsonArray)
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
        Index: Integer;
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
            EDS.ExecuteProviderBody(Connection."EDS Service Code", 'GET-MIXERS', Connection."EDS Provider Code",
                RuntimeParam, Body, 'application/json-patch+json', 'text/plain', Buffer);
            if Buffer."Result Type" <> Buffer."Result Type"::Success then
                Error('GetMixers page %1: HTTP %2; %3', PageNo, Buffer."HTTP Status Code", Buffer."Error Message");
            if not Response.ReadFrom(Buffer.GetBodyText()) then
                Error('GetMixers page %1: invalid JSON.', PageNo);
            if not Response.Get('responseStatus', Token) then
                Error('GetMixers page %1: missing responseStatus.', PageNo);
            if not Token.AsValue().AsBoolean() then
                Error('GetMixers page %1: %2', PageNo, GetText(Response, 'responseMessage'));
            if not Response.Get('mixer', Token) then
                Error('GetMixers page %1: missing mixer array.', PageNo);
            if not Token.IsArray() then
                Error('GetMixers page %1: mixer is not array.', PageNo);
            Items := Token.AsArray();
            for Index := 0 to Items.Count() - 1 do begin
                Items.Get(Index, Item);
                AllMixers.Add(Item);
            end;
            Pages := GetInt(Response, 'totalpages');
            if Pages < 1 then
                Pages := 1;
            PageNo += 1;
        until PageNo > Pages;
    end;

    local procedure FindByBusinessKey(Remote: JsonArray; VehicleNo: Code[20]; var Mixer: JsonObject): Boolean
    var
        Item: JsonToken;
        Candidate: JsonObject;
        Index: Integer;
        CountFound: Integer;
    begin
        for Index := 0 to Remote.Count() - 1 do begin
            Remote.Get(Index, Item);
            Candidate := Item.AsObject();
            if GetText(Candidate, 'kamyon_kod') = VehicleNo then begin
                Mixer := Candidate;
                CountFound += 1;
            end;
        end;
        if CountFound > 1 then
            Error('У Proktek знайдено %1 міксерів з kamyon_kod=%2. Upsert заблоковано.', CountFound, VehicleNo);
        exit(CountFound = 1);
    end;

    local procedure CheckIdentity(ConnectionCode: Code[50]; VehicleNo: Code[20]; MixerId: Integer; MixerUuid: Guid)
    var
        Other: Record "SI Prok Vehicle Mapping";
    begin
        Other.SetRange("Connection Code", ConnectionCode);
        Other.SetRange("External Mixer ID", MixerId);
        if Other.FindSet() then
            repeat
                if Other."Vehicle No." <> VehicleNo then
                    Error('Proktek Mixer ID %1 already belongs to BC vehicle %2.', MixerId, Other."Vehicle No.");
            until Other.Next() = 0;
        Other.Reset();
        Other.SetRange("Connection Code", ConnectionCode);
        Other.SetRange("External Mixer UUID", MixerUuid);
        if Other.FindSet() then
            repeat
                if Other."Vehicle No." <> VehicleNo then
                    Error('Proktek Mixer UUID already belongs to BC vehicle %1.', Other."Vehicle No.");
            until Other.Next() = 0;
    end;

    local procedure SaveMixer(var Connection: Record "SI Prok Connection"; Mixer: JsonObject; var Result: JsonObject)
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
        Request.Add('mixer', Mixer);
        Request.WriteTo(Body);
        EDS.ExecuteProviderBody(Connection."EDS Service Code", 'SAVE-MIXER', Connection."EDS Provider Code",
            RuntimeParam, Body, 'application/json-patch+json', 'text/plain', Buffer);
        if Buffer."Result Type" <> Buffer."Result Type"::Success then
            Error('SaveMixer HTTP %1: %2. Перед повтором перевірте GetMixers.', Buffer."HTTP Status Code", Buffer."Error Message");
        if not Response.ReadFrom(Buffer.GetBodyText()) then
            Error('SaveMixer returned invalid JSON. Verify GetMixers before retry.');
        if not Response.Get('responseStatus', Token) then
            Error('SaveMixer: missing responseStatus. Verify GetMixers before retry.');
        if not Token.AsValue().AsBoolean() then
            Error('SaveMixer: %1', GetText(Response, 'responseMessage'));
        if not Response.Get('mixer', Token) then
            Error('SaveMixer: missing mixer object. Verify GetMixers before retry.');
        Result := Token.AsObject();
    end;

    // Validate all BC-owned fields in the SaveMixer response, not just the identity.
    // This catches successful HTTP responses that did not actually persist capacity.
    local procedure VerifySavedValues(Result: JsonObject; Vehicle: Record "SI Vehicle Profile"; Capacity: Decimal)
    var
        Token: JsonToken;
    begin
        if (GetText(Result, 'plaka') <> Vehicle."Registration No.") or
           (GetText(Result, 'aciklama1') <> Vehicle."VIN") then
            Error('SaveMixer: plate/VIN mismatch for vehicle %1. Check GetMixers before retry.', Vehicle."No.");
        if not Result.Get('kapasite', Token) then
            Error('SaveMixer: missing kapasite for vehicle %1. Check GetMixers before retry.', Vehicle."No.");
        if (not Token.IsValue()) or Token.AsValue().IsNull() then
            Error('SaveMixer: invalid kapasite for vehicle %1.', Vehicle."No.");
        if Token.AsValue().AsDecimal() <> Capacity then
            Error('SaveMixer: kapasite mismatch for vehicle %1. Expected %2, returned %3. Check GetMixers before retry.',
                Vehicle."No.", Capacity, Token.AsValue().AsDecimal());
        if not Result.Get('aktif', Token) then
            Error('SaveMixer: missing aktif for vehicle %1.', Vehicle."No.");
        if (not Token.IsValue()) or Token.AsValue().IsNull() then
            Error('SaveMixer: invalid aktif for vehicle %1.', Vehicle."No.");
        if Token.AsValue().AsBoolean() <> (not Vehicle.Blocked) then
            Error('SaveMixer: aktif mismatch for vehicle %1. Check GetMixers before retry.', Vehicle."No.");
    end;

    local procedure GetCapacity(VehicleNo: Code[20]): Decimal
    var
        VehicleMgt: Codeunit "SI Vehicle Management";
        Value: Decimal;
        UoM: Code[10];
    begin
        if not VehicleMgt.GetActualCharacteristicValue(VehicleNo, 'DRUM-VOLUME', Value, UoM) then
            Error('Vehicle %1: actual DRUM-VOLUME missing.', VehicleNo);
        if (UoM <> 'M3') or (Value <= 0) then
            Error('Vehicle %1: actual DRUM-VOLUME must be positive in M3.', VehicleNo);
        exit(Value);
    end;

    local procedure GetText(Obj: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
    begin
        if Obj.Get(KeyName, Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull() then
                    exit(Token.AsValue().AsText());
        exit('');
    end;

    local procedure GetInt(Obj: JsonObject; KeyName: Text): Integer
    var
        Token: JsonToken;
    begin
        if Obj.Get(KeyName, Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull() then
                    exit(Token.AsValue().AsInteger());
        exit(0);
    end;

    local procedure GetDecimal(Obj: JsonObject; KeyName: Text): Decimal
    var
        Token: JsonToken;
    begin
        if Obj.Get(KeyName, Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull() then
                    exit(Token.AsValue().AsDecimal());
        exit(0);
    end;

    local procedure GetBool(Obj: JsonObject; KeyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if Obj.Get(KeyName, Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull() then
                    exit(Token.AsValue().AsBoolean());
        exit(false);
    end;

    local procedure GetGuid(Obj: JsonObject; KeyName: Text): Guid
    var
        G: Guid;
    begin
        if not Evaluate(G, GetText(Obj, KeyName)) then
            Clear(G);
        exit(G);
    end;

    local procedure SetValue(var Obj: JsonObject; KeyName: Text; Value: Text)
    begin
        if Obj.Contains(KeyName) then
            Obj.Replace(KeyName, Value)
        else
            Obj.Add(KeyName, Value);
    end;

    local procedure SetValue(var Obj: JsonObject; KeyName: Text; Value: Decimal)
    begin
        if Obj.Contains(KeyName) then
            Obj.Replace(KeyName, Value)
        else
            Obj.Add(KeyName, Value);
    end;

    local procedure SetValue(var Obj: JsonObject; KeyName: Text; Value: Boolean)
    begin
        if Obj.Contains(KeyName) then
            Obj.Replace(KeyName, Value)
        else
            Obj.Add(KeyName, Value);
    end;
}
