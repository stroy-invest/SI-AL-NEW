codeunit 53013 "SI ERP Variant Materializer"
{
    Permissions =
        tabledata "Item Variant" = RIM,
        tabledata "SI ERP Variant No. Counter" = RIM;

    procedure FindOrCreate(
        ItemNo: Code[20];
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ItemVariant: Record "Item Variant"): Boolean
    var
        VariantNoMgt: Codeunit "SI ERP Variant No. Mgt.";
        VariantCode: Code[10];
    begin
        Clear(ItemVariant);

        if PrevBuffer."Variant Projection Key" = '' then
            exit(false);

        // A previously materialized projection keeps its assigned technical code permanently.
        if PrevBuffer."Existing Variant Code" <> '' then begin
            ItemVariant.Get(ItemNo, PrevBuffer."Existing Variant Code");
            exit(false);
        end;

        VariantCode := VariantNoMgt.GetNextCode(ItemNo);

        ItemVariant.Init();
        ItemVariant.Validate("Item No.", ItemNo);
        ItemVariant.Validate(Code, VariantCode);
        ItemVariant.Validate(
            Description,
            CopyStr(
                PrevBuffer."Generated Variant Description",
                1,
                MaxStrLen(ItemVariant.Description)));
        ItemVariant.Insert(true);

        exit(true);
    end;
}
