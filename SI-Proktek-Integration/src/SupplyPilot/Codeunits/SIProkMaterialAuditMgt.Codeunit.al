codeunit 57097 "SI Prok Material Audit Mgt"
{
    procedure BuildAudit(OrderUuid: Guid; var Buffer: Record "SI Prok Material Audit" temporary)
    var
        Fact: Record "SI Prok Production Fact";
        FactMgt: Codeunit "SI Prok Prod Fact Mgt.";
        ScopeCode: Text[30];
        NextLineNo: Integer;
    begin
        Buffer.DeleteAll();
        // Repair previously imported simulation facts from their stored canonical JSON.
        FactMgt.RepairSimulationTruckFields(OrderUuid);
        Fact.SetRange("Order UUID", OrderUuid);
        Fact.SetRange("Simulation", true);
        if not Fact.FindSet() then
            Error('Для Proktek Order %1 не знайдено симульованих фактів.', OrderUuid);

        repeat
            ScopeCode := CopyStr(Fact."Truck Code", 1, MaxStrLen(ScopeCode));
            if ScopeCode = '' then
                Error('Факт %1 не має коду автоміксера.', Fact."Entry No.");
            if not ScopeExists(Buffer, ScopeCode) then
                BuildScope(OrderUuid, ScopeCode, false, Buffer, NextLineNo);
        until Fact.Next() = 0;
        BuildScope(OrderUuid, 'УСЬОГО', true, Buffer, NextLineNo);
    end;

    local procedure ScopeExists(var Buffer: Record "SI Prok Material Audit" temporary; ScopeCode: Text[30]): Boolean
    begin
        Buffer.Reset();
        Buffer.SetRange("Scope", ScopeCode);
        exit(Buffer.FindFirst());
    end;

    local procedure BuildScope(OrderUuid: Guid; ScopeCode: Text[30]; AllTrucks: Boolean; var Buffer: Record "SI Prok Material Audit" temporary; var NextLineNo: Integer)
    var
        Fact: Record "SI Prok Production Fact";
        FactLine: Record "SI Prok Prod Fact Material";
        Recipe: Record "SI Concrete Recipe";
        RecipeLine: Record "SI Concrete Recipe Line";
        Item: Record Item;
        Conversion: Codeunit "SI Item UoM Conversion";
        Row: Record "SI Prok Material Audit" temporary;
        Produced: Decimal;
        Ordered: Decimal;
        KgPerM3: Decimal;
        FromUoM: Code[10];
        MixCount: Integer;
        RecipeNo: Code[50];
        RevisionNo: Integer;
    begin
        Fact.SetRange("Order UUID", OrderUuid);
        Fact.SetRange("Simulation", true);
        if not AllTrucks then
            Fact.SetRange("Truck Code", ScopeCode);
        if not Fact.FindSet() then
            exit;
        RecipeNo := Fact."Recipe No.";
        RevisionNo := Fact."Recipe Revision No.";
        Ordered := Fact."Ordered Quantity M3";
        repeat
            if (Fact."Recipe No." <> RecipeNo) or (Fact."Recipe Revision No." <> RevisionNo) then
                Error('У межах %1 змішані різні ревізії рецептури.', ScopeCode);
            Produced += Fact."Produced Quantity M3";
            MixCount += 1;
        until Fact.Next() = 0;

        Recipe.Get(RecipeNo);
        if Recipe."Output Quantity" <= 0 then
            Error('Для рецептури %1 не задано коректний Output Quantity.', RecipeNo);
        RecipeLine.SetRange("Recipe No.", RecipeNo);
        RecipeLine.SetRange("Revision No.", RevisionNo);
        if not RecipeLine.FindSet() then
            Error('У рецептурі %1, ревізія %2, відсутні матеріали.', RecipeNo, RevisionNo);
        repeat
            FromUoM := RecipeLine."Unit of Measure Code";
            if FromUoM = '' then begin
                Item.Get(RecipeLine."Item No.");
                FromUoM := Item."Base Unit of Measure";
            end;
            KgPerM3 := Conversion.ConvertItemQuantity(
                RecipeLine."Item No.", RecipeLine."Variant Code",
                RecipeLine.Quantity / Recipe."Output Quantity", FromUoM, 'KG');
            Buffer.Reset();
            Buffer.SetRange("Scope", ScopeCode);
            Buffer.SetRange("Item No.", RecipeLine."Item No.");
            Buffer.SetRange("Variant Code", RecipeLine."Variant Code");
            if not Buffer.FindFirst() then begin
                NextLineNo += 10000;
                Buffer.Init();
                Buffer."Line No." := NextLineNo;
                Buffer."Scope" := ScopeCode;
                Buffer."Item No." := RecipeLine."Item No.";
                Buffer."Variant Code" := RecipeLine."Variant Code";
                Buffer."Material Name" := CopyStr(RecipeLine.Description, 1, MaxStrLen(Buffer."Material Name"));
                Buffer."Produced M3" := Produced;
                Buffer."Ordered M3" := Ordered;
                Buffer."Mix Count" := MixCount;
                Buffer."Recipe Material" := true;
                Buffer."BC Material Resolved" := true;
                Buffer.Insert();
            end;
            Buffer."Recipe Kg Per M3" += KgPerM3;
            Buffer."BC Norm Kg" += KgPerM3 * Produced;
            if AllTrucks then
                Buffer."Ordered Norm Kg" += KgPerM3 * Ordered;
            Buffer.Modify();
        until RecipeLine.Next() = 0;

        Fact.FindSet();
        repeat
            FactLine.SetRange("Production Fact Entry No.", Fact."Entry No.");
            if FactLine.FindSet() then
                repeat
                    Buffer.Reset();
                    Buffer.SetRange("Scope", ScopeCode);
                    Buffer.SetRange("Item No.", FactLine."Item No.");
                    Buffer.SetRange("Variant Code", FactLine."Variant Code");
                    if not Buffer.FindFirst() then begin
                        // Preserve unmapped and extra materials rather than silently dropping them.
                        NextLineNo += 10000;
                        Buffer.Init();
                        Buffer."Line No." := NextLineNo;
                        Buffer."Scope" := ScopeCode;
                        Buffer."Item No." := FactLine."Item No.";
                        Buffer."Variant Code" := FactLine."Variant Code";
                        Buffer."Material Name" := FactLine."Material Name";
                        Buffer."External Material Code" := FactLine."External Material Code";
                        Buffer."Produced M3" := Produced;
                        Buffer."Ordered M3" := Ordered;
                        Buffer."Mix Count" := MixCount;
                        Buffer."Recipe Material" := false;
                        Buffer."BC Material Resolved" := FactLine."BC Material Resolved";
                        Buffer.Insert();
                    end;
                    Buffer."Proktek Plan Kg" += FactLine."Requested Kg";
                    Buffer."Actual Kg" += FactLine."Actual Kg";
                    if not FactLine."BC Material Resolved" then
                        Buffer."BC Material Resolved" := false;
                    if Buffer."External Material Code" = '' then
                        Buffer."External Material Code" := FactLine."External Material Code";
                    Buffer.Modify();
                until FactLine.Next() = 0;
        until Fact.Next() = 0;

        Buffer.Reset();
        Buffer.SetRange("Scope", ScopeCode);
        if Buffer.FindSet(true) then
            repeat
                Buffer."Variance Kg" := Buffer."Actual Kg" - Buffer."BC Norm Kg";
                Buffer."Plan Difference Kg" := Buffer."Proktek Plan Kg" - Buffer."BC Norm Kg";
                if Buffer."BC Norm Kg" <> 0 then
                    Buffer."Variance Percent" := 100 * Buffer."Variance Kg" / Buffer."BC Norm Kg";
                if not Buffer."Recipe Material" then
                    Buffer."Check Result" := 'ПОЗА РЕЦЕПТУРОЮ'
                else
                    if not Buffer."BC Material Resolved" then
                        Buffer."Check Result" := 'НЕ ВИЗНАЧЕНО В BC'
                    else
                        if Buffer."Actual Kg" = 0 then
                            Buffer."Check Result" := 'НЕМАЄ ФАКТИЧНИХ ВИТРАТ'
                        else
                            if Buffer."Variance Kg" > 0 then
                                Buffer."Check Result" := 'ПЕРЕВИТРАТА'
                            else
                                if Buffer."Variance Kg" < 0 then
                                    Buffer."Check Result" := 'ЕКОНОМІЯ'
                                else
                                    Buffer."Check Result" := 'ТОЧНО ЗА НОРМОЮ';
                Buffer.Modify();
            until Buffer.Next() = 0;
        Buffer.Reset();
    end;
}
