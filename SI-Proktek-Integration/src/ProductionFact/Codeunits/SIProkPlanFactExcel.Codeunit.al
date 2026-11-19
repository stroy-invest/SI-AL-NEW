codeunit 57222 "SI Prok Plan Fact Excel"
{
    // Report structure and styles are defined by Resources/PlanFactTemplate.xlsx.
    // One sheet; header, consecutive concrete parties and one material summary.
    // No accounting operations, diagnostic sections or technical metadata in output.

    procedure ExportForSupplyRequest(SourceNo: Code[30])
    var
        Request: Record "SI Concrete Prod Request";
    begin
        if SourceNo = '' then
            Error('Номер заявки не задано.');
        Request.SetRange("Source Type", Request."Source Type"::"Supply Request");
        Request.SetRange("Source No.", SourceNo);
        if Request.IsEmpty() then
            Error('Для заявки %1 не знайдено виробничих заявок бетону.', SourceNo);
        ExportFilteredRequests(Request, SourceNo);
    end;

    procedure ExportForProductionRequest(EntryNo: Integer)
    var
        Request: Record "SI Concrete Prod Request";
        CaptionNo: Text;
    begin
        if not Request.Get(EntryNo) then
            Error('Виробничу заявку #%1 не знайдено.', EntryNo);
        CaptionNo := Request."Source No.";
        if CaptionNo = '' then
            CaptionNo := StrSubstNo('Виробнича заявка #%1', EntryNo);
        Request.SetRange("Entry No.", EntryNo);
        ExportFilteredRequests(Request, CaptionNo);
    end;

    procedure ExportWithoutOrder()
    begin
        ExportStandalone(0);
    end;

    procedure ExportForFact(FactEntryNo: Integer)
    begin
        if FactEntryNo = 0 then
            Error('Не задано виробничий факт.');
        ExportStandalone(FactEntryNo);
    end;

    local procedure ExportFilteredRequests(var Request: Record "SI Concrete Prod Request"; ReportNo: Text)
    var
        Writer: Codeunit "SI Prok PF Template Writer";
        Summary: Record "SI Prok PF Material Buffer" temporary;
        Fact: Record "SI Prok Production Fact";
        Plan: Record "SI Prok Production Plan";
        FirstRequest: Record "SI Concrete Prod Request";
        FirstPlan: Record "SI Prok Production Plan";
        FirstFact: Record "SI Prok Production Fact";
        Resolver: Codeunit "SI Prok PF Link Resolver";
        PlanM3: Decimal;
        ActualM3: Decimal;
        PartyM3: Decimal;
        TotalPlanM3: Decimal;
        TotalActualM3: Decimal;
        PartyNo: Integer;
        RequestCount: Integer;
        Concrete: Text;
        Recipe: Text;
        DriverName: Text;
        DeliverySite: Text;
        ProjectName: Text;
        NeedDate: Text;
        OrderCaption: Text;
    begin
        if Request.FindSet() then
            repeat
                if not Plan.Get(Request."Entry No.") then
                    Error('Для виробничої заявки #%1 не знайдено зафіксованого плану.', Request."Entry No.");
                AssertPlanComplete(Plan);
                PlanM3 := GetPlanOutputM3(Plan);
                TotalPlanM3 += PlanM3;
                RequestCount += 1;
                if RequestCount = 1 then begin
                    FirstRequest := Request;
                    FirstPlan := Plan;
                end;
                Fact.Reset();
                if Fact.FindSet() then
                    repeat
                        if Resolver.MatchesRequest(Fact, Request."Entry No.") then begin
                            PartyM3 := RequireFactM3(Fact);
                            TotalActualM3 += PartyM3;
                            PartyNo += 1;
                            if PartyNo = 1 then
                                FirstFact := Fact;
                        end;
                    until Fact.Next() = 0;
            until Request.Next() = 0;
        if PartyNo = 0 then
            Error('Для заявки %1 не знайдено виробничих фактів Proktek.', ReportNo);

        Concrete := FirstRequest.GetProductDescription();
        Recipe := GetLinkedRecipeCaption(FirstRequest, FirstPlan, FirstFact);
        NeedDate := FormatDateTime(FirstRequest."Required Date/Time");
        ProjectName := GetProjectName(FirstRequest."Project No.");
        if RequestCount > 1 then begin
            Concrete := 'Кілька позицій бетону';
            Recipe := 'Кілька рецептур';
        end;
        GetPartyDisplay(FirstFact, DriverName, DeliverySite);
        OrderCaption := GetOrderCaption(ReportNo, FirstRequest."Created At");

        Writer.Start();
        Writer.AddMainTitle();
        Writer.AddOrderHeader(OrderCaption, Concrete, NeedDate, Recipe, ProjectName,
            DeliverySite, true, TotalPlanM3, TotalActualM3);
        PartyNo := 0;
        if Request.FindSet() then
            repeat
                Plan.Get(Request."Entry No.");
                PlanM3 := GetPlanOutputM3(Plan);
                Fact.Reset();
                Fact.SetCurrentKey("Entry No.");
                if Fact.FindSet() then
                    repeat
                        if Resolver.MatchesRequest(Fact, Request."Entry No.") then begin
                            PartyNo += 1;
                            PartyM3 := RequireFactM3(Fact);
                            GetPartyDisplay(Fact, DriverName, DeliverySite);
                            // Use the same stored party plan and produced volume as the BC fact card.
                            // A missing party plan stays blank; never substitute the order total.
                            Writer.AddPartyHeader(PartyNo, Fact."Truck Plate", DriverName,
                                FormatDateTime(Fact."Production Date/Time"), Fact."Planned Quantity M3" > 0,
                                Fact."Planned Quantity M3", PartyM3);
                            WriteLinkedMaterials(Writer, Fact, Plan, PlanM3, PartyM3, Summary);
                            Writer.BlankRow();
                        end;
                    until Fact.Next() = 0;
            until Request.Next() = 0;
        Writer.AddMaterialSummaryHeader(false);
        WriteMaterialRows(Writer, Summary, false);
        Writer.Download(StrSubstNo('PlanFact_%1_%2', SafeFilePart(ReportNo), Format(Today, 0, '<Year4><Month,2><Day,2>')));
    end;

    local procedure ExportStandalone(FactEntryNo: Integer)
    var
        Writer: Codeunit "SI Prok PF Template Writer";
        Summary: Record "SI Prok PF Material Buffer" temporary;
        Fact: Record "SI Prok Production Fact";
        FirstFact: Record "SI Prok Production Fact";
        Request: Record "SI Concrete Prod Request";
        Plan: Record "SI Prok Production Plan";
        Resolver: Codeunit "SI Prok PF Link Resolver";
        LinkState: Enum "SI Prok PF Link State";
        PartyNo: Integer;
        PartyM3: Decimal;
        TotalM3: Decimal;
        PlannedM3: Decimal;
        IsLinked: Boolean;
        OrderCaption: Text;
        Concrete: Text;
        Recipe: Text;
        NeededAt: Text;
        ProjectName: Text;
        DriverName: Text;
        DeliverySite: Text;
        FileName: Text;
    begin
        if FactEntryNo <> 0 then begin
            if not Fact.Get(FactEntryNo) then
                Error('Виробничий факт #%1 не знайдено.', FactEntryNo);
            LinkState := Resolver.Resolve(Fact, Request);
            if LinkState = LinkState::Broken then
                Error('Виробничий факт #%1 має некоректний зв’язок із заявкою.', FactEntryNo);
            IsLinked := LinkState = LinkState::Linked;
            TotalM3 := RequireFactM3(Fact);
            FirstFact := Fact;
            PartyNo := 1;
            if IsLinked then begin
                if not Plan.Get(Request."Entry No.") then
                    Error('Для заявки #%1 немає зафіксованого плану.', Request."Entry No.");
                AssertPlanComplete(Plan);
                PlannedM3 := GetPlanOutputM3(Plan);
            end else
                PlannedM3 := 0; // No BC order means no ordered quantity.
        end else begin
            if Fact.FindSet() then
                repeat
                    if Resolver.Resolve(Fact, Request) = LinkState::WithoutOrder then begin
                        PartyM3 := RequireFactM3(Fact);
                        TotalM3 += PartyM3;
                        PartyNo += 1;
                        if PartyNo = 1 then
                            FirstFact := Fact;
                    end;
                until Fact.Next() = 0;
            if PartyNo = 0 then
                Error('Виробничих фактів без замовлення не знайдено.');
            PlannedM3 := 0; // No BC order means no ordered quantity.
        end;

        GetPartyDisplay(FirstFact, DriverName, DeliverySite);
        if IsLinked then begin
            OrderCaption := GetOrderCaption(Request."Source No.", Request."Created At");
            Concrete := Request.GetProductDescription();
            Recipe := GetLinkedRecipeCaption(Request, Plan, FirstFact);
            NeededAt := FormatDateTime(Request."Required Date/Time");
            ProjectName := GetProjectName(Request."Project No.");
        end else begin
            if (FactEntryNo <> 0) and (LinkState = LinkState::Unmatched) then
                OrderCaption := FirstFact."Order No."
            else
                OrderCaption := 'Без замовлення';
            Concrete := GetFactConcrete(FirstFact);
            Recipe := GetFactRecipe(FirstFact);
            ProjectName := GetProjectName(FirstFact."Project No.");
            if FactEntryNo = 0 then begin
                Concrete := 'Різні марки бетону';
                Recipe := 'Різні рецептури';
            end;
        end;

        Writer.Start();
        Writer.AddMainTitle();
        Writer.AddOrderHeader(OrderCaption, Concrete, NeededAt, Recipe, ProjectName,
            DeliverySite, IsLinked, PlannedM3, TotalM3);
        PartyNo := 0;
        if FactEntryNo <> 0 then begin
            PartyNo := 1;
            Writer.AddPartyHeader(PartyNo, FirstFact."Truck Plate", DriverName,
                FormatDateTime(FirstFact."Production Date/Time"), FirstFact."Planned Quantity M3" > 0,
                FirstFact."Planned Quantity M3", TotalM3);
            if IsLinked then
                WriteLinkedMaterials(Writer, FirstFact, Plan, PlannedM3, TotalM3, Summary)
            else
                WriteUnlinkedMaterials(Writer, FirstFact, Summary);
        end else begin
            Fact.Reset();
            if Fact.FindSet() then
                repeat
                    if Resolver.Resolve(Fact, Request) = LinkState::WithoutOrder then begin
                        PartyNo += 1;
                        PartyM3 := RequireFactM3(Fact);
                        GetPartyDisplay(Fact, DriverName, DeliverySite);
                        Writer.AddPartyHeader(PartyNo, Fact."Truck Plate", DriverName,
                            FormatDateTime(Fact."Production Date/Time"), Fact."Planned Quantity M3" > 0,
                            Fact."Planned Quantity M3", PartyM3);
                        WriteUnlinkedMaterials(Writer, Fact, Summary);
                        Writer.BlankRow();
                    end;
                until Fact.Next() = 0;
        end;
        Writer.BlankRow();
        Writer.AddMaterialSummaryHeader(not IsLinked);
        WriteMaterialRows(Writer, Summary, not IsLinked);
        if FactEntryNo = 0 then
            FileName := StrSubstNo('PlanFact_Bez_zamovlennia_%1', Format(Today, 0, '<Year4><Month,2><Day,2>'))
        else
            FileName := StrSubstNo('PlanFact_Production_%1_%2', FirstFact."Production ID", Format(Today, 0, '<Year4><Month,2><Day,2>'));
        Writer.Download(FileName);
    end;

    local procedure WriteLinkedMaterials(var Writer: Codeunit "SI Prok PF Template Writer"; Fact: Record "SI Prok Production Fact"; Plan: Record "SI Prok Production Plan"; PlanM3: Decimal; PartyM3: Decimal; var Summary: Record "SI Prok PF Material Buffer" temporary)
    var
        Batch: Record "SI Prok PF Material Buffer" temporary;
        PlanLine: Record "SI Prok Production Plan Line";
        Material: Record "SI Prok Prod Fact Material";
        MaterialKey: Text[250];
        MaterialName: Text[150];
        NormKg: Decimal;
        NormBaseM3: Decimal;
        IsMapped: Boolean;
    begin
        if (Fact."Item No." <> '') and (Fact."Item No." <> Plan."Item No.") then
            Error('Факт #%1 має іншу продукцію, ніж заявка #%2.', Fact."Entry No.", Plan."Prod. Request Entry No.");
        if (Fact."Variant Code" <> '') and (Fact."Variant Code" <> Plan."Variant Code") then
            Error('Факт #%1 має інший варіант продукції, ніж заявка #%2.', Fact."Entry No.", Plan."Prod. Request Entry No.");
        if PlanM3 <= 0 then
            Error('Для виробничої заявки #%1 немає додатного планового обсягу.', Plan."Prod. Request Entry No.");
        NormBaseM3 := PartyM3;
        if Fact."Planned Quantity M3" > 0 then
            NormBaseM3 := Fact."Planned Quantity M3";
        PlanLine.SetRange("Prod. Request Entry No.", Plan."Prod. Request Entry No.");
        if PlanLine.FindSet() then
            repeat
                NormKg := GetPlanMaterialKg(PlanLine) * NormBaseM3 / PlanM3;
                MaterialKey := BuildBCKey(PlanLine."Item No.", PlanLine."Variant Code");
                MaterialName := CopyStr(PlanLine.Description, 1, MaxStrLen(MaterialName));
                if MaterialName = '' then
                    MaterialName := PlanLine."Item No.";
                Accumulate(Batch, MaterialKey, PlanLine."Item No.", PlanLine."Variant Code",
                    MaterialName, NormKg, 0, 0, true, false, false);
            until PlanLine.Next() = 0;
        Material.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if Material.FindSet() then
            repeat
                IsMapped := Material."BC Material Resolved" and (Material."Item No." <> '');
                if IsMapped then
                    MaterialKey := BuildBCKey(Material."Item No.", Material."Variant Code")
                else
                    MaterialKey := BuildExternalKey(Material, Fact."Connection Code");
                MaterialName := GetMaterialName(Material, MaterialKey);
                Accumulate(Batch, MaterialKey, Material."Item No.", Material."Variant Code",
                    MaterialName, 0, Material."Requested Kg", Material."Actual Kg", false, true, not IsMapped);
            until Material.Next() = 0;
        WriteMaterialRows(Writer, Batch, false);
        if Batch.FindSet() then
            repeat
                // The summary must sum the exact values displayed in the party blocks.
                Accumulate(Summary, Batch."Material Key", Batch."Item No.", Batch."Variant Code",
                    Batch."Material Name", GetDisplayPlanKg(Batch, false), 0,
                    Batch."Actual Kg", Batch."Has Norm", Batch."Has Actual Line", Batch.Unmapped);
            until Batch.Next() = 0;
    end;

    local procedure WriteUnlinkedMaterials(var Writer: Codeunit "SI Prok PF Template Writer"; Fact: Record "SI Prok Production Fact"; var Summary: Record "SI Prok PF Material Buffer" temporary)
    var
        Batch: Record "SI Prok PF Material Buffer" temporary;
        Material: Record "SI Prok Prod Fact Material";
        MaterialKey: Text[250];
        MaterialName: Text[150];
        IsMapped: Boolean;
    begin
        Material.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if Material.FindSet() then
            repeat
                IsMapped := Material."BC Material Resolved" and (Material."Item No." <> '');
                if IsMapped then
                    MaterialKey := BuildBCKey(Material."Item No.", Material."Variant Code")
                else
                    MaterialKey := BuildExternalKey(Material, Fact."Connection Code");
                MaterialName := GetMaterialName(Material, MaterialKey);
                Accumulate(Batch, MaterialKey, Material."Item No.", Material."Variant Code",
                    MaterialName, 0, Material."Requested Kg", Material."Actual Kg", false, true, not IsMapped);
            until Material.Next() = 0;
        WriteMaterialRows(Writer, Batch, true);
        if Batch.FindSet() then
            repeat
                Accumulate(Summary, Batch."Material Key", Batch."Item No.", Batch."Variant Code",
                    Batch."Material Name", 0, Batch."MES Requested Kg", Batch."Actual Kg", false, true, Batch.Unmapped);
            until Batch.Next() = 0;
    end;

    local procedure WriteMaterialRows(var Writer: Codeunit "SI Prok PF Template Writer"; var Buffer: Record "SI Prok PF Material Buffer" temporary; WithoutOrder: Boolean)
    var
        MaterialName: Text;
        PlanKg: Decimal;
        Highlight: Boolean;
    begin
        if Buffer.FindSet() then
            repeat
                PlanKg := GetDisplayPlanKg(Buffer, WithoutOrder);
                MaterialName := Buffer."Material Name";
                Highlight := false;
                if not WithoutOrder then begin
                    if Buffer."Has Norm" and (Buffer."Actual Kg" = 0) then begin
                        MaterialName += ' · нормативний';
                        Highlight := true;
                    end else
                        if not Buffer."Has Norm" then begin
                            MaterialName := '↳ ' + MaterialName + ' · фактичний';
                            Highlight := true;
                        end;
                end;
                Writer.AddMaterial(MaterialName, PlanKg, Buffer."Actual Kg", Highlight);
            until Buffer.Next() = 0;
    end;

    local procedure GetDisplayPlanKg(Buffer: Record "SI Prok PF Material Buffer"; WithoutOrder: Boolean): Decimal
    begin
        if WithoutOrder then
            exit(Buffer."MES Requested Kg");
        // A material outside the approved recipe has no normative plan.
        if not Buffer."Has Norm" then
            exit(0);
        // For a recipe material, the party-specific MES plan takes priority.
        if Buffer."MES Requested Kg" <> 0 then
            exit(Buffer."MES Requested Kg");
        // Historical missing MES material: fallback to the BC recipe snapshot.
        exit(Buffer."Norm Kg");
    end;

    local procedure Accumulate(var Buffer: Record "SI Prok PF Material Buffer" temporary; MaterialKey: Text[250]; ItemNo: Code[20]; VariantCode: Code[10]; MaterialName: Text[150]; NormKg: Decimal; RequestedKg: Decimal; ActualKg: Decimal; HasNorm: Boolean; HasActual: Boolean; Unmapped: Boolean)
    begin
        if not Buffer.Get(MaterialKey) then begin
            Buffer.Init();
            Buffer."Material Key" := MaterialKey;
            Buffer."Item No." := ItemNo;
            Buffer."Variant Code" := VariantCode;
            Buffer."Material Name" := MaterialName;
            Buffer.Insert();
        end;
        if (Buffer."Material Name" = '') and (MaterialName <> '') then
            Buffer."Material Name" := MaterialName;
        Buffer."Norm Kg" += NormKg;
        Buffer."MES Requested Kg" += RequestedKg;
        Buffer."Actual Kg" += ActualKg;
        Buffer."Has Norm" := Buffer."Has Norm" or HasNorm;
        Buffer."Has Actual Line" := Buffer."Has Actual Line" or HasActual;
        Buffer.Unmapped := Buffer.Unmapped or Unmapped;
        Buffer.Modify();
    end;

    local procedure GetMaterialName(Material: Record "SI Prok Prod Fact Material"; MaterialKey: Text[250]): Text[150]
    var
        NameText: Text[150];
    begin
        NameText := Material."Material Name";
        if NameText = '' then
            NameText := Material."External Material Code";
        if NameText = '' then
            NameText := CopyStr(MaterialKey, 1, MaxStrLen(NameText));
        exit(NameText);
    end;

    local procedure AssertPlanComplete(Plan: Record "SI Prok Production Plan")
    var
        PlanLine: Record "SI Prok Production Plan Line";
    begin
        if Plan."Planned Quantity" <= 0 then
            Error('Виробнича заявка #%1 не має додатного планового обсягу.', Plan."Prod. Request Entry No.");
        PlanLine.SetRange("Prod. Request Entry No.", Plan."Prod. Request Entry No.");
        if PlanLine.IsEmpty() then
            Error('Виробнича заявка #%1 не має рядків плану матеріалів.', Plan."Prod. Request Entry No.");
    end;

    local procedure GetPlanOutputM3(Plan: Record "SI Prok Production Plan"): Decimal
    var
        Converter: Codeunit "SI Item UoM Conversion";
    begin
        if Plan."Unit of Measure Code" = '' then
            Error('Не задано одиницю виміру виробничої заявки #%1.', Plan."Prod. Request Entry No.");
        if not Converter.CanConvertItemQuantity(Plan."Item No.", Plan."Variant Code", Plan."Unit of Measure Code", 'M3') then
            Error('Немає перерахунку %1 → M3 для %2.', Plan."Unit of Measure Code", Plan."Item No.");
        exit(Converter.ConvertItemQuantity(Plan."Item No.", Plan."Variant Code", Plan."Planned Quantity", Plan."Unit of Measure Code", 'M3'));
    end;

    local procedure GetPlanMaterialKg(PlanLine: Record "SI Prok Production Plan Line"): Decimal
    var
        Converter: Codeunit "SI Item UoM Conversion";
        Item: Record Item;
        SourceUoM: Code[10];
    begin
        SourceUoM := PlanLine."Unit of Measure Code";
        if SourceUoM = '' then begin
            Item.Get(PlanLine."Item No.");
            SourceUoM := Item."Base Unit of Measure";
        end;
        if not Converter.CanConvertItemQuantity(PlanLine."Item No.", PlanLine."Variant Code", SourceUoM, 'KG') then
            Error('Немає перерахунку %1 → KG для %2.', SourceUoM, PlanLine."Item No.");
        exit(Converter.ConvertItemQuantity(PlanLine."Item No.", PlanLine."Variant Code", PlanLine."Planned Quantity", SourceUoM, 'KG'));
    end;

    local procedure RequireFactM3(Fact: Record "SI Prok Production Fact"): Decimal
    begin
        // Exactly the same source as "Факт, м³" on the production fact card.
        // Reported Quantity M3 is the MES declaration, not the produced quantity.
        if Fact."Produced Quantity M3" < 0 then
            Error('Факт #%1: фактичний обсяг не може бути від’ємним.', Fact."Entry No.");
        if (Fact."Produced Quantity M3" = 0) and
            (Fact."Verification Status" <> Fact."Verification Status"::Verified) then
            Error('Факт #%1: фактичний обсяг виробництва не визначено.', Fact."Entry No.");
        exit(Fact."Produced Quantity M3");
    end;

    local procedure GetOrderCaption(OrderNo: Text; CreatedAt: DateTime): Text
    begin
        if CreatedAt = 0DT then
            exit(OrderNo);
        exit(StrSubstNo('%1 від %2', OrderNo, Format(DT2Date(CreatedAt), 0, '<Day,2>.<Month,2>.<Year4>')));
    end;

    local procedure GetLinkedRecipeCaption(Request: Record "SI Concrete Prod Request"; Plan: Record "SI Prok Production Plan"; Fact: Record "SI Prok Production Fact"): Text
    var
        Shipment: Record "SI Prok Shipment";
    begin
        Shipment.SetRange("Production UUID", Fact."Production UUID");
        if Shipment.FindFirst() then
            if Shipment."Recipe Name" <> '' then
                exit(Shipment."Recipe Name");
        if Request."Formula Description" <> '' then
            exit(Request."Formula Description");
        if Fact."Formula Name" <> '' then
            exit(Fact."Formula Name");
        exit(GetRecipeCaption(Plan));
    end;

    local procedure GetRecipeCaption(Plan: Record "SI Prok Production Plan"): Text
    begin
        if Plan."Recipe No." = '' then
            exit('');
        if Plan."Recipe Revision No." = 0 then
            exit(Plan."Recipe No.");
        exit(StrSubstNo('%1 v.%2', Plan."Recipe No.", Plan."Recipe Revision No."));
    end;

    local procedure GetFactRecipe(Fact: Record "SI Prok Production Fact"): Text
    begin
        if Fact."Recipe No." <> '' then
            if Fact."Recipe Revision No." <> 0 then
                exit(StrSubstNo('%1 v.%2', Fact."Recipe No.", Fact."Recipe Revision No."))
            else
                exit(Fact."Recipe No.");
        exit(Fact."Formula Code");
    end;

    local procedure GetFactConcrete(Fact: Record "SI Prok Production Fact"): Text
    var
        Item: Record Item;
    begin
        if Fact."Formula Name" <> '' then
            exit(Fact."Formula Name");
        if Item.Get(Fact."Item No.") then
            exit(Item.Description);
        exit(Fact."Item No.");
    end;

    local procedure GetProjectName(ProjectNo: Code[20]): Text
    var
        Project: Record Job;
    begin
        if Project.Get(ProjectNo) then
            exit(Project.Description);
        exit(ProjectNo);
    end;

    local procedure FormatDateTime(Value: DateTime): Text
    begin
        if Value = 0DT then
            exit('');
        exit(Format(Value, 0, '<Day,2>.<Month,2>.<Year4> <Hours24,2>:<Minutes,2>'));
    end;

    local procedure GetPartyDisplay(Fact: Record "SI Prok Production Fact"; var DriverName: Text; var DeliverySite: Text)
    var
        Shipment: Record "SI Prok Shipment";
        Root: JsonObject;
        Transport: JsonObject;
        Driver: JsonObject;
        Token: JsonToken;
    begin
        Clear(DriverName);
        Clear(DeliverySite);
        if Root.ReadFrom(Fact.GetCanonicalJson()) then begin
            if Root.Get('transport', Token) and Token.IsObject() then begin
                Transport := Token.AsObject();
                if Transport.Get('driver', Token) and Token.IsObject() then begin
                    Driver := Token.AsObject();
                    if Driver.Get('name', Token) and Token.IsValue() then
                        if not Token.AsValue().IsNull() then
                            DriverName := Token.AsValue().AsText();
                end;
            end;
            // constructionSite.name is not a verified unloading point in the BC card.
        end;
        Shipment.SetRange("Production UUID", Fact."Production UUID");
        if Shipment.FindFirst() then begin
            if Shipment."Driver Name" <> '' then
                DriverName := Shipment."Driver Name";
            // Delivery point is deliberately blank until the mapping is verified.
        end;
    end;

    local procedure BuildBCKey(ItemNo: Code[20]; VariantCode: Code[10]): Text[250]
    begin
        exit(CopyStr(StrSubstNo('BC|%1|%2', ItemNo, VariantCode), 1, 250));
    end;

    local procedure BuildExternalKey(Material: Record "SI Prok Prod Fact Material"; ConnectionCode: Code[50]): Text[250]
    begin
        if not IsNullGuid(Material."Material UUID") then
            exit(CopyStr('EXT|UUID|' + ConnectionCode + '|' + Format(Material."Material UUID"), 1, 250));
        if Material."External Material Code" <> '' then
            exit(CopyStr('EXT|CODE|' + ConnectionCode + '|' + Material."External Material Code", 1, 250));
        exit(CopyStr(StrSubstNo('EXT|UNIDENTIFIED|%1|%2|%3', ConnectionCode,
            Material."Production Fact Entry No.", Material."Line No."), 1, 250));
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    begin
        exit(Value = '00000000-0000-0000-0000-000000000000');
    end;

    local procedure SafeFilePart(Value: Text): Text
    begin
        Value := DelChr(Value, '=', '\\/:*?"<>|');
        if Value = '' then
            Value := 'Request';
        exit(CopyStr(Value, 1, 50));
    end;
}
