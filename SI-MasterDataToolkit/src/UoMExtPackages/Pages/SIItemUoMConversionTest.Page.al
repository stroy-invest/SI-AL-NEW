page 58008 "SI Item UoM Conversion Test"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Тест перерахунку одиниць товару';

    layout
    {
        area(Content)
        {
            group(Input)
            {
                Caption = 'Вхідні дані';

                field(ItemNo; ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Товар';
                    TableRelation = Item."No.";
                    ToolTip = 'Товар, для якого виконується item-aware перерахунок.';
                }
                field(VariantCode; VariantCode)
                {
                    ApplicationArea = All;
                    Caption = 'Варіант';
                    TableRelation = "Item Variant".Code;
                    ToolTip = 'Необов''язковий варіант товару. Якщо не задано, перевіряються рівні Item і Category.';

                    trigger OnValidate()
                    var
                        ItemVariant: Record "Item Variant";
                    begin
                        if VariantCode = '' then
                            exit;
                        if ItemNo = '' then
                            Error('Спочатку вкажіть товар.');
                        if not ItemVariant.Get(ItemNo, VariantCode) then
                            Error('Варіант %1 не належить товару %2.', VariantCode, ItemNo);
                    end;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Кількість';
                    DecimalPlaces = 0 : 5;
                }
                field(FromUoMCode; FromUoMCode)
                {
                    ApplicationArea = All;
                    Caption = 'З одиниці виміру';
                    TableRelation = "Unit of Measure".Code where("SI Blocked" = const(false));
                }
                field(ToUoMCode; ToUoMCode)
                {
                    ApplicationArea = All;
                    Caption = 'В одиницю виміру';
                    TableRelation = "Unit of Measure".Code where("SI Blocked" = const(false));
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ItemUoMConversion: Codeunit "SI Item UoM Conversion";
        UoMMgt: Codeunit "SI UoM Mgt.";
        ResultQuantity: Decimal;
        DerivedValue: Decimal;
        DerivedUoMCode: Code[10];
        SourceDescription: Text;
    begin
        if CloseAction <> Action::OK then
            exit(true);

        ValidateInput();

        if UoMMgt.AreConvertible(FromUoMCode, ToUoMCode) then begin
            ResultQuantity := ItemUoMConversion.ConvertItemQuantity(
                ItemNo, VariantCode, Quantity, FromUoMCode, ToUoMCode);
            SourceDescription := 'Прямий перерахунок у межах однієї фізичної групи; bridge не потрібен.';
        end else begin
            ItemUoMConversion.ResolvePhysicalBridge(
                ItemNo,
                VariantCode,
                FromUoMCode,
                ToUoMCode,
                DerivedValue,
                DerivedUoMCode,
                SourceDescription);

            ResultQuantity := ItemUoMConversion.ConvertItemQuantity(
                ItemNo, VariantCode, Quantity, FromUoMCode, ToUoMCode);
        end;

        Message(
            'Перерахунок виконано: %1 %2 → %3 %4.\Bridge: %5 %6.\Джерело: %7',
            Quantity,
            FromUoMCode,
            ResultQuantity,
            ToUoMCode,
            DerivedValue,
            DerivedUoMCode,
            SourceDescription);

        exit(true);
    end;

    procedure SetItem(ItemNoValue: Code[20]; VariantCodeValue: Code[10])
    begin
        ItemNo := ItemNoValue;
        VariantCode := VariantCodeValue;
    end;

    local procedure ValidateInput()
    begin
        if ItemNo = '' then
            Error('Не вказано товар.');
        if Quantity = 0 then
            Error('Кількість має відрізнятися від нуля.');
        if FromUoMCode = '' then
            Error('Не вказано вихідну одиницю виміру.');
        if ToUoMCode = '' then
            Error('Не вказано цільову одиницю виміру.');
    end;

    var
        ItemNo: Code[20];
        VariantCode: Code[10];
        Quantity: Decimal;
        FromUoMCode: Code[10];
        ToUoMCode: Code[10];
}
