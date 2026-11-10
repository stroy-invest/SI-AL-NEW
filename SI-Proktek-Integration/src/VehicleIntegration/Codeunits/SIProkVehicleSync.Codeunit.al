codeunit 57112 "SI Prok Vehicle Sync"
{
    // PF-01.3A.2: safe discovery and adoption; no remote mutation.
    procedure AdoptExisting(ConnectionCode: Code[50]; VehicleNo: Code[20]; ExternalId: Integer; ExternalUuid: Guid)
    var
        Mapping: Record "SI Prok Vehicle Mapping";
        Other: Record "SI Prok Vehicle Mapping";
        Vehicle: Record "SI Vehicle Profile";
        Connection: Record "SI Prok Connection";
        Response: JsonObject;
        Mixer: JsonObject;
        ExternalCode: Text;
        ReturnedId: Integer;
        ReturnedUuid: Guid;
    begin
        Connection.Get(ConnectionCode);
        Vehicle.Get(VehicleNo);
        if ExternalId <= 0 then
            Error('Для прив’язки потрібен додатний Proktek Mixer ID.');
        if IsNullGuid(ExternalUuid) then
            Error('Для прив’язки потрібен Proktek Mixer UUID.');

        GetMixers(Connection, Response);
        if not FindMixer(Response, ExternalId, ExternalUuid, Mixer) then
            Error('Міксер ID %1 / UUID %2 не знайдено у GetMixers. Перевірте підключення та сторінки результату.', ExternalId, ExternalUuid);

        ExternalCode := GetText(Mixer, 'kamyon_kod');
        ReturnedId := GetInteger(Mixer, 'kod');
        ReturnedUuid := GetGuid(Mixer, 'uuid');
        if (ReturnedId <> ExternalId) or (ReturnedUuid <> ExternalUuid) then
            Error('Зовнішня ідентичність міксера не збігається.');
        if ExternalCode <> VehicleNo then
            Error('Mixer Code у Proktek (%1) не збігається з BC Vehicle No. (%2). Спочатку узгодьте код у Proktek.', ExternalCode, VehicleNo);

        Other.SetRange("Connection Code", ConnectionCode);
        Other.SetRange("External Mixer ID", ExternalId);
        if Other.FindFirst() then
            if Other."Vehicle No." <> VehicleNo then
                Error('Proktek Mixer ID %1 вже прив’язаний до BC Vehicle %2.', ExternalId, Other."Vehicle No.");
        Other.Reset();
        Other.SetRange("Connection Code", ConnectionCode);
        Other.SetRange("External Mixer UUID", ExternalUuid);
        if Other.FindFirst() then
            if Other."Vehicle No." <> VehicleNo then
                Error('Proktek Mixer UUID вже прив’язаний до BC Vehicle %1.', Other."Vehicle No.");

        if not Mapping.Get(ConnectionCode, VehicleNo) then begin
            Mapping.Init();
            Mapping."Connection Code" := ConnectionCode;
            Mapping."Vehicle No." := VehicleNo;
            Mapping.Insert(true);
        end else
            if (Mapping."External Mixer ID" <> 0) and
               ((Mapping."External Mixer ID" <> ExternalId) or (Mapping."External Mixer UUID" <> ExternalUuid)) then
                Error('Поточний мапінг має іншу зовнішню ідентичність. Автоматичне переприв’язування заборонено.');

        Mapping."External Mixer Code" := CopyStr(ExternalCode, 1, MaxStrLen(Mapping."External Mixer Code"));
        Mapping."External Mixer ID" := ExternalId;
        Mapping."External Mixer UUID" := ExternalUuid;
        Mapping."Sync Status" := Mapping."Sync Status"::Synced;
        Mapping."Last Synced At" := CurrentDateTime;
        Mapping."Last Error" := '';
        Mapping.Modify(true);
    end;

    procedure VerifyExisting(ConnectionCode: Code[50]; VehicleNo: Code[20])
    var
        Connection: Record "SI Prok Connection";
        Mapping: Record "SI Prok Vehicle Mapping";
        Response: JsonObject;
        Mixer: JsonObject;
    begin
        Mapping.Get(ConnectionCode, VehicleNo);
        Mapping.TestField("External Mixer ID");
        if IsNullGuid(Mapping."External Mixer UUID") then
            Error('Мапінг не містить Proktek Mixer UUID.');
        Connection.Get(ConnectionCode);
        GetMixers(Connection, Response);
        if not FindMixer(Response, Mapping."External Mixer ID", Mapping."External Mixer UUID", Mixer) then
            Error('Proktek Mixer не знайдено. Мапінг не змінено.');
        if GetText(Mixer, 'kamyon_kod') <> VehicleNo then
            Error('Proktek Mixer Code відрізняється від BC Vehicle No. Мапінг не змінено.');
        Mapping."Last Synced At" := CurrentDateTime;
        Mapping."Sync Status" := Mapping."Sync Status"::Synced;
        Mapping."Last Error" := '';
        Mapping.Modify(true);
    end;

    local procedure GetMixers(var Connection: Record "SI Prok Connection"; var Response: JsonObject)
    var
        Auth: Codeunit "SI Prok Auth Mgt.";
        EDS: Codeunit "SI EDS Orchestrator";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        Buffer: Record "SI EDS Response Buffer" temporary;
        Request: JsonObject;
        Body: Text;
        Token: JsonToken;
    begin
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");
        Request.Add('guid', Format(Auth.GetSessionGuid(Connection), 0, 4));
        Request.Add('filter', '');
        Request.Add('perpage', 1000);
        Request.Add('page', 1);
        Request.WriteTo(Body);
        EDS.ExecuteProviderBody(Connection."EDS Service Code", 'GET-MIXERS', Connection."EDS Provider Code",
            RuntimeParam, Body, 'application/json-patch+json', 'text/plain', Buffer);
        if Buffer."Result Type" <> Buffer."Result Type"::Success then
            Error('GetMixers EDS: HTTP %1; %2', Buffer."HTTP Status Code", Buffer."Error Message");
        if not Response.ReadFrom(Buffer.GetBodyText()) then
            Error('GetMixers повернув некоректний JSON.');
        if not Response.Get('responseStatus', Token) then
            Error('GetMixers не повернув responseStatus.');
        if not Token.AsValue().AsBoolean() then
            Error('GetMixers: responseStatus=false. %1', GetText(Response, 'responseMessage'));
        // Do not silently trust a truncated first page.
        if GetInteger(Response, 'totalpages') > 1 then
            Error('GetMixers має більше однієї сторінки. Для безпечної прив’язки потрібна пагінація; операцію зупинено.');
    end;

    local procedure FindMixer(Response: JsonObject; ExternalId: Integer; ExternalUuid: Guid; var Mixer: JsonObject): Boolean
    var
        Items: JsonArray;
        Token: JsonToken;
        ItemToken: JsonToken;
        Candidate: JsonObject;
        Index: Integer;
    begin
        if not Response.Get('mixer', Token) then
            Error('GetMixers не повернув масив mixer.');
        if not Token.IsArray() then
            Error('GetMixers.mixer має неочікуваний формат.');
        Items := Token.AsArray();
        for Index := 0 to Items.Count() - 1 do begin
            Items.Get(Index, ItemToken);
            Candidate := ItemToken.AsObject();
            if (GetInteger(Candidate, 'kod') = ExternalId) and
               (GetGuid(Candidate, 'uuid') = ExternalUuid) then begin
                Mixer := Candidate;
                exit(true);
            end;
        end;
        exit(false);
    end;

    local procedure GetText(Value: JsonObject; Name: Text): Text
    var Token: JsonToken;
    begin
        if Value.Get(Name, Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull() then
                    exit(Token.AsValue().AsText());
        exit('');
    end;

    local procedure GetInteger(Value: JsonObject; Name: Text): Integer
    var Token: JsonToken;
    begin
        if Value.Get(Name, Token) then
            if Token.IsValue() then
                if not Token.AsValue().IsNull() then
                    exit(Token.AsValue().AsInteger());
        exit(0);
    end;

    local procedure GetGuid(Value: JsonObject; Name: Text): Guid
    var Result: Guid;
    begin
        if not Evaluate(Result, GetText(Value, Name)) then
            Clear(Result);
        exit(Result);
    end;

    procedure CreateMixer(ConnectionCode: Code[50]; VehicleNo: Code[20])
    var
        Connection: Record "SI Prok Connection";
        Vehicle: Record "SI Vehicle Profile";
        CapacityM3: Decimal;
        Mapping: Record "SI Prok Vehicle Mapping";
        Other: Record "SI Prok Vehicle Mapping";
        Auth: Codeunit "SI Prok Auth Mgt.";
        EDS: Codeunit "SI EDS Orchestrator";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        Buffer: Record "SI EDS Response Buffer" temporary;
        ListResponse: JsonObject;
        Response: JsonObject;
        Mixer: JsonObject;
        Request: JsonObject;
        Existing: JsonObject;
        Token: JsonToken;
        Items: JsonArray;
        EmptyHub: JsonArray;
        ItemToken: JsonToken;
        Body: Text;
        Index: Integer;
        NewId: Integer;
        NewUuid: Guid;
    begin
        Connection.Get(ConnectionCode);
        Vehicle.Get(VehicleNo);
        Vehicle.TestField("Vehicle Type Code", 'CONCRETE-MIXER');
        Vehicle.TestField("Registration No.");
        Vehicle.TestField(Description);
        CapacityM3 := ResolveDrumVolumeM3(VehicleNo);
        if Mapping.Get(ConnectionCode, VehicleNo) then
            if (Mapping."External Mixer ID" <> 0) or not IsNullGuid(Mapping."External Mixer UUID") then
                Error('ТЗ %1 уже має зовнішню прив’язку. Create заборонено.', VehicleNo);

        GetMixers(Connection, ListResponse);
        if not ListResponse.Get('mixer', Token) then
            Error('GetMixers не повернув mixer.');
        Items := Token.AsArray();
        for Index := 0 to Items.Count() - 1 do begin
            Items.Get(Index, ItemToken);
            Existing := ItemToken.AsObject();
            if GetText(Existing, 'kamyon_kod') = VehicleNo then
                Error('У Proktek вже є Mixer Code %1 (ID %2). Використайте Adopt Existing.', VehicleNo, GetInteger(Existing, 'kod'));
        end;

        // Create only. The server is expected to allocate kod and uuid.
        Mixer.Add('kod', 0);
        Mixer.Add('kamyon_kod', VehicleNo);
        Mixer.Add('aktif', not Vehicle.Blocked);
        Mixer.Add('plaka', Vehicle."Registration No.");
        Mixer.Add('kapasite', CapacityM3);
        Mixer.Add('surucu_kod', 0);
        Mixer.Add('aciklama1', Vehicle.Description);
        Mixer.Add('aciklama2', '');
        Mixer.Add('hub', EmptyHub);
        Mixer.Add('uuid', '00000000-0000-0000-0000-000000000000');
        Mixer.Add('surucu_uuid', '00000000-0000-0000-0000-000000000000');
        Request.Add('guid', Format(Auth.GetSessionGuid(Connection), 0, 4));
        Request.Add('mixer', Mixer);
        Request.WriteTo(Body);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");
        EDS.ExecuteProviderBody(Connection."EDS Service Code", 'SAVE-MIXER', Connection."EDS Provider Code",
            RuntimeParam, Body, 'application/json-patch+json', 'text/plain', Buffer);
        if Buffer."Result Type" <> Buffer."Result Type"::Success then
            Error('SaveMixer: HTTP %1; %2. Перед повтором перевірте GetMixers: сервер міг створити запис.',
                Buffer."HTTP Status Code", Buffer."Error Message");
        if not Response.ReadFrom(Buffer.GetBodyText()) then
            Error('SaveMixer повернув некоректний JSON. Перед повтором перевірте GetMixers.');
        if not Response.Get('responseStatus', Token) then
            Error('SaveMixer не повернув responseStatus. Перед повтором перевірте GetMixers.');
        if not Token.AsValue().AsBoolean() then
            Error('SaveMixer: %1', GetText(Response, 'responseMessage'));
        if not Response.Get('mixer', Token) then
            Error('SaveMixer не повернув mixer. Перед повтором перевірте GetMixers.');
        Existing := Token.AsObject();
        NewId := GetInteger(Existing, 'kod');
        NewUuid := GetGuid(Existing, 'uuid');
        if (NewId <= 0) or IsNullGuid(NewUuid) or (GetText(Existing, 'kamyon_kod') <> VehicleNo) then
            Error('SaveMixer повернув неочікувану ідентичність. Перевірте Proktek вручну перед повтором.');

        Other.SetRange("Connection Code", ConnectionCode);
        Other.SetRange("External Mixer ID", NewId);
        if Other.FindFirst() then
            if Other."Vehicle No." <> VehicleNo then
                Error('Mixer ID %1 уже прив’язаний до %2.', NewId, Other."Vehicle No.");
        Other.Reset();
        Other.SetRange("Connection Code", ConnectionCode);
        Other.SetRange("External Mixer UUID", NewUuid);
        if Other.FindFirst() then
            if Other."Vehicle No." <> VehicleNo then
                Error('Mixer UUID уже прив’язаний до %1.', Other."Vehicle No.");

        if not Mapping.Get(ConnectionCode, VehicleNo) then begin
            Mapping.Init();
            Mapping."Connection Code" := ConnectionCode;
            Mapping."Vehicle No." := VehicleNo;
            Mapping.Insert(true);
        end;
        Mapping."External Mixer Code" := CopyStr(VehicleNo, 1, MaxStrLen(Mapping."External Mixer Code"));
        Mapping."External Mixer ID" := NewId;
        Mapping."External Mixer UUID" := NewUuid;
        Mapping."Sync Status" := Mapping."Sync Status"::Synced;
        Mapping."Last Synced At" := CurrentDateTime;
        Mapping."Last Error" := '';
        Mapping.Modify(true);
    end;

    // PF-01.3A.4: controlled update of BC-owned fields only.
    // Returns false if the remote record already matches BC; no SaveMixer call in that case.
    procedure UpdateMixer(ConnectionCode: Code[50]; VehicleNo: Code[20]): Boolean
    var
        Connection: Record "SI Prok Connection";
        Vehicle: Record "SI Vehicle Profile";
        CapacityM3: Decimal;
        Mapping: Record "SI Prok Vehicle Mapping";
        Auth: Codeunit "SI Prok Auth Mgt.";
        EDS: Codeunit "SI EDS Orchestrator";
        RuntimeParam: Record "SI EDS Runtime Param" temporary;
        Buffer: Record "SI EDS Response Buffer" temporary;
        ListResponse: JsonObject;
        Mixer: JsonObject;
        Request: JsonObject;
        Response: JsonObject;
        Returned: JsonObject;
        Token: JsonToken;
        Body: Text;
        OldCode: Text;
        OldPlate: Text;
        OldDescription: Text;
        OldCapacity: Decimal;
        OldActive: Boolean;
    begin
        Mapping.Get(ConnectionCode, VehicleNo);
        Mapping.TestField("External Mixer ID");
        if IsNullGuid(Mapping."External Mixer UUID") then
            Error('Відсутній Mixer UUID. Спочатку виконайте Adopt Existing.');
        if Mapping."External Mixer Code" <> VehicleNo then
            Error('Код у мапінгу не відповідає Vehicle No. Update заблоковано.');

        Connection.Get(ConnectionCode);
        Vehicle.Get(VehicleNo);
        Vehicle.TestField("Vehicle Type Code", 'CONCRETE-MIXER');
        Vehicle.TestField("Registration No.");
        Vehicle.TestField(Description);
        CapacityM3 := ResolveDrumVolumeM3(VehicleNo);

        GetMixers(Connection, ListResponse);
        if not FindMixer(ListResponse, Mapping."External Mixer ID", Mapping."External Mixer UUID", Mixer) then
            Error('Міксер ID %1 / UUID %2 не знайдено. Update заборонено.',
                Mapping."External Mixer ID", Mapping."External Mixer UUID");
        OldCode := GetText(Mixer, 'kamyon_kod');
        if OldCode <> VehicleNo then
            Error('Mixer Code (%1) не відповідає Vehicle No. (%2).', OldCode, VehicleNo);
        if not Mixer.Contains('hub') or not Mixer.Contains('surucu_kod') or
           not Mixer.Contains('surucu_uuid') or not Mixer.Contains('aciklama2') then
            Error('GetMixers не повернув усі сторонні поля. Безпечний merge неможливий.');

        OldPlate := GetText(Mixer, 'plaka');
        OldDescription := GetText(Mixer, 'aciklama1');
        if not Mixer.Get('kapasite', Token) then
            Error('GetMixers не повернув kapasite.');
        OldCapacity := Token.AsValue().AsDecimal();
        if not Mixer.Get('aktif', Token) then
            Error('GetMixers не повернув aktif.');
        OldActive := Token.AsValue().AsBoolean();

        if (OldPlate = Vehicle."Registration No.") and
           (OldDescription = Vehicle.Description) and
           (OldCapacity = CapacityM3) and
           (OldActive = not Vehicle.Blocked) then begin
            Mapping."Sync Status" := Mapping."Sync Status"::Synced;
            Mapping."Last Synced At" := CurrentDateTime;
            Mapping."Last Error" := '';
            Mapping.Modify(true);
            exit(false);
        end;

        if not Confirm(
            'Оновити міксер %1 (ID %2)?\Поточні дані Proktek: %3 / %4 / %5 м3 / Active=%6\Дані BC: %7 / %8 / %9 м3 / Active=%10',
            false, VehicleNo, Mapping."External Mixer ID", OldPlate, OldDescription,
            OldCapacity, OldActive, Vehicle."Registration No.", Vehicle.Description,
            CapacityM3, not Vehicle.Blocked) then
            exit(false);

        // Merge into the object returned by GetMixers. Preserve driver, hub,
        // timestamps, aciklama2, kod, uuid and all unknown API fields.
        Mixer.Replace('plaka', Vehicle."Registration No.");
        Mixer.Replace('kapasite', CapacityM3);
        Mixer.Replace('aciklama1', Vehicle.Description);
        Mixer.Replace('aktif', not Vehicle.Blocked);
        Request.Add('guid', Format(Auth.GetSessionGuid(Connection), 0, 4));
        Request.Add('mixer', Mixer);
        Request.WriteTo(Body);
        Connection.TestField("EDS Service Code");
        Connection.TestField("EDS Provider Code");
        EDS.ExecuteProviderBody(Connection."EDS Service Code", 'SAVE-MIXER', Connection."EDS Provider Code",
            RuntimeParam, Body, 'application/json-patch+json', 'text/plain', Buffer);
        if Buffer."Result Type" <> Buffer."Result Type"::Success then
            Error('SaveMixer Update: HTTP %1; %2. Перед повтором перевірте Proktek.',
                Buffer."HTTP Status Code", Buffer."Error Message");
        if not Response.ReadFrom(Buffer.GetBodyText()) then
            Error('SaveMixer Update повернув некоректний JSON. Перевірте Proktek.');
        if not Response.Get('responseStatus', Token) then
            Error('SaveMixer Update не повернув responseStatus.');
        if not Token.AsValue().AsBoolean() then
            Error('SaveMixer Update: %1', GetText(Response, 'responseMessage'));
        if not Response.Get('mixer', Token) then
            Error('SaveMixer Update не повернув mixer. Перевірте Proktek.');
        Returned := Token.AsObject();
        if (GetInteger(Returned, 'kod') <> Mapping."External Mixer ID") or
           (GetGuid(Returned, 'uuid') <> Mapping."External Mixer UUID") or
           (GetText(Returned, 'kamyon_kod') <> VehicleNo) then
            Error('SaveMixer Update змінив або повернув неочікувану ідентичність. Перевірте Proktek вручну.');
        if (GetText(Returned, 'plaka') <> Vehicle."Registration No.") or
           (GetText(Returned, 'aciklama1') <> Vehicle.Description) then
            Error('SaveMixer Update повернув відмінні значення. Перевірте Proktek вручну.');
        if not Returned.Get('kapasite', Token) then
            Error('SaveMixer Update не повернув kapasite.');
        if Token.AsValue().AsDecimal() <> CapacityM3 then
            Error('SaveMixer Update повернув іншу місткість.');
        if not Returned.Get('aktif', Token) then
            Error('SaveMixer Update не повернув aktif.');
        if Token.AsValue().AsBoolean() <> (not Vehicle.Blocked) then
            Error('SaveMixer Update повернув інший статус Active.');

        Mapping."Sync Status" := Mapping."Sync Status"::Synced;
        Mapping."Last Synced At" := CurrentDateTime;
        Mapping."Last Error" := '';
        Mapping.Modify(true);
        exit(true);
    end;


    // PF-01.3A.5: resolve model-level characteristic via Vehicle Management.
    local procedure ResolveDrumVolumeM3(VehicleNo: Code[20]): Decimal
    var
        VehicleMgt: Codeunit "SI Vehicle Management";
        Quantity: Decimal;
        UoMCode: Code[10];
    begin
        if not VehicleMgt.GetCharacteristicValue(VehicleNo, 'DRUM-VOLUME', Quantity, UoMCode) then
            Error('Для ТЗ %1 не задано DRUM-VOLUME у характеристиках моделі.', VehicleNo);
        if UoMCode <> 'M3' then
            Error('Для ТЗ %1 одиниця DRUM-VOLUME = %2; очікується M3. Синхронізацію зупинено.', VehicleNo, UoMCode);
        if Quantity <= 0 then
            Error('DRUM-VOLUME для ТЗ %1 має бути більше нуля.', VehicleNo);
        exit(Quantity);
    end;
}
