codeunit 57182 "SI Prok Two Truck Sim"
{
    // Explicitly scoped, no-order test scenario. No Proktek HTTP calls and no posting.
    procedure RunTwoTruckSimulation()
    var
        Recipe: Record "SI Concrete Recipe";
        Revision: Record "SI Concrete Recipe Revision";
        Connection: Record "SI Prok Connection";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        Fact: Record "SI Prok Production Fact";
        FormulaMapping: Record "SI Prok Entity Mapping";
        BomVersion: Record "Production BOM Version";
        Batch: Record "SI Prok Sim Truck Batch";
        OrderUuid: Guid;
        Created: Integer;
        TruckNo: Integer;
        Planned: Decimal;
        Produced: Decimal;
    begin
        // Resolve business identity from the deployed standard BOM-version contract.
        Recipe.SetRange("Production BOM No.", 'P00020');
        if Recipe.Count() <> 1 then
            Error('Очікується одна коренева рецептура для BOM P00020; знайдено %1.', Recipe.Count());
        Recipe.FindFirst();
        Revision.SetRange("Recipe No.", Recipe."Recipe No.");
        Revision.SetRange("Production BOM Version Code", 'REV-3');
        if Revision.Count() <> 1 then
            Error('Очікується одна ревізія P00020|REV-3; знайдено %1.', Revision.Count());
        Revision.FindFirst();
        if Recipe."Output Quantity" <= 0 then
            Error('У рецептурі не задано Output Quantity.');
        if not Evaluate(OrderUuid, 'bca17203-2026-4000-8000-000000000061') then
            Error('Некоректний службовий UUID симуляції.');
        ConnectionMgt.GetActive(Connection);
        if not BomVersion.Get('P00020', 'REV-3') then
            Error('Production BOM Version P00020|REV-3 відсутня.');
        if not FormulaMapping.Get(Connection.Code, FormulaMapping."Entity Type"::Formula, Revision.SystemId) then
            Error('Для активного Proktek Connection немає Formula Mapping ревізії 3.');
        if (LowerCase(Format(FormulaMapping."Proktek UUID", 0, 4)) <> 'ac5c8657-1718-4b02-a842-a73fd3c6a369') or
           ((FormulaMapping."Proktek Internal Code" <> 0) and (FormulaMapping."Proktek Internal Code" <> 172)) then
            Error('Formula Mapping не відповідає PROD Formula 172; симуляцію зупинено.');
        // A fixed scenario UUID makes reruns deterministic and prevents duplicate batches.
        for TruckNo := 1 to 2 do begin
            if TruckNo = 1 then begin
                Planned := 8;
                Produced := 7.8;
            end else begin
                Planned := 12;
                Produced := 11.7;
            end;
            Fact.Reset();
            Fact.SetRange("Production ID", 99172060 + TruckNo);
            if not Fact.IsEmpty() then
                Error('Production ID %1 уже зайнятий. Тест не запускатиметься.', 99172060 + TruckNo);
            if Batch.Get(OrderUuid, TruckNo) then
                Error('Симуляція автоміксера %1 уже існує. Повторний запуск заблоковано.', TruckNo);
        end;
        if not Confirm('PROD: створити ДВА тестові факти без заявки (8/7,8 і 12/11,7 м³) за P00020|REV-3? Проведення заборонено.', false) then
            exit;
        for TruckNo := 1 to 2 do begin
            if TruckNo = 1 then begin
                Planned := 8;
                Produced := 7.8;
            end else begin
                Planned := 12;
                Produced := 11.7;
            end;
            CreateTruck(Recipe, Revision, Connection.Code, OrderUuid, TruckNo, Planned, Produced);
            Created += 1;
        end;
        Commit();
        Message('Створено %1 тестових факти: план 20 м³, заявлений факт 19,5 м³. Capture Mode=Test, Simulation=true, Ready for Posting=false.', Created);
        Batch.Reset();
        Batch.SetRange("Order UUID", OrderUuid);
        Page.Run(Page::"SI Prok Sim Truck Batches", Batch);
    end;

    procedure ClearScenario()
    var
        Fact: Record "SI Prok Production Fact";
        Line: Record "SI Prok Prod Fact Material";
        Batch: Record "SI Prok Sim Truck Batch";
        OrderUuid: Guid;
        TruckNo: Integer;
        ProductionUuid: Guid;
    begin
        Evaluate(OrderUuid, 'bca17203-2026-4000-8000-000000000061');
        if not Confirm('Видалити лише тестові факти 99172061/99172062 та дві партії цієї симуляції? Дію не можна скасувати.', false) then
            exit;
        for TruckNo := 1 to 2 do begin
            Evaluate(ProductionUuid, StrSubstNo('bca17203-2026-4000-8000-0000000000%1', 60 + TruckNo));
            Fact.Reset();
            Fact.SetRange("Production UUID", ProductionUuid);
            if Fact.FindFirst() then begin
                if (Fact."Production ID" <> 99172060 + TruckNo) or
                   (Fact."Order UUID" <> OrderUuid) or
                   (not Fact.Simulation) or
                   (Fact."Capture Mode" <> Enum::"SI Prok Capture Mode"::Test) or
                   Fact."Ready for Posting" then
                    Error('Факт %1 не відповідає ізольованому тестовому сценарію. Видалення заборонено.', Fact."Entry No.");
                Line.SetRange("Production Fact Entry No.", Fact."Entry No.");
                Line.DeleteAll(true);
                Fact.Delete(true);
            end;
            if Batch.Get(OrderUuid, TruckNo) then begin
                if Batch."Truck Code" <> StrSubstNo('SIM-TRUCK-%1', TruckNo) then
                    Error('Партія %1 не відповідає тестовому сценарію.', TruckNo);
                Batch.Delete(true);
            end;
        end;
        Message('Тестові факти та партії двох автоміксерів очищено.');
    end;

    local procedure CreateTruck(Recipe: Record "SI Concrete Recipe"; Revision: Record "SI Concrete Recipe Revision"; ConnectionCode: Code[50]; OrderUuid: Guid; TruckNo: Integer; Planned: Decimal; Produced: Decimal)
    var
        RecipeLine: Record "SI Concrete Recipe Line";
        Item: Record Item;
        Conversion: Codeunit "SI Item UoM Conversion";
        FactMgt: Codeunit "SI Prok Prod Fact Mgt.";
        Fact: Record "SI Prok Production Fact";
        Batch: Record "SI Prok Sim Truck Batch";
        Result: Enum "SI Prok Intake Result";
        Root: JsonObject;
        Formula: JsonObject;
        OrderJson: JsonObject;
        Truck: JsonObject;
        Transport: JsonObject;
        Material: JsonObject;
        Hopper: JsonObject;
        Materials: JsonArray;
        Hoppers: JsonArray;
        Canonical: Text;
        Reason: Text;
        FromUom: Code[10];
        MaterialCode: Text;
        Name: Text;
        Requested: Decimal;
        Actual: Decimal;
        DeltaPct: Decimal;
        SlotNo: Integer;
        ProductionUuid: Guid;
    begin
        if not Evaluate(ProductionUuid, StrSubstNo('bca17203-2026-4000-8000-0000000000%1', 60 + TruckNo)) then
            Error('Некоректний Production UUID.');
        Root.Add('productionId', 99172060 + TruckNo);
        Root.Add('productionUuid', Format(ProductionUuid, 0, 4));
        Root.Add('productionDate', Format(Today, 0, '<Day,2>.<Month,2>.<Year4>'));
        Root.Add('productionTime', '12:00:00');
        Root.Add('productionDateTime', Format(Today, 0, '<Year4>-<Month,2>-<Day,2>') + 'T12:00:00');
        Root.Add('plantId', 1);
        Root.Add('quantityM3', Produced);
        Root.Add('quantityM3Present', true);
        Root.Add('simulated', true);
        Root.Add('automatic', true);
        Root.Add('operator', 'SI-TEST-2TRUCKS');
        Formula.Add('id', 172);
        Formula.Add('uuid', 'ac5c8657-1718-4b02-a842-a73fd3c6a369');
        Formula.Add('code', 'C16/20 S1|R3');
        Formula.Add('erpCode', 'P00020|REV-3');
        Formula.Add('name', 'C16/20 S1 v.3');
        Root.Add('formula', Formula);
        OrderJson.Add('uuid', Format(OrderUuid, 0, 4));
        OrderJson.Add('number', 'SIM-172-REV3');
        Root.Add('order', OrderJson);
        Truck.Add('uuid', StrSubstNo('bca17203-2026-4000-9000-0000000000%1', 60 + TruckNo));
        Truck.Add('code', StrSubstNo('SIM-TRUCK-%1', TruckNo));
        Truck.Add('plate', StrSubstNo('SIM-%1', TruckNo));
        Transport.Add('truck', Truck);
        Root.Add('transport', Transport);
        RecipeLine.SetRange("Recipe No.", Recipe."Recipe No.");
        RecipeLine.SetRange("Revision No.", Revision."Revision No.");
        if not RecipeLine.FindSet() then
            Error('У ревізії відсутні матеріали.');
        repeat
            SlotNo += 1;
            if SlotNo > 8 then
                Error('Симуляція підтримує максимум 8 матеріальних рядків.');
            FromUom := RecipeLine."Unit of Measure Code";
            if FromUom = '' then begin
                Item.Get(RecipeLine."Item No.");
                FromUom := Item."Base Unit of Measure";
            end;
            Requested := Round(Conversion.ConvertItemQuantity(RecipeLine."Item No.", RecipeLine."Variant Code", RecipeLine.Quantity / Recipe."Output Quantity" * Produced, FromUom, 'KG'), 0.01, '=');
            case SlotNo of
                1:
                    if TruckNo = 1 then
                        DeltaPct := 1.2 else
                        DeltaPct := -0.8;
                2:
                    if TruckNo = 1 then
                        DeltaPct := -1.5 else
                        DeltaPct := 0.9;
                3:
                    if TruckNo = 1 then
                        DeltaPct := 2.0 else
                        DeltaPct := -1.2;
                4:
                    if TruckNo = 1 then
                        DeltaPct := -1.0 else
                        DeltaPct := 1.4;
                5:
                    if TruckNo = 1 then
                        DeltaPct := 2.5 else
                        DeltaPct := -2.0;
                else
                    DeltaPct := 0;
            end;
            Actual := Round(Requested * (1 + DeltaPct / 100), 0.01, '=');
            MaterialCode := RecipeLine."Item No.";
            if RecipeLine."Variant Code" <> '' then
                MaterialCode += '|' + RecipeLine."Variant Code";
            Name := RecipeLine.Description;
            Clear(Material);
            Material.Add('uuid', '');
            Material.Add('entCode', MaterialCode);
            Material.Add('itemNo', RecipeLine."Item No.");
            Material.Add('variantCode', RecipeLine."Variant Code");
            Material.Add('name', Name);
            Material.Add('requestedKg', Requested);
            Material.Add('adjustedKg', Requested);
            Material.Add('actualKg', Actual);
            Materials.Add(Material);
            Clear(Hopper);
            Hopper.Add('hopper', StrSubstNo('agrega%1', SlotNo));
            Hopper.Add('materialUuid', '');
            Hopper.Add('entCode', MaterialCode);
            Hopper.Add('itemNo', RecipeLine."Item No.");
            Hopper.Add('variantCode', RecipeLine."Variant Code");
            Hopper.Add('materialName', Name);
            Hopper.Add('requestedKg', Requested);
            Hopper.Add('adjustedKg', Requested);
            Hopper.Add('actualKg', Actual);
            Hopper.Add('actualKgPresent', true);
            Hopper.Add('actualKgInvalid', false);
            Hoppers.Add(Hopper);
        until RecipeLine.Next() = 0;
        Root.Add('hoppers', Hoppers);
        Root.Add('materials', Materials);
        Root.WriteTo(Canonical);
        Result := FactMgt.PersistIntake(Canonical, ConnectionCode, Enum::"SI Prok Capture Mode"::Test, Fact, Reason);
        if Result <> Result::Imported then
            Error('Не вдалося створити тестовий факт: %1.', Reason);
        if not Fact.Simulation or Fact."Ready for Posting" then
            Error('Порушено захист симуляції: запис %1.', Fact."Entry No.");
        // The simulator's reported output is deliberately NOT certified as MES-verified output.
        // Existing Material Audit uses Produced Quantity M3 for test-only comparisons.
        Fact."Produced Quantity M3" := Produced;
        Fact."Ordered Quantity M3" := Planned;
        Fact."Ready for Posting" := false;
        Fact.Modify(true);
        Batch.Init();
        Batch."Order UUID" := OrderUuid;
        Batch."Truck No." := TruckNo;
        Batch."Truck Code" := CopyStr(StrSubstNo('SIM-TRUCK-%1', TruckNo), 1, MaxStrLen(Batch."Truck Code"));
        Batch."Truck Capacity M3" := Planned;
        Batch."Mix Count" := 1;
        Batch."Produced M3" := Produced;
        Batch.Insert(true);
    end;
}
