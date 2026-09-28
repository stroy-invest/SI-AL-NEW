codeunit 61022 "SI Schrift Property Resolver"
{
    procedure Resolve(DocumentObject: JsonObject; var ResolvedProperties: JsonArray)
    var
        Client: Codeunit "SI Schrift Client";
        PropertyValues: JsonArray;
        Definitions: JsonArray;
        PropertyIds: List of [Integer];
        Token: JsonToken;
        ValueObject: JsonObject;
        PropertyId: Integer;
        i: Integer;
    begin
        Clear(ResolvedProperties);
        if not DocumentObject.Get('PropertyValues', Token) then
            exit;
        if not Token.IsArray() then
            Error('PropertyValues у відповіді Schrift не є масивом.');
        PropertyValues := Token.AsArray();

        for i := 0 to PropertyValues.Count() - 1 do begin
            PropertyValues.Get(i, Token);
            if Token.IsObject() then begin
                ValueObject := Token.AsObject();
                PropertyId := GetRequiredInteger(ValueObject, 'PropertyId');
                if not PropertyIds.Contains(PropertyId) then
                    PropertyIds.Add(PropertyId);
            end;
        end;

        if PropertyIds.Count() = 0 then
            exit;

        Client.GetPropertyDefinitions(PropertyIds, Definitions);
        for i := 0 to PropertyValues.Count() - 1 do begin
            PropertyValues.Get(i, Token);
            if Token.IsObject() then
                ResolveOne(Token.AsObject(), Definitions, ResolvedProperties);
        end;
    end;

    local procedure ResolveOne(ValueObject: JsonObject; Definitions: JsonArray; var ResolvedProperties: JsonArray)
    var
        Definition: JsonObject;
        Resolved: JsonObject;
        PropertyId: Integer;
        ValueType: Integer;
        CustomDictionaryId: Integer;
        IntValue: Integer;
        TextValue: Text;
        DecimalValue: Decimal;
        BoolValue: Boolean;
        DateTimeValue: DateTime;
    begin
        PropertyId := GetRequiredInteger(ValueObject, 'PropertyId');
        if not FindDefinition(Definitions, PropertyId, Definition) then
            Error('Schrift не повернув metadata для PropertyId=%1.', PropertyId);

        ValueType := GetOptionalInteger(Definition, 'ValueType');
        Resolved.Add('PropertyId', PropertyId);
        Resolved.Add('PropertyName', GetOptionalText(Definition, 'PropertyName'));
        Resolved.Add('PropertyCode', GetOptionalText(Definition, 'PropertyCode'));
        Resolved.Add('ValueType', ValueType);

        case ValueType of
            1: // Text
                begin
                    TextValue := GetOptionalText(ValueObject, 'PropertyTextValue');
                    Resolved.Add('TextValue', TextValue);
                end;
            2, 7: // Int / Long
                begin
                    IntValue := GetOptionalInteger(ValueObject, 'PropertyIntValue');
                    Resolved.Add('DecimalValue', IntValue);
                    Resolved.Add('TextValue', Format(IntValue));
                end;
            3, 6: // Date / DateTime
                begin
                    DateTimeValue := GetOptionalDateTime(ValueObject, 'PropertyDateTimeValue');
                    Resolved.Add('DateTimeValue', DateTimeValue);
                    Resolved.Add('TextValue', Format(DateTimeValue, 0, 9));
                end;
            4: // Decimal
                begin
                    DecimalValue := GetOptionalDecimal(ValueObject, 'PropertyDecimalValue');
                    Resolved.Add('DecimalValue', DecimalValue);
                    Resolved.Add('TextValue', Format(DecimalValue, 0, 9));
                end;
            5: // Bool. Schrift may omit PropertyBoolValue for false.
                begin
                    BoolValue := GetOptionalBoolean(ValueObject, 'PropertyBoolValue');
                    Resolved.Add('BoolValue', BoolValue);
                    if BoolValue then
                        Resolved.Add('TextValue', 'true')
                    else
                        Resolved.Add('TextValue', 'false');
                end;
            9: // Reference
                begin
                    IntValue := GetOptionalInteger(ValueObject, 'PropertyIntValue');
                    CustomDictionaryId := GetOptionalInteger(Definition, 'ReferenceCustomDictionaryId');
                    Resolved.Add('ReferenceId', IntValue);
                    Resolved.Add('CustomDictionaryId', CustomDictionaryId);
                    if (CustomDictionaryId <> 0) and (IntValue <> 0) then
                        ResolveCustomDictionaryValue(CustomDictionaryId, IntValue, Resolved)
                    else
                        Resolved.Add('TextValue', Format(IntValue));
                end;
            else begin
                TextValue := GetFirstAvailableText(ValueObject);
                Resolved.Add('TextValue', TextValue);
            end;
        end;
        ResolvedProperties.Add(Resolved);
    end;

    local procedure ResolveCustomDictionaryValue(CustomDictionaryId: Integer; ValueId: Integer; var Resolved: JsonObject)
    var
        Client: Codeunit "SI Schrift Client";
        Values: JsonArray;
        Token: JsonToken;
        ValueObject: JsonObject;
        i: Integer;
    begin
        Client.GetCustomDictionaryValue(CustomDictionaryId, ValueId, Values);
        for i := 0 to Values.Count() - 1 do begin
            Values.Get(i, Token);
            if Token.IsObject() then begin
                ValueObject := Token.AsObject();
                if GetOptionalInteger(ValueObject, 'CustomDictionaryValueId') = ValueId then begin
                    Resolved.Add('ValueCode', GetOptionalText(ValueObject, 'CustomDictionaryValueCode'));
                    Resolved.Add('TextValue', GetOptionalText(ValueObject, 'CustomDictionaryValueName'));
                    exit;
                end;
            end;
        end;
        Resolved.Add('TextValue', Format(ValueId));
    end;

    local procedure FindDefinition(Definitions: JsonArray; PropertyId: Integer; var Definition: JsonObject): Boolean
    var
        Token: JsonToken;
        Candidate: JsonObject;
        i: Integer;
    begin
        for i := 0 to Definitions.Count() - 1 do begin
            Definitions.Get(i, Token);
            if Token.IsObject() then begin
                Candidate := Token.AsObject();
                if GetOptionalInteger(Candidate, 'PropertyId') = PropertyId then begin
                    Definition := Candidate;
                    exit(true);
                end;
            end;
        end;
        exit(false);
    end;

    local procedure GetFirstAvailableText(Object: JsonObject): Text
    var
        Value: Text;
    begin
        Value := GetOptionalText(Object, 'PropertyTextValue');
        if Value <> '' then exit(Value);
        Value := GetOptionalText(Object, 'PropertyDecimalValue');
        if Value <> '' then exit(Value);
        Value := GetOptionalText(Object, 'PropertyIntValue');
        if Value <> '' then exit(Value);
        exit('');
    end;

    local procedure GetRequiredInteger(Object: JsonObject; JsonKey: Text): Integer
    var Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then
            Error('У відповіді Schrift відсутнє обов''язкове поле %1.', JsonKey);
        exit(Token.AsValue().AsInteger());
    end;

    local procedure GetOptionalInteger(Object: JsonObject; JsonKey: Text): Integer
    var Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then exit(0);
        exit(Token.AsValue().AsInteger());
    end;

    local procedure GetOptionalText(Object: JsonObject; JsonKey: Text): Text
    var Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetOptionalDecimal(Object: JsonObject; JsonKey: Text): Decimal
    var Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then exit(0);
        exit(Token.AsValue().AsDecimal());
    end;

    local procedure GetOptionalBoolean(Object: JsonObject; JsonKey: Text): Boolean
    var Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then exit(false);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure GetOptionalDateTime(Object: JsonObject; JsonKey: Text): DateTime
    var Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then exit(0DT);
        exit(Token.AsValue().AsDateTime());
    end;
}
