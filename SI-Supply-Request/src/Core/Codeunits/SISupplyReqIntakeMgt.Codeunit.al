codeunit 61002 "SI Supply Request Intake Mgt."
{
    procedure AcceptExternalApprovedRequest(Intake: JsonObject; var Header: Record "SI Supply Req Header")
    var
        ExternalSystemCode: Code[20];
        ExternalDocumentId: Text[100];
        ProjectNo: Code[20];
        RequiredOnSiteAt: DateTime;
        Lines: JsonArray;
        ConcreteSpec: JsonObject;
    begin
        ExternalSystemCode := CopyStr(GetRequiredText(Intake, 'externalSystem'), 1, MaxStrLen(ExternalSystemCode));
        ExternalDocumentId := CopyStr(GetRequiredText(Intake, 'externalDocumentId'), 1, MaxStrLen(ExternalDocumentId));

        if FindExistingExternalRequest(ExternalSystemCode, ExternalDocumentId, Header) then
            exit;

        ProjectNo := CopyStr(GetRequiredText(Intake, 'projectNo'), 1, MaxStrLen(ProjectNo));
        RequiredOnSiteAt := GetRequiredDateTime(Intake, 'requiredOnSiteAt');

        Header.Init();
        Header."Request Profile" := Header."Request Profile"::Concrete;
        Header."Source Type" := Header."Source Type"::External;
        Header."External System Code" := ExternalSystemCode;
        Header."External Document ID" := ExternalDocumentId;
        Header."External Document No." := CopyStr(GetOptionalText(Intake, 'externalDocumentNo'), 1, MaxStrLen(Header."External Document No."));
        Header."External Registered At" := GetOptionalDateTime(Intake, 'externalRegisteredAt');
        Header.Validate("Project No.", ProjectNo);
        Header.Validate("Required on Site At", RequiredOnSiteAt);
        Header.Description := CopyStr(GetOptionalText(Intake, 'description'), 1, MaxStrLen(Header.Description));
        Header.Insert(true);

        Lines := GetRequiredArray(Intake, 'lines');
        CreateLines(Header, Lines);

        if TryGetObject(Intake, 'concreteSupplySpec', ConcreteSpec) then
            CreateConcreteSpec(Header, ConcreteSpec);

        Header.Status := Header.Status::Approved;
        Header.Modify(true);
    end;

    procedure FindExistingExternalRequest(ExternalSystemCode: Code[20]; ExternalDocumentId: Text[100]; var Header: Record "SI Supply Req Header"): Boolean
    begin
        Header.Reset();
        Header.SetRange("External System Code", ExternalSystemCode);
        Header.SetRange("External Document ID", ExternalDocumentId);
        exit(Header.FindFirst());
    end;

    local procedure CreateLines(Header: Record "SI Supply Req Header"; Lines: JsonArray)
    var
        Line: Record "SI Supply Req Line";
        LineToken: JsonToken;
        LineObject: JsonObject;
        Parameters: JsonArray;
        ItemNo: Code[20];
        VariantCode: Code[10];
        ProductCode: Text;
        LineNo: Integer;
        I: Integer;
    begin
        if Lines.Count() = 0 then
            Error('Canonical intake must contain at least one line.');

        LineNo := 10000;
        for I := 0 to Lines.Count() - 1 do begin
            Lines.Get(I, LineToken);
            LineObject := LineToken.AsObject();

            ItemNo := CopyStr(GetOptionalText(LineObject, 'itemNo'), 1, MaxStrLen(ItemNo));
            VariantCode := CopyStr(GetOptionalText(LineObject, 'variantCode'), 1, MaxStrLen(VariantCode));
            ProductCode := GetOptionalText(LineObject, 'productCode');

            if ItemNo = '' then begin
                if ProductCode = '' then
                    Error('Line %1 must contain itemNo or productCode.', I + 1);
                OnResolveProduct(ProductCode, LineObject, ItemNo, VariantCode);
                if ItemNo = '' then
                    Error('Product %1 could not be resolved to a Business Central item.', ProductCode);
            end;

            Line.Init();
            Line."Request No." := Header."No.";
            Line."Line No." := LineNo;
            Line."Line Type" := Line."Line Type"::Item;
            Line.Insert(true);
            Line.Validate("Item No.", ItemNo);
            if VariantCode <> '' then
                Line.Validate("Variant Code", VariantCode);
            Line.Validate("Requested Quantity", GetRequiredDecimal(LineObject, 'quantity'));
            if GetOptionalText(LineObject, 'uomCode') <> '' then
                Line.Validate("Unit of Measure Code", CopyStr(GetOptionalText(LineObject, 'uomCode'), 1, MaxStrLen(Line."Unit of Measure Code")));
            if GetOptionalText(LineObject, 'description') <> '' then
                Line.Description := CopyStr(GetOptionalText(LineObject, 'description'), 1, MaxStrLen(Line.Description));
            Line.Modify(true);

            if TryGetArray(LineObject, 'parameters', Parameters) then
                CreateParameters(Header, Line, Parameters);

            LineNo += 10000;
        end;
    end;

    local procedure CreateParameters(Header: Record "SI Supply Req Header"; Line: Record "SI Supply Req Line"; Parameters: JsonArray)
    var
        Parameter: Record "SI Supply Req Parameter";
        ParameterToken: JsonToken;
        ParameterObject: JsonObject;
        ValueType: Text;
        I: Integer;
    begin
        for I := 0 to Parameters.Count() - 1 do begin
            Parameters.Get(I, ParameterToken);
            ParameterObject := ParameterToken.AsObject();

            Parameter.Init();
            Parameter."Request No." := Header."No.";
            Parameter."Request Line No." := Line."Line No.";
            Parameter."Parameter Code" := CopyStr(GetRequiredText(ParameterObject, 'parameterCode'), 1, MaxStrLen(Parameter."Parameter Code"));
            Parameter.Source := Parameter.Source::External;
            ValueType := LowerCase(GetRequiredText(ParameterObject, 'valueType'));

            case ValueType of
                'code':
                    begin
                        Parameter."Value Type" := Parameter."Value Type"::Code;
                        Parameter."Requested Code Value" := CopyStr(GetRequiredText(ParameterObject, 'value'), 1, MaxStrLen(Parameter."Requested Code Value"));
                    end;
                'decimal':
                    begin
                        Parameter."Value Type" := Parameter."Value Type"::Decimal;
                        Parameter."Requested Decimal Value" := GetRequiredDecimal(ParameterObject, 'value');
                    end;
                'text':
                    begin
                        Parameter."Value Type" := Parameter."Value Type"::Text;
                        Parameter."Requested Text Value" := CopyStr(GetRequiredText(ParameterObject, 'value'), 1, MaxStrLen(Parameter."Requested Text Value"));
                    end;
                'boolean':
                    begin
                        Parameter."Value Type" := Parameter."Value Type"::Boolean;
                        Parameter."Requested Bool Value" := GetRequiredBoolean(ParameterObject, 'value');
                    end;
                'date':
                    begin
                        Parameter."Value Type" := Parameter."Value Type"::Date;
                        Parameter."Requested Date Value" := GetRequiredDate(ParameterObject, 'value');
                    end;
                'datetime':
                    begin
                        Parameter."Value Type" := Parameter."Value Type"::DateTime;
                        Parameter."Requested DateTime Value" := GetRequiredDateTime(ParameterObject, 'value');
                    end;
                else
                    Error('Unsupported parameter valueType %1 for parameter %2.', ValueType, Parameter."Parameter Code");
            end;

            Parameter."Unit of Measure Code" := CopyStr(GetOptionalText(ParameterObject, 'uomCode'), 1, MaxStrLen(Parameter."Unit of Measure Code"));
            Parameter.Insert(true);
        end;
    end;

    local procedure CreateConcreteSpec(Header: Record "SI Supply Req Header"; SpecObject: JsonObject)
    var
        Spec: Record "SI Concrete Supply Spec";
        UnloadingMethod: Text;
        PumpType: Text;
    begin
        Spec.Init();
        Spec."Request No." := Header."No.";
        Spec."Truck Interval Minutes" := GetOptionalInteger(SpecObject, 'truckIntervalMinutes');
        Spec."Delivery Address" := CopyStr(GetOptionalText(SpecObject, 'deliveryAddress'), 1, MaxStrLen(Spec."Delivery Address"));
        Spec."Entry Restrictions" := CopyStr(GetOptionalText(SpecObject, 'entryRestrictions'), 1, MaxStrLen(Spec."Entry Restrictions"));
        Spec."Access Road Conditions" := CopyStr(GetOptionalText(SpecObject, 'accessRoadConditions'), 1, MaxStrLen(Spec."Access Road Conditions"));
        Spec."Concrete Pump Required" := GetOptionalBoolean(SpecObject, 'concretePumpRequired');
        Spec."Pump Boom Length" := GetOptionalDecimal(SpecObject, 'pumpBoomLength');
        Spec."Additional Chute Required" := GetOptionalBoolean(SpecObject, 'additionalChuteRequired');
        Spec."Discharge Pipe Required" := GetOptionalBoolean(SpecObject, 'dischargePipeRequired');
        Spec."Contact Name" := CopyStr(GetOptionalText(SpecObject, 'contactName'), 1, MaxStrLen(Spec."Contact Name"));
        Spec."Contact Phone" := CopyStr(GetOptionalText(SpecObject, 'contactPhone'), 1, MaxStrLen(Spec."Contact Phone"));
        Spec."Contact E-Mail" := CopyStr(GetOptionalText(SpecObject, 'contactEmail'), 1, MaxStrLen(Spec."Contact E-Mail"));
        Spec."Special Instructions" := CopyStr(GetOptionalText(SpecObject, 'specialInstructions'), 1, MaxStrLen(Spec."Special Instructions"));

        UnloadingMethod := LowerCase(GetOptionalText(SpecObject, 'unloadingMethod'));
        case UnloadingMethod of
            '', 'none':;
            'selfdischarge': Spec."Unloading Method" := Spec."Unloading Method"::"Self Discharge";
            'concretepump': Spec."Unloading Method" := Spec."Unloading Method"::"Concrete Pump";
            'hopper': Spec."Unloading Method" := Spec."Unloading Method"::Hopper;
            'other': Spec."Unloading Method" := Spec."Unloading Method"::Other;
            else Error('Unsupported concrete unloadingMethod %1.', UnloadingMethod);
        end;

        PumpType := LowerCase(GetOptionalText(SpecObject, 'pumpType'));
        case PumpType of
            '', 'none':;
            'mobile': Spec."Pump Type" := Spec."Pump Type"::Mobile;
            'stationary': Spec."Pump Type" := Spec."Pump Type"::Stationary;
            else Error('Unsupported concrete pumpType %1.', PumpType);
        end;

        Spec.Insert(true);
    end;

    local procedure GetRequiredText(Object: JsonObject; JsonKey: Text): Text
    var
        Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then
            Error('Canonical intake field %1 is required.', JsonKey);
        exit(Token.AsValue().AsText());
    end;

    local procedure GetOptionalText(Object: JsonObject; JsonKey: Text): Text
    var
        Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetRequiredDecimal(Object: JsonObject; JsonKey: Text): Decimal
    var
        Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then
            Error('Canonical intake field %1 is required.', JsonKey);
        exit(Token.AsValue().AsDecimal());
    end;

    local procedure GetOptionalDecimal(Object: JsonObject; JsonKey: Text): Decimal
    var
        Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then
            exit(0);
        exit(Token.AsValue().AsDecimal());
    end;

    local procedure GetOptionalInteger(Object: JsonObject; JsonKey: Text): Integer
    var
        Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then
            exit(0);
        exit(Token.AsValue().AsInteger());
    end;

    local procedure GetRequiredBoolean(Object: JsonObject; JsonKey: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then
            Error('Canonical intake field %1 is required.', JsonKey);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure GetOptionalBoolean(Object: JsonObject; JsonKey: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then
            exit(false);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure GetRequiredDate(Object: JsonObject; JsonKey: Text): Date
    var
        Value: Text;
        Parsed: Date;
    begin
        Value := GetRequiredText(Object, JsonKey);
        if not Evaluate(Parsed, Value, 9) then
            Error('Canonical intake field %1 contains invalid ISO date %2.', JsonKey, Value);
        exit(Parsed);
    end;

    local procedure GetRequiredDateTime(Object: JsonObject; JsonKey: Text): DateTime
    var
        Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then
            Error('Canonical intake field %1 is required.', JsonKey);
        exit(Token.AsValue().AsDateTime());
    end;

    local procedure GetOptionalDateTime(Object: JsonObject; JsonKey: Text): DateTime
    var
        Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then
            exit(0DT);
        exit(Token.AsValue().AsDateTime());
    end;

    local procedure GetRequiredArray(Object: JsonObject; JsonKey: Text): JsonArray
    var
        Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) then
            Error('Canonical intake array %1 is required.', JsonKey);
        if not Token.IsArray() then
            Error('Canonical intake field %1 must be an array.', JsonKey);
        exit(Token.AsArray());
    end;

    local procedure TryGetArray(Object: JsonObject; JsonKey: Text; var Value: JsonArray): Boolean
    var
        Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) then
            exit(false);
        if not Token.IsArray() then
            Error('Canonical intake field %1 must be an array.', JsonKey);
        Value := Token.AsArray();
        exit(true);
    end;

    local procedure TryGetObject(Object: JsonObject; JsonKey: Text; var Value: JsonObject): Boolean
    var
        Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) then
            exit(false);
        if not Token.IsObject() then
            Error('Canonical intake field %1 must be an object.', JsonKey);
        Value := Token.AsObject();
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResolveProduct(ProductCode: Text; LineObject: JsonObject; var ItemNo: Code[20]; var VariantCode: Code[10])
    begin
    end;
}
