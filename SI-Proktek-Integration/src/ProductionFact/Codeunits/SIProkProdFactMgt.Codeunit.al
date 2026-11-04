codeunit 57091 "SI Prok Prod Fact Mgt."
{
    procedure ImportForAllocation(Allocation: Record "SI Supply Allocation"; var ImportedCount: Integer; var ExistingCount: Integer)
    var
        ProdRequest: Record "SI Concrete Prod Request";
        Connection: Record "SI Prok Connection";
        ProductionsMgt: Codeunit "SI Prok Productions";
        ExportMgt: Codeunit "SI Prok Production Export Mgt.";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        ProductionUuids: List of [Text];
        ResponseText: Text;
        CanonicalText: Text;
        ProductionUuidText: Text;
        DateFrom: Date;
        DateTo: Date;
        PageNo: Integer;
        TotalPages: Integer;
        PageUuids: List of [Text];
        CandidateUuid: Text;
        Fact: Record "SI Prok Production Fact";
    begin
        Allocation.TestField("Supply Method", Allocation."Supply Method"::Production);
        if IsNullGuid(Allocation."Execution System ID") then
            Error('Для розподілу ще не створено документ виконання.');
        if not ProdRequest.GetBySystemId(Allocation."Execution System ID") then
            Error('Документ виконання для розподілу %1/%2/%3 не знайдено.', Allocation."Decision No.", Allocation."Decision Line No.", Allocation."Line No.");
        if IsNullGuid(ProdRequest."Proktek Order UUID") then
            Error('Для виробничої заявки відсутній Proktek Order UUID.');

        ConnectionMgt.GetActive(Connection);
        DateFrom := Today;
        if ProdRequest."Proktek Order Synced At" <> 0DT then
            DateFrom := DT2Date(ProdRequest."Proktek Order Synced At");
        DateTo := Today;
        if DateFrom > DateTo then
            DateFrom := DateTo;

        PageNo := 1;
        repeat
            Clear(ResponseText);
            ProductionsMgt.GetPage(Connection, DateFrom, DateTo, 100, PageNo, false, false, ResponseText);
            Clear(PageUuids);
            ExportMgt.GetProductionUuidsFromRaw(ResponseText, PageUuids);
            foreach CandidateUuid in PageUuids do
                ProductionUuids.Add(CandidateUuid);
            TotalPages := GetTotalPages(ResponseText);
            PageNo += 1;
        until PageNo > TotalPages;

        foreach ProductionUuidText in ProductionUuids do begin
            Clear(CanonicalText);
            ExportMgt.BuildCanonicalForProduction(Connection, ProductionUuidText, CanonicalText);
            if CanonicalBelongsToOrder(CanonicalText, ProdRequest."Proktek Order UUID") then begin
                if FindFactByProductionUuid(ProductionUuidText, Fact) then begin
                    AssertSameConnection(Fact, Connection.Code);
                    ExistingCount += 1;
                end
                else begin
                    PersistCanonicalWithConnection(ProdRequest, CanonicalText, Connection.Code, Fact);
                    ImportedCount += 1;
                end;
            end;
        end;

        RefreshOrderTotals(ProdRequest."Proktek Order UUID");
    end;

    // Explicit provenance for callers that know the source connection.
    procedure PersistCanonicalIfNewWithConnection(
        ProdRequest: Record "SI Concrete Prod Request";
        CanonicalText: Text;
        ConnectionCode: Code[50];
        var Fact: Record "SI Prok Production Fact"): Boolean
    var
        Root: JsonObject;
        ProductionUuidText: Text;
    begin
        if CanonicalText = '' then
            Error('Canonical Production JSON порожній.');
        if not Root.ReadFrom(CanonicalText) then
            Error('Canonical Production JSON невалідний.');
        ProductionUuidText := GetRequiredText(Root, 'productionUuid');
        if FindFactByProductionUuid(ProductionUuidText, Fact) then begin
            AssertSameConnection(Fact, ConnectionCode);
            RefreshOrderTotals(Fact."Order UUID");
            Fact.Get(Fact."Entry No.");
            exit(false);
        end;
        PersistCanonicalWithConnection(ProdRequest, CanonicalText, ConnectionCode, Fact);
        Fact.Get(Fact."Entry No.");
        exit(true);
    end;

    procedure PersistCanonicalIfNew(
        ProdRequest: Record "SI Concrete Prod Request";
        CanonicalText: Text;
        var Fact: Record "SI Prok Production Fact"): Boolean
    var
        Root: JsonObject;
        ProductionUuidText: Text;
    begin
        if CanonicalText = '' then
            Error('Canonical Production JSON порожній.');
        if not Root.ReadFrom(CanonicalText) then
            Error('Canonical Production JSON невалідний.');

        ProductionUuidText := GetRequiredText(Root, 'productionUuid');
        if FindFactByProductionUuid(ProductionUuidText, Fact) then begin
            RefreshOrderTotals(Fact."Order UUID");
            Fact.Get(Fact."Entry No.");
            exit(false);
        end;

        PersistCanonical(ProdRequest, CanonicalText, Fact);
        Fact.Get(Fact."Entry No.");
        exit(true);
    end;

    // Compatibility entry point: no source provenance => never posting-ready.
    procedure PersistCanonical(ProdRequest: Record "SI Concrete Prod Request"; CanonicalText: Text; var Fact: Record "SI Prok Production Fact")
    begin
        PersistCanonicalWithConnection(ProdRequest, CanonicalText, '', Fact);
    end;

    procedure PersistCanonicalWithConnection(ProdRequest: Record "SI Concrete Prod Request"; CanonicalText: Text; ConnectionCode: Code[50]; var Fact: Record "SI Prok Production Fact")
    var
        Root: JsonObject;
        MaterialsToken: JsonToken;
        Materials: JsonArray;
        MaterialToken: JsonToken;
        ProductionUuidText: Text;
        OrderUuidText: Text;
        FormulaUuidText: Text;
        I: Integer;
    begin
        if CanonicalText = '' then
            Error('Canonical Production JSON порожній.');
        if not Root.ReadFrom(CanonicalText) then
            Error('Canonical Production JSON невалідний.');

        ProductionUuidText := GetRequiredText(Root, 'productionUuid');
        if FindFactByProductionUuid(ProductionUuidText, Fact) then begin
            AssertSameConnection(Fact, ConnectionCode);
            exit;
        end;

        OrderUuidText := GetNestedText(Root, 'order', 'uuid');
        if LowerCase(OrderUuidText) <> LowerCase(Format(ProdRequest."Proktek Order UUID", 0, 4)) then
            Error('Production %1 належить іншому Proktek Order.', ProductionUuidText);

        // Record.Init() does not reset primary key fields.
        // The same var Fact is reused when importing multiple productions.
        Clear(Fact);
        Fact.Init();
        Evaluate(Fact."Production UUID", ProductionUuidText);
        Fact."Connection Code" := ConnectionCode;
        Fact."Production ID" := GetInteger(Root, 'productionId');
        Fact."Production Date/Time" := GetProductionDateTime(Root);
        Fact."Plant ID" := GetInteger(Root, 'plantId');
        Fact."Produced Quantity M3" := GetDecimal(Root, 'quantityM3');
        Fact."Order ID" := ProdRequest."Proktek Order ID";
        Fact."Order UUID" := ProdRequest."Proktek Order UUID";
        Fact."Order No." := CopyStr(GetNestedText(Root, 'order', 'number'), 1, MaxStrLen(Fact."Order No."));
        Fact."Prod. Request Entry No." := ProdRequest."Entry No.";
        Fact."Supply Decision No." := ProdRequest."Supply Decision No.";
        Fact."Supply Decision Line No." := ProdRequest."Supply Decision Line No.";
        Fact."Supply Allocation Line No." := ProdRequest."Supply Allocation Line No.";
        Fact."Project No." := ProdRequest."Project No.";
        Fact."Item No." := ProdRequest."Item No.";
        Fact."Variant Code" := ProdRequest."Variant Code";
        Fact."Recipe No." := ProdRequest."Recipe No.";
        Fact."Recipe Revision No." := ProdRequest."Recipe Revision No.";
        FormulaUuidText := GetNestedText(Root, 'formula', 'uuid');
        if FormulaUuidText <> '' then
            Evaluate(Fact."Formula UUID", FormulaUuidText);
        Fact."Formula Code" := CopyStr(GetNestedText(Root, 'formula', 'code'), 1, MaxStrLen(Fact."Formula Code"));
        Fact."Simulation" := IsSimulated(Root);
        ReadTruckFromCanonical(Root, Fact);
        Fact."Ordered Quantity M3" := ProdRequest.Quantity;
        Fact.Status := Fact.Status::Received;
        Fact."Ready for Posting" := false;
        Fact."Validation Message" := 'Production Fact отримано; очікує перевірки.';
        Fact.SetCanonicalJson(CanonicalText);
        Fact.Insert(true);

        if Root.Get('materials', MaterialsToken) and MaterialsToken.IsArray() then begin
            Materials := MaterialsToken.AsArray();
            for I := 0 to Materials.Count() - 1 do begin
                Materials.Get(I, MaterialToken);
                if MaterialToken.IsObject() then
                    InsertMaterial(Fact, I + 1, MaterialToken.AsObject());
            end;
        end;

        ValidateFact(Fact);
        RefreshOrderTotals(Fact."Order UUID");
    end;

    procedure PersistCaptureOnly(CanonicalText: Text; var Fact: Record "SI Prok Production Fact"): Boolean
    begin
        exit(PersistCaptureOnlyWithConnection(CanonicalText, '', Fact));
    end;

    procedure PersistCaptureOnlyWithConnection(CanonicalText: Text; ConnectionCode: Code[50]; var Fact: Record "SI Prok Production Fact"): Boolean
    var
        Root: JsonObject;
        MaterialsToken: JsonToken;
        MaterialToken: JsonToken;
        Materials: JsonArray;
        ProductionUuidText: Text;
        OrderUuidText: Text;
        FormulaUuidText: Text;
        I: Integer;
    begin
        if not Root.ReadFrom(CanonicalText) then
            Error('Невалідний Canonical JSON. Оригінал збережено в Raw Archive.');
        ProductionUuidText := GetRequiredText(Root, 'productionUuid');
        if FindFactByProductionUuid(ProductionUuidText, Fact) then begin
            AssertSameConnection(Fact, ConnectionCode);
            if Fact."Capture Mode" <> Fact."Capture Mode"::Test then
                Error('Production UUID %1 уже існує в режимі Normal. Запис не змінено.', ProductionUuidText);
            exit(false);
        end;
        Clear(Fact);
        Fact.Init();
        if not Evaluate(Fact."Production UUID", ProductionUuidText) then
            Error('Невалідний Production UUID: %1', ProductionUuidText);
        Fact."Connection Code" := ConnectionCode;
        Fact."Production ID" := GetInteger(Root, 'productionId');
        // Date parsing is isolated in the caller's TryFunction; raw payload survives.
        Fact."Production Date/Time" := GetProductionDateTime(Root);
        Fact."Plant ID" := GetInteger(Root, 'plantId');
        Fact."Produced Quantity M3" := GetDecimal(Root, 'quantityM3');
        Fact."Order No." := CopyStr(GetNestedText(Root, 'order', 'number'), 1, MaxStrLen(Fact."Order No."));
        OrderUuidText := GetNestedText(Root, 'order', 'uuid');
        if OrderUuidText <> '' then
            Evaluate(Fact."Order UUID", OrderUuidText);
        FormulaUuidText := GetNestedText(Root, 'formula', 'uuid');
        if FormulaUuidText <> '' then
            Evaluate(Fact."Formula UUID", FormulaUuidText);
        Fact."Formula Code" := CopyStr(GetNestedText(Root, 'formula', 'code'), 1, MaxStrLen(Fact."Formula Code"));
        Fact."Simulation" := IsSimulated(Root);
        ReadTruckFromCanonical(Root, Fact);
        Fact."Capture Mode" := Fact."Capture Mode"::Test;
        Fact.Status := Fact.Status::Received;
        Fact."Ready for Posting" := false;
        Fact."Validation Message" := 'Тестове приймання: бізнесова валідація не виконувалася.';
        Fact.SetCanonicalJson(CanonicalText);
        Fact.Insert(true);
        if Root.Get('materials', MaterialsToken) and MaterialsToken.IsArray() then begin
            Materials := MaterialsToken.AsArray();
            for I := 0 to Materials.Count() - 1 do begin
                Materials.Get(I, MaterialToken);
                if MaterialToken.IsObject() then
                    InsertMaterialCapture(Fact, I + 1, MaterialToken.AsObject());
            end;
        end;
        DiagnoseCaptureProvenance(Fact);
        exit(true);
    end;

    local procedure InsertMaterialCapture(Fact: Record "SI Prok Production Fact"; SequenceNo: Integer; MaterialJson: JsonObject)
    var
        Line: Record "SI Prok Prod Fact Material";
        UuidText: Text;
    begin
        Line.Init();
        Line."Production Fact Entry No." := Fact."Entry No.";
        Line."Line No." := SequenceNo * 10000;
        UuidText := GetText(MaterialJson, 'uuid');
        if UuidText <> '' then
            Evaluate(Line."Material UUID", UuidText);
        Line."External Material Code" := CopyStr(GetText(MaterialJson, 'entCode'), 1, MaxStrLen(Line."External Material Code"));
        Line."Material Name" := CopyStr(GetText(MaterialJson, 'name'), 1, MaxStrLen(Line."Material Name"));
        Line."Item No." := CopyStr(GetText(MaterialJson, 'itemNo'), 1, MaxStrLen(Line."Item No."));
        Line."Variant Code" := CopyStr(GetText(MaterialJson, 'variantCode'), 1, MaxStrLen(Line."Variant Code"));
        Line."Requested Kg" := GetDecimal(MaterialJson, 'requestedKg');
        Line."Adjusted Kg" := GetDecimal(MaterialJson, 'adjustedKg');
        Line."Actual Kg" := GetDecimal(MaterialJson, 'actualKg');
        Line."Variance Kg" := Line."Actual Kg" - Line."Requested Kg";
        if Line."Requested Kg" <> 0 then
            Line."Variance %" := 100 * Line."Variance Kg" / Line."Requested Kg";
        // No Item, Variant, Recipe, Allocation, status or approval lookups in Test mode.
        Line.Insert(true);
    end;

    procedure RepairSimulationTruckFields(OrderUuid: Guid)
    var
        Fact: Record "SI Prok Production Fact";
        Root: JsonObject;
        CanonicalText: Text;
    begin
        Fact.SetRange("Order UUID", OrderUuid);
        Fact.SetRange("Simulation", true);
        Fact.SetRange("Truck Code", '');
        if Fact.FindSet(true) then
            repeat
                CanonicalText := Fact.GetCanonicalJson();
                if (CanonicalText <> '') and Root.ReadFrom(CanonicalText) then begin
                    ReadTruckFromCanonical(Root, Fact);
                    if Fact."Truck Code" <> '' then
                        //Fact.Modify(false);
                        Fact.Modify(true);
                end;
                Clear(Root);
            until Fact.Next() = 0;
    end;

    local procedure ReadTruckFromCanonical(Root: JsonObject; var Fact: Record "SI Prok Production Fact")
    var
        TransportToken: JsonToken;
        TruckToken: JsonToken;
        TransportJson: JsonObject;
        TruckJson: JsonObject;
    begin
        if not Root.Get('transport', TransportToken) then
            exit;
        if not TransportToken.IsObject() then
            exit;
        TransportJson := TransportToken.AsObject();
        if not TransportJson.Get('truck', TruckToken) then
            exit;
        if not TruckToken.IsObject() then
            exit;
        TruckJson := TruckToken.AsObject();
        Fact."Truck UUID" := CopyStr(GetText(TruckJson, 'uuid'), 1, MaxStrLen(Fact."Truck UUID"));
        Fact."Truck Code" := CopyStr(GetText(TruckJson, 'code'), 1, MaxStrLen(Fact."Truck Code"));
        Fact."Truck Plate" := CopyStr(GetText(TruckJson, 'plate'), 1, MaxStrLen(Fact."Truck Plate"));
    end;

    local procedure InsertMaterial(Fact: Record "SI Prok Production Fact"; SequenceNo: Integer; MaterialJson: JsonObject)
    var
        Line: Record "SI Prok Prod Fact Material";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        RecipeLine: Record "SI Concrete Recipe Line";
        MaterialUuidText: Text;
    begin
        Line.Init();
        Line."Production Fact Entry No." := Fact."Entry No.";
        Line."Line No." := SequenceNo * 10000;
        MaterialUuidText := GetText(MaterialJson, 'uuid');
        if MaterialUuidText <> '' then
            Evaluate(Line."Material UUID", MaterialUuidText);
        Line."External Material Code" := CopyStr(GetText(MaterialJson, 'entCode'), 1, MaxStrLen(Line."External Material Code"));
        Line."Material Name" := CopyStr(GetText(MaterialJson, 'name'), 1, MaxStrLen(Line."Material Name"));
        Line."Item No." := CopyStr(GetText(MaterialJson, 'itemNo'), 1, MaxStrLen(Line."Item No."));
        Line."Variant Code" := CopyStr(GetText(MaterialJson, 'variantCode'), 1, MaxStrLen(Line."Variant Code"));
        Line."Requested Kg" := GetDecimal(MaterialJson, 'requestedKg');
        Line."Adjusted Kg" := GetDecimal(MaterialJson, 'adjustedKg');
        Line."Actual Kg" := GetDecimal(MaterialJson, 'actualKg');
        Line."Variance Kg" := Line."Actual Kg" - Line."Requested Kg";
        if Line."Requested Kg" <> 0 then
            Line."Variance %" := (Line."Variance Kg" / Line."Requested Kg") * 100;

        Line."BC Material Resolved" := (Line."Item No." <> '') and Item.Get(Line."Item No.");
        if Line."BC Material Resolved" and (Line."Variant Code" <> '') then
            Line."BC Material Resolved" := ItemVariant.Get(Line."Item No.", Line."Variant Code");

        RecipeLine.SetRange("Recipe No.", Fact."Recipe No.");
        RecipeLine.SetRange("Revision No.", Fact."Recipe Revision No.");
        RecipeLine.SetRange("Item No.", Line."Item No.");
        RecipeLine.SetRange("Variant Code", Line."Variant Code");
        Line."Recipe Material" := RecipeLine.FindFirst();
        Line.Insert(true);
    end;

    local procedure ValidateFact(var Fact: Record "SI Prok Production Fact")
    var
        Line: Record "SI Prok Prod Fact Material";
        ProdRequest: Record "SI Concrete Prod Request";
        Connection: Record "SI Prok Connection";
        FormulaMapping: Record "SI Prok Entity Mapping";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        BlockReason: Text;
        MatchCount: Integer;
        MatchedRevisionId: Guid;
    begin
        if not ProdRequest.Get(Fact."Prod. Request Entry No.") then
            BlockReason := 'Не знайдено заявку на виробництво.';

        if BlockReason = '' then
            if Fact."Connection Code" = '' then
                BlockReason := 'Не визначено Connection Code джерела факту.'
            else
                if not Connection.Get(Fact."Connection Code") then
                    BlockReason := 'Connection Code джерела факту не існує.';

        if BlockReason = '' then
            if IsNullGuid(Fact."Formula UUID") then
                BlockReason := 'Production Fact не містить Formula UUID.';

        if BlockReason = '' then
            if not RecipeRevision.Get(Fact."Recipe No.", Fact."Recipe Revision No.") then
                BlockReason := 'Не знайдено ревізію рецептури, зазначену у Production Fact.';

        if BlockReason = '' then begin
            FormulaMapping.Reset();
            FormulaMapping.SetRange("Connection Code", Fact."Connection Code");
            FormulaMapping.SetRange("Entity Type", FormulaMapping."Entity Type"::Formula);
            FormulaMapping.SetRange("Proktek UUID", Fact."Formula UUID");
            MatchCount := FormulaMapping.Count();
            if MatchCount = 0 then
                BlockReason := 'Formula UUID не зареєстровано для цього підключення Proktek.'
            else
                if MatchCount > 1 then
                    BlockReason := 'Formula UUID має неоднозначні відповідності у Proktek Mapping.'
                else begin
                    FormulaMapping.FindFirst();
                    MatchedRevisionId := FormulaMapping."BC SystemId";
                    if MatchedRevisionId <> RecipeRevision.SystemId then
                        BlockReason := 'Formula UUID пов’язаний з іншою ревізією BC.'
                    else
                        if FormulaMapping."SI Formula Proj. Status" <> FormulaMapping."SI Formula Proj. Status"::Published then
                            BlockReason := 'Formula Mapping не має статусу Published.'
                        else
                            if FormulaMapping."Last Sync At" = 0DT then
                                BlockReason := 'Відсутнє підтвердження синхронізації Formula.';
                end;
        end;

        Line.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if Line.FindSet() then
            repeat
                if not Line."BC Material Resolved" then
                    if BlockReason = '' then
                        BlockReason := StrSubstNo('Матеріал %1 не визначено в BC.', Line."External Material Code");
                if not Line."Recipe Material" then
                    if BlockReason = '' then
                        BlockReason := StrSubstNo('Матеріал %1 відсутній у Recipe Revision.', Line."External Material Code");
            until Line.Next() = 0;

        if BlockReason <> '' then begin
            Fact.Status := Fact.Status::Blocked;
            Fact."Ready for Posting" := false;
            Fact."Validation Message" := CopyStr(BlockReason, 1, MaxStrLen(Fact."Validation Message"));
        end else begin
            Fact."Ready for Posting" := not Fact."Simulation" and (Fact."Capture Mode" <> Fact."Capture Mode"::Test);
            Fact."Validation Message" := 'Production Fact пройшов перевірку походження та матеріалів.';
        end;
        if Fact."Simulation" then begin
            Fact."Ready for Posting" := false;
            if BlockReason = '' then
                Fact."Validation Message" := 'SIMULATION: перевірку пройдено; проведення заборонено.';
        end;
        Fact.Modify(true);
    end;

    // Diagnostic-only: does not change status or grant posting eligibility.
    procedure DiagnoseCaptureProvenance(var Fact: Record "SI Prok Production Fact")
    var
        Mapping: Record "SI Prok Entity Mapping";
        Revision: Record "SI Concrete Recipe Revision";
        Reason: Text;
    begin
        if Fact."Capture Mode" <> Fact."Capture Mode"::Test then
            Error('Діагностика призначена лише для TEST Capture.');
        if Fact."Connection Code" = '' then
            Reason := 'Не визначено Connection Code.'
        else
            if IsNullGuid(Fact."Formula UUID") then
                Reason := 'Не визначено Formula UUID.'
            else begin
                Mapping.SetRange("Connection Code", Fact."Connection Code");
                Mapping.SetRange("Entity Type", Mapping."Entity Type"::Formula);
                Mapping.SetRange("Proktek UUID", Fact."Formula UUID");
                if Mapping.Count() = 0 then
                    Reason := 'Formula UUID не зареєстровано у BC для цього Connection.'
                else
                    if Mapping.Count() > 1 then
                        Reason := 'Formula UUID має кілька відповідностей у BC.'
                    else begin
                        Mapping.FindFirst();
                        if not Revision.GetBySystemId(Mapping."BC SystemId") then
                            Reason := 'Formula Mapping посилається на відсутню ревізію.'
                        else
                            if Mapping."SI Formula Proj. Status" <> Mapping."SI Formula Proj. Status"::Published then
                                Reason := 'Formula Mapping не має статусу Published.'
                            else
                                if Mapping."Last Sync At" = 0DT then
                                    Reason := 'Formula Mapping не містить часу синхронізації.';
                    end;
            end;
        Fact."Ready for Posting" := false;
        if Reason = '' then
            Fact."Validation Message" := 'TEST: Formula UUID зареєстровано; проведення заборонено.'
        else
            Fact."Validation Message" := CopyStr('TEST / Provenance: ' + Reason, 1, MaxStrLen(Fact."Validation Message"));
        Fact.Modify(true);
    end;

    local procedure AssertSameConnection(Fact: Record "SI Prok Production Fact"; ConnectionCode: Code[50])
    begin
        if Fact."Connection Code" <> ConnectionCode then
            Error('Production UUID %1 уже існує з Connection Code %2; нове джерело %3. Конфлікт походження.',
                Fact."Production UUID", Fact."Connection Code", ConnectionCode);
    end;

    local procedure IsSimulated(Root: JsonObject): Boolean
    var
        Token: JsonToken;
    begin
        if Root.Get('simulated', Token) and Token.IsValue() then
            exit(Token.AsValue().AsBoolean());
        exit(false);
    end;

    local procedure RefreshOrderTotals(OrderUuid: Guid)
    var
        Fact: Record "SI Prok Production Fact";
        TotalProduced: Decimal;
        OrderedQty: Decimal;
        RemainingQty: Decimal;
    begin
        if IsNullGuid(OrderUuid) then
            exit;
        Fact.SetRange("Order UUID", OrderUuid);
        if Fact.FindSet() then begin
            repeat
                TotalProduced += Fact."Produced Quantity M3";
                if OrderedQty = 0 then
                    OrderedQty := Fact."Ordered Quantity M3";
            until Fact.Next() = 0;

            RemainingQty := OrderedQty - TotalProduced;
            if RemainingQty < 0 then
                RemainingQty := 0;

            Fact.FindSet(true);
            repeat
                Fact."Order Produced Total M3" := TotalProduced;
                Fact."Order Remaining M3" := RemainingQty;
                if Fact.Status <> Fact.Status::Blocked then begin
                    if TotalProduced > OrderedQty then
                        Fact.Status := Fact.Status::Overproduced
                    else
                        if TotalProduced = OrderedQty then
                            Fact.Status := Fact.Status::Complete
                        else
                            Fact.Status := Fact.Status::Partial;
                end;
                Fact.Modify(true);
            until Fact.Next() = 0;
        end;
    end;

    local procedure FindFactByProductionUuid(ProductionUuidText: Text; var Fact: Record "SI Prok Production Fact"): Boolean
    var
        ProductionUuid: Guid;
    begin
        if not Evaluate(ProductionUuid, ProductionUuidText) then
            exit(false);
        Fact.Reset();
        Fact.SetRange("Production UUID", ProductionUuid);
        exit(Fact.FindFirst());
    end;

    local procedure CanonicalBelongsToOrder(CanonicalText: Text; OrderUuid: Guid): Boolean
    var
        Root: JsonObject;
        OrderUuidText: Text;
    begin
        if not Root.ReadFrom(CanonicalText) then
            exit(false);
        OrderUuidText := GetNestedText(Root, 'order', 'uuid');
        exit(LowerCase(OrderUuidText) = LowerCase(Format(OrderUuid, 0, 4)));
    end;

    local procedure GetTotalPages(ResponseText: Text): Integer
    var
        Root: JsonObject;
        Value: Integer;
    begin
        if Root.ReadFrom(ResponseText) then
            Value := GetInteger(Root, 'totalpages');
        if Value < 1 then
            Value := 1;
        exit(Value);
    end;

    local procedure GetProductionDateTime(Root: JsonObject): DateTime
    var
        DateText: Text;
        TimeText: Text;
        ProductionDate: Date;
        ProductionTime: Time;
    begin
        DateText := GetText(Root, 'productionDate');
        TimeText := GetText(Root, 'productionTime');
        if not Evaluate(ProductionDate, DateText) then
            Error('Не вдалося розібрати дату Production: %1.', DateText);
        if not Evaluate(ProductionTime, TimeText) then
            Error('Не вдалося розібрати час Production: %1.', TimeText);
        exit(CreateDateTime(ProductionDate, ProductionTime));
    end;

    local procedure GetNestedText(Root: JsonObject; ObjectName: Text; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if Root.Get(ObjectName, Token) and Token.IsObject() then
            exit(GetText(Token.AsObject(), PropertyName));
        exit('');
    end;

    local procedure GetRequiredText(Root: JsonObject; PropertyName: Text): Text
    var
        Value: Text;
    begin
        Value := GetText(Root, PropertyName);
        if Value = '' then
            Error('У Canonical Production відсутнє поле %1.', PropertyName);
        exit(Value);
    end;

    local procedure GetText(Root: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Root.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() or Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetInteger(Root: JsonObject; PropertyName: Text): Integer
    var
        Token: JsonToken;
    begin
        if not Root.Get(PropertyName, Token) then
            exit(0);
        if not Token.IsValue() or Token.AsValue().IsNull() then
            exit(0);
        exit(Token.AsValue().AsInteger());
    end;

    local procedure GetDecimal(Root: JsonObject; PropertyName: Text): Decimal
    var
        Token: JsonToken;
    begin
        if not Root.Get(PropertyName, Token) then
            exit(0);
        if not Token.IsValue() or Token.AsValue().IsNull() then
            exit(0);
        exit(Token.AsValue().AsDecimal());
    end;
}
