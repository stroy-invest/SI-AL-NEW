codeunit 57228 "SI Prok PF Period Summary"
{
    // R4: read-only, all production facts by Production Date/Time (inclusive dates).
    // Groups by concrete Item/Variant, not by Proktek production/order UUID.
    // Materials are collected using the accepted Plan/Fact report's aggregation.

    procedure Export(FromDate: Date; ToDate: Date)
    var
        Groups: Record "SI Prok PF Concrete Group" temporary;
        FactIndex: Record "SI Prok PF Sum Fact Index" temporary;
        CurrentGroup: Record "SI Prok PF Concrete Group" temporary;
        Materials: Record "SI Prok PF Material Buffer" temporary;
        Grand: Record "SI Prok PF Material Buffer" temporary;
        Fact: Record "SI Prok Production Fact";
        Excel: Codeunit "SI Prok Plan Fact Excel";
        Writer: Codeunit "SI Prok PF Sum Writer";
        GroupKey: Text[250];
        ConcreteName: Text[150];
        RecipeName: Text[150];
        CountFacts: Integer;
        SeenOrders: Dictionary of [Text, Decimal];
    begin
        if (FromDate = 0D) or (ToDate = 0D) then
            Error('Укажіть початкову та кінцеву дати.');
        if ToDate < FromDate then
            Error('Кінцева дата не може бути ранішою за початкову.');

        ApplyPeriodFilter(Fact, FromDate, ToDate);
        if Fact.FindSet() then
            repeat
                ResolveConcrete(Fact, GroupKey, ConcreteName, RecipeName);
                if not Groups.Get(GroupKey) then begin
                    Groups.Init();
                    Groups."Group Key" := GroupKey;
                    Groups."Concrete Name" := ConcreteName;
                    Groups."Recipe Name" := RecipeName;
                    Groups.Insert();
                end;
                if (Groups."Concrete Name" = '') and (ConcreteName <> '') then
                    Groups."Concrete Name" := ConcreteName;
                if (Groups."Recipe Name" = '') and (RecipeName <> '') then
                    Groups."Recipe Name" := RecipeName
                else
                    if (RecipeName <> '') and (Groups."Recipe Name" <> RecipeName) then
                        Groups."Mixed Recipes" := true;

                AddOrderedQuantity(Fact, Groups, SeenOrders);
                // The period report sums recorded actual production, just like the
                // accepted fact card and single-order Plan/Fact report. Verification
                // status controls accounting readiness, NOT display of the quantity.
                if Fact."Produced Quantity M3" < 0 then
                    Error('Факт #%1: фактичний обсяг не може бути від’ємним.', Fact."Entry No.");
                Groups."Produced M3" += Fact."Produced Quantity M3";
                Groups.Modify();
                FactIndex.Init();
                FactIndex."Group Key" := GroupKey;
                FactIndex."Fact Entry No." := Fact."Entry No.";
                FactIndex.Insert();
                CountFacts += 1;
            until Fact.Next() = 0;
        if CountFacts = 0 then
            Error('За період %1–%2 виробничих фактів Proktek не знайдено.', FromDate, ToDate);

        Writer.Start(FromDate, ToDate);
        Groups.SetCurrentKey("Concrete Name");
        if Groups.FindSet() then
            repeat
                CurrentGroup := Groups;
                if CurrentGroup."Mixed Recipes" then
                    CurrentGroup."Recipe Name" := 'Кілька рецептур';
                Writer.AddConcrete(CurrentGroup."Concrete Name", CurrentGroup."Recipe Name",
                    CurrentGroup."Planned M3" > 0, CurrentGroup."Planned M3",
                    true, CurrentGroup."Produced M3");

                Materials.DeleteAll();
                FactIndex.SetRange("Group Key", CurrentGroup."Group Key");
                if FactIndex.FindSet() then
                    repeat
                        Fact.Get(FactIndex."Fact Entry No.");
                        Excel.AccumulateFactMaterials(Fact, Materials);
                    until FactIndex.Next() = 0;
                FactIndex.Reset();
                WriteMaterials(Writer, Materials, Grand, true);
                Writer.BlankRow();
            until Groups.Next() = 0;

        Writer.AddGrandMaterialsTitle();
        WriteMaterials(Writer, Grand, Materials, false);
        Writer.Download(StrSubstNo('PlanFactSum_%1_%2',
            Format(FromDate, 0, '<Year4><Month,2><Day,2>'),
            Format(ToDate, 0, '<Year4><Month,2><Day,2>')));
    end;

    local procedure AddOrderedQuantity(Fact: Record "SI Prok Production Fact"; var ConcreteGroup: Record "SI Prok PF Concrete Group" temporary; var SeenOrders: Dictionary of [Text, Decimal])
    var
        Request: Record "SI Concrete Prod Request";
        Plan: Record "SI Prok Production Plan";
        Resolver: Codeunit "SI Prok PF Link Resolver";
        Excel: Codeunit "SI Prok Plan Fact Excel";
        LinkState: Enum "SI Prok PF Link State";
        OrderKey: Text;
        OrderedM3: Decimal;
        PreviousM3: Decimal;
    begin
        // Order quantities are counted once per identifiable order, not once
        // per mixer. If an order-level plan is unavailable, use the recorded
        // party plan as a fallback; never turn a missing plan into a blank
        // result for the whole concrete group.
        LinkState := Resolver.Resolve(Fact, Request);
        if LinkState = LinkState::Linked then begin
            OrderKey := StrSubstNo('BC|%1', Request."Entry No.");
            if Plan.Get(Request."Entry No.") and (Plan."Planned Quantity" > 0) then
                OrderedM3 := Excel.GetPlanOutputM3(Plan)
            else
                OrderedM3 := Fact."Ordered Quantity M3";
        end else
            if LinkState = LinkState::WithoutOrder then begin
                OrderKey := StrSubstNo('PARTY|%1', Fact."Entry No.");
                OrderedM3 := Fact."Planned Quantity M3";
                // A manual production fact may carry a Proktek order ID even
                // without a BC order. Use the order total only when it can be
                // identified and deduplicated across parties.
                if (OrderedM3 <= 0) and (Fact."Ordered Quantity M3" > 0) then begin
                    if not IsNullGuid(Fact."Order UUID") then begin
                        OrderKey := StrSubstNo('MES|%1|UUID|%2', Fact."Connection Code", Fact."Order UUID");
                        OrderedM3 := Fact."Ordered Quantity M3";
                    end else
                        if Fact."Order ID" <> 0 then begin
                            OrderKey := StrSubstNo('MES|%1|ID|%2', Fact."Connection Code", Fact."Order ID");
                            OrderedM3 := Fact."Ordered Quantity M3";
                        end;
                end;
            end else begin
                if not IsNullGuid(Fact."Order UUID") then
                    OrderKey := StrSubstNo('MES|%1|UUID|%2', Fact."Connection Code", Fact."Order UUID")
                else
                    if Fact."Order ID" <> 0 then
                        OrderKey := StrSubstNo('MES|%1|ID|%2', Fact."Connection Code", Fact."Order ID")
                    else
                        if Fact."Order No." <> '' then
                            OrderKey := StrSubstNo('MES|%1|NO|%2', Fact."Connection Code", Fact."Order No.")
                        else
                            OrderKey := StrSubstNo('PARTY|%1', Fact."Entry No.");
                OrderedM3 := Fact."Ordered Quantity M3";
            end;

        // No known order-level quantity: sum the plans of the individual
        // parties instead. A party-specific plan is never deduplicated using
        // the order key, because multiple mixers can share the same order.
        if (OrderedM3 <= 0) and (Fact."Planned Quantity M3" > 0) then begin
            OrderKey := StrSubstNo('PARTY|%1', Fact."Entry No.");
            OrderedM3 := Fact."Planned Quantity M3";
        end;
        OrderKey := ConcreteGroup."Group Key" + '|' + OrderKey;

        if SeenOrders.Get(OrderKey, PreviousM3) then begin
            // If the first party did not carry an order quantity but a later
            // party does, include the recovered quantity exactly once.
            if (PreviousM3 <= 0) and (OrderedM3 > 0) then begin
                SeenOrders.Set(OrderKey, OrderedM3);
                ConcreteGroup."Planned M3" += OrderedM3;
            end else
                if (OrderedM3 > 0) and (PreviousM3 > 0) and (Abs(PreviousM3 - OrderedM3) > 0.001) then
                    Error('Для одного замовлення Proktek виявлено різні планові обсяги (%1 та %2 м³). Перевірте дані перед формуванням підсумку.', PreviousM3, OrderedM3);
            exit;
        end;
        SeenOrders.Add(OrderKey, OrderedM3);
        if OrderedM3 > 0 then
            ConcreteGroup."Planned M3" += OrderedM3
        else
            ConcreteGroup."Missing Plan" := true;
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    begin
        exit(Value = '00000000-0000-0000-0000-000000000000');
    end;

    local procedure ApplyPeriodFilter(var Fact: Record "SI Prok Production Fact"; FromDate: Date; ToDate: Date)
    begin
        // Half-open range includes all timestamps of the last date, including milliseconds.
        Fact.SetFilter("Production Date/Time", '>=%1&<%2',
            CreateDateTime(FromDate, 0T), CreateDateTime(ToDate + 1, 0T));
    end;

    local procedure ResolveConcrete(Fact: Record "SI Prok Production Fact"; var GroupKey: Text[250]; var ConcreteName: Text[150]; var RecipeName: Text[150])
    var
        Resolver: Codeunit "SI Prok PF Link Resolver";
        Request: Record "SI Concrete Prod Request";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemNo: Code[20];
        VariantCode: Code[10];
        LinkState: Enum "SI Prok PF Link State";
        Fallback: Text;
    begin
        Clear(GroupKey);
        Clear(ConcreteName);
        Clear(RecipeName);
        LinkState := Resolver.Resolve(Fact, Request);
        ItemNo := Fact."Item No.";
        VariantCode := Fact."Variant Code";
        if (LinkState = LinkState::Linked) and (Request."Item No." <> '') then begin
            ItemNo := Request."Item No.";
            VariantCode := Request."Variant Code";
            ConcreteName := Request.GetProductDescription();
            RecipeName := Request."Formula Description";
        end;

        if ItemNo <> '' then begin
            GroupKey := CopyStr(StrSubstNo('BC|%1|%2', ItemNo, VariantCode), 1, MaxStrLen(GroupKey));
            if ConcreteName = '' then begin
                if (VariantCode <> '') and ItemVariant.Get(ItemNo, VariantCode) and (ItemVariant.Description <> '') then
                    ConcreteName := CopyStr(ItemVariant.Description, 1, MaxStrLen(ConcreteName))
                else
                    if Item.Get(ItemNo) then
                        ConcreteName := CopyStr(Item.Description, 1, MaxStrLen(ConcreteName));
            end;
            if ConcreteName = '' then
                ConcreteName := ItemNo;
        end else begin
            // Unmapped historical facts still participate, but never merge with a BC Item by name.
            Fallback := Fact."Formula Name";
            if Fallback = '' then
                Fallback := Fact."Formula ERP Code";
            if Fallback = '' then
                Fallback := Fact."Formula Code";
            if Fallback = '' then
                Fallback := Fact."Recipe No.";
            if Fallback = '' then
                Fallback := StrSubstNo('Невизначений бетон #%1', Fact."Entry No.");
            ConcreteName := CopyStr(Fallback, 1, MaxStrLen(ConcreteName));
            GroupKey := CopyStr('EXT|' + Fact."Connection Code" + '|' + UpperCase(Fallback), 1, MaxStrLen(GroupKey));
        end;

        if RecipeName = '' then
            RecipeName := Fact."Formula Name";
        if RecipeName = '' then begin
            RecipeName := Fact."Recipe No.";
            if (RecipeName <> '') and (Fact."Recipe Revision No." <> 0) then
                RecipeName := CopyStr(StrSubstNo('%1 v.%2', RecipeName, Fact."Recipe Revision No."), 1, MaxStrLen(RecipeName));
        end;
    end;

    local procedure WriteMaterials(var Writer: Codeunit "SI Prok PF Sum Writer"; var Buffer: Record "SI Prok PF Material Buffer" temporary; var Grand: Record "SI Prok PF Material Buffer" temporary; AccumulateGrand: Boolean)
    var
        PlanKg: Decimal;
        MaterialName: Text;
        Highlight: Boolean;
    begin
        if Buffer.FindSet() then
            repeat
                PlanKg := Buffer."Norm Kg" + Buffer."MES Requested Kg";
                MaterialName := Buffer."Material Name";
                Highlight := false;
                if Buffer."Has Norm" and (Buffer."Actual Kg" = 0) and (PlanKg > 0) then begin
                    MaterialName += ' · нормативний';
                    Highlight := true;
                end else
                    if (not Buffer."Has Norm") and (PlanKg = 0) and (Buffer."Actual Kg" <> 0) then begin
                        MaterialName := '↳ ' + MaterialName + ' · фактичний';
                        Highlight := true;
                    end;
                Writer.AddMaterial(MaterialName, PlanKg, Buffer."Actual Kg", Highlight);
                if AccumulateGrand then
                    AddToGrand(Grand, Buffer, PlanKg);
            until Buffer.Next() = 0;
    end;

    local procedure AddToGrand(var Grand: Record "SI Prok PF Material Buffer" temporary; Material: Record "SI Prok PF Material Buffer"; PlanKg: Decimal)
    var
        GrandKey: Text[250];
    begin
        // R6: only the grand total groups by the material name visible in Excel.
        // BC/external identifiers can differ between concrete groups even when
        // the displayed material is identical. Per-concrete rows remain intact.
        GrandKey := GetGrandMaterialKey(Material);
        if not Grand.Get(GrandKey) then begin
            Grand.Init();
            Grand."Material Key" := GrandKey;
            Grand."Item No." := Material."Item No.";
            Grand."Variant Code" := Material."Variant Code";
            Grand."Material Name" := Material."Material Name";
            Grand.Insert();
        end;
        Grand."Norm Kg" += PlanKg;
        Grand."Actual Kg" += Material."Actual Kg";
        Grand."Has Norm" := Grand."Has Norm" or Material."Has Norm";
        Grand."Has Actual Line" := Grand."Has Actual Line" or Material."Has Actual Line";
        Grand.Unmapped := Grand.Unmapped or Material.Unmapped;
        Grand.Modify();
    end;

    local procedure GetGrandMaterialKey(Material: Record "SI Prok PF Material Buffer"): Text[250]
    var
        MaterialName: Text;
    begin
        // Ignore case and surrounding spaces. A missing display name must not
        // collapse unrelated unidentified materials into one summary row.
        MaterialName := UpperCase(DelChr(Material."Material Name", '<>', ' '));
        if MaterialName = '' then
            exit(Material."Material Key");
        exit(CopyStr('NAME|' + MaterialName, 1, 250));
    end;
}
