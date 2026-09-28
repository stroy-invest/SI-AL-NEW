codeunit 58001 "SI Item Package Mgt."
{
    procedure BuildDescription(ItemPackage: Record "SI Item Package"): Text[150]
    var
        PackageType: Record "SI Package Type";
        UnitOfMeasure: Record "Unit of Measure";
        UoMMgt: Codeunit "SI UoM Mgt.";
        PackageTypeDescription: Text[100];
        UoMSymbol: Text[30];
    begin
        if PackageType.Get(ItemPackage."Package Type Code") then
            PackageTypeDescription := PackageType.Description;

        if UnitOfMeasure.Get(ItemPackage."UoM Code") then
            UoMSymbol := UoMMgt.GetDisplaySymbol(UnitOfMeasure);

        exit(CopyStr(
            StrSubstNo('%1 %2 %3', PackageTypeDescription, ItemPackage.Quantity, UoMSymbol),
            1,
            MaxStrLen(ItemPackage.Description)));
    end;

    procedure RefreshGeneratedFields(var ItemPackage: Record "SI Item Package")
    var
        GeneratedCode: Code[20];
        GeneratedItemUoMCode: Code[10];
    begin
        if (ItemPackage."Package Type Code" = '') or
           (ItemPackage.Quantity <= 0) or
           (ItemPackage."UoM Code" = '')
        then begin
            Clear(ItemPackage.Code);
            Clear(ItemPackage."Item UoM Code");
            exit;
        end;

        GeneratedCode := BuildPackageCode(ItemPackage);
        GeneratedItemUoMCode := BuildItemUoMCode(ItemPackage);

        ItemPackage.Code := GeneratedCode;
        ItemPackage."Item UoM Code" := GeneratedItemUoMCode;

        if ItemPackage.Description = '' then
            ItemPackage.Description := BuildDescription(ItemPackage);
    end;

    procedure ValidatePackageContentUoM(ItemPackage: Record "SI Item Package")
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        UoMMgt: Codeunit "SI UoM Mgt.";
    begin
        if ItemPackage."UoM Code" = '' then
            exit;

        UnitOfMeasure.Get(ItemPackage."UoM Code");
        UnitOfMeasure.TestField("SI Blocked", false);
        UnitOfMeasure.TestField("SI UoM Kind");

        if UnitOfMeasure."SI UoM Kind" in
           [UnitOfMeasure."SI UoM Kind"::Derived, UnitOfMeasure."SI UoM Kind"::Packaging]
        then
            Error(
                'Одиницю вимірювання %1 не можна використовувати як одиницю фізичного вмісту паковання.',
                UnitOfMeasure.Code);

        if ItemPackage."Item No." = '' then
            exit;

        Item.Get(ItemPackage."Item No.");
        Item.TestField("Base Unit of Measure");

        if not UoMMgt.AreConvertible(ItemPackage."UoM Code", Item."Base Unit of Measure") then
            Error(
                'Одиниця вимірювання %1 не має налаштованого зв’язку перерахунку з базовою одиницею товару %2.',
                ItemPackage."UoM Code",
                Item."Base Unit of Measure");
    end;

    procedure LookupCompatibleUoM(var ItemPackage: Record "SI Item Package"): Boolean
    var
        Item: Record Item;
        SelectedUoM: Record "Unit of Measure" temporary;
        CompatibleUoMLookup: Page "SI Compatible UoM Lookup";
    begin
        ItemPackage.TestField("Item No.");
        Item.Get(ItemPackage."Item No.");
        Item.TestField("Base Unit of Measure");

        CompatibleUoMLookup.LoadCompatibleUoMs(Item."Base Unit of Measure");
        CompatibleUoMLookup.LookupMode(true);

        if CompatibleUoMLookup.RunModal() <> Action::LookupOK then
            exit(false);

        CompatibleUoMLookup.GetRecord(SelectedUoM);
        if SelectedUoM.Code = '' then
            exit(false);

        ItemPackage.Validate("UoM Code", SelectedUoM.Code);
        exit(true);
    end;

    procedure SyncStandardItemUoM(var ItemPackage: Record "SI Item Package")
    var
        Item: Record Item;
        ItemUoM: Record "Item Unit of Measure";
        UoMMgt: Codeunit "SI UoM Mgt.";
        QtyPerItemUoM: Decimal;
    begin
        RefreshGeneratedFields(ItemPackage);

        if (ItemPackage."Item No." = '') or
           (ItemPackage."Item UoM Code" = '') or
           (ItemPackage.Quantity <= 0) or
           (ItemPackage."UoM Code" = '')
        then
            exit;

        ValidatePackageContentUoM(ItemPackage);

        Item.Get(ItemPackage."Item No.");
        Item.TestField("Base Unit of Measure");

        QtyPerItemUoM := UoMMgt.ConvertQuantity(
            ItemPackage.Quantity,
            ItemPackage."UoM Code",
            Item."Base Unit of Measure");

        EnsurePackagingUnitOfMeasure(ItemPackage);

        if ItemUoM.Get(ItemPackage."Item No.", ItemPackage."Item UoM Code") then begin
            if ItemUoM."Qty. per Unit of Measure" <> QtyPerItemUoM then begin
                ItemUoM.Validate("Qty. per Unit of Measure", QtyPerItemUoM);
                ItemUoM.Modify(true);
            end;
        end else begin
            ItemUoM.Init();
            ItemUoM.Validate("Item No.", ItemPackage."Item No.");
            ItemUoM.Validate(Code, ItemPackage."Item UoM Code");
            ItemUoM.Validate("Qty. per Unit of Measure", QtyPerItemUoM);
            ItemUoM.Insert(true);
        end;
    end;

    procedure ValidateItemPackage(var ItemPackage: Record "SI Item Package")
    begin
        RefreshGeneratedFields(ItemPackage);

        ItemPackage.TestField("Item No.");
        ItemPackage.TestField("Package Type Code");
        ItemPackage.TestField(Quantity);
        ItemPackage.TestField("UoM Code");
        ItemPackage.TestField(Code);
        ItemPackage.TestField("Item UoM Code");

        if ItemPackage.Quantity <= 0 then
            Error('Кількість у пакованні повинна бути більшою за нуль.');

        ValidatePackageContentUoM(ItemPackage);
        SyncStandardItemUoM(ItemPackage);
    end;

    local procedure EnsurePackagingUnitOfMeasure(ItemPackage: Record "SI Item Package")
    var
        UnitOfMeasure: Record "Unit of Measure";
        PackageDescription: Text[50];
    begin
        if UnitOfMeasure.Get(ItemPackage."Item UoM Code") then begin
            if UnitOfMeasure."SI UoM Kind" <> UnitOfMeasure."SI UoM Kind"::Packaging then
                Error(
                    'Код %1 уже існує в довіднику одиниць вимірювання та має тип %2. Змініть код типу паковання або параметри паковання, щоб сформувався інший код.',
                    UnitOfMeasure.Code,
                    Format(UnitOfMeasure."SI UoM Kind"));
            exit;
        end;

        PackageDescription := CopyStr(BuildDescription(ItemPackage), 1, MaxStrLen(UnitOfMeasure.Description));

        UnitOfMeasure.Init();
        UnitOfMeasure.Validate(Code, ItemPackage."Item UoM Code");
        UnitOfMeasure.Validate(Description, PackageDescription);
        UnitOfMeasure."SI UoM Kind" := UnitOfMeasure."SI UoM Kind"::Packaging;
        UnitOfMeasure.Insert(true);
    end;

    local procedure BuildPackageCode(ItemPackage: Record "SI Item Package"): Code[20]
    var
        QuantityText: Text;
        ResultCode: Text;
    begin
        QuantityText := NormalizeQuantity(ItemPackage.Quantity);
        ResultCode :=
            DelChr(UpperCase(ItemPackage."Package Type Code"), '=', ' ') +
            QuantityText +
            DelChr(UpperCase(ItemPackage."UoM Code"), '=', ' ');

        exit(CopyStr(ResultCode, 1, 20));
    end;

    local procedure BuildItemUoMCode(ItemPackage: Record "SI Item Package"): Code[10]
    var
        QuantityText: Text;
        ResultCode: Text;
    begin
        QuantityText := NormalizeQuantity(ItemPackage.Quantity);
        ResultCode :=
            CopyStr(DelChr(UpperCase(ItemPackage."Package Type Code"), '=', ' '), 1, 4) +
            CopyStr(QuantityText, 1, 4) +
            CopyStr(DelChr(UpperCase(ItemPackage."UoM Code"), '=', ' '), 1, 2);

        exit(CopyStr(ResultCode, 1, 10));
    end;

    local procedure NormalizeQuantity(Quantity: Decimal): Text
    var
        QuantityText: Text;
    begin
        QuantityText := Format(Quantity, 0, 9);
        QuantityText := ConvertStr(QuantityText, '.,', 'PP');
        QuantityText := DelChr(QuantityText, '=', ' +-');
        exit(UpperCase(QuantityText));
    end;
}
