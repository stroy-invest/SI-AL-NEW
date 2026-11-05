codeunit 57104 "SI Prok Fact Content Compare"
{
    procedure SameContent(Stored: Text; Incoming: Text; var Reason: Text): Boolean
    var
        LeftRoot: JsonObject;
        RightRoot: JsonObject;
        LeftToken: JsonToken;
        RightToken: JsonToken;
        StoredConfiguration: JsonArray;
        IncomingConfiguration: JsonArray;
        StoredConfigurationText: Text;
        IncomingConfigurationText: Text;
    begin
        Clear(Reason);
        if not LeftRoot.ReadFrom(Stored) or not RightRoot.ReadFrom(Incoming) then begin
            Reason := 'Неможливо порівняти збережений і новий Canonical JSON.';
            exit(false);
        end;
        if not ValidateMaterials(LeftRoot, Reason) then begin
            Reason := 'Збережений canonical: ' + Reason;
            exit(false);
        end;
        if not ValidateMaterials(RightRoot, Reason) then begin
            Reason := 'Новий canonical: ' + Reason;
            exit(false);
        end;
        // Older canonical records discarded field presence and zero-only slots.
        // Their missing evidence must never be invented during a repeat intake.
        IgnoreSimulationPresence := ReadBoolean(LeftRoot, 'simulated') and ReadBoolean(RightRoot, 'simulated');
        if not IgnoreSimulationPresence and
           (LeftRoot.Contains('quantityM3Present') <> RightRoot.Contains('quantityM3Present')) then begin
            Reason := 'Історичний canonical не містить ознак наявності даних E1.1; потрібен окремий розбір без зміни факту.';
            exit(false);
        end;
        LeftToken := LeftRoot.AsToken();
        RightToken := RightRoot.AsToken();
        if not EqualToken(LeftToken, RightToken, '') then begin
            Reason := 'Змінено виробничий зміст: показники, контекст або наявність джерельних даних. Первинний факт не змінено.';
            exit(false);
        end;
        StoredConfiguration := ConfigurationProjection(LeftRoot);
        IncomingConfiguration := ConfigurationProjection(RightRoot);
        if not EqualToken(StoredConfiguration.AsToken(), IncomingConfiguration.AsToken(), '/configuration') then begin
            StoredConfiguration.WriteTo(StoredConfigurationText);
            IncomingConfiguration.WriteTo(IncomingConfigurationText);
            Reason := StrSubstNo(
                'Material Configuration Changed. Джерело: GetMaterialsConfig; показники замісу незмінні. Прийнятий факт і mapping не оновлено. Було: %1; отримано: %2.',
                CopyStr(StoredConfigurationText, 1, 500), CopyStr(IncomingConfigurationText, 1, 500));
        end;
        exit(true);
    end;

    // These properties are observations of current Material Config, not
    // historical material identity from the production payload.
    local procedure ConfigurationProjection(Root: JsonObject): JsonArray
    var
        Token: JsonToken;
        HopperToken: JsonToken;
        Value: JsonToken;
        Hoppers: JsonArray;
        Projection: JsonArray;
        Entry: JsonObject;
        PropertyNames: List of [Text];
        PropertyName: Text;
        I: Integer;
    begin
        PropertyNames.Add('hopper');
        PropertyNames.Add('materialUuid');
        PropertyNames.Add('entCode');
        PropertyNames.Add('itemNo');
        PropertyNames.Add('variantCode');
        PropertyNames.Add('materialName');
        Root.Get('hoppers', Token);
        Hoppers := Token.AsArray();
        for I := 0 to Hoppers.Count() - 1 do begin
            Hoppers.Get(I, HopperToken);
            Clear(Entry);
            Entry.Add('projection', 'hopper');
            foreach PropertyName in PropertyNames do
                if HopperToken.AsObject().Get(PropertyName, Value) then
                    Entry.Add(PropertyName, Value);
            Projection.Add(Entry);
        end;
        Clear(PropertyNames);
        PropertyNames.Add('uuid');
        PropertyNames.Add('entCode');
        PropertyNames.Add('itemNo');
        PropertyNames.Add('variantCode');
        PropertyNames.Add('name');
        Root.Get('materials', Token);
        Hoppers := Token.AsArray();
        for I := 0 to Hoppers.Count() - 1 do begin
            Hoppers.Get(I, HopperToken);
            Clear(Entry);
            Entry.Add('projection', 'material');
            foreach PropertyName in PropertyNames do
                if HopperToken.AsObject().Get(PropertyName, Value) then
                    Entry.Add(PropertyName, Value);
            Projection.Add(Entry);
        end;
        exit(Projection);
    end;

    procedure ValidateMaterials(Root: JsonObject; var Reason: Text): Boolean
    var
        Token: JsonToken;
        RowToken: JsonToken;
        Row: JsonObject;
        Hoppers: JsonArray;
        Materials: JsonArray;
        Requested: Dictionary of [Text, Decimal];
        Adjusted: Dictionary of [Text, Decimal];
        Actual: Dictionary of [Text, Decimal];
        SeenHoppers: Dictionary of [Text, Boolean];
        SeenMaterials: Dictionary of [Text, Boolean];
        EntCode: Text;
        HopperCode: Text;
        RequestedKg: Decimal;
        AdjustedKg: Decimal;
        ActualKg: Decimal;
        Expected: Decimal;
        I: Integer;
    begin
        Clear(Reason);
        if not Root.Get('hoppers', Token) then begin
            Reason := 'Відсутня деталізація hoppers.';
            exit(false);
        end;
        if not Token.IsArray() then begin
            Reason := 'hoppers не є масивом.';
            exit(false);
        end;
        Hoppers := Token.AsArray();
        if not Root.Get('materials', Token) then begin
            Reason := 'Відсутній агрегат materials.';
            exit(false);
        end;
        if not Token.IsArray() then begin
            Reason := 'materials не є масивом.';
            exit(false);
        end;
        Materials := Token.AsArray();
        for I := 0 to Hoppers.Count() - 1 do begin
            Hoppers.Get(I, RowToken);
            if not RowToken.IsObject() then begin
                Reason := StrSubstNo('hoppers[%1] не є об’єктом.', I);
                exit(false);
            end;
            Row := RowToken.AsObject();
            HopperCode := ReadText(Row, 'hopper');
            EntCode := ReadText(Row, 'entCode');
            if (HopperCode = '') or (EntCode = '') or SeenHoppers.ContainsKey(HopperCode) then begin
                Reason := StrSubstNo('Бункер %1: відсутня ідентичність або повтор слота.', HopperCode);
                exit(false);
            end;
            SeenHoppers.Add(HopperCode, true);
            if not ReadQuantities(Row, RequestedKg, AdjustedKg, ActualKg) then begin
                Reason := StrSubstNo('Бункер %1: некоректні requestedKg/adjustedKg/actualKg.', HopperCode);
                exit(false);
            end;
            // A zero-only hopper is not a material used in this production,
            // even when it has a configured UUID / ERP code.
            // Invalid actual readings must still be validated.
            if (RequestedKg = 0) and (AdjustedKg = 0) and (ActualKg = 0) and
               not ReadBoolean(Row, 'actualKgInvalid') then
                continue;
            AddAmount(Requested, EntCode, RequestedKg);
            AddAmount(Adjusted, EntCode, AdjustedKg);
            AddAmount(Actual, EntCode, ActualKg);
        end;
        for I := 0 to Materials.Count() - 1 do begin
            Materials.Get(I, RowToken);
            if not RowToken.IsObject() then begin
                Reason := StrSubstNo('materials[%1] не є об’єктом.', I);
                exit(false);
            end;
            Row := RowToken.AsObject();
            EntCode := ReadText(Row, 'entCode');
            if (EntCode = '') or SeenMaterials.ContainsKey(EntCode) then begin
                Reason := 'Агрегат materials містить порожній або повторний entCode.';
                exit(false);
            end;
            SeenMaterials.Add(EntCode, true);
            if not MaterialMatchesHoppers(Row, Hoppers) then begin
                Reason := StrSubstNo('Матеріал %1: реквізити агрегату не відповідають жодному його hopper.', EntCode);
                exit(false);
            end;
            if not ReadQuantities(Row, RequestedKg, AdjustedKg, ActualKg) then begin
                Reason := StrSubstNo('Матеріал %1: некоректні кількості.', EntCode);
                exit(false);
            end;
            if (RequestedKg = 0) and (AdjustedKg = 0) and (ActualKg = 0) and
               not Requested.ContainsKey(EntCode) then
                continue; // Accept legacy zero-only mapped/unmapped aggregates.
            if not Requested.Get(EntCode, Expected) then begin
                Reason := StrSubstNo('Матеріал %1 не має відповідних hoppers.', EntCode);
                exit(false);
            end;
            if RequestedKg <> Expected then begin
                Reason := StrSubstNo('Матеріал %1: requestedKg=%2, сума hoppers=%3.', EntCode, RequestedKg, Expected);
                exit(false);
            end;
            Adjusted.Get(EntCode, Expected);
            if AdjustedKg <> Expected then begin
                Reason := StrSubstNo('Матеріал %1: adjustedKg=%2, сума hoppers=%3.', EntCode, AdjustedKg, Expected);
                exit(false);
            end;
            Actual.Get(EntCode, Expected);
            if ActualKg <> Expected then begin
                Reason := StrSubstNo('Матеріал %1: actualKg=%2, сума hoppers=%3.', EntCode, ActualKg, Expected);
                exit(false);
            end;
        end;
        if not AllExpectedMaterialsSeen(Requested, SeenMaterials) then begin
            Reason := 'Не всі hoppers представлені в агрегаті materials.';
            exit(false);
        end;
        exit(true);
    end;

    local procedure AllExpectedMaterialsSeen(
        ExpectedMaterials: Dictionary of [Text, Decimal];
        SeenMaterials: Dictionary of [Text, Boolean]): Boolean
    var
        EntCodes: List of [Text];
        EntCode: Text;
    begin
        EntCodes := ExpectedMaterials.Keys();
        foreach EntCode in EntCodes do
            if not SeenMaterials.ContainsKey(EntCode) then
                exit(false);
        exit(true);
    end;

    local procedure MaterialMatchesHoppers(Material: JsonObject; Hoppers: JsonArray): Boolean
    var
        HopperToken: JsonToken;
        MaterialIdentity: JsonObject;
        HopperIdentity: JsonObject;
        I: Integer;
    begin
        MaterialIdentity := ConfigurationIdentity(Material, false);
        for I := 0 to Hoppers.Count() - 1 do begin
            Hoppers.Get(I, HopperToken);
            HopperIdentity := ConfigurationIdentity(HopperToken.AsObject(), true);
            if EqualToken(MaterialIdentity.AsToken(), HopperIdentity.AsToken(), '/identity') then
                exit(true);
        end;
        exit(false);
    end;

    local procedure ConfigurationIdentity(Row: JsonObject; IsHopper: Boolean): JsonObject
    var
        Identity: JsonObject;
    begin
        Identity.Add('entCode', ReadText(Row, 'entCode'));
        Identity.Add('itemNo', ReadText(Row, 'itemNo'));
        Identity.Add('variantCode', ReadText(Row, 'variantCode'));
        if IsHopper then begin
            Identity.Add('uuid', ReadText(Row, 'materialUuid'));
            Identity.Add('name', ReadText(Row, 'materialName'));
        end else begin
            Identity.Add('uuid', ReadText(Row, 'uuid'));
            Identity.Add('name', ReadText(Row, 'name'));
        end;
        exit(Identity);
    end;

    local procedure ReadText(Root: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if Root.Get(PropertyName, Token) and Token.IsValue() then
            if not Token.AsValue().IsNull() then
                exit(Token.AsValue().AsText());
        exit('');
    end;

    local procedure ReadQuantities(Row: JsonObject; var RequestedKg: Decimal; var AdjustedKg: Decimal; var ActualKg: Decimal): Boolean
    begin
        exit(ReadDecimal(Row, 'requestedKg', RequestedKg) and
            ReadDecimal(Row, 'adjustedKg', AdjustedKg) and
            ReadDecimal(Row, 'actualKg', ActualKg));
    end;

    local procedure AddAmount(var Totals: Dictionary of [Text, Decimal]; EntCode: Text; Amount: Decimal)
    var
        Existing: Decimal;
    begin
        if Totals.Get(EntCode, Existing) then
            Totals.Set(EntCode, Existing + Amount)
        else
            Totals.Add(EntCode, Amount);
    end;

    local procedure EqualToken(LeftToken: JsonToken; RightToken: JsonToken; Path: Text): Boolean
    var
        LeftObject: JsonObject;
        RightObject: JsonObject;
        LeftArray: JsonArray;
        RightArray: JsonArray;
        LeftChild: JsonToken;
        RightChild: JsonToken;
        Matched: Dictionary of [Integer, Boolean];
        PropertyName: Text;
        LeftText: Text;
        RightText: Text;
        LeftNumber: Decimal;
        RightNumber: Decimal;
        LeftGuid: Guid;
        RightGuid: Guid;
        I: Integer;
        J: Integer;
        Found: Boolean;
    begin
        if LeftToken.IsObject() and RightToken.IsObject() then begin
            LeftObject := LeftToken.AsObject();
            RightObject := RightToken.AsObject();
            foreach PropertyName in LeftObject.Keys() do
                if not IgnoreKey(Path, PropertyName, LeftObject, RightObject) then begin
                    if not RightObject.Get(PropertyName, RightChild) then
                        exit(false);
                    LeftObject.Get(PropertyName, LeftChild);
                    if not EqualToken(LeftChild, RightChild, Path + '/' + PropertyName) then
                        exit(false);
                end;
            foreach PropertyName in RightObject.Keys() do
                if not IgnoreKey(Path, PropertyName, LeftObject, RightObject) then
                    if not LeftObject.Contains(PropertyName) then
                        exit(false);
            exit(true);
        end;
        if LeftToken.IsArray() and RightToken.IsArray() then begin
            LeftArray := LeftToken.AsArray();
            RightArray := RightToken.AsArray();
            if LeftArray.Count() <> RightArray.Count() then
                exit(false);
            // Arrays are compared as multisets; duplicates still count.
            for I := 0 to LeftArray.Count() - 1 do begin
                LeftArray.Get(I, LeftChild);
                Found := false;
                for J := 0 to RightArray.Count() - 1 do
                    if not Matched.ContainsKey(J) then begin
                        RightArray.Get(J, RightChild);
                        if EqualToken(LeftChild, RightChild, Path + '[]') then begin
                            Matched.Add(J, true);
                            Found := true;
                            break;
                        end;
                    end;
                if not Found then
                    exit(false);
            end;
            exit(true);
        end;
        if not LeftToken.IsValue() or not RightToken.IsValue() then
            exit(false);
        if LeftToken.AsValue().IsNull() or RightToken.AsValue().IsNull() then
            exit(LeftToken.AsValue().IsNull() and RightToken.AsValue().IsNull());
        LeftText := LeftToken.AsValue().AsText();
        RightText := RightToken.AsValue().AsText();
        if (StrPos(LowerCase(Path), 'uuid') > 0) then
            if Evaluate(LeftGuid, LeftText) and Evaluate(RightGuid, RightText) then
                exit(LeftGuid = RightGuid);
        // Normalize numeric JSON values, preserving ordinary strings verbatim.
        LeftToken.WriteTo(LeftText);
        RightToken.WriteTo(RightText);
        if Evaluate(LeftNumber, LeftText, 9) and Evaluate(RightNumber, RightText, 9) then
            exit(LeftNumber = RightNumber);
        exit(LeftToken.AsValue().AsText() = RightToken.AsValue().AsText());
    end;

    local procedure IgnoreKey(Path: Text; PropertyName: Text; LeftObject: JsonObject; RightObject: JsonObject): Boolean
    begin
        // Existing simulation fixtures predate presence metadata. Their numeric
        // scenario remains comparable without rewriting stored canonical JSON.
        if IgnoreSimulationPresence then
            if ((Path = '') and (PropertyName = 'quantityM3Present')) or
               ((Path = '/hoppers[]') and (PropertyName in ['actualKgPresent', 'actualKgInvalid'])) then
                exit(true);
        if (Path = '') and (PropertyName = 'materials') then
            // Aggregated material identity depends on mutable Material Config.
            // The independent physical hopper projection is compared instead.
            exit(HasHoppers(LeftObject) and HasHoppers(RightObject));
        if Path = '/hoppers[]' then
            exit(PropertyName in ['materialUuid', 'entCode', 'itemNo', 'variantCode', 'materialName']);
        exit(false);
    end;

    local procedure HasHoppers(Root: JsonObject): Boolean
    var
        Token: JsonToken;
    begin
        if Root.Get('hoppers', Token) and Token.IsArray() then
            exit(Token.AsArray().Count() > 0);
        exit(false);
    end;

    procedure Assess(var Fact: Record "SI Prok Production Fact"; Root: JsonObject)
    var
        Token: JsonToken;
        HopperToken: JsonToken;
        Hoppers: JsonArray;
        Hopper: JsonObject;
        Slots: Integer;
        Observed: Integer;
        I: Integer;
        Actual: Decimal;
        Positive: Boolean;
        Invalid: Boolean;
    begin
        Fact."Reported Quantity Present" := ReadBoolean(Root, 'quantityM3Present');
        // Compatibility canonical has no presence metadata; it can still report
        // an explicit quantity, but cannot prove actual-measurement coverage.
        if not Root.Contains('quantityM3Present') then
            Fact."Reported Quantity Present" := ReadDecimal(Root, 'quantityM3', Actual);
        if Fact."Reported Quantity Present" then
            if ReadDecimal(Root, 'quantityM3', Actual) then
                Fact."Reported Quantity M3" := Actual;
        Fact."Verification Status" := Fact."Verification Status"::Unverified;
        Fact."Execution Evidence" := Fact."Execution Evidence"::Unavailable;
        Fact."Verification Message" := 'Немає погодженого критерію підтвердження точного обсягу м³. Нуль у підтвердженому обсязі не доводить відсутності виробництва.';
        if Root.Get('hoppers', Token) and Token.IsArray() then begin
            Hoppers := Token.AsArray();
            Slots := Hoppers.Count();
            for I := 0 to Slots - 1 do begin
                Hoppers.Get(I, HopperToken);
                if HopperToken.IsObject() then begin
                    Hopper := HopperToken.AsObject();
                    Invalid := Invalid or ReadBoolean(Hopper, 'actualKgInvalid');
                    if ReadBoolean(Hopper, 'actualKgPresent') then
                        if ReadDecimal(Hopper, 'actualKg', Actual) then begin
                            Observed += 1;
                            Positive := Positive or (Actual > 0);
                            Invalid := Invalid or (Actual < 0);
                        end else
                            Invalid := true;
                end else
                    Invalid := true;
            end;
        end;
        if Invalid then
            Fact."Execution Evidence" := Fact."Execution Evidence"::Inconsistent
        else
            if Observed > 0 then
                if Positive then
                    Fact."Execution Evidence" := Fact."Execution Evidence"::PositiveObserved
                else begin
                    Fact."Execution Evidence" := Fact."Execution Evidence"::ZeroObserved;
                    if Fact."Reported Quantity Present" and (Fact."Reported Quantity M3" > 0) then
                        Fact."Verification Status" := Fact."Verification Status"::"Suspected Failure";
                end;
        Fact."Verification Message" := CopyStr(
            StrSubstNo('%1. Отримано фактичних показників: %2 із %3 джерельних бункерів. %4',
                Format(Fact."Execution Evidence"), Observed, Slots, Fact."Verification Message"),
            1, MaxStrLen(Fact."Verification Message"));
        if Observed < Slots then
            Fact."Verification Message" := CopyStr('Дані неповні. ' + Fact."Verification Message", 1, MaxStrLen(Fact."Verification Message"));
        if Fact."Verification Status" = Fact."Verification Status"::"Suspected Failure" then
            Fact."Verification Message" := CopyStr('Підозра не є доказом невдалого замісу. ' + Fact."Verification Message", 1, MaxStrLen(Fact."Verification Message"));
        // Preserve the existing simulation quantity, without certifying it.
        if not Fact.Simulation then
            Fact."Produced Quantity M3" := 0;
        Fact."Ready for Posting" := false;
    end;

    procedure ReadBoolean(Root: JsonObject; PropertyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if Root.Get(PropertyName, Token) and Token.IsValue() then
            if not Token.AsValue().IsNull() then
                exit(LowerCase(Token.AsValue().AsText()) = 'true');
        exit(false);
    end;

    procedure ReadDecimal(Root: JsonObject; PropertyName: Text; var Value: Decimal): Boolean
    var
        Token: JsonToken;
    begin
        Clear(Value);
        if Root.Get(PropertyName, Token) and Token.IsValue() then
            if not Token.AsValue().IsNull() then
                exit(Evaluate(Value, Token.AsValue().AsText(), 9));
        exit(false);
    end;

    var
        IgnoreSimulationPresence: Boolean;
}
