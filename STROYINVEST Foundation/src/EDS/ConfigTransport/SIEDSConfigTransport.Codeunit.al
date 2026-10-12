codeunit 50780 "SI EDS Config Transport"
{
    // Configuration-only transport. No secrets, runtime data, or deletions.
    Access = Internal;

    procedure ExportConfiguration(): Text
    var
        Root: JsonObject;
        Groups: JsonObject;
        Output: Text;
    begin
        Root.Add('schemaVersion', '1.1');
        Root.Add('packageType', 'SI-EDS-CONFIG');
        Root.Add('sourceAppVersion', '1.0.0.77');
        Clear(Groups);
        Groups.Add('SI EDS Service', Export0());
        Groups.Add('SI EDS Operation Group', Export1());
        Groups.Add('SI EDS Operation', Export2());
        Groups.Add('SI EDS Provider', Export3());
        Groups.Add('SI EDS Endpoint', Export4());
        Groups.Add('SI EDS Credential', Export5());
        Groups.Add('SI EDS Provider Route', Export6());
        Groups.Add('SI EDS Provider Rate Limit', Export7());
        Groups.Add('SI EDS Parameter', Export8());
        Root.Add('entities', Groups);
        Root.WriteTo(Output);
        exit(Output);
    end;

    procedure AnalyzeConfiguration(Payload: Text; ApplyChanges: Boolean; var Summary: Text)
    var
        Root: JsonObject;
        Entities: JsonObject;
        Token: JsonToken;
        VersionToken: JsonToken;
        TypeToken: JsonToken;
        Created: Integer;
        Updated: Integer;
        Unchanged: Integer;
    begin
        if not Root.ReadFrom(Payload) then
            Error('Некоректний JSON.');
        if not Root.Get('schemaVersion', VersionToken) then
            Error('Немає версії схеми.');
        if VersionToken.AsValue().AsText() <> '1.1' then
            Error('Непідтримувана версія схеми.');
        if not Root.Get('packageType', TypeToken) then
            Error('Немає типу пакета.');
        if TypeToken.AsValue().AsText() <> 'SI-EDS-CONFIG' then
            Error('Це не пакет EDS.');
        if not Root.Get('entities', Token) then
            Error('Немає секції entities.');
        Entities := Token.AsObject();
        Import0(GetRequiredArray(Entities, 'SI EDS Service'), ApplyChanges, Created, Updated, Unchanged);
        Import1(GetRequiredArray(Entities, 'SI EDS Operation Group'), ApplyChanges, Created, Updated, Unchanged);
        Import2(GetRequiredArray(Entities, 'SI EDS Operation'), ApplyChanges, Created, Updated, Unchanged);
        Import3(GetRequiredArray(Entities, 'SI EDS Provider'), ApplyChanges, Created, Updated, Unchanged);
        Import4(GetRequiredArray(Entities, 'SI EDS Endpoint'), ApplyChanges, Created, Updated, Unchanged);
        Import5(GetRequiredArray(Entities, 'SI EDS Credential'), ApplyChanges, Created, Updated, Unchanged);
        Import6(GetRequiredArray(Entities, 'SI EDS Provider Route'), ApplyChanges, Created, Updated, Unchanged);
        Import7(GetRequiredArray(Entities, 'SI EDS Provider Rate Limit'), ApplyChanges, Created, Updated, Unchanged);
        Import8(GetRequiredArray(Entities, 'SI EDS Parameter'), ApplyChanges, Created, Updated, Unchanged);
        Summary := StrSubstNo('Створити: %1; оновити: %2; без змін: %3.', Created, Updated, Unchanged);
    end;

    procedure BuildPreview(Payload: Text; var Preview: Record "SI EDS Transport Preview" temporary)
    var
        SourceRoot: JsonObject;
        TargetRoot: JsonObject;
        SourceEntities: JsonObject;
        TargetEntities: JsonObject;
        Token: JsonToken;
        TargetToken: JsonToken;
        CurrentPayload: Text;
        EntityName: Text;
        Names: List of [Text];
        EntryNo: Integer;
    begin
        // Always validate with the actual importer before displaying any preview.
        if not SourceRoot.ReadFrom(Payload) then
            Error('Некоректний JSON.');
        CurrentPayload := ExportConfiguration();
        if not TargetRoot.ReadFrom(CurrentPayload) then
            Error('Не вдалося отримати поточну конфігурацію.');
        SourceRoot.Get('entities', Token);
        SourceEntities := Token.AsObject();
        TargetRoot.Get('entities', TargetToken);
        TargetEntities := TargetToken.AsObject();
        Preview.Reset();
        Preview.DeleteAll();
        Names := SourceEntities.Keys();
        foreach EntityName in Names do begin
            SourceEntities.Get(EntityName, Token);
            if not TargetEntities.Get(EntityName, TargetToken) then
                Error('Невідома сутність %1.', EntityName);
            CompareEntity(EntityName, Token.AsArray(), TargetToken.AsArray(), Preview, EntryNo);
        end;
    end;

    local procedure CompareEntity(EntityName: Text; SourceItems: JsonArray; TargetItems: JsonArray; var Preview: Record "SI EDS Transport Preview" temporary; var EntryNo: Integer)
    var
        SourceToken: JsonToken;
        TargetToken: JsonToken;
        FieldToken: JsonToken;
        ExistingFieldToken: JsonToken;
        SourceObj: JsonObject;
        TargetObj: JsonObject;
        FieldKeys: List of [Text];
        FieldKey: Text;
        RecordKey: Text;
        TargetKey: Text;
        OldValue: Text;
        NewValue: Text;
        Found: Boolean;
        I: Integer;
        J: Integer;
    begin
        for I := 0 to SourceItems.Count() - 1 do begin
            SourceItems.Get(I, SourceToken);
            SourceObj := SourceToken.AsObject();
            RecordKey := BuildRecordKey(EntityName, SourceObj);
            Found := false;
            Clear(TargetObj);
            for J := 0 to TargetItems.Count() - 1 do begin
                TargetItems.Get(J, TargetToken);
                TargetObj := TargetToken.AsObject();
                TargetKey := BuildRecordKey(EntityName, TargetObj);
                if TargetKey = RecordKey then begin
                    Found := true;
                    break;
                end;
            end;
            FieldKeys := SourceObj.Keys();
            foreach FieldKey in FieldKeys do begin
                SourceObj.Get(FieldKey, FieldToken);
                FieldToken.WriteTo(NewValue);
                OldValue := '';
                if Found then begin
                    if not TargetObj.Get(FieldKey, ExistingFieldToken) then
                        Error('Відсутнє поле %1 у поточному записі %2.', FieldKey, RecordKey);
                    ExistingFieldToken.WriteTo(OldValue);
                end;
                EntryNo += 1;
                Preview.Init();
                Preview."Entry No." := EntryNo;
                Preview."Entity Name" := CopyStr(EntityName, 1, MaxStrLen(Preview."Entity Name"));
                Preview."Record Key" := CopyStr(RecordKey, 1, MaxStrLen(Preview."Record Key"));
                Preview."Field No." := FieldKey;
                Preview."Field Caption" := CopyStr(GetFieldCaption(EntityName, FieldKey), 1, MaxStrLen(Preview."Field Caption"));
                Preview."Current Value" := CopyStr(OldValue, 1, MaxStrLen(Preview."Current Value"));
                Preview."Package Value" := CopyStr(NewValue, 1, MaxStrLen(Preview."Package Value"));
                if not Found then
                    Preview.Status := Preview.Status::Create
                else
                    if OldValue <> NewValue then
                        Preview.Status := Preview.Status::Update
                    else
                        Preview.Status := Preview.Status::Unchanged;
                Preview.Insert();
            end;
        end;
    end;

    local procedure BuildRecordKey(EntityName: Text; Obj: JsonObject): Text
    var
        Fields: Text;
        Parts: List of [Text];
        FieldKey: Text;
        Token: JsonToken;
        ValueText: Text;
        Result: Text;
    begin
        case EntityName of
            'SI EDS Service', 'SI EDS Provider': Fields := '1';
            'SI EDS Operation Group', 'SI EDS Operation', 'SI EDS Endpoint', 'SI EDS Credential', 'SI EDS Provider Rate Limit': Fields := '1,2';
            'SI EDS Provider Route': Fields := '1,2,3,4';
            'SI EDS Parameter': Fields := '1,2,3,5';
            else Error('Невідома сутність %1.', EntityName);
        end;
        Parts := Fields.Split(',');
        foreach FieldKey in Parts do begin
            if not Obj.Get(FieldKey, Token) then
                Error('Немає ключового поля %1 у %2.', FieldKey, EntityName);
            Token.WriteTo(ValueText);
            if Result <> '' then
                Result += ' / ';
            Result += ValueText;
        end;
        exit(Result);
    end;

    local procedure GetFieldCaption(EntityName: Text; FieldKey: Text): Text
    var
        RecRef: RecordRef;
        FRef: FieldRef;
        FieldNo: Integer;
    begin
        if not Evaluate(FieldNo, FieldKey) then
            exit(FieldKey);
        case EntityName of
            'SI EDS Service': RecRef.Open(Database::"SI EDS Service");
            'SI EDS Operation Group': RecRef.Open(Database::"SI EDS Operation Group");
            'SI EDS Operation': RecRef.Open(Database::"SI EDS Operation");
            'SI EDS Provider': RecRef.Open(Database::"SI EDS Provider");
            'SI EDS Endpoint': RecRef.Open(Database::"SI EDS Endpoint");
            'SI EDS Credential': RecRef.Open(Database::"SI EDS Credential");
            'SI EDS Provider Route': RecRef.Open(Database::"SI EDS Provider Route");
            'SI EDS Provider Rate Limit': RecRef.Open(Database::"SI EDS Provider Rate Limit");
            'SI EDS Parameter': RecRef.Open(Database::"SI EDS Parameter");
            else exit(FieldKey);
        end;
        FRef := RecRef.Field(FieldNo);
        exit(FRef.Caption());
    end;

    local procedure GetRequiredArray(Entities: JsonObject; Name: Text): JsonArray
    var
        Token: JsonToken;
    begin
        if not Entities.Get(Name, Token) then
            Error('У пакеті немає секції %1.', Name);
        if not Token.IsArray() then
            Error('Секція %1 має бути масивом.', Name);
        exit(Token.AsArray());
    end;

    local procedure GetTextField(Obj: JsonObject; FieldName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Obj.Get(FieldName, Token) then
            Error('Немає обов’язкового поля %1.', FieldName);
        if not Token.IsValue() then
            Error('Некоректне поле %1.', FieldName);
        exit(Token.AsValue().AsText());
    end;

    local procedure GetBooleanField(Obj: JsonObject; FieldName: Text; EntityName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not Obj.Get(FieldName, Token) then
            Error('%1: відсутнє поле %2.', EntityName, FieldName);
        if not Token.IsValue() then
            Error('%1: поле %2 має бути Boolean.', EntityName, FieldName);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure GetIntegerField(Obj: JsonObject; FieldName: Text; EntityName: Text): Integer
    var
        Token: JsonToken;
    begin
        if not Obj.Get(FieldName, Token) then
            Error('%1: відсутнє поле %2.', EntityName, FieldName);
        if not Token.IsValue() then
            Error('%1: поле %2 має бути числом.', EntityName, FieldName);
        exit(Token.AsValue().AsInteger());
    end;

    local procedure AssertSafeFixedValue(Param: Record "SI EDS Parameter")
    var
        Candidate: Text;
    begin
        if Param.Source <> Param.Source::Fixed then
            exit;
        Candidate := UpperCase(Param.Code + ' ' + Param."External Name" + ' ' + Param."Runtime Key");
        if (StrLen(Param.Value) > 100) or (StrPos(UpperCase(Param.Value), 'BEARER ') > 0) or
           (StrPos(Param.Value, '-----BEGIN') > 0) then
            Error('Параметр %1 має потенційно секретне Fixed Value. Експорт заблоковано.', Param.Code);
        if (StrPos(Candidate, 'SECRET') > 0) or (StrPos(Candidate, 'PASSWORD') > 0) or
           (StrPos(Candidate, 'TOKEN') > 0) or (StrPos(Candidate, 'APIKEY') > 0) or
           (StrPos(Candidate, 'API_KEY') > 0) or (StrPos(Candidate, 'AUTHORIZATION') > 0) or
           (StrPos(Candidate, 'CLIENT_SECRET') > 0) then
            Error('Експорт/імпорт заблоковано: потенційно секретний Fixed Value %1 / %2 / %3 / %4.',
                Param."Service Code", Param."Operation Code", Param."Provider Code", Param.Code);
    end;

    local procedure Export0(): JsonArray
    var
        R0: Record "SI EDS Service";
        Items: JsonArray;
        Obj: JsonObject;
    begin
        if R0.FindSet() then
            repeat
                Clear(Obj);
                Obj.Add('1', Format(R0.Code));
                Obj.Add('2', Format(R0.Description));
                Obj.Add('3', R0.Enabled);
                Items.Add(Obj);
            until R0.Next() = 0;
        exit(Items);
    end;

    local procedure Import0(Items: JsonArray; ApplyChanges: Boolean; var Created: Integer; var Updated: Integer; var Unchanged: Integer)
    var
        R0: Record "SI EDS Service";
        Incoming: Record "SI EDS Service";
        Item: JsonToken;
        Obj: JsonObject;
        Index: Integer;
        Exists: Boolean;
        Different: Boolean;
    begin
        for Index := 0 to Items.Count() - 1 do begin
            Items.Get(Index, Item);
            Obj := Item.AsObject();
            Incoming.Code := CopyStr(GetTextField(Obj, '1'), 1, MaxStrLen(Incoming.Code));
            Incoming.Description := CopyStr(GetTextField(Obj, '2'), 1, MaxStrLen(Incoming.Description));
            Incoming.Enabled := GetBooleanField(Obj, '3', 'SI EDS 0');
            Exists := R0.Get(Incoming.Code);
            if Exists then begin
                Different := false;
                if R0.Description <> Incoming.Description then Different := true;
                if R0.Enabled <> Incoming.Enabled then Different := true;
                if Different then begin
                    Updated += 1;
                    if ApplyChanges then begin
                        R0.Description := Incoming.Description;
                        R0.Enabled := Incoming.Enabled;
                        R0.Modify(true);
                    end;
                end else
                    Unchanged += 1;
            end else begin
                Created += 1;
                if ApplyChanges then
                    Incoming.Insert(true);
            end;
        end;
    end;

    local procedure Export1(): JsonArray
    var
        R1: Record "SI EDS Operation Group";
        Items: JsonArray;
        Obj: JsonObject;
    begin
        if R1.FindSet() then
            repeat
                Clear(Obj);
                Obj.Add('1', Format(R1."Service Code"));
                Obj.Add('2', Format(R1.Code));
                Obj.Add('3', Format(R1.Description));
                Obj.Add('4', Format(R1."Path Prefix"));
                Obj.Add('5', R1.Sequence);
                Obj.Add('6', R1.Enabled);
                Items.Add(Obj);
            until R1.Next() = 0;
        exit(Items);
    end;

    local procedure Import1(Items: JsonArray; ApplyChanges: Boolean; var Created: Integer; var Updated: Integer; var Unchanged: Integer)
    var
        R1: Record "SI EDS Operation Group";
        Incoming: Record "SI EDS Operation Group";
        Item: JsonToken;
        Obj: JsonObject;
        Index: Integer;
        Exists: Boolean;
        Different: Boolean;
    begin
        for Index := 0 to Items.Count() - 1 do begin
            Items.Get(Index, Item);
            Obj := Item.AsObject();
            Incoming."Service Code" := CopyStr(GetTextField(Obj, '1'), 1, MaxStrLen(Incoming."Service Code"));
            Incoming.Code := CopyStr(GetTextField(Obj, '2'), 1, MaxStrLen(Incoming.Code));
            Incoming.Description := CopyStr(GetTextField(Obj, '3'), 1, MaxStrLen(Incoming.Description));
            Incoming."Path Prefix" := CopyStr(GetTextField(Obj, '4'), 1, MaxStrLen(Incoming."Path Prefix"));
            Incoming.Sequence := GetIntegerField(Obj, '5', 'SI EDS 1');
            Incoming.Enabled := GetBooleanField(Obj, '6', 'SI EDS 1');
            Exists := R1.Get(Incoming."Service Code", Incoming.Code);
            if Exists then begin
                Different := false;
                if R1.Description <> Incoming.Description then Different := true;
                if R1."Path Prefix" <> Incoming."Path Prefix" then Different := true;
                if R1.Sequence <> Incoming.Sequence then Different := true;
                if R1.Enabled <> Incoming.Enabled then Different := true;
                if Different then begin
                    Updated += 1;
                    if ApplyChanges then begin
                        R1.Description := Incoming.Description;
                        R1."Path Prefix" := Incoming."Path Prefix";
                        R1.Sequence := Incoming.Sequence;
                        R1.Enabled := Incoming.Enabled;
                        R1.Modify(true);
                    end;
                end else
                    Unchanged += 1;
            end else begin
                Created += 1;
                if ApplyChanges then
                    Incoming.Insert(true);
            end;
        end;
    end;

    local procedure Export2(): JsonArray
    var
        R2: Record "SI EDS Operation";
        Items: JsonArray;
        Obj: JsonObject;
    begin
        if R2.FindSet() then
            repeat
                Clear(Obj);
                Obj.Add('1', Format(R2."Service Code"));
                Obj.Add('2', Format(R2.Code));
                Obj.Add('3', Format(R2.Description));
                Obj.Add('4', R2."HTTP Method".AsInteger());
                Obj.Add('5', Format(R2."Relative Path"));
                Obj.Add('6', R2.Enabled);
                Obj.Add('7', Format(R2."Operation Group Code"));
                Obj.Add('8', R2."Log Response Body");
                Obj.Add('9', R2."Async Retry Mode".AsInteger());
                Obj.Add('10', R2."Async Max Attempts");
                Items.Add(Obj);
            until R2.Next() = 0;
        exit(Items);
    end;

    local procedure Import2(Items: JsonArray; ApplyChanges: Boolean; var Created: Integer; var Updated: Integer; var Unchanged: Integer)
    var
        R2: Record "SI EDS Operation";
        Incoming: Record "SI EDS Operation";
        Item: JsonToken;
        Obj: JsonObject;
        Index: Integer;
        Exists: Boolean;
        Different: Boolean;
    begin
        for Index := 0 to Items.Count() - 1 do begin
            Items.Get(Index, Item);
            Obj := Item.AsObject();
            Incoming."Service Code" := CopyStr(GetTextField(Obj, '1'), 1, MaxStrLen(Incoming."Service Code"));
            Incoming.Code := CopyStr(GetTextField(Obj, '2'), 1, MaxStrLen(Incoming.Code));
            Incoming.Description := CopyStr(GetTextField(Obj, '3'), 1, MaxStrLen(Incoming.Description));
            Incoming."HTTP Method" := Enum::"SI EDS HTTP Method".FromInteger(GetIntegerField(Obj, '4', 'SI EDS 2'));
            Incoming."Relative Path" := CopyStr(GetTextField(Obj, '5'), 1, MaxStrLen(Incoming."Relative Path"));
            Incoming.Enabled := GetBooleanField(Obj, '6', 'SI EDS 2');
            Incoming."Operation Group Code" := CopyStr(GetTextField(Obj, '7'), 1, MaxStrLen(Incoming."Operation Group Code"));
            Incoming."Log Response Body" := GetBooleanField(Obj, '8', 'SI EDS 2');
            Incoming."Async Retry Mode" := Enum::"SI EDS Async Retry Mode".FromInteger(GetIntegerField(Obj, '9', 'SI EDS 2'));
            Incoming."Async Max Attempts" := GetIntegerField(Obj, '10', 'SI EDS 2');
            Exists := R2.Get(Incoming."Service Code", Incoming.Code);
            if Exists then begin
                Different := false;
                if R2.Description <> Incoming.Description then Different := true;
                if R2."HTTP Method" <> Incoming."HTTP Method" then Different := true;
                if R2."Relative Path" <> Incoming."Relative Path" then Different := true;
                if R2.Enabled <> Incoming.Enabled then Different := true;
                if R2."Operation Group Code" <> Incoming."Operation Group Code" then Different := true;
                if R2."Log Response Body" <> Incoming."Log Response Body" then Different := true;
                if R2."Async Retry Mode" <> Incoming."Async Retry Mode" then Different := true;
                if R2."Async Max Attempts" <> Incoming."Async Max Attempts" then Different := true;
                if Different then begin
                    Updated += 1;
                    if ApplyChanges then begin
                        R2.Description := Incoming.Description;
                        R2."HTTP Method" := Incoming."HTTP Method";
                        R2."Relative Path" := Incoming."Relative Path";
                        R2.Enabled := Incoming.Enabled;
                        R2."Operation Group Code" := Incoming."Operation Group Code";
                        R2."Log Response Body" := Incoming."Log Response Body";
                        R2."Async Retry Mode" := Incoming."Async Retry Mode";
                        R2."Async Max Attempts" := Incoming."Async Max Attempts";
                        R2.Modify(true);
                    end;
                end else
                    Unchanged += 1;
            end else begin
                Created += 1;
                if ApplyChanges then
                    Incoming.Insert(true);
            end;
        end;
    end;

    local procedure Export3(): JsonArray
    var
        R3: Record "SI EDS Provider";
        Items: JsonArray;
        Obj: JsonObject;
    begin
        if R3.FindSet() then
            repeat
                Clear(Obj);
                Obj.Add('1', Format(R3.Code));
                Obj.Add('2', Format(R3.Description));
                Obj.Add('3', R3.Enabled);
                Items.Add(Obj);
            until R3.Next() = 0;
        exit(Items);
    end;

    local procedure Import3(Items: JsonArray; ApplyChanges: Boolean; var Created: Integer; var Updated: Integer; var Unchanged: Integer)
    var
        R3: Record "SI EDS Provider";
        Incoming: Record "SI EDS Provider";
        Item: JsonToken;
        Obj: JsonObject;
        Index: Integer;
        Exists: Boolean;
        Different: Boolean;
    begin
        for Index := 0 to Items.Count() - 1 do begin
            Items.Get(Index, Item);
            Obj := Item.AsObject();
            Incoming.Code := CopyStr(GetTextField(Obj, '1'), 1, MaxStrLen(Incoming.Code));
            Incoming.Description := CopyStr(GetTextField(Obj, '2'), 1, MaxStrLen(Incoming.Description));
            Incoming.Enabled := GetBooleanField(Obj, '3', 'SI EDS 3');
            Exists := R3.Get(Incoming.Code);
            if Exists then begin
                Different := false;
                if R3.Description <> Incoming.Description then Different := true;
                if R3.Enabled <> Incoming.Enabled then Different := true;
                if Different then begin
                    Updated += 1;
                    if ApplyChanges then begin
                        R3.Description := Incoming.Description;
                        R3.Enabled := Incoming.Enabled;
                        R3.Modify(true);
                    end;
                end else
                    Unchanged += 1;
            end else begin
                Created += 1;
                if ApplyChanges then
                    Incoming.Insert(true);
            end;
        end;
    end;

    local procedure Export4(): JsonArray
    var
        R4: Record "SI EDS Endpoint";
        Items: JsonArray;
        Obj: JsonObject;
    begin
        if R4.FindSet() then
            repeat
                Clear(Obj);
                Obj.Add('1', Format(R4."Provider Code"));
                Obj.Add('2', Format(R4.Code));
                Obj.Add('3', Format(R4.Description));
                Obj.Add('4', Format(R4."Base URL"));
                Obj.Add('5', R4.Priority);
                Obj.Add('6', R4.Enabled);
                Items.Add(Obj);
            until R4.Next() = 0;
        exit(Items);
    end;

    local procedure Import4(Items: JsonArray; ApplyChanges: Boolean; var Created: Integer; var Updated: Integer; var Unchanged: Integer)
    var
        R4: Record "SI EDS Endpoint";
        Incoming: Record "SI EDS Endpoint";
        Item: JsonToken;
        Obj: JsonObject;
        Index: Integer;
        Exists: Boolean;
        Different: Boolean;
    begin
        for Index := 0 to Items.Count() - 1 do begin
            Items.Get(Index, Item);
            Obj := Item.AsObject();
            Incoming."Provider Code" := CopyStr(GetTextField(Obj, '1'), 1, MaxStrLen(Incoming."Provider Code"));
            Incoming.Code := CopyStr(GetTextField(Obj, '2'), 1, MaxStrLen(Incoming.Code));
            Incoming.Description := CopyStr(GetTextField(Obj, '3'), 1, MaxStrLen(Incoming.Description));
            Incoming."Base URL" := CopyStr(GetTextField(Obj, '4'), 1, MaxStrLen(Incoming."Base URL"));
            Incoming.Priority := GetIntegerField(Obj, '5', 'SI EDS 4');
            Incoming.Enabled := GetBooleanField(Obj, '6', 'SI EDS 4');
            Exists := R4.Get(Incoming."Provider Code", Incoming.Code);
            if Exists then begin
                Different := false;
                if R4.Description <> Incoming.Description then Different := true;
                if R4."Base URL" <> Incoming."Base URL" then Different := true;
                if R4.Priority <> Incoming.Priority then Different := true;
                if R4.Enabled <> Incoming.Enabled then Different := true;
                if Different then begin
                    Updated += 1;
                    if ApplyChanges then begin
                        R4.Description := Incoming.Description;
                        R4."Base URL" := Incoming."Base URL";
                        R4.Priority := Incoming.Priority;
                        R4.Enabled := Incoming.Enabled;
                        R4.Modify(true);
                    end;
                end else
                    Unchanged += 1;
            end else begin
                Created += 1;
                if ApplyChanges then
                    Incoming.Insert(true);
            end;
        end;
    end;

    local procedure Export5(): JsonArray
    var
        R5: Record "SI EDS Credential";
        Items: JsonArray;
        Obj: JsonObject;
    begin
        if R5.FindSet() then
            repeat
                Clear(Obj);
                Obj.Add('1', Format(R5."Provider Code"));
                Obj.Add('2', Format(R5.Code));
                Obj.Add('3', Format(R5.Description));
                Obj.Add('4', R5."Credential Type".AsInteger());
                Obj.Add('5', R5.Enabled);
                Items.Add(Obj);
            until R5.Next() = 0;
        exit(Items);
    end;

    local procedure Import5(Items: JsonArray; ApplyChanges: Boolean; var Created: Integer; var Updated: Integer; var Unchanged: Integer)
    var
        R5: Record "SI EDS Credential";
        Incoming: Record "SI EDS Credential";
        Item: JsonToken;
        Obj: JsonObject;
        Index: Integer;
        Exists: Boolean;
        Different: Boolean;
    begin
        for Index := 0 to Items.Count() - 1 do begin
            Items.Get(Index, Item);
            Obj := Item.AsObject();
            Incoming."Provider Code" := CopyStr(GetTextField(Obj, '1'), 1, MaxStrLen(Incoming."Provider Code"));
            Incoming.Code := CopyStr(GetTextField(Obj, '2'), 1, MaxStrLen(Incoming.Code));
            Incoming.Description := CopyStr(GetTextField(Obj, '3'), 1, MaxStrLen(Incoming.Description));
            Incoming."Credential Type" := Enum::"SI EDS Credential Type".FromInteger(GetIntegerField(Obj, '4', 'SI EDS 5'));
            Incoming.Enabled := GetBooleanField(Obj, '5', 'SI EDS 5');
            Exists := R5.Get(Incoming."Provider Code", Incoming.Code);
            if Exists then begin
                Different := false;
                if R5.Description <> Incoming.Description then Different := true;
                if R5."Credential Type" <> Incoming."Credential Type" then Different := true;
                if R5.Enabled <> Incoming.Enabled then Different := true;
                if Different then begin
                    Updated += 1;
                    if ApplyChanges then begin
                        R5.Description := Incoming.Description;
                        R5."Credential Type" := Incoming."Credential Type";
                        R5.Enabled := Incoming.Enabled;
                        R5.Modify(true);
                    end;
                end else
                    Unchanged += 1;
            end else begin
                Created += 1;
                if ApplyChanges then
                    Incoming.Insert(true);
            end;
        end;
    end;

    local procedure Export6(): JsonArray
    var
        R6: Record "SI EDS Provider Route";
        Items: JsonArray;
        Obj: JsonObject;
    begin
        if R6.FindSet() then
            repeat
                Clear(Obj);
                Obj.Add('1', Format(R6."Service Code"));
                Obj.Add('2', Format(R6."Operation Code"));
                Obj.Add('3', R6.Priority);
                Obj.Add('4', Format(R6."Provider Code"));
                Obj.Add('5', R6.Enabled);
                Items.Add(Obj);
            until R6.Next() = 0;
        exit(Items);
    end;

    local procedure Import6(Items: JsonArray; ApplyChanges: Boolean; var Created: Integer; var Updated: Integer; var Unchanged: Integer)
    var
        R6: Record "SI EDS Provider Route";
        Incoming: Record "SI EDS Provider Route";
        Item: JsonToken;
        Obj: JsonObject;
        Index: Integer;
        Exists: Boolean;
        Different: Boolean;
    begin
        for Index := 0 to Items.Count() - 1 do begin
            Items.Get(Index, Item);
            Obj := Item.AsObject();
            Incoming."Service Code" := CopyStr(GetTextField(Obj, '1'), 1, MaxStrLen(Incoming."Service Code"));
            Incoming."Operation Code" := CopyStr(GetTextField(Obj, '2'), 1, MaxStrLen(Incoming."Operation Code"));
            Incoming.Priority := GetIntegerField(Obj, '3', 'SI EDS 6');
            Incoming."Provider Code" := CopyStr(GetTextField(Obj, '4'), 1, MaxStrLen(Incoming."Provider Code"));
            Incoming.Enabled := GetBooleanField(Obj, '5', 'SI EDS 6');
            Exists := R6.Get(Incoming."Service Code", Incoming."Operation Code", Incoming.Priority, Incoming."Provider Code");
            if Exists then begin
                Different := false;
                if R6.Enabled <> Incoming.Enabled then Different := true;
                if Different then begin
                    Updated += 1;
                    if ApplyChanges then begin
                        R6.Enabled := Incoming.Enabled;
                        R6.Modify(true);
                    end;
                end else
                    Unchanged += 1;
            end else begin
                Created += 1;
                if ApplyChanges then
                    Incoming.Insert(true);
            end;
        end;
    end;

    local procedure Export7(): JsonArray
    var
        R7: Record "SI EDS Provider Rate Limit";
        Items: JsonArray;
        Obj: JsonObject;
    begin
        if R7.FindSet() then
            repeat
                Clear(Obj);
                Obj.Add('1', Format(R7."Provider Code"));
                Obj.Add('2', R7.Sequence);
                Obj.Add('3', R7."Window Seconds");
                Obj.Add('4', R7."Max Requests");
                Obj.Add('5', R7."Safety Margin %");
                Obj.Add('6', R7.Enabled);
                Obj.Add('7', Format(R7.Description));
                Items.Add(Obj);
            until R7.Next() = 0;
        exit(Items);
    end;

    local procedure Import7(Items: JsonArray; ApplyChanges: Boolean; var Created: Integer; var Updated: Integer; var Unchanged: Integer)
    var
        R7: Record "SI EDS Provider Rate Limit";
        Incoming: Record "SI EDS Provider Rate Limit";
        Item: JsonToken;
        Obj: JsonObject;
        Index: Integer;
        Exists: Boolean;
        Different: Boolean;
    begin
        for Index := 0 to Items.Count() - 1 do begin
            Items.Get(Index, Item);
            Obj := Item.AsObject();
            Incoming."Provider Code" := CopyStr(GetTextField(Obj, '1'), 1, MaxStrLen(Incoming."Provider Code"));
            Incoming.Sequence := GetIntegerField(Obj, '2', 'SI EDS 7');
            Incoming."Window Seconds" := GetIntegerField(Obj, '3', 'SI EDS 7');
            Incoming."Max Requests" := GetIntegerField(Obj, '4', 'SI EDS 7');
            Incoming."Safety Margin %" := GetIntegerField(Obj, '5', 'SI EDS 7');
            Incoming.Enabled := GetBooleanField(Obj, '6', 'SI EDS 7');
            Incoming.Description := CopyStr(GetTextField(Obj, '7'), 1, MaxStrLen(Incoming.Description));
            Exists := R7.Get(Incoming."Provider Code", Incoming.Sequence);
            if Exists then begin
                Different := false;
                if R7."Window Seconds" <> Incoming."Window Seconds" then Different := true;
                if R7."Max Requests" <> Incoming."Max Requests" then Different := true;
                if R7."Safety Margin %" <> Incoming."Safety Margin %" then Different := true;
                if R7.Enabled <> Incoming.Enabled then Different := true;
                if R7.Description <> Incoming.Description then Different := true;
                if Different then begin
                    Updated += 1;
                    if ApplyChanges then begin
                        R7."Window Seconds" := Incoming."Window Seconds";
                        R7."Max Requests" := Incoming."Max Requests";
                        R7."Safety Margin %" := Incoming."Safety Margin %";
                        R7.Enabled := Incoming.Enabled;
                        R7.Description := Incoming.Description;
                        R7.Modify(true);
                    end;
                end else
                    Unchanged += 1;
            end else begin
                Created += 1;
                if ApplyChanges then
                    Incoming.Insert(true);
            end;
        end;
    end;

    local procedure Export8(): JsonArray
    var
        R8: Record "SI EDS Parameter";
        Items: JsonArray;
        Obj: JsonObject;
    begin
        if R8.FindSet() then
            repeat
                AssertSafeFixedValue(R8);
                Clear(Obj);
                Obj.Add('1', Format(R8."Service Code"));
                Obj.Add('2', Format(R8."Operation Code"));
                Obj.Add('3', Format(R8."Provider Code"));
                Obj.Add('4', R8.Sequence);
                Obj.Add('5', Format(R8.Code));
                Obj.Add('6', R8.Location.AsInteger());
                Obj.Add('7', R8.Source.AsInteger());
                Obj.Add('8', R8.Format.AsInteger());
                Obj.Add('9', Format(R8."Runtime Key"));
                Obj.Add('10', Format(R8.Value));
                Obj.Add('11', R8.Required);
                Obj.Add('12', R8.Enabled);
                Obj.Add('13', Format(R8."External Name"));
                Obj.Add('14', Format(R8."Credential Code"));
                Obj.Add('15', Format(R8."Value Prefix"));
                Items.Add(Obj);
            until R8.Next() = 0;
        exit(Items);
    end;

    local procedure Import8(Items: JsonArray; ApplyChanges: Boolean; var Created: Integer; var Updated: Integer; var Unchanged: Integer)
    var
        R8: Record "SI EDS Parameter";
        Incoming: Record "SI EDS Parameter";
        Item: JsonToken;
        Obj: JsonObject;
        Index: Integer;
        Exists: Boolean;
        Different: Boolean;
    begin
        for Index := 0 to Items.Count() - 1 do begin
            Items.Get(Index, Item);
            Obj := Item.AsObject();
            Incoming."Service Code" := CopyStr(GetTextField(Obj, '1'), 1, MaxStrLen(Incoming."Service Code"));
            Incoming."Operation Code" := CopyStr(GetTextField(Obj, '2'), 1, MaxStrLen(Incoming."Operation Code"));
            Incoming."Provider Code" := CopyStr(GetTextField(Obj, '3'), 1, MaxStrLen(Incoming."Provider Code"));
            Incoming.Sequence := GetIntegerField(Obj, '4', 'SI EDS 8');
            Incoming.Code := CopyStr(GetTextField(Obj, '5'), 1, MaxStrLen(Incoming.Code));
            Incoming.Location := Enum::"SI EDS Param. Location".FromInteger(GetIntegerField(Obj, '6', 'SI EDS 8'));
            Incoming.Source := Enum::"SI EDS Param. Source".FromInteger(GetIntegerField(Obj, '7', 'SI EDS 8'));
            Incoming.Format := Enum::"SI EDS Param. Format".FromInteger(GetIntegerField(Obj, '8', 'SI EDS 8'));
            Incoming."Runtime Key" := CopyStr(GetTextField(Obj, '9'), 1, MaxStrLen(Incoming."Runtime Key"));
            Incoming.Value := CopyStr(GetTextField(Obj, '10'), 1, MaxStrLen(Incoming.Value));
            Incoming.Required := GetBooleanField(Obj, '11', 'SI EDS 8');
            Incoming.Enabled := GetBooleanField(Obj, '12', 'SI EDS 8');
            Incoming."External Name" := CopyStr(GetTextField(Obj, '13'), 1, MaxStrLen(Incoming."External Name"));
            Incoming."Credential Code" := CopyStr(GetTextField(Obj, '14'), 1, MaxStrLen(Incoming."Credential Code"));
            Incoming."Value Prefix" := CopyStr(GetTextField(Obj, '15'), 1, MaxStrLen(Incoming."Value Prefix"));
            AssertSafeFixedValue(Incoming);
            Exists := R8.Get(Incoming."Service Code", Incoming."Operation Code", Incoming."Provider Code", Incoming.Code);
            if Exists then begin
                Different := false;
                if R8.Sequence <> Incoming.Sequence then Different := true;
                if R8.Location <> Incoming.Location then Different := true;
                if R8.Source <> Incoming.Source then Different := true;
                if R8.Format <> Incoming.Format then Different := true;
                if R8."Runtime Key" <> Incoming."Runtime Key" then Different := true;
                if R8.Value <> Incoming.Value then Different := true;
                if R8.Required <> Incoming.Required then Different := true;
                if R8.Enabled <> Incoming.Enabled then Different := true;
                if R8."External Name" <> Incoming."External Name" then Different := true;
                if R8."Credential Code" <> Incoming."Credential Code" then Different := true;
                if R8."Value Prefix" <> Incoming."Value Prefix" then Different := true;
                if Different then begin
                    Updated += 1;
                    if ApplyChanges then begin
                        R8.Sequence := Incoming.Sequence;
                        R8.Location := Incoming.Location;
                        R8.Source := Incoming.Source;
                        R8.Format := Incoming.Format;
                        R8."Runtime Key" := Incoming."Runtime Key";
                        R8.Value := Incoming.Value;
                        R8.Required := Incoming.Required;
                        R8.Enabled := Incoming.Enabled;
                        R8."External Name" := Incoming."External Name";
                        R8."Credential Code" := Incoming."Credential Code";
                        R8."Value Prefix" := Incoming."Value Prefix";
                        R8.Modify(true);
                    end;
                end else
                    Unchanged += 1;
            end else begin
                Created += 1;
                if ApplyChanges then
                    Incoming.Insert(true);
            end;
        end;
    end;
}
