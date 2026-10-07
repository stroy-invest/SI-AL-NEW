page 61060 "SI VSC Wizard"
{
    PageType = NavigatePage;
    SourceTable = "SI VSC Wizard Buffer";
    SourceTableTemporary = true;
    Caption = 'Канали та умови постачання';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(VendorGroup)
            {
                Caption = 'Постачальник';
                field(VendorName; VendorName)
                {
                    ApplicationArea = All;
                    Caption = 'Постачальник';
                    Editable = false;
                }
            }
            group(CategoriesStep)
            {
                Caption = 'Показати категорії';
                group(CategoryActionGroup)
                {
                    ShowCaption = false;
                    usercontrol(AddCategoryButton; "SI VSC Add Category Button")
                    {
                        ApplicationArea = All;

                        trigger AddCategory()
                        begin
                            SelectAndAddCategory();
                        end;
                    }
                }
                group(CategoriesGroup)
                {
                    ShowCaption = false;
                    InstructionalText = 'Виберіть категорії товарів, які може постачати цей постачальник.';
                    repeater(SelectedCategories)
                    {
                        field("Category Name"; Rec."Category Name")
                        {
                            ApplicationArea = All;
                            Caption = 'Категорія';
                            Editable = false;
                        }
                    }
                }
            }
            group(ConditionsStep)
            {
                Caption = 'Показати умови постачання';
                group(ConditionsGroup)
                {
                    Caption = 'Умови постачання';
                    InstructionalText = 'Для вибраної категорії додайте один або кілька каналів та задайте умови постачання.';
                    field(CurrentCategoryName; CurrentCategoryName)
                    {
                        ApplicationArea = All;
                        Caption = 'Категорія';
                        Editable = false;
                    }
                    usercontrol(ConditionsGrid; "SI VSC Conditions Grid")
                    {
                        ApplicationArea = All;

                        trigger ControlReady()
                        begin
                            ConditionsGridReady := true;
                            UpdateConditionsCategory();
                        end;

                        trigger AddRow()
                        begin
                            AddCondition();
                            RenderConditions();
                        end;

                        trigger DeleteRow(EntryNo: Integer)
                        begin
                            DeleteCondition(EntryNo);
                            RenderConditions();
                        end;

                        trigger RowChanged(EntryNo: Integer; ShipmentMethodCode: Text; MinimumOrderQuantity: Decimal; OrderMultiple: Decimal; UoMCode: Text; LeadTimeCalculation: Text)
                        begin
                            UpdateCondition(EntryNo, ShipmentMethodCode, MinimumOrderQuantity, OrderMultiple, UoMCode, LeadTimeCalculation);
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddCategory)
            {
                ApplicationArea = All;
                Caption = 'Додати категорію';
                ToolTip = 'Додати категорію товарів до налаштування каналів постачання.';
                Image = New;

                trigger OnAction()
                begin
                    SelectAndAddCategory();
                end;
            }
            action(RemoveCategory)
            {
                ApplicationArea = All;
                Caption = 'Видалити категорію';
                ToolTip = 'Видалити вибрану категорію та введені для неї умови з майстра.';
                Image = Delete;
                Enabled = CurrentCategoryCode <> '';

                trigger OnAction()
                begin
                    RemoveCurrentCategory();
                end;
            }
            action(Finish)
            {
                ApplicationArea = All;
                Caption = 'Завершити';
                InFooterBar = true;
                Image = Approve;

                trigger OnAction()
                begin
                    FinishWizard();
                    CurrPage.Close();
                end;
            }
            action(Cancel)
            {
                ApplicationArea = All;
                Caption = 'Скасувати';
                InFooterBar = true;
                Image = Cancel;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if VendorNo = '' then
            Error(VendorRequiredErr);
        if Vendor.Get(VendorNo) then
            VendorName := Vendor.Name;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateConditionsCategory();
    end;

    procedure SetVendor(NewVendorNo: Code[20])
    begin
        VendorNo := NewVendorNo;
    end;

    local procedure SelectAndAddCategory()
    var
        CategorySelectorMgt: Codeunit "SI Category Selector Mgt.";
        CategoryCode: Code[20];
    begin
        CategoryCode := CurrentCategoryCode;
        if not CategorySelectorMgt.SelectCategory(CategoryCode) then
            exit;

        AddCategoryToBuffer(CategoryCode);
    end;

    local procedure AddCategoryToBuffer(CategoryCode: Code[20])
    var
        ItemCategory: Record "Item Category";
        ExistingCategory: Record "SI VSC Wizard Buffer" temporary;
    begin
        ExistingCategory.Copy(Rec, true);
        ExistingCategory.Reset();
        ExistingCategory.SetRange("Category Code", CategoryCode);
        if ExistingCategory.FindFirst() then begin
            Rec.Get(ExistingCategory."Entry No.");
            CurrPage.Update(false);
            UpdateConditionsCategory();
            exit;
        end;

        if not ItemCategory.Get(CategoryCode) then
            Error(CategoryNotFoundErr, CategoryCode);

        Rec.Reset();
        Rec.Init();
        Rec."Entry No." := NextCategoryEntryNo();
        Rec."Category Code" := CategoryCode;
        Rec."Category Name" := CopyStr(ItemCategory.Description, 1, MaxStrLen(Rec."Category Name"));
        if Rec."Category Name" = '' then
            Rec."Category Name" := ItemCategory.Code;
        Rec."Default UoM Code" := ItemCategory."SI Default Base UoM Code";
        Rec.Insert();
        CurrPage.Update(false);
        UpdateConditionsCategory();
    end;

    local procedure RemoveCurrentCategory()
    var
        CategoryCode: Code[20];
    begin
        if CurrentCategoryCode = '' then
            exit;

        CategoryCode := CurrentCategoryCode;
        ClearCategoryConditions(CategoryCode);
        if Rec.Get(Rec."Entry No.") then
            Rec.Delete();

        Clear(CurrentCategoryCode);
        Clear(CurrentCategoryName);
        Clear(CurrentDefaultUoMCode);

        Rec.Reset();
        if Rec.FindFirst() then;
        CurrPage.Update(false);
        UpdateConditionsCategory();
    end;

    local procedure UpdateConditionsCategory()
    begin
        if ConditionsGridReady then
            CurrPage.ConditionsGrid.ClearGrid();

        if Rec."Category Code" = '' then begin
            Clear(CurrentCategoryCode);
            Clear(CurrentCategoryName);
            Clear(CurrentDefaultUoMCode);
            RenderConditions();
            exit;
        end;

        CurrentCategoryCode := Rec."Category Code";
        CurrentCategoryName := Rec."Category Name";
        CurrentDefaultUoMCode := Rec."Default UoM Code";
        RenderConditions();
    end;

    local procedure FinishWizard()
    var
        CreatedCount: Integer;
    begin
        if Rec.IsEmpty() then
            Error(SelectCategoryErr);
        ValidateAllConditions();
        CreatedCount := CreateCapabilities();
        Message(CreatedMsg, CreatedCount, VendorName);
    end;

    local procedure AddCondition()
    begin
        if CurrentCategoryCode = '' then
            Error(SelectCurrentCategoryErr);

        Clear(ConditionBuffer);
        ConditionBuffer.Init();
        ConditionBuffer."Entry No." := NextConditionEntryNo();
        ConditionBuffer."Category Code" := CurrentCategoryCode;
        ConditionBuffer."Shipment Method Code" := '';
        ConditionBuffer."Shipment Method Name" := '';
        ConditionBuffer."Minimum Order Quantity" := 0;
        ConditionBuffer."Order Multiple" := 0;
        ConditionBuffer."UoM Code" := CurrentDefaultUoMCode;
        Clear(ConditionBuffer."Lead Time Calculation");
        ConditionBuffer.Insert();
    end;

    local procedure DeleteCondition(EntryNo: Integer)
    begin
        ConditionBuffer.Reset();
        if ConditionBuffer.Get(EntryNo) then
            ConditionBuffer.Delete();
    end;

    local procedure UpdateCondition(EntryNo: Integer; ShipmentMethodCode: Text; MinimumOrderQuantity: Decimal; OrderMultiple: Decimal; UoMCode: Text; LeadTimeText: Text)
    var
        ShipmentMethod: Record "Shipment Method";
        LeadTime: DateFormula;
    begin
        ConditionBuffer.Reset();
        if not ConditionBuffer.Get(EntryNo) then
            exit;

        ConditionBuffer."Shipment Method Code" := CopyStr(ShipmentMethodCode, 1, MaxStrLen(ConditionBuffer."Shipment Method Code"));
        ConditionBuffer."Shipment Method Name" := '';
        if (ConditionBuffer."Shipment Method Code" <> '') and ShipmentMethod.Get(ConditionBuffer."Shipment Method Code") then begin
            ConditionBuffer."Shipment Method Name" := ShipmentMethod.Description;
            if ConditionBuffer."Shipment Method Name" = '' then
                ConditionBuffer."Shipment Method Name" := ShipmentMethod.Code;
        end;
        ConditionBuffer."Minimum Order Quantity" := MinimumOrderQuantity;
        ConditionBuffer."Order Multiple" := OrderMultiple;
        ConditionBuffer."UoM Code" := CopyStr(UoMCode, 1, MaxStrLen(ConditionBuffer."UoM Code"));
        Clear(LeadTime);
        if LeadTimeText <> '' then
            if not Evaluate(LeadTime, LeadTimeText) then
                Error(InvalidLeadTimeErr, LeadTimeText);
        ConditionBuffer."Lead Time Calculation" := LeadTime;
        ConditionBuffer.Modify();
    end;

    local procedure ClearCategoryConditions(CategoryCode: Code[20])
    begin
        ConditionBuffer.Reset();
        ConditionBuffer.SetRange("Category Code", CategoryCode);
        ConditionBuffer.DeleteAll();
        ConditionBuffer.Reset();
    end;

    local procedure NextConditionEntryNo(): Integer
    begin
        ConditionBuffer.Reset();
        if ConditionBuffer.FindLast() then
            exit(ConditionBuffer."Entry No." + 1);
        exit(1);
    end;

    local procedure RenderConditions()
    begin
        if not ConditionsGridReady then
            exit;
        CurrPage.ConditionsGrid.Render(GetConditionsJson(), GetShipmentMethodsJson(), GetUnitsOfMeasureJson(), CurrentCategoryName);
    end;

    local procedure GetConditionsJson(): Text
    var
        J: Text;
        First: Boolean;
    begin
        J := '[';
        First := true;
        ConditionBuffer.Reset();
        ConditionBuffer.SetRange("Category Code", CurrentCategoryCode);
        if ConditionBuffer.FindSet() then
            repeat
                if not First then
                    J += ',';
                J += '{' +
                    '"entryNo":' + Format(ConditionBuffer."Entry No.", 0, 9) + ',' +
                    '"shipmentMethodCode":"' + JsonEscape(ConditionBuffer."Shipment Method Code") + '",' +
                    '"minimumOrderQuantity":' + DecimalToJson(ConditionBuffer."Minimum Order Quantity") + ',' +
                    '"orderMultiple":' + DecimalToJson(ConditionBuffer."Order Multiple") + ',' +
                    '"uomCode":"' + JsonEscape(ConditionBuffer."UoM Code") + '",' +
                    '"leadTimeCalculation":"' + JsonEscape(Format(ConditionBuffer."Lead Time Calculation")) + '"}';
                First := false;
            until ConditionBuffer.Next() = 0;
        ConditionBuffer.Reset();
        exit(J + ']');
    end;

    local procedure GetShipmentMethodsJson(): Text
    var
        ShipmentMethod: Record "Shipment Method";
        J: Text;
        First: Boolean;
        DisplayName: Text;
    begin
        J := '[';
        First := true;
        if ShipmentMethod.FindSet() then
            repeat
                DisplayName := ShipmentMethod.Description;
                if DisplayName = '' then
                    DisplayName := ShipmentMethod.Code;
                if not First then
                    J += ',';
                J += '{"code":"' + JsonEscape(ShipmentMethod.Code) + '","name":"' + JsonEscape(DisplayName) + '"}';
                First := false;
            until ShipmentMethod.Next() = 0;
        exit(J + ']');
    end;

    local procedure GetUnitsOfMeasureJson(): Text
    var
        UnitOfMeasure: Record "Unit of Measure";
        J: Text;
        First: Boolean;
        DisplayName: Text;
    begin
        J := '[';
        First := true;
        if UnitOfMeasure.FindSet() then
            repeat
                DisplayName := UnitOfMeasure.Description;
                if DisplayName = '' then
                    DisplayName := UnitOfMeasure.Code;
                if not First then
                    J += ',';
                J += '{"code":"' + JsonEscape(UnitOfMeasure.Code) + '","name":"' + JsonEscape(DisplayName) + '"}';
                First := false;
            until UnitOfMeasure.Next() = 0;
        exit(J + ']');
    end;

    local procedure DecimalToJson(Value: Decimal): Text
    begin
        exit(Format(Value, 0, 9));
    end;

    local procedure ValidateAllConditions()
    begin
        ConditionBuffer.Reset();
        if ConditionBuffer.IsEmpty() then
            Error(NoConditionsErr);
        if ConditionBuffer.FindSet() then
            repeat
                if ConditionBuffer."Shipment Method Code" = '' then
                    Error(ShipmentMethodRequiredErr, ConditionBuffer."Category Code");
                if ((ConditionBuffer."Minimum Order Quantity" > 0) or (ConditionBuffer."Order Multiple" > 0)) and (ConditionBuffer."UoM Code" = '') then
                    Error(UoMRequiredErr, ConditionBuffer."Category Code");
            until ConditionBuffer.Next() = 0;
        ConditionBuffer.Reset();
    end;

    local procedure CreateCapabilities(): Integer
    var
        Capability: Record "SI Vendor Supply Capability";
        ItemCategory: Record "Item Category";
        CategoryName: Text[100];
        CreatedCount: Integer;
    begin
        ConditionBuffer.Reset();
        if ConditionBuffer.FindSet() then
            repeat
                CategoryName := ConditionBuffer."Category Code";
                if ItemCategory.Get(ConditionBuffer."Category Code") then begin
                    CategoryName := ItemCategory.Description;
                    if CategoryName = '' then
                        CategoryName := ItemCategory.Code;
                end;
                Clear(Capability);
                Capability.Init();
                Capability.Validate("Vendor No.", VendorNo);
                Capability.Validate("Item Category Code", ConditionBuffer."Category Code");
                Capability.Description := CopyStr(BuildCapabilityDescription(CategoryName, ConditionBuffer."Shipment Method Name"), 1, MaxStrLen(Capability.Description));
                Capability.Validate("Shipment Method Code", ConditionBuffer."Shipment Method Code");
                Capability.Validate("UoM Code", ConditionBuffer."UoM Code");
                Capability.Validate("Minimum Order Quantity", ConditionBuffer."Minimum Order Quantity");
                Capability.Validate("Order Multiple", ConditionBuffer."Order Multiple");
                Capability.Validate("Lead Time Calculation", ConditionBuffer."Lead Time Calculation");
                Capability.Insert(true);
                Capability.Validate(Status, Capability.Status::Active);
                Capability.Modify(true);
                CreatedCount += 1;
            until ConditionBuffer.Next() = 0;
        ConditionBuffer.Reset();
        exit(CreatedCount);
    end;

    local procedure BuildCapabilityDescription(CategoryName: Text; ShipmentMethodName: Text): Text
    begin
        if ShipmentMethodName = '' then
            exit(CategoryName);
        exit(StrSubstNo('%1 — %2', CategoryName, ShipmentMethodName));
    end;

    local procedure NextCategoryEntryNo(): Integer
    var
        B: Record "SI VSC Wizard Buffer" temporary;
    begin
        B.Copy(Rec, true);
        B.Reset();
        if B.FindLast() then
            exit(B."Entry No." + 1);
        exit(1);
    end;

    local procedure JsonEscape(Value: Text): Text
    begin
        Value := Value.Replace('\', '\\');
        Value := Value.Replace('"', '\"');
        Value := Value.Replace('/', '\/');
        Value := Value.Replace('<', '\u003C');
        Value := Value.Replace('>', '\u003E');
        Value := Value.Replace('&', '\u0026');
        exit(Value);
    end;

    var
        Vendor: Record Vendor;
        ConditionBuffer: Record "SI VSC Wizard Condition" temporary;
        VendorNo: Code[20];
        VendorName: Text[100];
        CurrentCategoryCode: Code[20];
        CurrentCategoryName: Text[100];
        CurrentDefaultUoMCode: Code[10];
        ConditionsGridReady: Boolean;
        VendorRequiredErr: Label 'Не визначено постачальника.';
        SelectCategoryErr: Label 'Виберіть хоча б одну категорію товарів.';
        SelectCurrentCategoryErr: Label 'Спочатку виберіть категорію товарів.';
        CategoryNotFoundErr: Label 'Категорію товарів %1 не знайдено.';
        NoConditionsErr: Label 'Додайте хоча б одну умову постачання.';
        ShipmentMethodRequiredErr: Label 'Для категорії %1 виберіть спосіб постачання.';
        UoMRequiredErr: Label 'Для кількісних умов категорії %1 потрібно вказати одиницю виміру.';
        InvalidLeadTimeErr: Label 'Некоректний термін постачання: %1.';
        CreatedMsg: Label 'Створено каналів постачання: %1. Постачальник: %2.';
}
