page 61041 "SI VSC Resolver Test"
{
    Caption = 'Тест визначення каналів постачання';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(Input)
            {
                Caption = 'Параметри потреби';

                field(ProductDisplayName; ProductDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Продукт';
                    Editable = false;
                    AssistEdit = true;
                    ToolTip = 'Виберіть товар або варіант через системний Product Selector.';

                    trigger OnAssistEdit()
                    begin
                        SelectProduct();
                    end;
                }
                field(RequiredQty; RequiredQty)
                {
                    ApplicationArea = All;
                    Caption = 'Кількість потреби';
                    DecimalPlaces = 0 : 5;
                }
                field(UoMCode; UoMCode)
                {
                    ApplicationArea = All;
                    Caption = 'Од. виміру';
                    TableRelation = "Unit of Measure".Code;
                }
                field(RequiredDate; RequiredDate)
                {
                    ApplicationArea = All;
                    Caption = 'Потрібно на дату';
                }
                field(ManufacturerName; ManufacturerName)
                {
                    ApplicationArea = All;
                    Caption = 'Виробник';
                    Editable = false;
                    AssistEdit = true;
                    ToolTip = 'Необов''язкове обмеження за виробником. Порожнє значення означає будь-якого виробника.';

                    trigger OnAssistEdit()
                    begin
                        SelectManufacturer();
                    end;
                }
            }
            group(Diagnostics)
            {
                Caption = 'Технічний контекст';
                Visible = ShowDiagnostics;

                field(ItemNo; ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    Editable = false;
                }
                field(VariantCode; VariantCode)
                {
                    ApplicationArea = All;
                    Caption = 'Variant Code';
                    Editable = false;
                }
                field(ManufacturerCode; ManufacturerCode)
                {
                    ApplicationArea = All;
                    Caption = 'Manufacturer Code';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectProductAction)
            {
                ApplicationArea = All;
                Caption = 'Вибрати продукт';
                Image = SelectEntries;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    SelectProduct();
                end;
            }
            action(ClearProduct)
            {
                ApplicationArea = All;
                Caption = 'Очистити продукт';
                Image = ClearFilter;

                trigger OnAction()
                begin
                    Clear(ItemNo);
                    Clear(VariantCode);
                    Clear(ProductDisplayName);
                    CurrPage.Update(false);
                end;
            }
            action(ClearManufacturer)
            {
                ApplicationArea = All;
                Caption = 'Будь-який виробник';
                Image = ClearFilter;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Clear(ManufacturerCode);
                    Clear(ManufacturerName);
                    CurrPage.Update(false);
                end;
            }
            action(Resolve)
            {
                ApplicationArea = All;
                Caption = 'Визначити канали';
                Image = Suggest;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Resolver: Codeunit "SI VSC Resolver";
                    TempCandidate: Record "SI VSC Candidate" temporary;
                    ResultsPage: Page "SI VSC Resolver Results";
                begin
                    Resolver.Resolve(ItemNo, VariantCode, RequiredQty, UoMCode, RequiredDate, ManufacturerCode, TempCandidate);
                    ResultsPage.LoadCandidates(TempCandidate);
                    ResultsPage.RunModal();
                end;
            }
            action(ToggleDiagnostics)
            {
                ApplicationArea = All;
                Caption = 'Технічний контекст';
                Image = ViewDetails;

                trigger OnAction()
                begin
                    ShowDiagnostics := not ShowDiagnostics;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    local procedure SelectProduct()
    var
        ProductSelector: Codeunit "SI Product Selector Mgt.";
    begin
        if not ProductSelector.SelectProduct(ItemNo, VariantCode) then
            exit;

        ProductDisplayName := ProductSelector.GetProductDisplayName(ItemNo, VariantCode);
        CurrPage.Update(false);
    end;

    local procedure SelectManufacturer()
    var
        Manufacturer: Record "SI Manufacturer";
        Manufacturers: Page "SI Manufacturers";
    begin
        Manufacturer.SetRange(Blocked, false);
        if ManufacturerCode <> '' then
            if Manufacturer.Get(ManufacturerCode) then
                Manufacturers.SetRecord(Manufacturer);

        Manufacturers.SetTableView(Manufacturer);
        Manufacturers.LookupMode(true);
        if Manufacturers.RunModal() <> Action::LookupOK then
            exit;

        Manufacturers.GetRecord(Manufacturer);
        ManufacturerCode := Manufacturer.Code;
        ManufacturerName := Manufacturer.Name;
        CurrPage.Update(false);
    end;

    var
        ItemNo: Code[20];
        VariantCode: Code[10];
        ProductDisplayName: Text[250];
        RequiredQty: Decimal;
        UoMCode: Code[10];
        RequiredDate: Date;
        ManufacturerCode: Code[20];
        ManufacturerName: Text[100];
        ShowDiagnostics: Boolean;
}
