codeunit 61021 "SI Schrift Intake Mgt."
{
    procedure SynchronizeApprovedRequests(var CreatedCount: Integer; var UpdatedCount: Integer; var UnchangedCount: Integer; var SkippedCount: Integer)
    var
        Setup: Record "SI Supply Req Setup";
        Client: Codeunit "SI Schrift Client";
        ListResponse: JsonObject;
        Documents: JsonArray;
        DocumentToken: JsonToken;
        DocumentSummary: JsonObject;
        DocumentId: Integer;
    begin
        CreatedCount := 0;
        UpdatedCount := 0;
        UnchangedCount := 0;
        SkippedCount := 0;

        GetSetup(Setup);
        Client.GetDocumentsByDocumentType(Setup."Schrift Document Type ID", ListResponse);
        Documents := ExtractDocumentsArray(ListResponse);

        foreach DocumentToken in Documents do begin
            if not DocumentToken.IsObject() then
                Error('Schrift Documents API повернув елемент, який не є JSON object.');

            DocumentSummary := DocumentToken.AsObject();
            if IsCandidateDocument(DocumentSummary, Setup."Schrift Document Type ID") then begin
                DocumentId := GetRequiredInteger(DocumentSummary, 'DocumentId');
                ProcessDocument(Setup, DocumentId, CreatedCount, UpdatedCount, UnchangedCount, SkippedCount);
            end else
                SkippedCount += 1;
        end;
    end;

    // Backward-compatible wrapper for callers from 1.0.0.7.
    procedure PullApprovedRequests(var CreatedCount: Integer; var SkippedCount: Integer)
    var
        UpdatedCount: Integer;
        UnchangedCount: Integer;
    begin
        SynchronizeApprovedRequests(CreatedCount, UpdatedCount, UnchangedCount, SkippedCount);
        SkippedCount += UpdatedCount + UnchangedCount;
    end;

    procedure SynchronizeRequest(var Header: Record "SI Supply Req Header"; var WasUpdated: Boolean; var HasConflict: Boolean)
    var
        Setup: Record "SI Supply Req Setup";
        Client: Codeunit "SI Schrift Client";
        ResponseObject: JsonObject;
        DocumentObject: JsonObject;
        DocumentId: Integer;
    begin
        Header.TestField("External System Code", 'SCHRIFT');
        Header.TestField("External Document ID");
        if not Evaluate(DocumentId, Header."External Document ID") then
            Error('Некоректний Schrift DocumentId у заявці %1: %2.', Header."No.", Header."External Document ID");

        GetSetup(Setup);
        Client.GetDocument(DocumentId, ResponseObject);
        DocumentObject := ExtractDocumentObject(ResponseObject);
        ValidateSourceDocument(Setup, DocumentObject);
        SynchronizeExistingHeader(Header, DocumentObject, WasUpdated, HasConflict);
    end;

    local procedure IsCandidateDocument(DocumentSummary: JsonObject; DocumentTypeId: Integer): Boolean
    var
        Token: JsonToken;
    begin
        if DocumentSummary.Get('TaskId', Token) then
            exit(false);
        if GetOptionalInteger(DocumentSummary, 'EntityType') <> 0 then
            exit(false);
        if GetOptionalInteger(DocumentSummary, 'DocumentTypeId') <> DocumentTypeId then
            exit(false);
        exit(true);
    end;

    local procedure ProcessDocument(Setup: Record "SI Supply Req Setup"; DocumentId: Integer; var CreatedCount: Integer; var UpdatedCount: Integer; var UnchangedCount: Integer; var SkippedCount: Integer)
    var
        Client: Codeunit "SI Schrift Client";
        ResponseObject: JsonObject;
        DocumentObject: JsonObject;
        ExistingHeader: Record "SI Supply Req Header";
        WasUpdated: Boolean;
        HasConflict: Boolean;
    begin
        Client.GetDocument(DocumentId, ResponseObject);
        DocumentObject := ExtractDocumentObject(ResponseObject);

        if not IsValidSourceDocument(Setup, DocumentObject) then begin
            SkippedCount += 1;
            exit;
        end;

        if not FindExisting(DocumentId, ExistingHeader) then begin
            CreateHeaderFromSchrift(DocumentObject);
            CreatedCount += 1;
            exit;
        end;

        SynchronizeExistingHeader(ExistingHeader, DocumentObject, WasUpdated, HasConflict);
        if WasUpdated or HasConflict then
            UpdatedCount += 1
        else
            UnchangedCount += 1;
    end;

    local procedure SynchronizeExistingHeader(var Header: Record "SI Supply Req Header"; DocumentObject: JsonObject; var WasUpdated: Boolean; var HasConflict: Boolean)
    var
        DecisionHeader: Record "SI Supply Decision Header";
        Resolver: Codeunit "SI Schrift Property Resolver";
        ResolvedProperties: JsonArray;
        DocumentNo: Text;
        DocumentName: Text;
        RegisteredAt: DateTime;
        Changed: Boolean;
    begin
        WasUpdated := false;
        HasConflict := false;
        DocumentNo := GetFirstNonEmptyText(DocumentObject, 'RegistrationFullNumber', 'DocumentFullNumber');
        DocumentName := GetOptionalText(DocumentObject, 'DocumentName');
        RegisteredAt := GetOptionalDateTime(DocumentObject, 'DocumentRegistrationDate');
        Resolver.Resolve(DocumentObject, ResolvedProperties);

        Changed :=
            (Header."External Document No." <> CopyStr(DocumentNo, 1, MaxStrLen(Header."External Document No."))) or
            (Header."External Registered At" <> RegisteredAt) or
            (Header.Description <> CopyStr(DocumentName, 1, MaxStrLen(Header.Description))) or
            BusinessDataChanged(Header, ResolvedProperties);

        Header."Last External Sync At" := CurrentDateTime();

        if not Changed then begin
            Header."External Sync Status" := Header."External Sync Status"::Synchronized;
            Header."External Sync Message" := 'Змін у бізнес-значущих полях Schrift не виявлено.';
            Header.Modify(false);
            exit;
        end;

        DecisionHeader.Reset();
        DecisionHeader.SetRange("Request No.", Header."No.");
        if DecisionHeader.FindFirst() or (Header.Status in [Header.Status::"In Fulfillment", Header.Status::"Partially Fulfilled", Header.Status::Fulfilled]) then begin
            Header."External Sync Status" := Header."External Sync Status"::Changed;
            Header."External Sync Message" := 'Документ Schrift змінено після початку обробки. Автоматичне оновлення заблоковано.';
            Header.Modify(false);
            HasConflict := true;
            exit;
        end;

        Header."External Document No." := CopyStr(DocumentNo, 1, MaxStrLen(Header."External Document No."));
        Header."External Registered At" := RegisteredAt;
        Header.Description := CopyStr(DocumentName, 1, MaxStrLen(Header.Description));
        ApplyBusinessData(Header, ResolvedProperties);
        Header."External Sync Status" := Header."External Sync Status"::Synchronized;
        Header."External Sync Message" := 'Дані та PropertyValues оновлено зі Schrift.';
        Header.Modify(false);
        WasUpdated := true;
    end;

    local procedure CreateHeaderFromSchrift(DocumentObject: JsonObject)
    var
        Header: Record "SI Supply Req Header";
        DocumentId: Integer;
        DocumentNo: Text;
        DocumentName: Text;
        RegisteredAt: DateTime;
    begin
        DocumentId := GetRequiredInteger(DocumentObject, 'DocumentId');
        DocumentNo := GetFirstNonEmptyText(DocumentObject, 'RegistrationFullNumber', 'DocumentFullNumber');
        DocumentName := GetOptionalText(DocumentObject, 'DocumentName');
        RegisteredAt := GetOptionalDateTime(DocumentObject, 'DocumentRegistrationDate');

        Header.Init();
        Header."Request Profile" := Header."Request Profile"::Concrete;
        Header."Source Type" := Header."Source Type"::External;
        Header."External System Code" := 'SCHRIFT';
        Header."Schrift Request" := true;
        Header."External Document ID" := CopyStr(Format(DocumentId), 1, MaxStrLen(Header."External Document ID"));
        Header."External Document No." := CopyStr(DocumentNo, 1, MaxStrLen(Header."External Document No."));
        Header."External Registered At" := RegisteredAt;
        Header.Description := CopyStr(DocumentName, 1, MaxStrLen(Header.Description));
        Header.Status := Header.Status::Approved;
        Header."Last External Sync At" := CurrentDateTime();
        Header."External Sync Status" := Header."External Sync Status"::Synchronized;
        Header."External Sync Message" := 'Створено зі Schrift.';
        Header.Insert(true);
        ApplyBusinessDataFromDocument(Header, DocumentObject);
    end;

    local procedure ApplyBusinessDataFromDocument(var Header: Record "SI Supply Req Header"; DocumentObject: JsonObject)
    var
        Resolver: Codeunit "SI Schrift Property Resolver";
        ResolvedProperties: JsonArray;
    begin
        Resolver.Resolve(DocumentObject, ResolvedProperties);
        ApplyBusinessData(Header, ResolvedProperties);
        Header.Modify(false);
    end;

    local procedure ApplyBusinessData(var Header: Record "SI Supply Req Header"; ResolvedProperties: JsonArray)
    var
        ProductText: Text;
        PaymentText: Text;
        Quantity: Decimal;
        RequiredAt: DateTime;
        PumpRequired: Boolean;
        SelfDischarge: Boolean;
        Hopper: Boolean;
    begin
        ProductText := FindPropertyText(ResolvedProperties, 'марка/клас бетону');
        Quantity := FindPropertyDecimal(ResolvedProperties, 'об''єм бетон');
        RequiredAt := FindPropertyDateTime(ResolvedProperties, 'дата та час поставки');
        PaymentText := FindPropertyText(ResolvedProperties, 'умови оплати');
        PumpRequired := FindPropertyBool(ResolvedProperties, 'бетононасос');
        SelfDischarge := FindPropertyBool(ResolvedProperties, 'самозлив');
        Hopper := FindPropertyBool(ResolvedProperties, 'бункер');

        if RequiredAt <> 0DT then
            Header."Required on Site At" := RequiredAt;

        UpsertConcreteLine(Header, ProductText, Quantity, RequiredAt);
        UpsertConcreteParameters(Header, ProductText);
        UpsertConcreteSpec(Header, PaymentText, PumpRequired, SelfDischarge, Hopper);
    end;

    local procedure BusinessDataChanged(Header: Record "SI Supply Req Header"; ResolvedProperties: JsonArray): Boolean
    var
        Line: Record "SI Supply Req Line";
        Spec: Record "SI Concrete Supply Spec";
        ProductText: Text;
        PaymentText: Text;
        Quantity: Decimal;
        RequiredAt: DateTime;
        PumpRequired: Boolean;
        SelfDischarge: Boolean;
        Hopper: Boolean;
        ExpectedMethod: Enum "SI Concrete Unloading Method";
    begin
        ProductText := FindPropertyText(ResolvedProperties, 'марка/клас бетону');
        Quantity := FindPropertyDecimal(ResolvedProperties, 'об''єм бетон');
        RequiredAt := FindPropertyDateTime(ResolvedProperties, 'дата та час поставки');
        PaymentText := FindPropertyText(ResolvedProperties, 'умови оплати');
        PumpRequired := FindPropertyBool(ResolvedProperties, 'бетононасос');
        SelfDischarge := FindPropertyBool(ResolvedProperties, 'самозлив');
        Hopper := FindPropertyBool(ResolvedProperties, 'бункер');

        if (RequiredAt <> 0DT) and (Header."Required on Site At" <> RequiredAt) then
            exit(true);

        if (ProductText <> '') or (Quantity <> 0) then begin
            Line.Reset();
            Line.SetRange("Request No.", Header."No.");
            if not Line.FindFirst() then
                exit(true);
            if Line."Requested Quantity" <> Quantity then
                exit(true);
            if Line."Unit of Measure Code" <> 'M3' then
                exit(true);
            if (RequiredAt <> 0DT) and (Line."Required on Site At" <> RequiredAt) then
                exit(true);

            // Once a line is resolved to Item, Schrift must never downgrade or overwrite its identity.
            if Line."Line Type" = Line."Line Type"::"Free Text" then begin
                if (ProductText <> '') and (Line.Description <> CopyStr(ProductText, 1, MaxStrLen(Line.Description))) then
                    exit(true);
                if CanResolveConcreteProduct(ProductText) then
                    exit(true);
            end;
        end;

        if (PaymentText <> '') or PumpRequired or SelfDischarge or Hopper then begin
            if not Spec.Get(Header."No.") then
                exit(true);
            if Spec."Payment Method Text" <> CopyStr(PaymentText, 1, MaxStrLen(Spec."Payment Method Text")) then
                exit(true);
            if Spec."Concrete Pump Required" <> PumpRequired then
                exit(true);
            ExpectedMethod := ExpectedUnloadingMethod(PumpRequired, SelfDischarge, Hopper);
            if Spec."Unloading Method" <> ExpectedMethod then
                exit(true);
        end;
        exit(false);
    end;

    local procedure UpsertConcreteLine(Header: Record "SI Supply Req Header"; ProductText: Text; Quantity: Decimal; RequiredAt: DateTime)
    var
        Line: Record "SI Supply Req Line";
        ProductResolver: Codeunit "SI Schrift Product Resolver";
        ResolvedItemNo: Code[20];
        ResolvedVariantCode: Code[10];
        ProductResolved: Boolean;
    begin
        if (ProductText = '') and (Quantity = 0) then
            exit;

        ProductResolved := ProductResolver.ResolveConcreteProduct(ProductText, ResolvedItemNo, ResolvedVariantCode);

        Line.Reset();
        Line.SetRange("Request No.", Header."No.");
        if not Line.FindFirst() then begin
            Line.Init();
            Line."Request No." := Header."No.";
            Line."Line No." := 10000;
            Line."Line Type" := Line."Line Type"::"Free Text";
            Line.Description := CopyStr(ProductText, 1, MaxStrLen(Line.Description));
            Line."Requested Quantity" := Quantity;
            Line."Approved Quantity" := 0;
            Line."Unit of Measure Code" := 'M3';
            Line."Required on Site At" := RequiredAt;
            Line.Insert(false);

            if ProductResolved then begin
                Line.Validate("Line Type", Line."Line Type"::Item);
                Line.Validate("Item No.", ResolvedItemNo);
                if ResolvedVariantCode <> '' then
                    Line.Validate("Variant Code", ResolvedVariantCode);
                Line."Unit of Measure Code" := 'M3';
                Line."Requested Quantity" := Quantity;
                Line."Approved Quantity" := 0;
                Line.Modify(false);
            end;
            exit;
        end;

        // Item identity is sticky: synchronization may update demand data, but never
        // overwrite Item/Variant or downgrade an already resolved Item line.
        if Line."Line Type" = Line."Line Type"::"Free Text" then begin
            if ProductResolved then begin
                Line.Validate("Line Type", Line."Line Type"::Item);
                Line.Validate("Item No.", ResolvedItemNo);
                if ResolvedVariantCode <> '' then
                    Line.Validate("Variant Code", ResolvedVariantCode);
            end else
                if ProductText <> '' then
                    Line.Description := CopyStr(ProductText, 1, MaxStrLen(Line.Description));
        end;

        Line."Requested Quantity" := Quantity;
        Line."Approved Quantity" := 0;
        Line."Unit of Measure Code" := 'M3';
        if RequiredAt <> 0DT then
            Line."Required on Site At" := RequiredAt;
        Line.Modify(false);
    end;

    local procedure CanResolveConcreteProduct(ProductText: Text): Boolean
    var
        ProductResolver: Codeunit "SI Schrift Product Resolver";
        ItemNo: Code[20];
        VariantCode: Code[10];
    begin
        exit(ProductResolver.ResolveConcreteProduct(ProductText, ItemNo, VariantCode));
    end;

    local procedure UpsertConcreteParameters(Header: Record "SI Supply Req Header"; ProductText: Text)
    begin
        UpsertTokenParameter(Header, ProductText, 'S');
        UpsertTokenParameter(Header, ProductText, 'W');
        UpsertTokenParameter(Header, ProductText, 'F');
    end;

    local procedure UpsertTokenParameter(Header: Record "SI Supply Req Header"; ProductText: Text; Prefix: Text)
    var
        Parameter: Record "SI Supply Req Parameter";
        TokenValue: Text;
    begin
        TokenValue := ExtractTokenByPrefix(ProductText, Prefix);
        if TokenValue = '' then
            exit;
        if not Parameter.Get(Header."No.", 10000, Prefix) then begin
            Parameter.Init();
            Parameter."Request No." := Header."No.";
            Parameter."Request Line No." := 10000;
            Parameter."Parameter Code" := CopyStr(Prefix, 1, MaxStrLen(Parameter."Parameter Code"));
            Parameter."Value Type" := Parameter."Value Type"::Code;
            Parameter."Requested Code Value" := CopyStr(TokenValue, 1, MaxStrLen(Parameter."Requested Code Value"));
            Parameter.Source := Parameter.Source::External;
            Parameter."Created At" := CurrentDateTime();
            Parameter."Created By User ID" := CopyStr(UserId(), 1, MaxStrLen(Parameter."Created By User ID"));
            Parameter.Insert(false);
        end else begin
            Parameter."Requested Code Value" := CopyStr(TokenValue, 1, MaxStrLen(Parameter."Requested Code Value"));
            Parameter.Source := Parameter.Source::External;
            Parameter.Modify(false);
        end;
    end;

    local procedure UpsertConcreteSpec(Header: Record "SI Supply Req Header"; PaymentText: Text; PumpRequired: Boolean; SelfDischarge: Boolean; Hopper: Boolean)
    var
        Spec: Record "SI Concrete Supply Spec";
        IsNew: Boolean;
    begin
        if not Spec.Get(Header."No.") then begin
            Spec.Init();
            Spec."Request No." := Header."No.";
            IsNew := true;
        end;
        Spec."Payment Method Text" := CopyStr(PaymentText, 1, MaxStrLen(Spec."Payment Method Text"));
        Spec."Concrete Pump Required" := PumpRequired;
        Spec."Unloading Method" := ExpectedUnloadingMethod(PumpRequired, SelfDischarge, Hopper);
        if IsNew then
            Spec.Insert(false)
        else
            Spec.Modify(false);
    end;

    local procedure ExpectedUnloadingMethod(PumpRequired: Boolean; SelfDischarge: Boolean; Hopper: Boolean): Enum "SI Concrete Unloading Method"
    var
        Method: Enum "SI Concrete Unloading Method";
    begin
        if PumpRequired then
            exit(Method::"Concrete Pump");
        if SelfDischarge then
            exit(Method::"Self Discharge");
        if Hopper then
            exit(Method::Hopper);
        exit(Method::" ");
    end;

    local procedure ExtractTokenByPrefix(ProductText: Text; Prefix: Text): Text
    var
        Parts: List of [Text];
        Part: Text;
        Normalized: Text;
    begin
        Normalized := ProductText.Replace(',', ' ');
        Parts := Normalized.Split(' ');
        foreach Part in Parts do
            if (StrLen(Part) > 1) and (UpperCase(CopyStr(Part, 1, 1)) = UpperCase(Prefix)) then
                exit(UpperCase(Part));
        exit('');
    end;

    local procedure FindPropertyText(Properties: JsonArray; NameFragment: Text): Text
    var
        Property: JsonObject;
    begin
        if FindProperty(Properties, NameFragment, Property) then
            exit(GetOptionalText(Property, 'TextValue'));
        exit('');
    end;

    local procedure FindPropertyDecimal(Properties: JsonArray; NameFragment: Text): Decimal
    var
        Property: JsonObject;
        Token: JsonToken;
        ValueText: Text;
        ValueDecimal: Decimal;
    begin
        if not FindProperty(Properties, NameFragment, Property) then
            exit(0);

        // Resolver normalizes Schrift Int/Long and Decimal values to DecimalValue.
        if Property.Get('DecimalValue', Token) then
            if not Token.AsValue().IsNull() then
                exit(Token.AsValue().AsDecimal());

        // Defensive fallback for metadata/value variations: use normalized TextValue.
        if Property.Get('TextValue', Token) then
            if not Token.AsValue().IsNull() then begin
                ValueText := Token.AsValue().AsText();
                if Evaluate(ValueDecimal, ValueText, 9) then
                    exit(ValueDecimal);
                if Evaluate(ValueDecimal, ValueText) then
                    exit(ValueDecimal);
            end;

        exit(0);
    end;

    local procedure FindPropertyDateTime(Properties: JsonArray; NameFragment: Text): DateTime
    var
        Property: JsonObject;
        Token: JsonToken;
    begin
        if not FindProperty(Properties, NameFragment, Property) then
            exit(0DT);
        if not Property.Get('DateTimeValue', Token) or Token.AsValue().IsNull() then
            exit(0DT);
        exit(Token.AsValue().AsDateTime());
    end;

    local procedure FindPropertyBool(Properties: JsonArray; NameFragment: Text): Boolean
    var
        Property: JsonObject;
        Token: JsonToken;
    begin
        if not FindProperty(Properties, NameFragment, Property) then
            exit(false);
        if not Property.Get('BoolValue', Token) or Token.AsValue().IsNull() then
            exit(false);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure FindProperty(Properties: JsonArray; NameFragment: Text; var FoundProperty: JsonObject): Boolean
    var
        Token: JsonToken;
        Property: JsonObject;
        NameText: Text;
        CodeText: Text;
        i: Integer;
    begin
        for i := 0 to Properties.Count() - 1 do begin
            Properties.Get(i, Token);
            if Token.IsObject() then begin
                Property := Token.AsObject();
                NameText := LowerCase(GetOptionalText(Property, 'PropertyName'));
                CodeText := LowerCase(GetOptionalText(Property, 'PropertyCode'));
                if (StrPos(NameText, LowerCase(NameFragment)) > 0) or (StrPos(CodeText, LowerCase(NameFragment)) > 0) then begin
                    FoundProperty := Property;
                    exit(true);
                end;
            end;
        end;
        exit(false);
    end;

    local procedure FindExisting(DocumentId: Integer; var Header: Record "SI Supply Req Header"): Boolean
    begin
        Header.Reset();
        Header.SetRange("External System Code", 'SCHRIFT');
        Header.SetRange("External Document ID", Format(DocumentId));
        exit(Header.FindFirst());
    end;

    local procedure ValidateSourceDocument(Setup: Record "SI Supply Req Setup"; DocumentObject: JsonObject)
    begin
        if GetRequiredInteger(DocumentObject, 'TemplateId') <> Setup."Schrift Template ID" then
            Error('Документ Schrift %1 має інший TemplateId.', GetRequiredInteger(DocumentObject, 'DocumentId'));
        if not GetOptionalBoolean(DocumentObject, 'DocumentIsRegistered') then
            Error('Документ Schrift %1 ще не зареєстрований.', GetRequiredInteger(DocumentObject, 'DocumentId'));
    end;

    local procedure IsValidSourceDocument(Setup: Record "SI Supply Req Setup"; DocumentObject: JsonObject): Boolean
    begin
        if GetRequiredInteger(DocumentObject, 'TemplateId') <> Setup."Schrift Template ID" then
            exit(false);
        if not GetOptionalBoolean(DocumentObject, 'DocumentIsRegistered') then
            exit(false);
        exit(true);
    end;

    local procedure ExtractDocumentsArray(ResponseObject: JsonObject): JsonArray
    var
        Token: JsonToken;
        DataObject: JsonObject;
    begin
        if ResponseObject.Get('Data', Token) then begin
            if Token.IsArray() then
                exit(Token.AsArray());
            if Token.IsObject() then begin
                DataObject := Token.AsObject();
                if DataObject.Get('Documents', Token) and Token.IsArray() then
                    exit(Token.AsArray());
                if DataObject.Get('Items', Token) and Token.IsArray() then
                    exit(Token.AsArray());
            end;
        end;
        if ResponseObject.Get('Documents', Token) and Token.IsArray() then
            exit(Token.AsArray());
        if ResponseObject.Get('Items', Token) and Token.IsArray() then
            exit(Token.AsArray());
        Error('Не вдалося знайти масив документів у відповіді Schrift Documents API.');
    end;

    local procedure ExtractDocumentObject(ResponseObject: JsonObject): JsonObject
    var Token: JsonToken;
    begin
        if ResponseObject.Get('Data', Token) then begin
            if not Token.IsObject() then
                Error('Поле Data у відповіді Schrift GetDocument не є JSON object.');
            exit(Token.AsObject());
        end;
        exit(ResponseObject);
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

    local procedure GetOptionalBoolean(Object: JsonObject; JsonKey: Text): Boolean
    var Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then exit(false);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure GetOptionalText(Object: JsonObject; JsonKey: Text): Text
    var Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetFirstNonEmptyText(Object: JsonObject; FirstKey: Text; SecondKey: Text): Text
    var Value: Text;
    begin
        Value := GetOptionalText(Object, FirstKey);
        if Value <> '' then exit(Value);
        exit(GetOptionalText(Object, SecondKey));
    end;

    local procedure GetOptionalDateTime(Object: JsonObject; JsonKey: Text): DateTime
    var Token: JsonToken;
    begin
        if not Object.Get(JsonKey, Token) or Token.AsValue().IsNull() then exit(0DT);
        exit(Token.AsValue().AsDateTime());
    end;

    local procedure GetSetup(var Setup: Record "SI Supply Req Setup")
    begin
        if not Setup.Get('') then Error('Спочатку налаштуйте заявки на забезпечення.');
        Setup.TestField("Schrift Template ID");
        Setup.TestField("Schrift Document Type ID");
    end;
}
