page 57062 "SI Prok Formula Payload"
{
    PageType = StandardDialog;
    Caption = 'Proktek — бойовий Formula JSON';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Context)
            {
                Caption = 'BC — контекст Formula';

                field(ProductionBOMNo; ProductionBOMNo)
                {
                    ApplicationArea = All;
                    Caption = 'Production BOM';
                    Editable = false;
                }
                field(ItemNo; ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Товар';
                    TableRelation = Item."No.";

                    trigger OnValidate()
                    begin
                        ClearVariant();
                        TryResolveSingleVariant();
                        RefreshPreview();
                    end;
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
                        if ItemNo = '' then
                            Error('Спочатку вкажіть товар.');

                        ItemVariant.SetRange("Item No.", ItemNo);
                        if VariantCode <> '' then
                            ItemVariant.SetRange(Code, VariantCode);

                        if Page.RunModal(Page::"Item Variants", ItemVariant) = Action::LookupOK then begin
                            SetVariant(ItemVariant);
                            RefreshPreview();
                        end;

                        exit(true);
                    end;

                    trigger OnValidate()
                    var
                        ItemVariant: Record "Item Variant";
                        SelectedCode: Code[10];
                    begin
                        if VariantDescription = '' then begin
                            ClearVariant();
                            RefreshPreview();
                            exit;
                        end;

                        if ItemNo = '' then
                            Error('Спочатку вкажіть товар.');

                        ItemVariant.SetRange("Item No.", ItemNo);
                        ItemVariant.SetRange(Description, VariantDescription);
                        if not ItemVariant.FindFirst() then
                            Error('Для товару %1 немає варіанта з назвою "%2".', ItemNo, VariantDescription);

                        SelectedCode := ItemVariant.Code;
                        if ItemVariant.Next() <> 0 then
                            Error('Для товару %1 знайдено кілька варіантів з назвою "%2". Виберіть варіант через lookup.', ItemNo, VariantDescription);

                        if not ItemVariant.Get(ItemNo, SelectedCode) then
                            Error('Не вдалося прочитати вибраний варіант %1 товару %2.', SelectedCode, ItemNo);

                        SetVariant(ItemVariant);
                        RefreshPreview();
                    end;
                }
            }
            group(FormulaHeader)
            {
                Caption = 'Formula Header';

                field(FormulaCode; FormulaCode)
                {
                    ApplicationArea = All;
                    Caption = 'recete_kod';
                    Editable = false;
                }
                field(FormulaGroup; FormulaGroup)
                {
                    ApplicationArea = All;
                    Caption = 'recete_grup';
                    Editable = false;
                }
                field(FormulaName; FormulaName)
                {
                    ApplicationArea = All;
                    Caption = 'ad';
                    Editable = false;
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        FormulaSync: Codeunit "SI Prok Formula Sync";
        Payload: Text;
    begin
        if CloseAction <> Action::OK then
            exit(true);

        if ItemNo = '' then
            Error('Не вказано товар.');

        Payload := FormulaSync.BuildFormulaSavePayloadPreview(ItemNo, VariantCode, ProductionBOMNo);
        Message('%1', Payload);
        exit(true);
    end;

    procedure SetContext(NewProductionBOMNo: Code[20])
    begin
        ProductionBOMNo := NewProductionBOMNo;
        TryResolveSingleItem();
        TryResolveSingleVariant();
        RefreshPreview();
    end;

    local procedure TryResolveSingleItem()
    var
        Item: Record Item;
        CandidateNo: Code[20];
    begin
        Item.SetRange("Production BOM No.", ProductionBOMNo);
        if not Item.FindFirst() then
            exit;
        CandidateNo := Item."No.";
        if Item.Next() <> 0 then
            exit;
        ItemNo := CandidateNo;
    end;

    local procedure TryResolveSingleVariant()
    var
        ItemVariant: Record "Item Variant";
        CandidateCode: Code[10];
    begin
        ClearVariant();
        if ItemNo = '' then
            exit;

        ItemVariant.SetRange("Item No.", ItemNo);
        if not ItemVariant.FindFirst() then
            exit;

        CandidateCode := ItemVariant.Code;
        if ItemVariant.Next() <> 0 then
            exit;

        if ItemVariant.Get(ItemNo, CandidateCode) then
            SetVariant(ItemVariant);
    end;

    local procedure SetVariant(ItemVariant: Record "Item Variant")
    begin
        VariantCode := ItemVariant.Code;
        VariantDescription := ItemVariant.Description;
    end;

    local procedure ClearVariant()
    begin
        Clear(VariantCode);
        Clear(VariantDescription);
    end;

    local procedure RefreshPreview()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        FormulaProjector: Codeunit "SI Prok Formula Projector";
    begin
        Clear(FormulaCode);
        Clear(FormulaGroup);
        Clear(FormulaName);
        if ItemNo = '' then
            exit;
        if not Item.Get(ItemNo) then
            exit;

        FormulaCode := FormulaProjector.BuildFormulaIntegrationKey(ItemNo, VariantCode);
        FormulaGroup := Item.Description;
        FormulaName := Item.Description;
        if VariantCode <> '' then
            if ItemVariant.Get(ItemNo, VariantCode) then
                if ItemVariant.Description <> '' then
                    FormulaName := ItemVariant.Description;
    end;

    var
        ProductionBOMNo: Code[20];
        ItemNo: Code[20];
        VariantCode: Code[10];
        VariantDescription: Text[100];
        FormulaCode: Text[100];
        FormulaGroup: Text[100];
        FormulaName: Text[100];
}
