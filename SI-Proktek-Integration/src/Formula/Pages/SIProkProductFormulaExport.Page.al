page 57061 "SI Prok Product Formula Export"
{
    PageType = StandardDialog;
    Caption = 'Експорт Formula до Proktek';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Product)
            {
                Caption = 'BC — джерело істини';
                field(ItemNo; ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Товар';
                    TableRelation = Item."No.";
                    Editable = false;
                }
                field(VariantDescription; VariantDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Варіант';
                    Lookup = true;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemVariant: Record "Item Variant";
                    begin
                        ItemVariant.SetRange("Item No.", ItemNo);
                        if Page.RunModal(Page::"Item Variants", ItemVariant) = Action::LookupOK then begin
                            VariantCode := ItemVariant.Code;
                            VariantDescription := ItemVariant.Description;
                            RefreshPreview();
                        end;
                        exit(true);
                    end;
                }
                field(ProductionBOMNo; ProductionBOMNo)
                {
                    ApplicationArea = All;
                    Caption = 'Production BOM';
                    Editable = false;
                }
            }
            group(Header)
            {
                Caption = 'Formula Header';
                field(FormulaCode; FormulaCode) { ApplicationArea = All; Caption = 'recete_kod'; Editable = false; }
                field(FormulaGroup; FormulaGroup) { ApplicationArea = All; Caption = 'recete_grup'; Editable = false; }
                field(FormulaName; FormulaName) { ApplicationArea = All; Caption = 'ad'; Editable = false; }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        FormulaSync: Codeunit "SI Prok Formula Sync";
    begin
        if CloseAction <> Action::OK then
            exit(true);
        RefreshPreview();
        FormulaSync.ExportFormula(ItemNo, VariantCode, ProductionBOMNo);
        exit(true);
    end;

    procedure SetItem(NewItemNo: Code[20])
    begin
        ItemNo := NewItemNo;
        Clear(VariantCode);
        Clear(VariantDescription);
        TryResolveSingleVariant();
        RefreshPreview();
    end;

    local procedure TryResolveSingleVariant()
    var
        ItemVariant: Record "Item Variant";
        CandidateCode: Code[10];
    begin
        ItemVariant.SetRange("Item No.", ItemNo);
        if not ItemVariant.FindFirst() then
            exit;
        CandidateCode := ItemVariant.Code;
        if ItemVariant.Next() <> 0 then
            exit;
        if ItemVariant.Get(ItemNo, CandidateCode) then begin
            VariantCode := ItemVariant.Code;
            VariantDescription := ItemVariant.Description;
        end;
    end;

    local procedure RefreshPreview()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        BOMResolver: Codeunit "SI Prok Product BOM Resolver";
        FormulaProjector: Codeunit "SI Prok Formula Projector";
    begin
        Item.Get(ItemNo);
        ProductionBOMNo := BOMResolver.ResolveProductionBOM(ItemNo, VariantCode);
        FormulaCode := FormulaProjector.BuildFormulaIntegrationKey(ItemNo, VariantCode);
        FormulaGroup := Item.Description;
        FormulaName := Item.Description;
        if VariantCode <> '' then begin
            ItemVariant.Get(ItemNo, VariantCode);
            if ItemVariant.Description <> '' then
                FormulaName := ItemVariant.Description;
        end;
    end;

    var
        ItemNo: Code[20];
        VariantCode: Code[10];
        VariantDescription: Text[100];
        ProductionBOMNo: Code[20];
        FormulaCode: Text[100];
        FormulaGroup: Text[100];
        FormulaName: Text[100];
}
