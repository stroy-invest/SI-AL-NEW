codeunit 57067 "SI Prok Recipe Workspace Mgt."
{
    procedure BuildTreeJson(): Text
    var
        Item: Record Item;
        Binding: Record "SI Prok Recipe BOM Binding";
        RootKeys: Dictionary of [Text, Boolean];
        Roots: JsonArray;
    begin
        Item.SetFilter("Production BOM No.", '<>%1', '');
        if Item.FindSet() then
            repeat
                AddRoot(Roots, RootKeys, Item."Production BOM No.", Item."No.", '');
            until Item.Next() = 0;

        if Binding.FindSet() then
            repeat
                AddRoot(Roots, RootKeys, Binding."Production BOM No.", Binding."Item No.", Binding."Variant Code");
            until Binding.Next() = 0;

        exit(Format(Roots));
    end;

    procedure CreateBaseRecipe()
    var
        Dialog: Page "SI Prok Base Recipe Dialog";
        BOM: Record "Production BOM Header";
        Item: Record Item;
        Binding: Record "SI Prok Recipe BOM Binding";
        ItemNo: Code[20];
        VariantCode: Code[10];
        BOMNo: Code[20];
        RecipeDescription: Text[100];
    begin
        if Dialog.RunModal() <> Action::OK then
            exit;
        Dialog.GetValues(ItemNo, VariantCode, BOMNo, RecipeDescription);
        if BOM.Get(BOMNo) then
            Error('Production BOM %1 вже існує.', BOMNo);
        Item.Get(ItemNo);

        BOM.Init();
        BOM."No." := BOMNo;
        BOM.Description := CopyStr(RecipeDescription, 1, MaxStrLen(BOM.Description));
        BOM."Unit of Measure Code" := Item."Base Unit of Measure";
        BOM.Insert(true);

        if VariantCode = '' then begin
            Item.Validate("Production BOM No.", BOMNo);
            Item.Modify(true);
        end else begin
            Binding.Init();
            Binding."Item No." := ItemNo;
            Binding."Variant Code" := VariantCode;
            Binding."Production BOM No." := BOMNo;
            Binding.Insert(true);
        end;
        Page.Run(Page::"Production BOM", BOM);
    end;

    procedure CreateModifiedRecipe(BOMNo: Code[20])
    var
        Snapshot: Record "SI Prok Recipe Snapshot";
        ItemNo: Code[20];
        VariantCode: Code[10];
    begin
        ResolveProductForBOM(BOMNo, ItemNo, VariantCode);
        if ItemNo = '' then
            Error('Для Production BOM %1 не знайдено прив’язку до товару/варіанта.', BOMNo);

        Snapshot.Init();
        Snapshot.Validate("Item No.", ItemNo);
        if VariantCode <> '' then
            Snapshot.Validate("Variant Code", VariantCode);
        Snapshot."Production BOM No." := BOMNo;
        Snapshot.Status := Snapshot.Status::Draft;
        Snapshot.Insert(true);
        Snapshot.RefreshBaseData();
        Snapshot.Modify(true);
        Page.Run(Page::"SI Prok Recipe Snapshot Card", Snapshot);
    end;

    procedure OpenNode(NodeType: Text; NodeId: Text)
    var
        BOM: Record "Production BOM Header";
        Snapshot: Record "SI Prok Recipe Snapshot";
        EntryNo: Integer;
    begin
        case UpperCase(NodeType) of
            'BASE':
                begin
                    BOM.Get(CopyStr(NodeId, 1, MaxStrLen(BOM."No.")));
                    Page.Run(Page::"Production BOM", BOM);
                end;
            'MODIFIED':
                begin
                    Evaluate(EntryNo, NodeId);
                    Snapshot.Get(EntryNo);
                    Page.Run(Page::"SI Prok Recipe Snapshot Card", Snapshot);
                end;
        end;
    end;

    procedure ResolveProductForBOM(BOMNo: Code[20]; var ItemNo: Code[20]; var VariantCode: Code[10])
    var
        Binding: Record "SI Prok Recipe BOM Binding";
        Item: Record Item;
    begin
        Clear(ItemNo);
        Clear(VariantCode);
        Binding.SetRange("Production BOM No.", BOMNo);
        if Binding.FindFirst() then begin
            ItemNo := Binding."Item No.";
            VariantCode := Binding."Variant Code";
            exit;
        end;
        Item.SetRange("Production BOM No.", BOMNo);
        if Item.FindFirst() then
            ItemNo := Item."No.";
    end;

    local procedure AddRoot(var Roots: JsonArray; var RootKeys: Dictionary of [Text, Boolean]; BOMNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10])
    var
        BOM: Record "Production BOM Header";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Snapshot: Record "SI Prok Recipe Snapshot";
        Root: JsonObject;
        Child: JsonObject;
        Children: JsonArray;
        RootName: Text;
        StatusText: Text;
    begin
        if RootKeys.ContainsKey(BOMNo) then
            exit;
        if not BOM.Get(BOMNo) then
            exit;
        RootKeys.Add(BOMNo, true);

        RootName := BOM.Description;
        if Item.Get(ItemNo) then begin
            RootName := Item.Description;
            if VariantCode <> '' then
                if ItemVariant.Get(ItemNo, VariantCode) then
                    if ItemVariant.Description <> '' then
                        RootName := ItemVariant.Description;
        end;
        StatusText := Format(BOM.Status);

        Snapshot.SetRange("Production BOM No.", BOMNo);
        if Snapshot.FindSet() then
            repeat
                Clear(Child);
                Child.Add('type', 'MODIFIED');
                Child.Add('id', Format(Snapshot."Entry No."));
                Child.Add('code', CopyStr(Snapshot."Derived Formula Code", 1, 100));
                Child.Add('name', StrSubstNo('%1 | RS-%2', Snapshot.Description, Snapshot."Entry No."));
                Child.Add('status', Format(Snapshot.Status));
                Child.Add('typeCaption', 'Модифікована');
                Children.Add(Child);
            until Snapshot.Next() = 0;

        Root.Add('type', 'BASE');
        Root.Add('id', BOMNo);
        Root.Add('code', BOMNo);
        Root.Add('name', RootName);
        Root.Add('status', StatusText);
        Root.Add('typeCaption', 'Базова');
        Root.Add('children', Children);
        Roots.Add(Root);
    end;
}
