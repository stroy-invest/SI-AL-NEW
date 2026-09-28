codeunit 61023 "SI Schrift Product Resolver"
{
    procedure ResolveConcreteProduct(ProductText: Text; var ItemNo: Code[20]; var VariantCode: Code[10]): Boolean
    var
        Item: Record Item;
        Variant: Record "Item Variant";
        NormalizedSource: Text;
        MatchCount: Integer;
    begin
        Clear(ItemNo);
        Clear(VariantCode);
        NormalizedSource := NormalizeConcreteName(ProductText);
        if NormalizedSource = '' then
            exit(false);

        Item.Reset();
        Item.SetFilter("Item Category Code", '<>%1', '');
        if Item.FindSet() then
            repeat
                if IsInReadyConcreteSubtree(Item."Item Category Code") then begin
                    RegisterMatch(NormalizedSource, Item.Description, Item."No.", '', MatchCount, ItemNo, VariantCode);

                    Variant.Reset();
                    Variant.SetRange("Item No.", Item."No.");
                    if Variant.FindSet() then
                        repeat
                            RegisterMatch(NormalizedSource, Variant.Description, Item."No.", Variant.Code, MatchCount, ItemNo, VariantCode);
                        until Variant.Next() = 0;
                end;
            until Item.Next() = 0;

        if MatchCount <> 1 then begin
            Clear(ItemNo);
            Clear(VariantCode);
            exit(false);
        end;

        exit(true);
    end;

    procedure NormalizeConcreteName(Value: Text): Text
    var
        Normalized: Text;
        FirstChar: Text[1];
    begin
        Normalized := UpperCase(DelChr(Value, '<>', ' '));
        if Normalized = '' then
            exit('');

        FirstChar := CopyStr(Normalized, 1, 1);
        if (FirstChar = 'C') or (FirstChar = 'С') then
            Normalized := 'C' + CopyStr(Normalized, 2);

        exit(Normalized);
    end;

    local procedure RegisterMatch(SourceName: Text; CandidateName: Text; CandidateItemNo: Code[20]; CandidateVariantCode: Code[10]; var MatchCount: Integer; var ItemNo: Code[20]; var VariantCode: Code[10])
    begin
        if NormalizeConcreteName(CandidateName) <> SourceName then
            exit;

        MatchCount += 1;
        if MatchCount = 1 then begin
            ItemNo := CandidateItemNo;
            VariantCode := CandidateVariantCode;
        end;
    end;

    local procedure IsInReadyConcreteSubtree(CategoryCode: Code[20]): Boolean
    var
        Category: Record "Item Category";
        CurrentCode: Code[20];
        Depth: Integer;
    begin
        CurrentCode := CategoryCode;
        while CurrentCode <> '' do begin
            if CurrentCode = 'READY-CONC' then
                exit(true);

            if not Category.Get(CurrentCode) then
                exit(false);

            CurrentCode := Category."Parent Category";
            Depth += 1;
            if Depth > 50 then
                exit(false);
        end;

        exit(false);
    end;
}
