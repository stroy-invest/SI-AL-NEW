codeunit 50442 "SI NBU Bank Resolver"
{
    procedure ApplyDirectoryResponse(
        var ResponseBuffer: Record "SI EDS Response Buffer" temporary;
        SyncRunId: Guid;
        SyncAt: DateTime;
        var InsertedCount: Integer;
        var UpdatedCount: Integer)
    var
        BodyInStream: InStream;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        i: Integer;
    begin
        InsertedCount := 0;
        UpdatedCount := 0;

        if not ResponseBuffer.GetBodyInStream(BodyInStream) then
            Error('НБУ повернув порожню відповідь.');

        if not JsonArray.ReadFrom(BodyInStream) then
            Error('Не вдалося розібрати JSON-відповідь НБУ.');

        for i := 0 to JsonArray.Count() - 1 do begin
            JsonArray.Get(i, JsonToken);

            if not JsonToken.IsObject() then
                Error(
                    'Некоректний формат відповіді НБУ: елемент %1 не є JSON object.',
                    i + 1);

            JsonObject := JsonToken.AsObject();

            ApplyBank(
                JsonObject,
                SyncRunId,
                SyncAt,
                InsertedCount,
                UpdatedCount);
        end;
    end;

    procedure DeactivateMissing(SyncRunId: Guid): Integer
    var
        Bank: Record "SI Bank Directory";
        DeactivatedCount: Integer;
    begin
        if Bank.FindSet(true) then
            repeat
                if Bank."Last Sync Run ID" <> SyncRunId then
                    if Bank.Active then begin
                        Bank.Active := false;
                        Bank.Modify();
                        DeactivatedCount += 1;
                    end;
            until Bank.Next() = 0;

        exit(DeactivatedCount);
    end;

    local procedure ApplyBank(
        JsonObject: JsonObject;
        SyncRunId: Guid;
        SyncAt: DateTime;
        var InsertedCount: Integer;
        var UpdatedCount: Integer)
    var
        Bank: Record "SI Bank Directory";
        NBUId: Code[20];
        IsNew: Boolean;
    begin
        NBUId :=
            CopyStr(
                GetText(JsonObject, 'IDNBU'),
                1,
                MaxStrLen(NBUId));

        if NBUId = '' then
            Error('У відповіді НБУ знайдено банк без IDNBU.');

        IsNew := not Bank.Get(NBUId);

        if IsNew then begin
            Bank.Init();
            Bank."NBU ID" := NBUId;
        end;

        Bank.MFO :=
            CopyStr(
                GetText(JsonObject, 'GLMFO'),
                1,
                MaxStrLen(Bank.MFO));

        Bank.EDRPOU :=
            CopyStr(
                GetText(JsonObject, 'KOD_EDRPOU'),
                1,
                MaxStrLen(Bank.EDRPOU));

        Bank."Short Name" :=
            CopyStr(
                GetText(JsonObject, 'SHORTNAME'),
                1,
                MaxStrLen(Bank."Short Name"));

        Bank.Name :=
            CopyStr(
                NormalizeDisplayName(Bank."Short Name"),
                1,
                MaxStrLen(Bank.Name));

        Bank."Full Name" :=
            CopyStr(
                GetText(JsonObject, 'FULLNAME'),
                1,
                MaxStrLen(Bank."Full Name"));

        Bank."English Name" :=
            CopyStr(
                GetText(JsonObject, 'NAME_E'),
                1,
                MaxStrLen(Bank."English Name"));

        Bank."English Short Name" :=
            CopyStr(
                GetText(JsonObject, 'SHORTNAME_EN'),
                1,
                MaxStrLen(Bank."English Short Name"));

        Bank.Region :=
            CopyStr(
                GetText(JsonObject, 'N_OBL'),
                1,
                MaxStrLen(Bank.Region));

        Bank.City :=
            CopyStr(
                GetText(JsonObject, 'NP'),
                1,
                MaxStrLen(Bank.City));

        Bank.Address :=
            CopyStr(
                GetText(JsonObject, 'ADRESS'),
                1,
                MaxStrLen(Bank.Address));

        Bank."Postal Code" :=
            CopyStr(
                GetText(JsonObject, 'P_IND'),
                1,
                MaxStrLen(Bank."Postal Code"));

        Bank.Phone :=
            CopyStr(
                GetText(JsonObject, 'TELEFON'),
                1,
                MaxStrLen(Bank.Phone));

        Bank.Website :=
            CopyStr(
                GetText(JsonObject, 'WEBSITE'),
                1,
                MaxStrLen(Bank.Website));

        Bank."NBU Status Code" :=
            CopyStr(
                GetText(JsonObject, 'KSTAN'),
                1,
                MaxStrLen(Bank."NBU Status Code"));

        Bank."NBU Status Name" :=
            CopyStr(
                GetText(JsonObject, 'N_STAN'),
                1,
                MaxStrLen(Bank."NBU Status Name"));

        Bank."Open Date" :=
            ParseNBUDate(
                GetText(JsonObject, 'D_OPEN'));

        Bank."Close Date" :=
            ParseNBUDate(
                GetText(JsonObject, 'D_CLOSE'));

        Bank."License No." :=
            GetInteger(JsonObject, 'NUM_LIC');

        Bank."License Granted At" :=
            ParseNBUDate(
                GetText(JsonObject, 'DT_GRAND_LIC'));

        Bank."License Status" :=
            GetInteger(JsonObject, 'PR_LIC');

        Bank."License Status Name" :=
            CopyStr(
                GetText(JsonObject, 'N_PR_LIC'),
                1,
                MaxStrLen(Bank."License Status Name"));

        Bank."License Date" :=
            ParseNBUDate(
                GetText(JsonObject, 'DT_LIC'));

        Bank.Active := ResolveActive(Bank);

        Bank."Last Sync At" := SyncAt;
        Bank."Last Sync Run ID" := SyncRunId;

        if IsNew then begin
            Bank.Insert();
            InsertedCount += 1;
        end else begin
            Bank.Modify();
            UpdatedCount += 1;
        end;
    end;

    local procedure ResolveActive(
        Bank: Record "SI Bank Directory"): Boolean
    begin
        exit(
            (Bank."Close Date" = 0D) and
            (Bank."NBU Status Code" = '1') and
            (Bank."License Status" = 1));
    end;

    local procedure NormalizeDisplayName(Value: Text): Text
    var
        Result: Text;
    begin
        Result := Value.Trim();

        Result := RemoveLegalFormPrefix(Result, 'АТ ');
        Result := RemoveLegalFormPrefix(Result, 'ПАТ ');
        Result := RemoveLegalFormPrefix(Result, 'ПрАТ ');

        Result := RemoveOuterQuotes(Result);

        exit(Result.Trim());
    end;

    local procedure RemoveLegalFormPrefix(Value: Text; Prefix: Text): Text
    begin
        if Value.StartsWith(Prefix) then
            exit(Value.Substring(StrLen(Prefix) + 1));

        exit(Value);
    end;

    local procedure RemoveOuterQuotes(Value: Text): Text
    var
        Result: Text;
    begin
        Result := Value.Trim();

        if StrLen(Result) < 2 then
            exit(Result);

        if (CopyStr(Result, 1, 1) = '"') and
           (CopyStr(Result, StrLen(Result), 1) = '"')
        then
            exit(CopyStr(Result, 2, StrLen(Result) - 2));

        exit(Result);
    end;

    local procedure GetText(
        JsonObject: JsonObject;
        PropertyName: Text): Text
    var
        JsonToken: JsonToken;
        JsonValue: JsonValue;
    begin
        if not JsonObject.Get(PropertyName, JsonToken) then
            exit('');

        if not JsonToken.IsValue() then
            exit('');

        JsonValue := JsonToken.AsValue();

        if JsonValue.IsNull() then
            exit('');

        exit(JsonValue.AsText());
    end;

    local procedure GetInteger(
        JsonObject: JsonObject;
        PropertyName: Text): Integer
    var
        ValueText: Text;
        ValueInteger: Integer;
    begin
        ValueText := GetText(JsonObject, PropertyName);

        if ValueText = '' then
            exit(0);

        if not Evaluate(ValueInteger, ValueText) then
            exit(0);

        exit(ValueInteger);
    end;

    local procedure ParseNBUDate(Value: Text): Date
    var
        DayValue: Integer;
        MonthValue: Integer;
        YearValue: Integer;
    begin
        if Value = '' then
            exit(0D);

        if StrLen(Value) < 10 then
            exit(0D);

        if not Evaluate(DayValue, CopyStr(Value, 1, 2)) then
            exit(0D);

        if not Evaluate(MonthValue, CopyStr(Value, 4, 2)) then
            exit(0D);

        if not Evaluate(YearValue, CopyStr(Value, 7, 4)) then
            exit(0D);

        exit(DMY2Date(DayValue, MonthValue, YearValue));
    end;
}
