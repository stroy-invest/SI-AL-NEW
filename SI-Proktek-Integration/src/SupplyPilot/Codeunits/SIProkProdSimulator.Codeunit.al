codeunit 57077 "SI Prok Prod Simulator"
{
    procedure RunForAllocation(Allocation: Record "SI Supply Allocation"; SimulationStep: Integer)
    var
        ProdRequest: Record "SI Concrete Prod Request";
        Fact: Record "SI Prok Production Fact";
        FactMgt: Codeunit "SI Prok Prod Fact Mgt.";
        ResultPage: Page "SI Prok Prod Sim Result";
        ProductionsJson: Text;
        DetailsJson: Text;
        MaterialsJson: Text;
        CanonicalJson: Text;
        AnalysisJson: Text;
        ScenarioCode: Text[30];
        Created: Boolean;
    begin
        ValidateAllocation(Allocation, ProdRequest);

        case SimulationStep of
            1:
                ScenarioCode := 'PRODUCTION-01/PART-1';
            2:
                ScenarioCode := 'PRODUCTION-01/PART-2';
            3:
                ScenarioCode := 'PRODUCTION-01/REPLAY-2';
            else
                Error('Невідомий крок симуляції: %1.', SimulationStep);
        end;

        BuildProduction01(
            ProdRequest,
            SimulationStep,
            ScenarioCode,
            ProductionsJson,
            DetailsJson,
            MaterialsJson);

        ParseAndAnalyze(
            ProdRequest,
            ScenarioCode,
            ProductionsJson,
            DetailsJson,
            MaterialsJson,
            CanonicalJson,
            AnalysisJson);

        Created := FactMgt.PersistCanonicalIfNew(ProdRequest, CanonicalJson, Fact);
        AppendPersistenceResult(AnalysisJson, Created, Fact);

        // Persistence above opens a write transaction (Production Fact Header + Materials).
        // BC does not allow Page.RunModal while that write transaction is active.
        // The diagnostic result page is intentionally shown only after the fact is durable.
        Commit();

        ResultPage.SetPayloads(
            ScenarioCode,
            ProductionsJson,
            DetailsJson,
            MaterialsJson,
            CanonicalJson,
            AnalysisJson);
        ResultPage.RunModal();
    end;

    local procedure ValidateAllocation(
        Allocation: Record "SI Supply Allocation";
        var ProdRequest: Record "SI Concrete Prod Request")
    begin
        Allocation.TestField("Supply Method", Allocation."Supply Method"::Production);
        if IsNullGuid(Allocation."Execution System ID") then
            Error('Для розподілу ще не створено документ виконання. Спочатку надішліть Order у Proktek.');
        if not ProdRequest.GetBySystemId(Allocation."Execution System ID") then
            Error(
                'Документ виконання для розподілу %1/%2/%3 не знайдено.',
                Allocation."Decision No.",
                Allocation."Decision Line No.",
                Allocation."Line No.");

        ProdRequest.TestField("Proktek Order ID");
        if IsNullGuid(ProdRequest."Proktek Order UUID") then
            Error('Для виробничої заявки відсутній Proktek Order UUID. Спочатку створіть і перевірте Order.');
        ProdRequest.TestField("Recipe No.");
        ProdRequest.TestField("Recipe Revision No.");
    end;

    local procedure BuildProduction01(
        ProdRequest: Record "SI Concrete Prod Request";
        SimulationStep: Integer;
        ScenarioCode: Text;
        var ProductionsText: Text;
        var DetailsText: Text;
        var MaterialsText: Text)
    var
        Recipe: Record "SI Concrete Recipe";
        RecipeLine: Record "SI Concrete Recipe Line";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        Connection: Record "SI Prok Connection";
        FormulaMapping: Record "SI Prok Entity Mapping";
        CustomerMapping: Record "SI Prok Entity Mapping";
        SiteMapping: Record "SI Prok Entity Mapping";
        Customer: Record Customer;
        Project: Record Job;
        Item: Record Item;
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        ItemUoMConversion: Codeunit "SI Item UoM Conversion";
        OrderProjector: Codeunit "SI Prok Order Projector";
        ProductionsRoot: JsonObject;
        DetailsRoot: JsonObject;
        MaterialsRoot: JsonObject;
        Production: JsonObject;
        Formula: JsonObject;
        ProductionArray: JsonArray;
        MaterialConfigs: JsonArray;
        OrderPayload: JsonObject;
        OrderToken: JsonToken;
        OrderJson: JsonObject;
        OrderNo: Text;
        ProductionUuid: Text;
        ProducedQty: Decimal;
        PlannedKg: Decimal;
        ActualKg: Decimal;
        FromUoM: Code[10];
        HopperNo: Integer;
        PlannedLineNo: Integer;
        ProductionId: Integer;
        DeliveryNo: Integer;
        ProductionTime: Text;
        StartTime: Text;
    begin
        Recipe.Get(ProdRequest."Recipe No.");
        RecipeRevision.Get(ProdRequest."Recipe No.", ProdRequest."Recipe Revision No.");
        ConnectionMgt.GetActive(Connection);
        Customer.Get(ProdRequest."Customer No.");
        Project.Get(ProdRequest."Project No.");

        if not FormulaMapping.Get(Connection.Code, FormulaMapping."Entity Type"::Formula, RecipeRevision.SystemId) then
            Error('Formula mapping для ревізії %1 рецептури %2 не знайдено.', ProdRequest."Recipe Revision No.", ProdRequest."Recipe No.");
        if not CustomerMapping.Get(Connection.Code, CustomerMapping."Entity Type"::Customer, Customer.SystemId) then
            Error('Customer mapping для %1 не знайдено.', Customer."No.");
        if not SiteMapping.Get(Connection.Code, SiteMapping."Entity Type"::Site, Project.SystemId) then
            Error('Site mapping для проєкту %1 не знайдено.', Project."No.");

        if not OrderPayload.ReadFrom(OrderProjector.BuildOrderPayload(ProdRequest)) then
            Error('Не вдалося прочитати Order payload для симулятора.');
        if OrderPayload.Get('order', OrderToken) and OrderToken.IsObject() then begin
            OrderJson := OrderToken.AsObject();
            TryGetText(OrderJson, 'addOrderNo', OrderNo);
        end;

        case SimulationStep of
            1:
                begin
                    ProducedQty := Round(ProdRequest.Quantity * 0.75, 0.01, '=');
                    ProductionUuid := '11111111-1111-4111-8111-111111111107';
                    ProductionId := 900007;
                    DeliveryNo := 1;
                    StartTime := '11:20:00';
                    ProductionTime := '11:30:00';
                end;
            2, 3:
                begin
                    ProducedQty := ProdRequest.Quantity - Round(ProdRequest.Quantity * 0.75, 0.01, '=');
                    ProductionUuid := '11111111-1111-4111-8111-111111111108';
                    ProductionId := 900008;
                    DeliveryNo := 2;
                    StartTime := '12:20:00';
                    ProductionTime := '12:30:00';
                end;
        end;

        if ProducedQty <= 0 then
            Error('Розрахована кількість симуляції має бути більшою за нуль.');

        Production.Add('kod', ProductionId);
        Production.Add('uuid', ProductionUuid);
        Production.Add('tarih', Format(Today, 0, '<Day,2>.<Month,2>.<Year4>'));
        Production.Add('saat', ProductionTime);
        Production.Add('tarihsaat', Format(Today, 0, '<Year4>-<Month,2>-<Day,2>') + 'T' + ProductionTime);
        Production.Add('metrekup', ProducedQty);
        Production.Add('otomatik', true);
        Production.Add('reset', false);
        Production.Add('kullanici', 'PILOT-SIMULATOR');
        Production.Add('baslangic_saati', StartTime);
        Production.Add('bitis_saati', ProductionTime);
        Production.Add('irsaliye_seri_no', 'SIM');
        Production.Add('irsaliye_no', DeliveryNo);
        Production.Add('irsaliye_basildi', false);
        Production.Add('santral_id', 1);
        Production.Add('sip_id', ProdRequest."Proktek Order ID");
        Production.Add('siparis_uuid', Format(ProdRequest."Proktek Order UUID", 0, 4));
        Production.Add('sip_no', OrderNo);

        Production.Add('recete_uuid', Format(FormulaMapping."Proktek UUID", 0, 4));
        Production.Add('recete_index', FormulaMapping."Proktek Code");
        Production.Add('recete_ad', ProdRequest."Formula Description");
        Formula.Add('uuid', Format(FormulaMapping."Proktek UUID", 0, 4));
        Formula.Add('recete_kod', ProdRequest."Formula Code");
        Formula.Add('erp_kod', Recipe."Production BOM No.");
        Formula.Add('ad', ProdRequest."Formula Description");
        Production.Add('recete', Formula);

        Production.Add('musteri_uuid', Format(CustomerMapping."Proktek UUID", 0, 4));
        Production.Add('musteri_index', Customer."No.");
        Production.Add('musteri_ad', Customer.Name);
        Production.Add('santiye_uuid', Format(SiteMapping."Proktek UUID", 0, 4));
        Production.Add('santiye_index', Project."No.");
        Production.Add('santiye_ad', Project.Description);

        RecipeLine.SetRange("Recipe No.", ProdRequest."Recipe No.");
        RecipeLine.SetRange("Revision No.", ProdRequest."Recipe Revision No.");
        if not RecipeLine.FindSet() then
            Error('Ревізія не містить компонентів.');

        repeat
            PlannedLineNo += 1;
            if PlannedLineNo > 6 then
                Error('PRODUCTION-01 наразі підтримує максимум 6 матеріальних слотів Proktek; у Recipe Revision знайдено більше.');

            HopperNo += 1;
            FromUoM := RecipeLine."Unit of Measure Code";
            if FromUoM = '' then begin
                Item.Get(RecipeLine."Item No.");
                FromUoM := Item."Base Unit of Measure";
            end;

            PlannedKg := ItemUoMConversion.ConvertItemQuantity(
                RecipeLine."Item No.",
                RecipeLine."Variant Code",
                (RecipeLine.Quantity / Recipe."Output Quantity") * ProducedQty,
                FromUoM,
                'KG');
            PlannedKg := Round(PlannedKg, 1, '=');

            // Only legitimate Recipe Revision materials are generated.
            // Variances model normal production fact, not formula drift.
            case PlannedLineNo of
                1:
                    ActualKg := Round(PlannedKg * 1.03, 1, '='); // overconsumption
                2:
                    ActualKg := Round(PlannedKg * 0.97, 1, '='); // economy
                else
                    ActualKg := PlannedKg;                       // exact / normal
            end;

            AddAgregaSlot(Production, HopperNo, PlannedKg, ActualKg);
            AddMaterialConfig(
                MaterialConfigs,
                HopperNo,
                BuildEntCode(RecipeLine."Item No.", RecipeLine."Variant Code"),
                RecipeLine.Description,
                StrSubstNo('22222222-2222-4222-8222-%1', Pad12(HopperNo)));
        until RecipeLine.Next() = 0;

        ProductionsRoot.Add('responseStatus', true);
        ProductionsRoot.Add('responseMessage', ScenarioCode);
        ProductionArray.Add(Production);
        ProductionsRoot.Add('productions', ProductionArray);
        ProductionsRoot.Add('totalrecords', 1);
        ProductionsRoot.Add('totalmetercubes', ProducedQty);
        ProductionsRoot.Add('totalpages', 1);
        ProductionsRoot.Add('perpage', 100);
        ProductionsRoot.Add('page', 1);
        ProductionsRoot.WriteTo(ProductionsText);

        DetailsRoot.Add('responseStatus', true);
        DetailsRoot.Add('responseMessage', ScenarioCode);
        DetailsRoot.Add('production', Production);
        DetailsRoot.WriteTo(DetailsText);

        MaterialsRoot.Add('responseStatus', true);
        MaterialsRoot.Add('responseMessage', ScenarioCode);
        MaterialsRoot.Add('materials_config', MaterialConfigs);
        MaterialsRoot.WriteTo(MaterialsText);
    end;

    local procedure ParseAndAnalyze(
        ProdRequest: Record "SI Concrete Prod Request";
        ScenarioCode: Text;
        ProductionsText: Text;
        DetailsText: Text;
        MaterialsText: Text;
        var CanonicalText: Text;
        var AnalysisText: Text)
    var
        ExportMgt: Codeunit "SI Prok Production Export Mgt.";
        Root: JsonObject;
        Correlation: JsonObject;
        Summary: JsonObject;
        Cases: JsonArray;
        Canonical: JsonObject;
        MaterialsToken: JsonToken;
        MaterialToken: JsonToken;
        Materials: JsonArray;
        Material: JsonObject;
        RecipeLine: Record "SI Concrete Recipe Line";
        ProductionUuid: Text;
        OrderUuid: Text;
        EntCode: Text;
        ItemNo: Text;
        VariantCode: Text;
        Name: Text;
        Classification: Text;
        VarianceClass: Text;
        RequestedKg: Decimal;
        ActualKg: Decimal;
        PlannedInRecipe: Boolean;
        I: Integer;
        ProducedQty: Decimal;
    begin
        if ScenarioCode = 'PRODUCTION-01/PART-1' then
            ProductionUuid := '11111111-1111-4111-8111-111111111107'
        else
            ProductionUuid := '11111111-1111-4111-8111-111111111108';

        ExportMgt.ParsePilotRawResponses(
            ProductionsText,
            DetailsText,
            MaterialsText,
            ProductionUuid,
            CanonicalText);

        if not Canonical.ReadFrom(CanonicalText) then
            Error('Simulator canonical JSON is invalid.');
        TryGetText(Canonical, 'productionUuid', ProductionUuid);
        if Canonical.Get('order', MaterialToken) and MaterialToken.IsObject() then begin
            Material := MaterialToken.AsObject();
            TryGetText(Material, 'uuid', OrderUuid);
        end;

        Correlation.Add('scenario', ScenarioCode);
        Correlation.Add('productionUuid', ProductionUuid);
        Correlation.Add('expectedOrderId', ProdRequest."Proktek Order ID");
        Correlation.Add('expectedOrderUuid', Format(ProdRequest."Proktek Order UUID", 0, 4));
        Correlation.Add('actualOrderUuid', OrderUuid);
        Correlation.Add('orderMatched', LowerCase(OrderUuid) = LowerCase(Format(ProdRequest."Proktek Order UUID", 0, 4)));
        Correlation.Add('supplyDecisionNo', ProdRequest."Supply Decision No.");
        Correlation.Add('supplyDecisionLineNo', ProdRequest."Supply Decision Line No.");
        Correlation.Add('supplyAllocationLineNo', ProdRequest."Supply Allocation Line No.");
        Correlation.Add('projectNo', ProdRequest."Project No.");
        Correlation.Add('recipeNo', ProdRequest."Recipe No.");
        Correlation.Add('recipeRevisionNo', ProdRequest."Recipe Revision No.");
        Root.Add('correlation', Correlation);

        if Canonical.Get('materials', MaterialsToken) and MaterialsToken.IsArray() then begin
            Materials := MaterialsToken.AsArray();
            for I := 0 to Materials.Count() - 1 do begin
                Materials.Get(I, MaterialToken);
                if not MaterialToken.IsObject() then
                    continue;
                Material := MaterialToken.AsObject();
                Clear(EntCode);
                Clear(ItemNo);
                Clear(VariantCode);
                Clear(Name);
                Clear(RequestedKg);
                Clear(ActualKg);
                TryGetText(Material, 'entCode', EntCode);
                TryGetText(Material, 'itemNo', ItemNo);
                TryGetText(Material, 'variantCode', VariantCode);
                TryGetText(Material, 'name', Name);
                TryGetDecimal(Material, 'requestedKg', RequestedKg);
                TryGetDecimal(Material, 'actualKg', ActualKg);

                RecipeLine.Reset();
                RecipeLine.SetRange("Recipe No.", ProdRequest."Recipe No.");
                RecipeLine.SetRange("Revision No.", ProdRequest."Recipe Revision No.");
                RecipeLine.SetRange("Item No.", CopyStr(ItemNo, 1, MaxStrLen(RecipeLine."Item No.")));
                RecipeLine.SetRange("Variant Code", CopyStr(VariantCode, 1, MaxStrLen(RecipeLine."Variant Code")));
                PlannedInRecipe := RecipeLine.FindFirst();

                if not PlannedInRecipe then
                    Error('PRODUCTION-01 сформував матеріал %1, якого немає в Recipe Revision.', EntCode);

                Classification := 'Planned + Actual';
                if ActualKg > RequestedKg then
                    VarianceClass := 'OVERCONSUMPTION'
                else
                    if ActualKg < RequestedKg then
                        VarianceClass := 'ECONOMY'
                    else
                        VarianceClass := 'EXACT';

                AddAnalysisCase(Cases, EntCode, Name, RequestedKg, ActualKg, Classification, VarianceClass, true);
            end;
        end;

        TryGetDecimal(Canonical, 'quantityM3', ProducedQty);
        Summary.Add('orderedQuantityM3', ProdRequest.Quantity);
        Summary.Add('producedQuantityM3', ProducedQty);
        Summary.Add('partialProduction', ProducedQty < ProdRequest.Quantity);
        Summary.Add('postingReady', true);
        Root.Add('summary', Summary);
        Root.Add('materialCases', Cases);
        Root.WriteTo(AnalysisText);
    end;

    local procedure AppendPersistenceResult(
        var AnalysisText: Text;
        Created: Boolean;
        Fact: Record "SI Prok Production Fact")
    var
        Root: JsonObject;
        Persistence: JsonObject;
    begin
        if not Root.ReadFrom(AnalysisText) then
            Error('Не вдалося доповнити analysis JSON результатом persistence.');

        Persistence.Add('created', Created);
        Persistence.Add('existing', not Created);
        Persistence.Add('productionFactEntryNo', Fact."Entry No.");
        Persistence.Add('status', Format(Fact.Status));
        Persistence.Add('readyForPosting', Fact."Ready for Posting");
        Persistence.Add('orderProducedTotalM3', Fact."Order Produced Total M3");
        Persistence.Add('orderRemainingM3', Fact."Order Remaining M3");
        Root.Add('persistence', Persistence);
        Clear(AnalysisText);
        Root.WriteTo(AnalysisText);
    end;

    local procedure AddAnalysisCase(
        var Cases: JsonArray;
        EntCode: Text;
        Name: Text;
        PlannedKg: Decimal;
        ActualKg: Decimal;
        Classification: Text;
        ResultText: Text;
        BCMaterialMatch: Boolean)
    var
        CaseJson: JsonObject;
    begin
        CaseJson.Add('entCode', EntCode);
        CaseJson.Add('name', Name);
        CaseJson.Add('plannedKg', PlannedKg);
        CaseJson.Add('actualKg', ActualKg);
        CaseJson.Add('varianceKg', ActualKg - PlannedKg);
        CaseJson.Add('classification', Classification);
        CaseJson.Add('result', ResultText);
        CaseJson.Add('bcMaterialMatch', BCMaterialMatch);
        Cases.Add(CaseJson);
    end;

    local procedure AddAgregaSlot(var Production: JsonObject; HopperNo: Integer; RequestedKg: Decimal; ActualKg: Decimal)
    begin
        if (HopperNo < 1) or (HopperNo > 8) then
            Error('REALISTIC-01 requires agrega hopper 1..8; requested %1.', HopperNo);
        Production.Add(StrSubstNo('agrega%1_ist', HopperNo), Round(RequestedKg, 1, '='));
        Production.Add(StrSubstNo('agrega%1_tart', HopperNo), Round(RequestedKg, 1, '='));
        Production.Add(StrSubstNo('agrega%1_ver', HopperNo), Round(ActualKg, 1, '='));
    end;

    local procedure AddMaterialConfig(
        var Configs: JsonArray;
        HopperNo: Integer;
        EntCode: Text;
        MaterialName: Text;
        MaterialUuid: Text)
    var
        Config: JsonObject;
        Material: JsonObject;
    begin
        Config.Add('id', HopperNo);
        Config.Add('bunker', StrSubstNo('agrega%1', HopperNo));
        Config.Add('aktif', true);
        Config.Add('santral_id', 1);
        Config.Add('malzeme_uuid', MaterialUuid);
        Material.Add('uuid', MaterialUuid);
        Material.Add('malzeme_ent_kod', EntCode);
        Material.Add('ad', MaterialName);
        Config.Add('malzeme', Material);
        Configs.Add(Config);
    end;


    local procedure BuildEntCode(ItemNo: Code[20]; VariantCode: Code[10]): Text
    begin
        if VariantCode = '' then
            exit(ItemNo);
        exit(ItemNo + '|' + VariantCode);
    end;

    local procedure Pad12(Value: Integer): Text
    var
        T: Text;
    begin
        T := Format(Value);
        while StrLen(T) < 12 do
            T := '0' + T;
        exit(T);
    end;

    local procedure TryGetText(Json: JsonObject; PropertyName: Text; var Value: Text): Boolean
    var
        Token: JsonToken;
    begin
        Clear(Value);
        if not Json.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() or Token.AsValue().IsNull() then
            exit(false);
        Value := Token.AsValue().AsText();
        exit(true);
    end;

    local procedure TryGetDecimal(Json: JsonObject; PropertyName: Text; var Value: Decimal): Boolean
    var
        Token: JsonToken;
    begin
        Clear(Value);
        if not Json.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() or Token.AsValue().IsNull() then
            exit(false);
        Value := Token.AsValue().AsDecimal();
        exit(true);
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    var
        EmptyGuid: Guid;
    begin
        exit(Value = EmptyGuid);
    end;
}
