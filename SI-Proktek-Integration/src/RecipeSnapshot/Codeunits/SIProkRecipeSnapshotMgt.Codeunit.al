codeunit 57064 "SI Prok Recipe Snapshot Mgt."
{
    procedure BuildDerivedFormulaPreview(SnapshotEntryNo: Integer): Text
    var
        NullGuid: Guid;
    begin
        exit(BuildDerivedFormulaSaveRequest(NullGuid, SnapshotEntryNo, 0, NullGuid));
    end;

    procedure BuildDerivedFormulaSaveRequest(
        SessionGuid: Guid;
        SnapshotEntryNo: Integer;
        FormulaIndex: BigInteger;
        FormulaUUID: Guid): Text
    var
        Snapshot: Record "SI Prok Recipe Snapshot";
        SnapshotLine: Record "SI Prok Recipe Snapshot Line";
        FormulaProjector: Codeunit "SI Prok Formula Projector";
        ItemUoMConversion: Codeunit "SI Item UoM Conversion";
        MaterialResolver: Codeunit "SI Prok Material Resolver";
        RootJson: JsonObject;
        FormulaJson: JsonObject;
        MaterialsToken: JsonToken;
        FormulaToken: JsonToken;
        RecipeMaterials: JsonArray;
        LoadedMaterials: JsonArray;
        MaterialJson: JsonObject;
        PlantIds: JsonArray;
        BaseRequest: Text;
        ResultJson: Text;
        FormulaName: Text[100];
        DerivedFormulaCode: Text[150];
        FromUoMCode: Code[10];
        QuantityKg: Decimal;
        ProktekCode: BigInteger;
        ProktekUUID: Guid;
        ProktekName: Text;
        ProktekType: Text;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        Snapshot.Get(SnapshotEntryNo);
        Snapshot.RefreshBaseData();
        Snapshot.Modify();

        Item.Get(Snapshot."Item No.");
        FormulaName := Snapshot.Description;
        if FormulaName = '' then begin
            if Snapshot."Variant Code" <> '' then begin
                ItemVariant.Get(Snapshot."Item No.", Snapshot."Variant Code");
                FormulaName := ItemVariant.Description;
            end;
            if FormulaName = '' then
                FormulaName := Item.Description;
        end;

        DerivedFormulaCode := Snapshot."Derived Formula Code";
        if DerivedFormulaCode = '' then
            DerivedFormulaCode := CopyStr(
                StrSubstNo('%1|RS-%2', Snapshot."Base Formula Code", Snapshot."Entry No."),
                1,
                MaxStrLen(DerivedFormulaCode));

        BaseRequest := FormulaProjector.BuildFormulaSaveRequest(
            SessionGuid,
            Snapshot."Item No.",
            Snapshot."Variant Code",
            Snapshot."Production BOM No.",
            FormulaIndex,
            FormulaUUID);

        RootJson.ReadFrom(BaseRequest);
        if not RootJson.Get('formula', FormulaToken) then
            Error('Formula JSON не містить вузол formula.');
        FormulaJson := FormulaToken.AsObject();

        FormulaJson.Remove('recete_kod');
        FormulaJson.Add('recete_kod', DerivedFormulaCode);
        FormulaJson.Remove('ad');
        FormulaJson.Add('ad', FormulaName);

        if not FormulaJson.Get('recete_malzeme', MaterialsToken) then
            Error('Formula JSON не містить recete_malzeme.');
        RecipeMaterials := MaterialsToken.AsArray();

        MaterialResolver.LoadMaterials(LoadedMaterials);
        SnapshotLine.SetRange("Snapshot Entry No.", SnapshotEntryNo);
        if SnapshotLine.FindSet() then
            repeat
                if SnapshotLine."Item No." = '' then
                    Error('У snapshot %1 рядок %2 не містить матеріалу.', SnapshotEntryNo, SnapshotLine."Line No.");
                if SnapshotLine.Quantity <= 0 then
                    Error('У snapshot %1 рядок %2 має некоректну кількість.', SnapshotEntryNo, SnapshotLine."Line No.");

                FromUoMCode := SnapshotLine."Unit of Measure Code";
                if FromUoMCode = '' then begin
                    Item.Get(SnapshotLine."Item No.");
                    FromUoMCode := Item."Base Unit of Measure";
                end;

                QuantityKg := ItemUoMConversion.ConvertItemQuantity(
                    SnapshotLine."Item No.",
                    SnapshotLine."Variant Code",
                    SnapshotLine.Quantity,
                    FromUoMCode,
                    'KG');

                MaterialResolver.ResolveFromLoadedMaterials(
                    LoadedMaterials,
                    SnapshotLine."Item No.",
                    SnapshotLine."Variant Code",
                    ProktekCode,
                    ProktekUUID,
                    ProktekName,
                    ProktekType);

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
            until SnapshotLine.Next() = 0;

        FormulaJson.Remove('recete_malzeme');
        FormulaJson.Add('recete_malzeme', RecipeMaterials);
        RootJson.Remove('formula');
        RootJson.Add('formula', FormulaJson);
        RootJson.WriteTo(ResultJson);
        exit(ResultJson);
    end;
}
