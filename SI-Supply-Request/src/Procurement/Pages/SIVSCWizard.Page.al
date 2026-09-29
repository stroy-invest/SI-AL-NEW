page 61060 "SI VSC Wizard"
{
    PageType = NavigatePage;
    SourceTable = "SI VSC Wizard Buffer";
    SourceTableTemporary = true;
    Caption = 'Налаштування каналів постачання';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(VendorGroup)
            {
                Caption = 'Постачальник';
                field(VendorName; VendorName) { ApplicationArea = All; Caption = 'Постачальник'; Editable = false; }
            }
            group(CategoryStep)
            {
                Caption = '1. Виберіть категорії товарів'; Visible = StepNo = 1;
                usercontrol(CategoryTree; "SI VSC Category Tree")
                {
                    ApplicationArea = All;
                    trigger ControlReady() begin CurrPage.CategoryTree.RenderTree(GetCategoryTreeJson()); end;
                    trigger CategoryToggled(CategoryCode: Text; IsSelected: Boolean) begin ToggleCategory(CopyStr(CategoryCode, 1, 20), IsSelected); end;
                }
            }
            group(TermsStep)
            {
                Caption = '2. Налаштуйте умови постачання'; Visible = StepNo = 2;
                group(SelectedCategoryGroup)
                {
                    Caption = 'Вибрані категорії';
                    repeater(SelectedCategories)
                    {
                        field("Category Name"; Rec."Category Name") { ApplicationArea = All; Caption = 'Категорія'; Editable = false; }
                        field("Default UoM Code"; Rec."Default UoM Code") { ApplicationArea = All; Caption = 'Од. виміру'; Editable = false; }
                    }
                }
                group(ConditionsGroup)
                {
                    Caption = 'Умови постачання';
                    usercontrol(ConditionsGrid; "SI VSC Conditions Grid")
                    {
                        ApplicationArea = All;

                        trigger ControlReady()
                        begin
                            ConditionsGridReady := true;
                            RenderConditions();
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
            action(Back)
            {
                ApplicationArea = All; Caption = 'Назад'; InFooterBar = true; Image = PreviousRecord; Visible = StepNo = 2;
                trigger OnAction() begin StepNo := 1; Rec.Reset(); CurrPage.Update(false); CurrPage.CategoryTree.RenderTree(GetCategoryTreeJson()); end;
            }
            action(Next)
            {
                ApplicationArea = All; Caption = 'Далі'; InFooterBar = true; Image = NextRecord; Visible = StepNo = 1;
                trigger OnAction()
                begin
                    if Rec.IsEmpty() then Error(SelectCategoryErr);
                    StepNo := 2; Rec.Reset(); if Rec.FindFirst() then; CurrPage.Update(false); UpdateConditionsCategory();
                end;
            }
            action(Finish)
            {
                ApplicationArea = All; Caption = 'Завершити'; InFooterBar = true; Image = Approve; Visible = StepNo = 2;
                trigger OnAction() begin FinishWizard(); CurrPage.Close(); end;
            }
            action(Cancel)
            {
                ApplicationArea = All; Caption = 'Скасувати'; InFooterBar = true; Image = Cancel;
                trigger OnAction() begin CurrPage.Close(); end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if VendorNo = '' then Error(VendorRequiredErr);
        StepNo := 1;
        if Vendor.Get(VendorNo) then VendorName := Vendor.Name;
    end;

    procedure SetVendor(NewVendorNo: Code[20])
    begin VendorNo := NewVendorNo; end;

    local procedure ToggleCategory(CategoryCode: Code[20]; IsSelected: Boolean)
    var ItemCategory: Record "Item Category";
    begin
        Rec.Reset(); Rec.SetRange("Category Code", CategoryCode);
        if IsSelected then begin
            if not Rec.IsEmpty() then begin Rec.Reset(); exit; end;
            if not ItemCategory.Get(CategoryCode) then begin Rec.Reset(); exit; end;
            Rec.Reset(); Rec.Init(); Rec."Entry No." := NextCategoryEntryNo(); Rec."Category Code" := CategoryCode;
            Rec."Category Name" := CopyStr(ItemCategory.Description, 1, MaxStrLen(Rec."Category Name"));
            if Rec."Category Name" = '' then Rec."Category Name" := ItemCategory.Code;
            Rec."Default UoM Code" := ItemCategory."SI Default Base UoM Code"; Rec.Insert();
        end else
            if Rec.FindFirst() then begin ClearCategoryConditions(CategoryCode); Rec.Delete(); end;
        Rec.Reset();
    end;

    local procedure UpdateConditionsCategory()
    begin
        if StepNo <> 2 then
            exit;
        // Clear the browser-side detail editor before switching category context.
        // Otherwise controls can retain the last rendered row while the new
        // category has no conditions yet.
        if ConditionsGridReady then
            CurrPage.ConditionsGrid.ClearGrid();

        CurrentCategoryCode := Rec."Category Code";
        CurrentCategoryName := Rec."Category Name";
        CurrentDefaultUoMCode := Rec."Default UoM Code";
        RenderConditions();
    end;

    local procedure FinishWizard()
    var
        CreatedCount: Integer;
    begin
        ValidateAllConditions();
        CreatedCount := CreateCapabilities();
        Message(CreatedMsg, CreatedCount, VendorName);
    end;

    local procedure AddCondition()
    begin
        if CurrentCategoryCode = '' then
            exit;
        // Do not let values from the previously current temporary record leak into a new condition.
        // Init() preserves primary-key values and record state can survive navigation, so clear explicitly.
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
        if StepNo <> 2 then
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
    var B: Record "SI VSC Wizard Buffer" temporary;
    begin B.Copy(Rec, true); B.Reset(); if B.FindLast() then exit(B."Entry No." + 1); exit(1); end;
    local procedure GetCategoryTreeJson(): Text
    var ItemCategory: Record "Item Category";
    begin ItemCategory.SetRange("Parent Category", ''); exit(BuildCategoryJson(ItemCategory)); end;
    local procedure BuildCategoryJson(var ItemCategory: Record "Item Category"): Text
    var J: Text; First: Boolean;
    begin J := '['; First := true; if ItemCategory.FindSet() then repeat if not First then J += ','; J += BuildCategoryNodeJson(ItemCategory); First := false; until ItemCategory.Next() = 0; exit(J + ']'); end;
    local procedure BuildCategoryNodeJson(ItemCategory: Record "Item Category"): Text
    var Child: Record "Item Category"; Name: Text; Selected: Boolean;
    begin
        Name := ItemCategory.Description; if Name = '' then Name := ItemCategory.Code; Rec.Reset(); Rec.SetRange("Category Code", ItemCategory.Code); Selected := not Rec.IsEmpty(); Rec.Reset();
        Child.SetRange("Parent Category", ItemCategory.Code);
        exit('{' + '"code":"' + JsonEscape(ItemCategory.Code) + '",' + '"name":"' + JsonEscape(Name) + '",' + '"baseUomCode":"' + JsonEscape(ItemCategory."SI Default Base UoM Code") + '",' + '"selected":' + BooleanToJson(Selected) + ',' + '"children":' + BuildCategoryJson(Child) + '}');
    end;
    local procedure BooleanToJson(Value: Boolean): Text
    begin
        if Value then
            exit('true');
        exit('false');
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

    trigger OnAfterGetCurrRecord()
    begin
        if StepNo = 2 then
            UpdateConditionsCategory();
    end;

    var
        Vendor: Record Vendor;
        ConditionBuffer: Record "SI VSC Wizard Condition" temporary;
        VendorNo: Code[20];
        VendorName: Text[100];
        CurrentCategoryCode: Code[20];
        CurrentCategoryName: Text[100];
        CurrentDefaultUoMCode: Code[10];
        StepNo: Integer;
        ConditionsGridReady: Boolean;
        VendorRequiredErr: Label 'Не визначено постачальника.';
        SelectCategoryErr: Label 'Виберіть хоча б одну категорію товарів.';
        NoConditionsErr: Label 'Додайте хоча б одну умову постачання.';
        ShipmentMethodRequiredErr: Label 'Для категорії %1 виберіть спосіб постачання.';
        UoMRequiredErr: Label 'Для кількісних умов категорії %1 потрібно вказати одиницю виміру.';
        InvalidLeadTimeErr: Label 'Некоректний термін постачання: %1.';
        CreatedMsg: Label 'Створено каналів постачання: %1. Постачальник: %2.';
}
