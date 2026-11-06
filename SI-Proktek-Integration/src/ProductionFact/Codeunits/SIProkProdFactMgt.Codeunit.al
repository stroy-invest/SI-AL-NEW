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
                    AssertSameContent(Fact, CanonicalText);
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
            AssertSameContent(Fact, CanonicalText);
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
            AssertSameConnection(Fact, '');
            AssertSameContent(Fact, CanonicalText);
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
            AssertSameContent(Fact, CanonicalText);
            exit;
        end;

        AssertMaterialConsistency(Root);
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
        Fact."Formula Name" := CopyStr(GetNestedText(Root, 'formula', 'name'), 1, MaxStrLen(Fact."Formula Name"));
        PopulateFormulaBomIdentity(Fact, Root);
        if Fact."Production BOM No." = '' then
            ResolveLegacyFormulaBom(Fact);
        EnrichRecipeContext(Fact);
        Fact."Simulation" := IsSimulated(Root);
        AssessNewFact(Fact, Root);
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
        Result: Enum "SI Prok Intake Result";
        Reason: Text;
    begin
        Result := PersistIntake(CanonicalText, ConnectionCode, Enum::"SI Prok Capture Mode"::Test, Fact, Reason);
        if Result = Result::Conflict then
            Error('%1', Reason);
        exit(Result = Result::Imported);
    end;

    procedure PersistIntake(CanonicalText: Text; ConnectionCode: Code[50]; Mode: Enum "SI Prok Capture Mode"; var Fact: Record "SI Prok Production Fact"; var Reason: Text): Enum "SI Prok Intake Result"
    var
        Root: JsonObject;
        Compare: Codeunit "SI Prok Fact Content Compare";
        Result: Enum "SI Prok Intake Result";
        ProductionUuidText: Text;
    begin
        Clear(Reason);
        Clear(Fact);
        if not Root.ReadFrom(CanonicalText) then
            Error('Невалідний Canonical JSON.');
        ProductionUuidText := GetRequiredText(Root, 'productionUuid');
        Fact.LockTable();
        if FindFactByProductionUuid(ProductionUuidText, Fact) then begin
            if Fact."Connection Code" <> ConnectionCode then begin
                Reason := 'Конфлікт походження: UUID уже збережено з іншим Connection Code.';
                exit(Result::Conflict);
            end;
            if Fact."Capture Mode" <> Mode then begin
                Reason := 'Конфлікт режиму приймання: UUID уже збережено як ' + Format(Fact."Capture Mode") + '. Режим і факт не змінено.';
                exit(Result::Conflict);
            end;
            if not Compare.SameContent(Fact.GetCanonicalJson(), CanonicalText, Reason) then
                exit(Result::Conflict);
            exit(Result::Existing);
        end;
        if not Compare.ValidateMaterials(Root, Reason) then
            Error('Суперечливий canonical: %1', Reason);
        PersistNewCapture(Root, CanonicalText, ConnectionCode, Mode, Fact);
        exit(Result::Imported);
    end;

    local procedure PersistNewCapture(Root: JsonObject; CanonicalText: Text; ConnectionCode: Code[50]; Mode: Enum "SI Prok Capture Mode"; var Fact: Record "SI Prok Production Fact")
    var
        MaterialsToken: JsonToken;
        MaterialToken: JsonToken;
        Materials: JsonArray;
        UuidText: Text;
        I: Integer;
    begin
        Clear(Fact);
        Fact.Init();
        UuidText := GetRequiredText(Root, 'productionUuid');
        if not Evaluate(Fact."Production UUID", UuidText) or IsNullGuid(Fact."Production UUID") then
            Error('Невалідний Production UUID.');
        Fact."Connection Code" := ConnectionCode;
        Fact."Capture Mode" := Mode;
        Fact."Production ID" := GetInteger(Root, 'productionId');
        Fact."Production Date/Time" := GetProductionDateTime(Root);
        Fact."Plant ID" := GetInteger(Root, 'plantId');
        Fact."Order No." := CopyStr(GetNestedText(Root, 'order', 'number'), 1, MaxStrLen(Fact."Order No."));
        UuidText := GetNestedText(Root, 'order', 'uuid');
        if UuidText <> '' then
            if not Evaluate(Fact."Order UUID", UuidText) then
                Error('Невалідний Order UUID.');
        UuidText := GetNestedText(Root, 'formula', 'uuid');
        if UuidText <> '' then
            if not Evaluate(Fact."Formula UUID", UuidText) then
                Error('Невалідний Formula UUID.');
        // Fact."Formula Code" := CopyStr(GetNestedText(Root, 'formula', 'code'), 1, MaxStrLen(Fact."Formula Code"));
        Fact."Formula Code" := CopyStr(
            GetNestedText(Root, 'formula', 'code'),
            1, MaxStrLen(Fact."Formula Code"));
        Fact."Formula Name" := CopyStr(GetNestedText(Root, 'formula', 'name'), 1, MaxStrLen(Fact."Formula Name"));
        PopulateFormulaBomIdentity(Fact, Root);

        // Recipe Revision mapping is optional metadata, not a resolution prerequisite.
        if Fact."Production BOM No." = '' then begin
            ResolveCaptureRecipe(Fact);
            ResolveLegacyFormulaBom(Fact);
        end;
        EnrichRecipeContext(Fact);
        Fact.Simulation := IsSimulated(Root);
        ReadTruckFromCanonical(Root, Fact);
        AssessNewFact(Fact, Root);
        Fact.Status := Fact.Status::Received;
        Fact.SetCanonicalJson(CanonicalText);
        Fact.Insert(true);
        if Root.Get('materials', MaterialsToken) and MaterialsToken.IsArray() then begin
            Materials := MaterialsToken.AsArray();
            for I := 0 to Materials.Count() - 1 do begin
                Materials.Get(I, MaterialToken);
                if not MaterialToken.IsObject() then
                    Error('Рядок materials %1 не є об’єктом.', I + 1);
                InsertMaterialCapture(Fact, I + 1, MaterialToken.AsObject());
            end;
        end;
        DiagnoseCaptureProvenance(Fact);
        AppendUnmappedDiagnostic(Fact);
    end;

    local procedure AssertMaterialConsistency(Root: JsonObject)
    var
        Compare: Codeunit "SI Prok Fact Content Compare";
        Reason: Text;
    begin
        if not Compare.ValidateMaterials(Root, Reason) then
            Error('Суперечливий canonical: %1', Reason);
    end;

    local procedure AssessNewFact(var Fact: Record "SI Prok Production Fact"; Root: JsonObject)
    var
        Compare: Codeunit "SI Prok Fact Content Compare";
    begin
        Compare.Assess(Fact, Root);
    end;

    local procedure AppendUnmappedDiagnostic(var Fact: Record "SI Prok Production Fact")
    var
        Line: Record "SI Prok Prod Fact Material";
    begin
        Line.SetRange("Production Fact Entry No.", Fact."Entry No.");
        Line.SetRange("BC Material Resolved", false);
        if not Line.IsEmpty() then begin
            Fact."Validation Message" := CopyStr(
                Fact."Validation Message" + ' Є матеріали без зіставлення з Item/Variant; зовнішні дані збережено.',
                1, MaxStrLen(Fact."Validation Message"));
            Fact.Modify(true);
        end;
    end;

    local procedure InsertMaterialCapture(Fact: Record "SI Prok Production Fact"; SequenceNo: Integer; MaterialJson: JsonObject)
    var
        Line: Record "SI Prok Prod Fact Material";
        UuidText: Text;
        Item: Record Item;
        Variant: Record "Item Variant";
    begin
        Line.Init();
        Line."Production Fact Entry No." := Fact."Entry No.";
        Line."Line No." := SequenceNo * 10000;
        UuidText := GetText(MaterialJson, 'uuid');
        if UuidText <> '' then
            if not Evaluate(Line."Material UUID", UuidText) then
                Clear(Line."Material UUID"); // External value remains in canonical JSON.
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
        Line."BC Material Resolved" := (Line."Item No." <> '') and Item.Get(Line."Item No.");
        if Line."BC Material Resolved" and (Line."Variant Code" <> '') then
            Line."BC Material Resolved" := Variant.Get(Line."Item No.", Line."Variant Code");
        ReadMaterialCoverage(Fact, MaterialJson, Line);
        Line.Insert(true);
    end;

    local procedure ReadMaterialCoverage(Fact: Record "SI Prok Production Fact"; MaterialJson: JsonObject; var Line: Record "SI Prok Prod Fact Material")
    var
        Root: JsonObject;
        Token: JsonToken;
        HopperToken: JsonToken;
        Hoppers: JsonArray;
        Hopper: JsonObject;
        Compare: Codeunit "SI Prok Fact Content Compare";
        I: Integer;
    begin
        if not Root.ReadFrom(Fact.GetCanonicalJson()) then
            exit;
        if not Root.Get('hoppers', Token) or not Token.IsArray() then
            exit;
        Hoppers := Token.AsArray();
        for I := 0 to Hoppers.Count() - 1 do begin
            Hoppers.Get(I, HopperToken);
            if HopperToken.IsObject() then begin
                Hopper := HopperToken.AsObject();
                if GetText(Hopper, 'entCode') = GetText(MaterialJson, 'entCode') then begin
                    Line."Source Slot Count" += 1;
                    if Compare.ReadBoolean(Hopper, 'actualKgPresent') then
                        Line."Actual Observed Slot Count" += 1;
                end;
            end;
        end;
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
        BOMLine: Record "Production BOM Line";
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

        // Standard BOM Version is the canonical material identity.
        Line."Recipe Material" := false;
        if (Fact."Production BOM No." <> '') and (Fact."Production BOM Version Code" <> '') and
           Line."BC Material Resolved" then begin
            BOMLine.SetRange("Production BOM No.", Fact."Production BOM No.");
            BOMLine.SetRange("Version Code", Fact."Production BOM Version Code");
            BOMLine.SetRange(Type, BOMLine.Type::Item);
            BOMLine.SetRange("No.", Line."Item No.");
            Line."Recipe Material" := not BOMLine.IsEmpty();
        end;
        Line.Insert(true);
    end;

    // Legacy order-bound intake validation. Never promote to posting-ready here:
    // Item/Variant, UoM, quantities, and production posting are not yet validated.
    local procedure ValidateFact(var Fact: Record "SI Prok Production Fact")
    var
        Line: Record "SI Prok Prod Fact Material";
        ProdRequest: Record "SI Concrete Prod Request";
        Connection: Record "SI Prok Connection";
        BOMVersion: Record "Production BOM Version";
        BlockReason: Text;
    begin
        if not ProdRequest.Get(Fact."Prod. Request Entry No.") then
            BlockReason := 'Не знайдено заявку на виробництво.';

        if BlockReason = '' then
            if (Fact."Connection Code" = '') or not Connection.Get(Fact."Connection Code") then
                BlockReason := 'Не визначено дійсне підключення Proktek.';

        if BlockReason = '' then
            if IsNullGuid(Fact."Formula UUID") then
                BlockReason := 'Production Fact не містить Formula UUID.';

        if BlockReason = '' then
            if (Fact."Production BOM No." = '') or (Fact."Production BOM Version Code" = '') then
                BlockReason := 'ERP Code не визначає стандартну Production BOM Version.'
            else
                if not BOMVersion.Get(Fact."Production BOM No.", Fact."Production BOM Version Code") then
                    BlockReason := 'Production BOM Version не знайдено.';

        Line.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if Line.FindSet() then
            repeat
                if (BlockReason = '') and not Line."BC Material Resolved" then
                    BlockReason := StrSubstNo('Матеріал %1 не визначено в BC.', Line."External Material Code");
                if (BlockReason = '') and not Line."Recipe Material" then
                    BlockReason := StrSubstNo('Матеріал %1 відсутній у Production BOM Version.', Line."External Material Code");
            until Line.Next() = 0;

        Fact."Ready for Posting" := false;
        if BlockReason <> '' then begin
            Fact.Status := Fact.Status::Blocked;
            Fact."Validation Message" := CopyStr(BlockReason, 1, MaxStrLen(Fact."Validation Message"));
        end else
            if Fact.Simulation then
                Fact."Validation Message" := 'SIMULATION: BOM і матеріали визначено; проведення заборонено.'
            else
                Fact."Validation Message" := 'BOM і матеріали визначено; проведення очікує окремої перевірки.';
        Fact.Modify(true);
    end;


    local procedure PopulateFormulaBomIdentity(var Fact: Record "SI Prok Production Fact"; Root: JsonObject)
    var
        BOMHeader: Record "Production BOM Header";
        BOMVersion: Record "Production BOM Version";
        ERPCode: Text;
        SeparatorPos: Integer;
        BOMNoText: Text;
        VersionText: Text;
    begin
        ERPCode := GetNestedText(Root, 'formula', 'erpCode');
        Fact."Formula ERP Code" := CopyStr(ERPCode, 1, MaxStrLen(Fact."Formula ERP Code"));
        Fact."Formula ID" := GetNestedInteger(Root, 'formula', 'id');
        Clear(Fact."Production BOM No.");
        Clear(Fact."Production BOM Version Code");
        SeparatorPos := StrPos(ERPCode, '|');
        if (SeparatorPos <= 1) or (SeparatorPos >= StrLen(ERPCode)) then
            exit;
        BOMNoText := CopyStr(ERPCode, 1, SeparatorPos - 1);
        VersionText := CopyStr(ERPCode, SeparatorPos + 1);
        if (StrLen(BOMNoText) > MaxStrLen(Fact."Production BOM No.")) or
           (StrLen(VersionText) > MaxStrLen(Fact."Production BOM Version Code")) or
           (StrPos(VersionText, '|') <> 0) then
            exit;
        if not BOMHeader.Get(BOMNoText) then
            exit;
        if not BOMVersion.Get(BOMNoText, VersionText) then
            exit;
        Fact."Production BOM No." := BOMHeader."No.";
        Fact."Production BOM Version Code" := BOMVersion."Version Code";
    end;

    local procedure GetNestedInteger(Root: JsonObject; ObjectKey: Text; FieldKey: Text): BigInteger
    var
        OuterToken: JsonToken;
        ValueToken: JsonToken;
        Inner: JsonObject;
    begin
        if not Root.Get(ObjectKey, OuterToken) or not OuterToken.IsObject() then
            exit(0);
        Inner := OuterToken.AsObject();
        if not Inner.Get(FieldKey, ValueToken) or not ValueToken.IsValue() then
            exit(0);
        if ValueToken.AsValue().IsNull then
            exit(0);
        exit(ValueToken.AsValue().AsInteger());
    end;

    local procedure ResolveCaptureRecipe(var Fact: Record "SI Prok Production Fact")
    var
        Mapping: Record "SI Prok Entity Mapping";
        Revision: Record "SI Concrete Recipe Revision";
    begin
        // Formula UUID is the authoritative external recipe identity.
        // Never infer a BC recipe from its name or Production BOM code.
        if IsNullGuid(Fact."Formula UUID") then
            exit;

        if Fact."Connection Code" = '' then
            exit;

        Mapping.SetRange("Connection Code", Fact."Connection Code");
        Mapping.SetRange("Entity Type", Mapping."Entity Type"::Formula);
        Mapping.SetRange("Proktek UUID", Fact."Formula UUID");

        // Resolve only unambiguous mappings.
        if Mapping.Count() <> 1 then
            exit;

        Mapping.FindFirst();

        // A mapping must reference an existing BC recipe revision.
        if not Revision.GetBySystemId(Mapping."BC SystemId") then
            exit;

        Fact."Recipe No." := Revision."Recipe No.";
        Fact."Recipe Revision No." := Revision."Revision No.";
    end;

    // A standard BOM Version is the primary technical identity. A verified historical
    // Formula UUID mapping may recover the version when legacy ERP Code lacks '|'.
    local procedure ResolveLegacyFormulaBom(var Fact: Record "SI Prok Production Fact")
    var
        Mapping: Record "SI Prok Entity Mapping";
        Revision: Record "SI Concrete Recipe Revision";
        Recipe: Record "SI Concrete Recipe";
        BOMVersion: Record "Production BOM Version";
        BOMHeader: Record "Production BOM Header";
    begin
        if (Fact."Production BOM No." <> '') or (Fact."Production BOM Version Code" <> '') then
            exit;
        if (Fact."Connection Code" = '') or IsNullGuid(Fact."Formula UUID") then
            exit;

        Mapping.SetRange("Connection Code", Fact."Connection Code");
        Mapping.SetRange("Entity Type", Mapping."Entity Type"::Formula);
        Mapping.SetRange("Proktek UUID", Fact."Formula UUID");
        if Mapping.Count() <> 1 then
            exit;
        Mapping.FindFirst();
        if not Revision.GetBySystemId(Mapping."BC SystemId") then
            exit;
        if not Recipe.Get(Revision."Recipe No.") then
            exit;
        if (Recipe."Production BOM No." = '') or (Revision."Production BOM Version Code" = '') then
            exit;
        if not BOMVersion.Get(Recipe."Production BOM No.", Revision."Production BOM Version Code") then
            exit;

        // An old ERP Code can be a non-standard legacy identifier. However, if it
        // names an existing BC BOM root, it must not contradict the mapped root.
        if (Fact."Formula ERP Code" <> '') and BOMHeader.Get(Fact."Formula ERP Code") then
            if BOMHeader."No." <> Recipe."Production BOM No." then
                exit;

        Fact."Production BOM No." := Recipe."Production BOM No.";
        Fact."Production BOM Version Code" := Revision."Production BOM Version Code";
        Fact."Recipe No." := Revision."Recipe No.";
        Fact."Recipe Revision No." := Revision."Revision No.";
    end;

    // Business context is optional. The standard BOM Version remains the canonical identity.
    local procedure EnrichRecipeContext(var Fact: Record "SI Prok Production Fact")
    var
        Recipe: Record "SI Concrete Recipe";
        Revision: Record "SI Concrete Recipe Revision";
        CandidateCount: Integer;
        CandidateRecipe: Code[50];
        CandidateRevision: Integer;
    begin
        Fact."Recipe Resolution Note" := '';
        if (Fact."Production BOM No." = '') or (Fact."Production BOM Version Code" = '') then begin
            Fact."Recipe Resolution Note" := 'BOM Version не визначено; зв’язок із рецептурою не підтверджено.';
            exit;
        end;

        Recipe.SetRange("Production BOM No.", Fact."Production BOM No.");
        if Recipe.FindSet() then
            repeat
                Revision.Reset();
                Revision.SetRange("Recipe No.", Recipe."Recipe No.");
                Revision.SetRange("Production BOM Version Code", Fact."Production BOM Version Code");
                if Revision.FindSet() then
                    repeat
                        CandidateCount += 1;
                        CandidateRecipe := Revision."Recipe No.";
                        CandidateRevision := Revision."Revision No.";
                    until Revision.Next() = 0;
            until Recipe.Next() = 0;

        case CandidateCount of
            0:
                Fact."Recipe Resolution Note" := 'BOM Version визначено; бізнесову ревізію не знайдено.';
            1:
                begin
                    // Do not silently overwrite a contradictory order-linked recipe.
                    if ((Fact."Recipe No." <> '') and (Fact."Recipe No." <> CandidateRecipe)) or
                       ((Fact."Recipe Revision No." <> 0) and (Fact."Recipe Revision No." <> CandidateRevision)) then begin
                        Fact."Recipe Resolution Note" := 'Конфлікт: рецептура заявки не збігається з BOM Version.';
                        exit;
                    end;
                    Fact."Recipe No." := CandidateRecipe;
                    Fact."Recipe Revision No." := CandidateRevision;
                    Fact."Recipe Resolution Note" := 'Рецептуру та ревізію підтверджено за BOM Version.';
                    ResolveFinishedProduct(Fact, CandidateRecipe);
                end;
            else
                Fact."Recipe Resolution Note" := 'Кілька ревізій відповідають BOM Version; автоматичний вибір заборонено.';
        end;
    end;

    // Finished product is owned by the recipe root, not by the BOM version.
    // A base recipe may legitimately have no variant; a variant recipe must have one.
    // Never guess a product from other Items that happen to reference the same BOM.
    local procedure ResolveFinishedProduct(var Fact: Record "SI Prok Production Fact"; RecipeNo: Code[50])
    var
        Recipe: Record "SI Concrete Recipe";
        FinishedItem: Record Item;
        FinishedVariant: Record "Item Variant";
    begin
        if not Recipe.Get(RecipeNo) then begin
            Fact."Recipe Resolution Note" := 'Рецептуру визначено, але кореневий запис не знайдено.';
            exit;
        end;
        if Recipe."Item No." = '' then begin
            Fact."Recipe Resolution Note" := 'У рецептурі не визначено товар готової продукції.';
            exit;
        end;
        if not FinishedItem.Get(Recipe."Item No.") then begin
            Fact."Recipe Resolution Note" := 'Товар готової продукції з рецептури не знайдено в BC.';
            exit;
        end;
        if (Recipe."Recipe Type" = Recipe."Recipe Type"::Variant) and (Recipe."Variant Code" = '') then begin
            Fact."Recipe Resolution Note" := 'Для рецептури варіанта не визначено код варіанта.';
            exit;
        end;
        if Recipe."Variant Code" <> '' then
            if not FinishedVariant.Get(Recipe."Item No.", Recipe."Variant Code") then begin
                Fact."Recipe Resolution Note" := 'Варіант готової продукції з рецептури не знайдено в BC.';
                exit;
            end;
        if ((Fact."Item No." <> '') and (Fact."Item No." <> Recipe."Item No.")) or
           ((Fact."Variant Code" <> '') and (Fact."Variant Code" <> Recipe."Variant Code")) then begin
            Fact."Recipe Resolution Note" := 'Конфлікт: товар або варіант факту не збігається з рецептурою.';
            exit;
        end;
        Fact."Item No." := Recipe."Item No.";
        Fact."Variant Code" := Recipe."Variant Code";
        Fact."Recipe Resolution Note" := 'Рецептуру, ревізію, товар і варіант визначено за BOM Version.';
    end;

    // Local-only enrichment: original canonical evidence, quantities and posting state
    // are never rewritten. This operation cannot grant Ready for Posting.
    procedure EnrichAndRevalidate(var Fact: Record "SI Prok Production Fact")
    var
        Root: JsonObject;
        CanonicalText: Text;
    begin
        Fact.TestField("Entry No.");
        CanonicalText := Fact.GetCanonicalJson();
        if (CanonicalText <> '') and Root.ReadFrom(CanonicalText) then begin
            if Fact."Formula Code" = '' then
                Fact."Formula Code" := CopyStr(GetNestedText(Root, 'formula', 'code'), 1, MaxStrLen(Fact."Formula Code"));
            if Fact."Formula Name" = '' then
                Fact."Formula Name" := CopyStr(GetNestedText(Root, 'formula', 'name'), 1, MaxStrLen(Fact."Formula Name"));
            if (Fact."Formula ERP Code" = '') or (Fact."Production BOM No." = '') then
                PopulateFormulaBomIdentity(Fact, Root);
        end;
        if (Fact."Production BOM No." = '') or (Fact."Production BOM Version Code" = '') then
            ResolveLegacyFormulaBom(Fact);
        EnrichRecipeContext(Fact);
        Fact."Ready for Posting" := false;
        Fact.Modify(true);
        DiagnoseCaptureProvenance(Fact);
    end;

    // Diagnostic-only: does not change status or grant posting eligibility.
    procedure DiagnoseCaptureProvenance(var Fact: Record "SI Prok Production Fact")
    var
        Mapping: Record "SI Prok Entity Mapping";
        Revision: Record "SI Concrete Recipe Revision";
        BOMVersion: Record "Production BOM Version";
        Reason: Text;
    begin
        // ERP Code is the primary BOM-version identity for Normal Capture.
        // The old Recipe Revision mapping remains informational only.
        if (Fact."Production BOM No." <> '') and (Fact."Production BOM Version Code" <> '') and
           BOMVersion.Get(Fact."Production BOM No.", Fact."Production BOM Version Code") then begin
            Fact."Ready for Posting" := false;
            Fact."Validation Message" := CopyStr(
                StrSubstNo('BOM версію визначено: %1|%2; Capture не надає готовності до проведення.',
                    Fact."Production BOM No.", Fact."Production BOM Version Code"),
                1, MaxStrLen(Fact."Validation Message"));
            Fact.Modify(true);
            exit;
        end;
        if Fact."Formula ERP Code" <> '' then begin
            Fact."Ready for Posting" := false;
            Fact."Validation Message" := CopyStr(
                StrSubstNo('Походження: ERP Code %1 не визначає наявну версію BOM (очікується BOM|VERSION).',
                    Fact."Formula ERP Code"), 1, MaxStrLen(Fact."Validation Message"));
            Fact.Modify(true);
            exit;
        end;
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
            Fact."Validation Message" := 'Formula UUID зареєстровано; Capture не надає готовності до проведення.'
        else
            Fact."Validation Message" := CopyStr('Походження: ' + Reason, 1, MaxStrLen(Fact."Validation Message"));
        Fact.Modify(true);
    end;

    local procedure AssertSameContent(Fact: Record "SI Prok Production Fact"; CanonicalText: Text)
    var
        Compare: Codeunit "SI Prok Fact Content Compare";
        Root: JsonObject;
        Reason: Text;
    begin
        if Fact."Capture Mode" <> Fact."Capture Mode"::Normal then
            Error('Конфлікт режиму приймання: UUID вже існує як Test.');
        if Root.ReadFrom(CanonicalText) then
            if IsSimulated(Root) <> Fact.Simulation then
                Error('Конфлікт контексту симуляції.');
        if not Compare.SameContent(Fact.GetCanonicalJson(), CanonicalText, Reason) then
            Error('%1', Reason);
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
        // Production totals are calculated read-only by GetConfirmedOrderTotal.
        // Keep the existing simulation scenario in its own scope.
        Fact.SetRange(Simulation, true);
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
                // Historical records are never rewritten by E1.1.
                if Fact."Verification Status" = Fact."Verification Status"::NotAssessed then
                    continue;
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
