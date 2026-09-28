using STROYINVEST.ConcreteRecipeEngine;

codeunit 57060 "SI Prok Formula Projector"
{
    procedure BuildBomKgProjection(ProductionBOMNo: Code[20]): Text
    begin
        exit(BuildProjection(ProductionBOMNo, false));
    end;

    procedure BuildBomKgMaterialProjection(ProductionBOMNo: Code[20]): Text
    begin
        exit(BuildProjection(ProductionBOMNo, true));
    end;


    procedure BuildFormulaMaterialsJsonPreview(ProductionBOMNo: Code[20]): Text
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        ItemUoMConversion: Codeunit "SI Item UoM Conversion";
        MaterialResolver: Codeunit "SI Prok Material Resolver";
        Materials: JsonArray;
        RecipeMaterials: JsonArray;
        MaterialJson: JsonObject;
        PreviewJson: JsonObject;
        PlantIds: JsonArray;
        FromUoMCode: Code[10];
        QuantityKg: Decimal;
        ProktekCode: BigInteger;
        ProktekUUID: Guid;
        ProktekName: Text;
        ProktekType: Text;
        ResultJson: Text;
        LineCount: Integer;
    begin
        if ProductionBOMNo = '' then
            Error(ProductionBOMRequiredErr);

        ProductionBOMHeader.Get(ProductionBOMNo);
        MaterialResolver.LoadMaterials(Materials);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.SetRange("Version Code", '');
        if not ProductionBOMLine.FindSet() then
            Error(NoBomLinesErr, ProductionBOMNo);

        repeat
            case ProductionBOMLine.Type of
                ProductionBOMLine.Type::Item:
                    begin
                        if ProductionBOMLine."No." = '' then
                            Error(EmptyItemNoErr, ProductionBOMNo, ProductionBOMLine."Line No.");

                        Item.Get(ProductionBOMLine."No.");
                        FromUoMCode := ProductionBOMLine."Unit of Measure Code";
                        if FromUoMCode = '' then
                            FromUoMCode := Item."Base Unit of Measure";
                        if FromUoMCode = '' then
                            Error(NoSourceUoMErr, ProductionBOMLine."No.", ProductionBOMLine."Line No.");

                        QuantityKg := ItemUoMConversion.ConvertItemQuantity(
                            ProductionBOMLine."No.",
                            ProductionBOMLine."Variant Code",
                            ProductionBOMLine."Quantity per",
                            FromUoMCode,
                            'KG');

                        MaterialResolver.ResolveFromLoadedMaterials(
                            Materials,
                            ProductionBOMLine."No.",
                            ProductionBOMLine."Variant Code",
                            ProktekCode,
                            ProktekUUID,
                            ProktekName,
                            ProktekType);

                        Clear(MaterialJson);
                        MaterialJson.Add('id', 0);
                        MaterialJson.Add('recete_kod', 0);
                        MaterialJson.Add('recete_ad', ProductionBOMHeader.Description);
                        MaterialJson.Add('malzeme_kod', ProktekCode);
                        MaterialJson.Add('malzeme_uuid', Format(ProktekUUID, 0, 4));
                        MaterialJson.Add('malzeme_ad', ProktekName);
                        MaterialJson.Add('type', ProktekType);
                        MaterialJson.Add('miktar', QuantityKg);
                        Clear(PlantIds);
                        PlantIds.Add(1);
                        MaterialJson.Add('santral_id', PlantIds);
                        RecipeMaterials.Add(MaterialJson);
                        LineCount += 1;
                    end;
                ProductionBOMLine.Type::"Production BOM":
                    Error(NestedBomNotSupportedErr, ProductionBOMNo, ProductionBOMLine."Line No.", ProductionBOMLine."No.");
            end;
        until ProductionBOMLine.Next() = 0;

        if LineCount = 0 then
            Error(NoItemLinesErr, ProductionBOMNo);

        // This slice intentionally previews only the API recipe-material array.
        // Formula identity/header fields (recete_index, uuid, recete_kod, recete_grup, etc.)
        // are resolved in the next slice; no SAVE-FORMULA call is made here.
        PreviewJson.Add('erp_kod', ProductionBOMHeader."No.");
        PreviewJson.Add('ad', ProductionBOMHeader.Description);
        PreviewJson.Add('recete_malzeme', RecipeMaterials);
        PreviewJson.WriteTo(ResultJson);
        exit(ResultJson);
    end;

    procedure BuildFormulaSaveRequest(
        SessionGuid: Guid;
        ItemNo: Code[20];
        VariantCode: Code[10];
        ProductionBOMNo: Code[20];
        ProktekFormulaIndex: BigInteger;
        ProktekFormulaUUID: Guid): Text
    var
        RootJson: JsonObject;
        FormulaJson: JsonObject;
        RecipeMaterials: JsonArray;
        PlantIds: JsonArray;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionBOMHeader: Record "Production BOM Header";
        FormulaCode: Text;
        FormulaName: Text;
        ResultJson: Text;
        NullGuid: Guid;
        TotalWeightKg: Decimal;
        WaterWeightKg: Decimal;
        CementWeightKg: Decimal;
        WaterCementRatio: Decimal;
    begin
        Item.Get(ItemNo);
        ProductionBOMHeader.Get(ProductionBOMNo);

        if VariantCode = '' then
            FormulaName := ProductionBOMHeader.Description
        else begin
            ItemVariant.Get(ItemNo, VariantCode);
            FormulaName := ItemVariant.Description;
            if FormulaName = '' then
                FormulaName := ProductionBOMHeader.Description;
        end;

        if FormulaName = '' then
            FormulaName := Item.Description;

        FormulaCode := BuildFormulaIntegrationKey(ItemNo, VariantCode);
        RecipeMaterials := BuildFormulaMaterialsArray(
            ProductionBOMNo,
            FormulaName,
            TotalWeightKg,
            WaterWeightKg,
            CementWeightKg);

        if CementWeightKg > 0 then
            WaterCementRatio := Round(WaterWeightKg / CementWeightKg, 0.1, '=');

        RootJson.Add('guid', Format(SessionGuid, 0, 4));

        FormulaJson.Add('recete_index', ProktekFormulaIndex);
        if ProktekFormulaUUID = NullGuid then
            FormulaJson.Add('uuid', Format(NullGuid, 0, 4))
        else
            FormulaJson.Add('uuid', Format(ProktekFormulaUUID, 0, 4));
        FormulaJson.Add('recete_kod', FormulaCode);
        FormulaJson.Add('erp_kod', ProductionBOMNo);
        FormulaJson.Add('ad', FormulaName);

        // Confirmed by differential testing against a Formula created by Proktek Desktop.
        // Sparse API payloads are accepted by the backend but are not Desktop-compatible.
        AddDesktopCompatibleFormulaDefaults(FormulaJson, WaterCementRatio, TotalWeightKg);

        FormulaJson.Add('aktif', true);
        Clear(PlantIds);
        PlantIds.Add(1);
        FormulaJson.Add('santral_id', PlantIds);
        FormulaJson.Add('recete_grup', Item.Description);
        FormulaJson.Add('tasarlanmis', true);
        FormulaJson.Add('silindi', false);
        FormulaJson.Add('recete_malzeme', RecipeMaterials);

        RootJson.Add('formula', FormulaJson);
        RootJson.WriteTo(ResultJson);
        exit(ResultJson);
    end;

    procedure BuildRecipeFormulaSaveRequest(
        SessionGuid: Guid;
        Recipe: Record "SI Concrete Recipe";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        ProktekFormulaIndex: BigInteger;
        ProktekFormulaUUID: Guid;
        FormulaActive: Boolean): Text
    var
        RootJson: JsonObject;
        FormulaJson: JsonObject;
        RecipeMaterials: JsonArray;
        PlantIds: JsonArray;
        Item: Record Item;
        FormulaCode: Text;
        FormulaName: Text;
        ResultJson: Text;
        NullGuid: Guid;
        TotalWeightKg: Decimal;
        WaterWeightKg: Decimal;
        CementWeightKg: Decimal;
        WaterCementRatio: Decimal;
    begin
        Recipe.TestField("Recipe No.");
        Recipe.TestField("Item No.");
        Recipe.TestField("Production BOM No.");
        RecipeRevision.TestField("Recipe No.", Recipe."Recipe No.");
        RecipeRevision.TestField("Production BOM Version Code");
        Item.Get(Recipe."Item No.");

        FormulaName := Recipe.Description;
        if FormulaName = '' then
            FormulaName := Item.Description;
        FormulaName := StrSubstNo('%1 v.%2', FormulaName, RecipeRevision."Revision No.");
        FormulaCode := BuildRecipeFormulaIntegrationKey(Recipe."Recipe No.", RecipeRevision."Revision No.");

        RecipeMaterials := BuildRecipeMaterialsArray(
            Recipe,
            RecipeRevision,
            FormulaName,
            TotalWeightKg,
            WaterWeightKg,
            CementWeightKg);

        if CementWeightKg > 0 then
            WaterCementRatio := Round(WaterWeightKg / CementWeightKg, 0.1, '=');

        RootJson.Add('guid', Format(SessionGuid, 0, 4));
        FormulaJson.Add('recete_index', ProktekFormulaIndex);
        if ProktekFormulaUUID = NullGuid then
            FormulaJson.Add('uuid', Format(NullGuid, 0, 4))
        else
            FormulaJson.Add('uuid', Format(ProktekFormulaUUID, 0, 4));
        FormulaJson.Add('recete_kod', FormulaCode);
        FormulaJson.Add('erp_kod', Recipe."Production BOM No.");
        FormulaJson.Add('ad', FormulaName);

        AddDesktopCompatibleFormulaDefaults(FormulaJson, WaterCementRatio, TotalWeightKg);
        FormulaJson.Add('aktif', FormulaActive);
        Clear(PlantIds);
        PlantIds.Add(1);
        FormulaJson.Add('santral_id', PlantIds);
        FormulaJson.Add('recete_grup', Item.Description);
        FormulaJson.Add('tasarlanmis', true);
        FormulaJson.Add('silindi', false);
        FormulaJson.Add('recete_malzeme', RecipeMaterials);

        RootJson.Add('formula', FormulaJson);
        RootJson.WriteTo(ResultJson);
        exit(ResultJson);
    end;

    procedure BuildRecipeFormulaIntegrationKey(RecipeNo: Code[50]; RevisionNo: Integer): Text
    var
        Recipe: Record "SI Concrete Recipe";
        ProductName: Text[100];
    begin
        if RecipeNo = '' then
            Error('Recipe No. must be specified for Formula integration key.');
        if RevisionNo <= 0 then
            Error('Recipe Revision No. must be greater than zero.');

        Recipe.Get(RecipeNo);
        ProductName := Recipe.Description;
        if ProductName = '' then
            Error('Для рецептури %1 не визначено коротку назву продукту.', RecipeNo);

        exit(StrSubstNo('%1|R%2', ProductName, RevisionNo));
    end;

    local procedure BuildRecipeMaterialsArray(
        Recipe: Record "SI Concrete Recipe";
        RecipeRevision: Record "SI Concrete Recipe Revision";
        FormulaName: Text;
        var TotalWeightKg: Decimal;
        var WaterWeightKg: Decimal;
        var CementWeightKg: Decimal): JsonArray
    var
        RecipeLine: Record "SI Concrete Recipe Line";
        Item: Record Item;
        ItemUoMConversion: Codeunit "SI Item UoM Conversion";
        MaterialResolver: Codeunit "SI Prok Material Resolver";
        Materials: JsonArray;
        RecipeMaterials: JsonArray;
        MaterialJson: JsonObject;
        PlantIds: JsonArray;
        FromUoMCode: Code[10];
        QuantityPerOutput: Decimal;
        QuantityKg: Decimal;
        ProktekCode: BigInteger;
        ProktekUUID: Guid;
        ProktekName: Text;
        ProktekType: Text;
        LineCount: Integer;
    begin
        TotalWeightKg := 0;
        WaterWeightKg := 0;
        CementWeightKg := 0;
        if Recipe."Output Quantity" <= 0 then
            Error('Рецептура %1 має некоректну вихідну кількість.', Recipe."Recipe No.");

        MaterialResolver.LoadMaterials(Materials);
        RecipeLine.SetRange("Recipe No.", RecipeRevision."Recipe No.");
        RecipeLine.SetRange("Revision No.", RecipeRevision."Revision No.");
        if not RecipeLine.FindSet() then
            Error('Ревізія %1 рецептури %2 не містить рядків.', RecipeRevision."Revision No.", RecipeRevision."Recipe No.");

        repeat
            RecipeLine.TestField("Item No.");
            RecipeLine.TestField(Quantity);
            Item.Get(RecipeLine."Item No.");
            FromUoMCode := RecipeLine."Unit of Measure Code";
            if FromUoMCode = '' then
                FromUoMCode := Item."Base Unit of Measure";
            if FromUoMCode = '' then
                Error('Для компонента %1 не визначено вихідну одиницю виміру.', RecipeLine."Item No.");

            QuantityPerOutput := RecipeLine.Quantity / Recipe."Output Quantity";
            QuantityKg := ItemUoMConversion.ConvertItemQuantity(
                RecipeLine."Item No.",
                RecipeLine."Variant Code",
                QuantityPerOutput,
                FromUoMCode,
                'KG');

            MaterialResolver.ResolveFromLoadedMaterials(
                Materials,
                RecipeLine."Item No.",
                RecipeLine."Variant Code",
                ProktekCode,
                ProktekUUID,
                ProktekName,
                ProktekType);

            TotalWeightKg += QuantityKg;
            case LowerCase(ProktekType) of
                'su': WaterWeightKg += QuantityKg;
                'cimento': CementWeightKg += QuantityKg;
            end;

            Clear(MaterialJson);
            MaterialJson.Add('id', 0);
            MaterialJson.Add('recete_kod', 0);
            MaterialJson.Add('recete_ad', FormulaName);
            MaterialJson.Add('malzeme_kod', ProktekCode);
            MaterialJson.Add('malzeme_uuid', Format(ProktekUUID, 0, 4));
            MaterialJson.Add('malzeme_ad', ProktekName);
            MaterialJson.Add('type', ProktekType);
            MaterialJson.Add('miktar', QuantityKg);
            Clear(PlantIds);
            PlantIds.Add(1);
            MaterialJson.Add('santral_id', PlantIds);
            RecipeMaterials.Add(MaterialJson);
            LineCount += 1;
        until RecipeLine.Next() = 0;

        if LineCount = 0 then
            Error('Ревізія %1 рецептури %2 не містить матеріальних рядків.', RecipeRevision."Revision No.", RecipeRevision."Recipe No.");

        exit(RecipeMaterials);
    end;

    procedure BuildFormulaIntegrationKey(ItemNo: Code[20]; VariantCode: Code[10]): Text
    begin
        if ItemNo = '' then
            Error('Item No. must be specified for Formula integration key.');
        if VariantCode = '' then
            exit(ItemNo);
        exit(StrSubstNo('%1|%2', ItemNo, VariantCode));
    end;

    local procedure BuildFormulaMaterialsArray(
        ProductionBOMNo: Code[20];
        FormulaName: Text;
        var TotalWeightKg: Decimal;
        var WaterWeightKg: Decimal;
        var CementWeightKg: Decimal): JsonArray
    var
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        ItemUoMConversion: Codeunit "SI Item UoM Conversion";
        MaterialResolver: Codeunit "SI Prok Material Resolver";
        Materials: JsonArray;
        RecipeMaterials: JsonArray;
        MaterialJson: JsonObject;
        PlantIds: JsonArray;
        FromUoMCode: Code[10];
        QuantityKg: Decimal;
        ProktekCode: BigInteger;
        ProktekUUID: Guid;
        ProktekName: Text;
        ProktekType: Text;
        LineCount: Integer;
    begin
        TotalWeightKg := 0;
        WaterWeightKg := 0;
        CementWeightKg := 0;

        if ProductionBOMNo = '' then
            Error(ProductionBOMRequiredErr);

        MaterialResolver.LoadMaterials(Materials);
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.SetRange("Version Code", '');
        if not ProductionBOMLine.FindSet() then
            Error(NoBomLinesErr, ProductionBOMNo);

        repeat
            case ProductionBOMLine.Type of
                ProductionBOMLine.Type::Item:
                    begin
                        Item.Get(ProductionBOMLine."No.");
                        FromUoMCode := ProductionBOMLine."Unit of Measure Code";
                        if FromUoMCode = '' then
                            FromUoMCode := Item."Base Unit of Measure";
                        if FromUoMCode = '' then
                            Error(NoSourceUoMErr, ProductionBOMLine."No.", ProductionBOMLine."Line No.");

                        QuantityKg := ItemUoMConversion.ConvertItemQuantity(
                            ProductionBOMLine."No.",
                            ProductionBOMLine."Variant Code",
                            ProductionBOMLine."Quantity per",
                            FromUoMCode,
                            'KG');

                        MaterialResolver.ResolveFromLoadedMaterials(
                            Materials,
                            ProductionBOMLine."No.",
                            ProductionBOMLine."Variant Code",
                            ProktekCode,
                            ProktekUUID,
                            ProktekName,
                            ProktekType);

                        TotalWeightKg += QuantityKg;
                        case LowerCase(ProktekType) of
                            'su':
                                WaterWeightKg += QuantityKg;
                            'cimento':
                                CementWeightKg += QuantityKg;
                        end;

                        Clear(MaterialJson);
                        MaterialJson.Add('id', 0);
                        MaterialJson.Add('recete_kod', 0);
                        MaterialJson.Add('recete_ad', FormulaName);
                        MaterialJson.Add('malzeme_kod', ProktekCode);
                        MaterialJson.Add('malzeme_uuid', Format(ProktekUUID, 0, 4));
                        MaterialJson.Add('malzeme_ad', ProktekName);
                        MaterialJson.Add('type', ProktekType);
                        MaterialJson.Add('miktar', QuantityKg);
                        Clear(PlantIds);
                        PlantIds.Add(1);
                        MaterialJson.Add('santral_id', PlantIds);
                        RecipeMaterials.Add(MaterialJson);
                        LineCount += 1;
                    end;
                ProductionBOMLine.Type::"Production BOM":
                    Error(NestedBomNotSupportedErr, ProductionBOMNo, ProductionBOMLine."Line No.", ProductionBOMLine."No.");
            end;
        until ProductionBOMLine.Next() = 0;

        if LineCount = 0 then
            Error(NoItemLinesErr, ProductionBOMNo);

        exit(RecipeMaterials);
    end;

    local procedure AddDesktopCompatibleFormulaDefaults(
        var FormulaJson: JsonObject;
        WaterCementRatio: Decimal;
        TotalWeightKg: Decimal)
    var
        NullValue: JsonValue;
    begin
        // recete_malzeme[] is authoritative; legacy material slots remain zero.
        FormulaJson.Add('agrega1', 0);
        FormulaJson.Add('agrega2', 0);
        FormulaJson.Add('agrega3', 0);
        FormulaJson.Add('agrega4', 0);
        FormulaJson.Add('agrega5', 0);
        FormulaJson.Add('agrega6', 0);
        FormulaJson.Add('agrega7', 0);
        FormulaJson.Add('agrega8', 0);
        FormulaJson.Add('cimento1', 0);
        FormulaJson.Add('cimento2', 0);
        FormulaJson.Add('cimento3', 0);
        FormulaJson.Add('cimento4', 0);
        FormulaJson.Add('cimento5', 0);
        FormulaJson.Add('cimento6', 0);
        FormulaJson.Add('su1', 0);
        FormulaJson.Add('su2', 0);
        FormulaJson.Add('katki1', 0);
        FormulaJson.Add('katki2', 0);
        FormulaJson.Add('kul', 0);
        FormulaJson.Add('boya', 0);
        FormulaJson.Add('buz', 0);
        FormulaJson.Add('toz', 0);
        FormulaJson.Add('yedek', 0);
        FormulaJson.Add('agrega1_hassas', 0);
        FormulaJson.Add('agrega2_hassas', 0);
        FormulaJson.Add('agrega3_hassas', 0);
        FormulaJson.Add('agrega4_hassas', 0);
        FormulaJson.Add('agrega5_hassas', 0);
        FormulaJson.Add('agrega6_hassas', 0);
        FormulaJson.Add('agrega7_hassas', 0);
        FormulaJson.Add('agrega8_hassas', 0);
        FormulaJson.Add('mikser_kar_sur', 0);
        FormulaJson.Add('mikser_bos_sur', 0);
        FormulaJson.Add('mikser_kad_bek', 10);
        FormulaJson.Add('mikser_kad_uyg', 10);

        // Proktek Desktop persists empty strings for these optional text fields.
        FormulaJson.Add('slump', '');
        FormulaJson.Add('granulite', '');
        FormulaJson.Add('mukavemet', '');
        FormulaJson.Add('recete_aciklama1', '');
        FormulaJson.Add('recete_aciklama2', '');
        FormulaJson.Add('recete_aciklama3', '');
        FormulaJson.Add('recete_aciklama4', '');

        // Derived values. The ratio follows the Desktop-observed water/cement convention.
        FormulaJson.Add('sucimorani', WaterCementRatio);
        FormulaJson.Add('toplam_agirlik', TotalWeightKg);
        FormulaJson.Add('sabit_mikser_kapasite', 2);

        FormulaJson.Add('agrega9', 0);
        FormulaJson.Add('agrega10', 0);
        FormulaJson.Add('agrega9_hassas', 0);
        FormulaJson.Add('agrega10_hassas', 0);
        FormulaJson.Add('katki3', 0);
        FormulaJson.Add('katki4', 0);
        FormulaJson.Add('katki6', 0);
        FormulaJson.Add('su1_hassas', 0);
        FormulaJson.Add('su2_hassas', 0);
        FormulaJson.Add('cimento3_crp', 1);
        FormulaJson.Add('cimento4_crp', 1);
        FormulaJson.Add('cimento5_crp', 1);
        FormulaJson.Add('cimento6_crp', 0);

        FormulaJson.Add('sistem', 1);
        FormulaJson.Add('mikser_nem', 1);
        FormulaJson.Add('kirli_su_yuzde', 0);

        Clear(NullValue);
        NullValue.SetValueToNull();
        FormulaJson.Add('ek1_uuid', NullValue);
        FormulaJson.Add('ek1_ad', '');
        Clear(NullValue);
        NullValue.SetValueToNull();
        FormulaJson.Add('ek2_uuid', NullValue);
        FormulaJson.Add('ek2_ad', '');

        FormulaJson.Add('aktarildi', true);
        FormulaJson.Add('gbelge', true);
        FormulaJson.Add('lifler', '');
        FormulaJson.Add('ozel_nitelikler', '');
    end;

    local procedure BuildProjection(ProductionBOMNo: Code[20]; ResolveMaterials: Boolean): Text
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        ItemUoMConversion: Codeunit "SI Item UoM Conversion";
        MaterialResolver: Codeunit "SI Prok Material Resolver";
        Materials: JsonArray;
        ResultText: Text;
        FromUoMCode: Code[10];
        QuantityKg: Decimal;
        LineCount: Integer;
        TotalKg: Decimal;
        ProktekCode: BigInteger;
        ProktekUUID: Guid;
        ProktekName: Text;
        ProktekType: Text;
        IntegrationKey: Text;
        CR: Char;
        LF: Char;
        NewLine: Text[2];
    begin
        if ProductionBOMNo = '' then
            Error(ProductionBOMRequiredErr);

        ProductionBOMHeader.Get(ProductionBOMNo);

        if ResolveMaterials then
            MaterialResolver.LoadMaterials(Materials);

        CR := 13;
        LF := 10;
        NewLine := Format(CR) + Format(LF);

        ResultText := StrSubstNo('Production BOM: %1 - %2', ProductionBOMHeader."No.", ProductionBOMHeader.Description) + NewLine;
        if ResolveMaterials then
            ResultText += 'Projection target: KG + Proktek Material identity' + NewLine + NewLine
        else
            ResultText += 'Projection target: KG' + NewLine + NewLine;

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.SetRange("Version Code", '');
        if not ProductionBOMLine.FindSet() then
            Error(NoBomLinesErr, ProductionBOMNo);

        repeat
            case ProductionBOMLine.Type of
                ProductionBOMLine.Type::Item:
                    begin
                        if ProductionBOMLine."No." = '' then
                            Error(EmptyItemNoErr, ProductionBOMNo, ProductionBOMLine."Line No.");

                        Item.Get(ProductionBOMLine."No.");
                        FromUoMCode := ProductionBOMLine."Unit of Measure Code";
                        if FromUoMCode = '' then
                            FromUoMCode := Item."Base Unit of Measure";

                        if FromUoMCode = '' then
                            Error(NoSourceUoMErr, ProductionBOMLine."No.", ProductionBOMLine."Line No.");

                        QuantityKg := ItemUoMConversion.ConvertItemQuantity(
                            ProductionBOMLine."No.",
                            ProductionBOMLine."Variant Code",
                            ProductionBOMLine."Quantity per",
                            FromUoMCode,
                            'KG');

                        LineCount += 1;
                        TotalKg += QuantityKg;

                        if ResolveMaterials then begin
                            IntegrationKey := MaterialResolver.BuildMaterialIntegrationKey(
                                ProductionBOMLine."No.", ProductionBOMLine."Variant Code");
                            MaterialResolver.ResolveFromLoadedMaterials(
                                Materials,
                                ProductionBOMLine."No.",
                                ProductionBOMLine."Variant Code",
                                ProktekCode,
                                ProktekUUID,
                                ProktekName,
                                ProktekType);

                            ResultText += StrSubstNo(
                                '%1. %2 | %3 KG -> ent=%4 | kod=%5 | uuid=%6 | type=%7 | ad=%8',
                                LineCount,
                                FormatItemVariant(ProductionBOMLine."No.", ProductionBOMLine."Variant Code"),
                                QuantityKg,
                                IntegrationKey,
                                ProktekCode,
                                ProktekUUID,
                                ProktekType,
                                ProktekName) + NewLine;
                        end else
                            ResultText += StrSubstNo(
                                '%1. %2 | Variant=%3 | %4 %5 -> %6 KG',
                                LineCount,
                                ProductionBOMLine."No.",
                                FormatVariant(ProductionBOMLine."Variant Code"),
                                ProductionBOMLine."Quantity per",
                                FromUoMCode,
                                QuantityKg) + NewLine;
                    end;
                ProductionBOMLine.Type::"Production BOM":
                    Error(NestedBomNotSupportedErr, ProductionBOMNo, ProductionBOMLine."Line No.", ProductionBOMLine."No.");
            end;
        until ProductionBOMLine.Next() = 0;

        if LineCount = 0 then
            Error(NoItemLinesErr, ProductionBOMNo);

        ResultText += NewLine + StrSubstNo('Item lines: %1; Total projected weight: %2 KG', LineCount, TotalKg);
        exit(ResultText);
    end;

    local procedure FormatVariant(VariantCode: Code[10]): Text
    begin
        if VariantCode = '' then
            exit('<none>');
        exit(VariantCode);
    end;

    local procedure FormatItemVariant(ItemNo: Code[20]; VariantCode: Code[10]): Text
    begin
        if VariantCode = '' then
            exit(ItemNo);
        exit(StrSubstNo('%1 | Variant=%2', ItemNo, VariantCode));
    end;

    var
        ProductionBOMRequiredErr: Label 'Production BOM No. must be specified.';
        NoBomLinesErr: Label 'Production BOM %1 has no base-version lines.';
        NoItemLinesErr: Label 'Production BOM %1 has no item lines to project.';
        EmptyItemNoErr: Label 'Production BOM %1 line %2 has no Item No.';
        NoSourceUoMErr: Label 'Item %1 on BOM line %2 has no source unit of measure.';
        NestedBomNotSupportedErr: Label 'Production BOM %1 line %2 references nested Production BOM %3. Nested BOM expansion is intentionally not included in this acceptance slice.';
}
