page 53030 "SI Product Config. Wizard"
{
    PageType = NavigatePage;
    SourceTable = "SI Product Config.";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Caption = 'Майстер створення конфігурації продукту';
    InsertAllowed = true;
    DeleteAllowed = true;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            grid(ProgressGrid)
            {
                GridLayout = Columns;

                field(FamilyStep; FamilyStepText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = FamilyStepCurrent;
                    ToolTip = 'Етап вибору сімейства продукту.';
                }

                field(ValuesStep; ValuesStepText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = ValuesStepCurrent;
                    ToolTip = 'Етап введення значень параметрів конфігурації.';
                }

                field(ReviewStep; ReviewStepText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = ReviewStepCurrent;
                    ToolTip = 'Етап перевірки й створення конфігурації.';
                }
            }

            group(FamilyStepGroup)
            {
                Caption = 'Крок 1. Сімейство';
                Visible = FamilyStepVisible;

                field(FamilyInstruction; FamilyInstructionText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    Style = StandardAccent;
                    StyleExpr = true;
                    ToolTip = 'Пояснює призначення першого кроку.';
                }

                field(SelectedFamilyCodeField; SelectedFamilyCode)
                {
                    ApplicationArea = All;
                    Caption = 'Сімейство';
                    Importance = Promoted;
                    TableRelation = "SI Product Family".Code where(Blocked = const(false));
                    ToolTip = 'Визначає продуктове сімейство, за моделлю якого створюється конфігурація.';

                    trigger OnValidate()
                    begin
                        LoadSelectedFamily();
                    end;
                }

                field(SelectedFamilyDescriptionField; SelectedFamilyDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Назва сімейства';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Визначає назву вибраного сімейства.';
                }

                field(SelectedFamilyCategoryField; SelectedFamilyItemCategoryCode)
                {
                    ApplicationArea = All;
                    Caption = 'Категорія товару BC';
                    Editable = false;
                    ToolTip = 'Визначає категорію товару Business Central, пов’язану із сімейством.';
                }

                field(SelectedFamilyPrefixField; SelectedFamilyNamePrefix)
                {
                    ApplicationArea = All;
                    Caption = 'Префікс назви';
                    Editable = false;
                    ToolTip = 'Визначає початковий текст майбутньої назви продукту.';
                }
            }

            group(ValuesStepGroup)
            {
                Caption = 'Крок 2. Значення параметрів';
                Visible = ValuesStepVisible;

                field(ValuesInstruction; ValuesInstructionText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    Style = StandardAccent;
                    StyleExpr = true;
                    ToolTip = 'Пояснює призначення другого кроку.';
                }

                group(ConfigurationContext)
                {
                    Caption = 'Поточна конфігурація';

                    field(ConfigurationNoField; Rec."No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Номер';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Визначає технічний номер створюваної конфігурації.';
                    }

                    field(ConfigurationFamilyField; Rec."Family Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Сімейство';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Визначає сімейство створюваної конфігурації.';
                    }

                    field(BaseItemNoField; Rec."Base Item No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Базовий товар';
                        Importance = Promoted;
                        Editable = BaseItemAvailable;
                        ShowMandatory = false;
                        ToolTip = 'Визначає наявний товар Business Central, для якого буде сформовано варіант. Доступні лише товари категорії, пов’язаної із сімейством.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            exit(SelectBaseItem(Text));
                        end;

                        trigger OnValidate()
                        begin
                            SaveBaseItemFromRec();
                        end;
                    }

                    field(BaseItemDescriptionField; BaseItemDescription)
                    {
                        ApplicationArea = All;
                        Caption = 'Назва базового товару';
                        Editable = false;
                        ToolTip = 'Визначає назву вибраного базового товару.';
                    }

                    field(IncludeBaseNameField; Rec."Include Base Name")
                    {
                        ApplicationArea = All;
                        Caption = 'Додати назву категорії/товару до назви конфігурації';
                        Importance = Promoted;
                        ToolTip = 'Визначає, чи потрібно додати перед назвою, сформованою з параметрів, назву категорії товару або назву базового товару.';

                        trigger OnValidate()
                        begin
                            SaveIncludeBaseNameFromRec();
                        end;
                    }

                    field(CompactDescriptionPartsField; Rec."Compact Description Parts")
                    {
                        ApplicationArea = All;
                        Caption = 'Прибрати пробіли між частинами назви';
                        Importance = Promoted;
                        ToolTip = 'Якщо ввімкнено, між параметричними частинами назви пробіли не додаються. Один пробіл після базової частини назви зберігається.';

                        trigger OnValidate()
                        begin
                            SaveCompactDescriptionPartsFromRec();
                        end;
                    }
                }

                usercontrol(ConfigValuesGrid; "SI Product Config Values Grid")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        ConfigValuesGridReady := true;
                        RenderConfigValuesGrid();
                    end;

                    trigger AddRowRequested()
                    begin
                        ShowNewConfigValueRow := true;
                        RenderConfigValuesGrid();
                    end;

                    trigger ParameterLookupRequested()
                    begin
                        AddConfigValueFromLookup();
                    end;

                    trigger ControlledValueLookupRequested(ParameterCode: Text)
                    begin
                        SelectControlledValue(CopyStr(ParameterCode, 1, 30));
                    end;

                    trigger ReferenceValueLookupRequested(ParameterCode: Text)
                    begin
                        SelectReferenceValue(CopyStr(ParameterCode, 1, 30));
                    end;

                    trigger ValueChanged(ParameterCode: Text; ValueField: Text; NewValue: Text)
                    begin
                        UpdateConfigValue(
                            CopyStr(ParameterCode, 1, 30),
                            ValueField,
                            NewValue);
                    end;

                    trigger DeleteRowRequested(ParameterCode: Text)
                    begin
                        DeleteConfigValue(CopyStr(ParameterCode, 1, 30));
                    end;
                }

                group(NamePreviewGroup)
                {
                    Caption = 'Попередній перегляд назви';

                    field(PreviewObjectTypeField; PreviewObjectTypeText)
                    {
                        ApplicationArea = All;
                        Caption = 'Буде створено';
                        Editable = false;
                        Style = Strong;
                        StyleExpr = true;
                        ToolTip = 'Показує, чи поточна конфігурація створює товар або варіант товару.';
                    }

                    field(PreviewDescriptionField; PreviewDescriptionText)
                    {
                        ApplicationArea = All;
                        Caption = 'Майбутня назва';
                        Editable = false;
                        MultiLine = true;
                        Style = StrongAccent;
                        StyleExpr = true;
                        ToolTip = 'Показує назву товару або варіанта, яка буде сформована з поточних значень параметрів і налаштувань назви.';
                    }
                }
            }

            group(ReviewStepGroup)
            {
                Caption = 'Крок 3. Перевірка';
                Visible = ReviewStepVisible;

                field(ReviewInstruction; ReviewInstructionText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    Style = StandardAccent;
                    StyleExpr = true;
                    ToolTip = 'Пояснює призначення фінального кроку.';
                }

                group(ReviewContext)
                {
                    Caption = 'Конфігурація, що буде створена';

                    field(ReviewConfigurationNo; Rec."No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Номер';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Визначає номер конфігурації.';
                    }

                    field(ReviewFamilyCode; Rec."Family Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Сімейство';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Визначає сімейство конфігурації.';
                    }

                    field(ReviewFamilyDescription; SelectedFamilyDescription)
                    {
                        ApplicationArea = All;
                        Caption = 'Назва сімейства';
                        Editable = false;
                        ToolTip = 'Визначає назву сімейства.';
                    }

                    field(ReviewBaseItemNo; Rec."Base Item No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Базовий товар';
                        Editable = false;
                        Visible = VariantMode;
                        Importance = Promoted;
                        ToolTip = 'Визначає наявний товар, для якого конфігурація створює варіант.';
                    }

                    field(ReviewBaseItemDescription; BaseItemDescription)
                    {
                        ApplicationArea = All;
                        Caption = 'Назва базового товару';
                        Editable = false;
                        Visible = VariantMode;
                        ToolTip = 'Визначає назву вибраного базового товару.';
                    }

                    field(ReviewIncludeBaseName; Rec."Include Base Name")
                    {
                        ApplicationArea = All;
                        Caption = 'Додати назву категорії/товару';
                        Editable = false;
                        ToolTip = 'Визначає, чи буде до параметричної частини назви додано назву категорії або базового товару.';
                    }


                    field(ReviewCompactDescriptionParts; Rec."Compact Description Parts")
                    {
                        ApplicationArea = All;
                        Caption = 'Прибрати пробіли між частинами назви';
                        Editable = false;
                        ToolTip = 'Показує, чи будуть параметричні частини назви з’єднані без пробілів.';
                    }
                }

                part(ReviewValues; "SI Prod. Config. Values")
                {
                    ApplicationArea = All;
                    Caption = 'Введені значення';
                    Editable = false;
                    SubPageLink = "Configuration No." = field("No.");
                }

                field(ReviewNote; ReviewNoteText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    Style = Subordinate;
                    StyleExpr = true;
                    ToolTip = 'Пояснює результат завершення майстра.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CancelWizard)
            {
                ApplicationArea = All;
                Caption = 'Скасувати';
                Image = Cancel;
                InFooterBar = true;
                ToolTip = 'Скасовує створення конфігурації та видаляє чернетку майстра.';

                trigger OnAction()
                begin
                    CancelAndClose();
                end;
            }

            action(BackStep)
            {
                ApplicationArea = All;
                Caption = 'Назад';
                Image = PreviousRecord;
                InFooterBar = true;
                Visible = BackVisible;
                ToolTip = 'Повертає до попереднього кроку.';

                trigger OnAction()
                begin
                    GoBack();
                end;
            }

            action(NextStep)
            {
                ApplicationArea = All;
                Caption = 'Далі';
                Image = NextRecord;
                InFooterBar = true;
                Visible = NextVisible;
                ToolTip = 'Переходить до наступного кроку.';

                trigger OnAction()
                begin
                    GoNext();
                end;
            }

            action(FinishWizard)
            {
                ApplicationArea = All;
                Caption = 'Створити конфігурацію';
                Image = Approve;
                InFooterBar = true;
                Visible = FinishVisible;
                ToolTip = 'Перевіряє введені значення та завершує створення конфігурації продукту.';

                trigger OnAction()
                begin
                    FinishConfiguration();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        InitializeWizard();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateNamePreview();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not WizardCompleted then
            DeleteWizardDraft();

        exit(true);
    end;

    procedure GetCreatedConfigurationNo(): Code[20]
    begin
        exit(CreatedConfigurationNo);
    end;

    local procedure InitializeWizard()
    begin
        CurrentStep := CurrentStep::Family;

        FamilyInstructionText :=
            'Виберіть сімейство, яке описує потрібний тип продукту. ' +
            'Сімейство визначає набір параметрів, допустимі значення та правила ERP-проєкції.';

        ValuesInstructionText :=
            'Заповніть значення параметрів конкретного продукту. ' +
            'Якщо сімейство формує тільки варіант, спочатку виберіть базовий товар із категорії сімейства. ' +
            'Обов’язкові параметри вже додані автоматично.';

        ReviewInstructionText :=
            'Перевірте сімейство та введені значення. Після завершення система збере назву, ' +
            'Composite Key і hash та збереже конфігурацію у довіднику.';

        ReviewNoteText :=
            'На цьому етапі створюється продуктова конфігурація. ' +
            'Стандартні Item та Item Variant ще не створюються.';

        UpdateWizardState();
    end;

    local procedure GoNext()
    begin
        case CurrentStep of
            CurrentStep::Family:
                begin
                    TestSelectedFamily();
                    CreateWizardDraft();
                    CurrentStep := CurrentStep::Values;
                end;

            CurrentStep::Values:
                begin
                    TestDraftExists();
                    TestBaseItem();
                    CurrentStep := CurrentStep::Configuration;
                end;
        end;

        UpdateWizardState();
        UpdateNamePreview();
        CurrPage.Update(false);
        RenderConfigValuesGrid();
    end;

    local procedure GoBack()
    begin
        case CurrentStep of
            CurrentStep::Values:
                begin
                    DeleteWizardDraft();
                    CurrentStep := CurrentStep::Family;
                end;

            CurrentStep::Configuration:
                CurrentStep := CurrentStep::Values;
        end;

        UpdateWizardState();
        UpdateNamePreview();
        CurrPage.Update(false);
        RenderConfigValuesGrid();
    end;

    local procedure LoadSelectedFamily()
    var
        ProductFamily: Record "SI Product Family";
    begin
        Clear(SelectedFamilyDescription);
        Clear(SelectedFamilyItemCategoryCode);
        Clear(SelectedFamilyNamePrefix);

        if SelectedFamilyCode = '' then
            exit;

        ProductFamily.Get(SelectedFamilyCode);

        if ProductFamily.Blocked then
            Error(BlockedFamilyErr, ProductFamily.Code);

        SelectedFamilyDescription := ProductFamily.Description;
        SelectedFamilyItemCategoryCode := ProductFamily."Item Category Code";
        SelectedFamilyNamePrefix := ProductFamily."Name Prefix";

        DetermineConfigurationMode();
    end;

    local procedure TestSelectedFamily()
    begin
        if SelectedFamilyCode = '' then
            Error(FamilyRequiredErr);

        LoadSelectedFamily();
    end;

    local procedure CreateWizardDraft()
    var
        ProductConfig: Record "SI Product Config.";
        ProductConfigValue: Record "SI Product Config. Value";
        ProductConfigMgt: Codeunit "SI Product Config. Mgt.";
    begin
        if CreatedConfigurationNo <> '' then
            exit;

        CreatedConfigurationNo :=
            ProductConfigMgt.CreateDraftConfiguration(SelectedFamilyCode);

        ProductConfig.Get(CreatedConfigurationNo);
        Rec := ProductConfig;
        Rec.Insert();

        ProductConfigValue.SetRange("Configuration No.", CreatedConfigurationNo);
        ShowNewConfigValueRow := ProductConfigValue.IsEmpty();

        LoadBaseItem();
    end;

    local procedure TestDraftExists()
    var
        ProductConfig: Record "SI Product Config.";
    begin
        if CreatedConfigurationNo = '' then
            Error(ConfigurationDraftMissingErr);

        if not ProductConfig.Get(CreatedConfigurationNo) then
            Error(ConfigurationDraftMissingErr);
    end;

    local procedure FinishConfiguration()
    var
        ProductConfig: Record "SI Product Config.";
        ProductConfigMgt: Codeunit "SI Product Config. Mgt.";
    begin
        TestDraftExists();
        TestBaseItem();
        CurrPage.Update(true);

        if not ProductConfigMgt.ValidateConfiguration(Rec."No.") then begin
            ProductConfig.Get(Rec."No.");
            Error(ProductConfig."Validation Message");
        end;

        ProductConfig.Get(CreatedConfigurationNo);
        Rec := ProductConfig;
        Rec.Modify();
        WizardCompleted := true;

        Message(
            ConfigurationCreatedMsg,
            ProductConfig."No.",
            ProductConfig.Description);
        CurrPage.Close();
    end;

    local procedure CancelAndClose()
    begin
        DeleteWizardDraft();
        CurrPage.Close();
    end;

    local procedure DeleteWizardDraft()
    var
        ProductConfigMgt: Codeunit "SI Product Config. Mgt.";
        DraftNo: Code[20];
    begin
        DraftNo := CreatedConfigurationNo;

        if DraftNo = '' then
            exit;

        ProductConfigMgt.CancelDraftConfiguration(DraftNo);
        Clear(Rec);
        Clear(CreatedConfigurationNo);
        Clear(Rec."Base Item No.");
        Clear(BaseItemDescription);
        ShowNewConfigValueRow := false;
        RenderConfigValuesGrid();
    end;

    local procedure DetermineConfigurationMode()
    var
        Item: Record Item;
    begin
        Clear(BaseItemAvailable);
        Clear(VariantMode);

        if SelectedFamilyItemCategoryCode = '' then
            exit;

        Item.SetRange("Item Category Code", SelectedFamilyItemCategoryCode);
        Item.SetRange(Blocked, false);
        BaseItemAvailable := not Item.IsEmpty();

        VariantMode := Rec."Base Item No." <> '';
    end;

    local procedure SelectBaseItem(var LookupText: Text): Boolean
    var
        Item: Record Item;
        CurrentItem: Record Item;
        ItemList: Page "Item List";
    begin
        if not BaseItemAvailable then
            exit(false);

        Item.SetRange("Item Category Code", SelectedFamilyItemCategoryCode);
        Item.SetRange(Blocked, false);

        ItemList.SetTableView(Item);
        ItemList.LookupMode(true);

        if (Rec."Base Item No." <> '') and CurrentItem.Get(Rec."Base Item No.") then
            ItemList.SetRecord(CurrentItem);

        if ItemList.RunModal() <> Action::LookupOK then
            exit(false);

        ItemList.GetRecord(Item);
        LookupText := Item."No.";
        Rec.Validate("Base Item No.", Item."No.");
        SaveBaseItemFromRec();
        exit(true);
    end;

    local procedure SaveBaseItemFromRec()
    var
        ProductConfig: Record "SI Product Config.";
        ProductConfigMgt: Codeunit "SI Product Config. Mgt.";
        Item: Record Item;
        NewBaseItemNo: Code[20];
    begin
        TestDraftExists();
        NewBaseItemNo := Rec."Base Item No.";

        ProductConfig.Get(CreatedConfigurationNo);
        if ProductConfig."Base Item No." = NewBaseItemNo then begin
            LoadBaseItem();
            DetermineConfigurationMode();
            exit;
        end;

        ProductConfig.Validate("Base Item No.", NewBaseItemNo);
        ProductConfig.Modify(true);
        ProductConfigMgt.ReinitializeConfigValues(ProductConfig."No.");

        Rec := ProductConfig;
        Rec.Modify();

        if NewBaseItemNo <> '' then begin
            Item.Get(NewBaseItemNo);
            BaseItemDescription := Item.Description;
        end else
            Clear(BaseItemDescription);

        DetermineConfigurationMode();
        RefreshValuesStep();
    end;

    local procedure SaveIncludeBaseNameFromRec()
    var
        ProductConfig: Record "SI Product Config.";
    begin
        TestDraftExists();

        ProductConfig.Get(CreatedConfigurationNo);
        ProductConfig.Validate("Include Base Name", Rec."Include Base Name");
        ProductConfig.Modify(true);

        Rec."Include Base Name" := ProductConfig."Include Base Name";
        Rec.Modify();
        RefreshValuesStep();
    end;

    local procedure SaveCompactDescriptionPartsFromRec()
    var
        ProductConfig: Record "SI Product Config.";
    begin
        TestDraftExists();

        ProductConfig.Get(CreatedConfigurationNo);
        ProductConfig.Validate(
            "Compact Description Parts",
            Rec."Compact Description Parts");
        ProductConfig.Modify(true);

        Rec."Compact Description Parts" :=
            ProductConfig."Compact Description Parts";
        Rec.Modify();
        RefreshValuesStep();
    end;

    local procedure RefreshValuesStep()
    begin
        UpdateNamePreview();
        CurrPage.Update(false);
        RenderConfigValuesGrid();
    end;

    local procedure RenderConfigValuesGrid()
    var
        ProductConfigValue: Record "SI Product Config. Value";
        Payload: JsonObject;
        Rows: JsonArray;
        Row: JsonObject;
        RowsJson: Text;
    begin
        if not ConfigValuesGridReady then
            exit;

        if (CurrentStep <> CurrentStep::Values) or (CreatedConfigurationNo = '') then begin
            Payload.Add('rows', Rows);
            Payload.Add('showNewRow', false);
            Payload.WriteTo(RowsJson);
            CurrPage.ConfigValuesGrid.RenderRows(RowsJson);
            exit;
        end;

        ProductConfigValue.SetRange("Configuration No.", CreatedConfigurationNo);
        ProductConfigValue.SetCurrentKey(
            "Configuration No.",
            "Parameter Order",
            "Parameter Code");

        if ProductConfigValue.FindSet() then
            repeat
                Clear(Row);
                Row.Add('parameterCode', ProductConfigValue."Parameter Code");
                Row.Add('valueType', GetValueTypeToken(ProductConfigValue."Value Type"));
                Row.Add('valueTypeCaption', Format(ProductConfigValue."Value Type"));
                Row.Add('parameterValueCode', ProductConfigValue."Parameter Value Code");
                Row.Add('decimalValue', Format(ProductConfigValue."Decimal Value"));
                Row.Add('integerValue', Format(ProductConfigValue."Integer Value"));
                Row.Add('textValue', ProductConfigValue."Text Value");
                Row.Add('booleanValue', ProductConfigValue."Boolean Value");
                if ProductConfigValue."Date Value" <> 0D then
                    Row.Add('dateValue', Format(ProductConfigValue."Date Value", 0, 9))
                else
                    Row.Add('dateValue', '');
                Row.Add('displayValue', ProductConfigValue."Display Value");
                Rows.Add(Row);
            until ProductConfigValue.Next() = 0;

        Payload.Add('rows', Rows);
        Payload.Add('showNewRow', ShowNewConfigValueRow);
        Payload.WriteTo(RowsJson);
        CurrPage.ConfigValuesGrid.RenderRows(RowsJson);
    end;

    local procedure GetValueTypeToken(ValueType: Enum "SI Param. Value Type"): Text
    begin
        case ValueType of
            ValueType::"Controlled Value":
                exit('Controlled Value');
            ValueType::Decimal:
                exit('Decimal');
            ValueType::Integer:
                exit('Integer');
            ValueType::Text:
                exit('Text');
            ValueType::Boolean:
                exit('Boolean');
            ValueType::Date:
                exit('Date');
            ValueType::Reference:
                exit('Reference');
        end;

        exit('');
    end;

    local procedure AddConfigValueFromLookup()
    var
        ProductConfig: Record "SI Product Config.";
        ProductConfigValue: Record "SI Product Config. Value";
        FamilyParameter: Record "SI Family Parameter";
        FamilyParametersPage: Page "SI Family Parameters";
    begin
        TestDraftExists();
        ProductConfig.Get(CreatedConfigurationNo);

        FamilyParameter.SetRange("Family Code", ProductConfig."Family Code");
        FamilyParameter.SetRange(Blocked, false);

        if ProductConfig."Base Item No." <> '' then
            FamilyParameter.SetRange(
                "ERP Projection Role",
                FamilyParameter."ERP Projection Role"::"Variant Identity")
        else
            FamilyParameter.SetRange(
                "ERP Projection Role",
                FamilyParameter."ERP Projection Role"::"Item Identity");

        Clear(FamilyParametersPage);
        FamilyParametersPage.SetTableView(FamilyParameter);
        FamilyParametersPage.LookupMode(true);

        if FamilyParametersPage.RunModal() <> Action::LookupOK then
            exit;

        FamilyParametersPage.GetRecord(FamilyParameter);

        if ProductConfigValue.Get(
            CreatedConfigurationNo,
            FamilyParameter."Parameter Code")
        then
            Error(ParameterAlreadyAddedErr, FamilyParameter."Parameter Code");

        ProductConfigValue.Init();
        ProductConfigValue."Configuration No." := CreatedConfigurationNo;
        ProductConfigValue.Validate(
            "Parameter Code",
            FamilyParameter."Parameter Code");
        ProductConfigValue.Insert(true);

        ShowNewConfigValueRow := false;
        RefreshValuesStep();
    end;

    local procedure SelectControlledValue(ParameterCode: Code[30])
    var
        ProductConfigValue: Record "SI Product Config. Value";
        ParameterValue: Record "SI Parameter Value";
        CurrentParameterValue: Record "SI Parameter Value";
        ParameterValuesPage: Page "SI Parameter Values";
    begin
        TestDraftExists();
        ProductConfigValue.Get(CreatedConfigurationNo, ParameterCode);
        ProductConfigValue.TestField(
            "Value Type",
            ProductConfigValue."Value Type"::"Controlled Value");

        ParameterValue.SetRange("Parameter Code", ParameterCode);
        ParameterValue.SetRange(Blocked, false);

        Clear(ParameterValuesPage);
        ParameterValuesPage.SetTableView(ParameterValue);
        ParameterValuesPage.LookupMode(true);

        if (ProductConfigValue."Parameter Value Code" <> '') and
           CurrentParameterValue.Get(
                ParameterCode,
                ProductConfigValue."Parameter Value Code")
        then
            ParameterValuesPage.SetRecord(CurrentParameterValue);

        if ParameterValuesPage.RunModal() <> Action::LookupOK then
            exit;

        ParameterValuesPage.GetRecord(ParameterValue);
        ProductConfigValue.Validate(
            "Parameter Value Code",
            ParameterValue.Code);
        ProductConfigValue.Modify(true);

        RefreshValuesStep();
    end;

    local procedure SelectReferenceValue(ParameterCode: Code[30])
    var
        ProductConfig: Record "SI Product Config.";
        ProductConfigValue: Record "SI Product Config. Value";
        ProductParameter: Record "SI Product Parameter";
        FamilyParameter: Record "SI Family Parameter";
        ReferenceParameterMgt: Codeunit "SI Reference Parameter Mgt.";
        SelectedSystemId: Guid;
        SelectedKey: Text[250];
        SelectedDisplayValue: Text[250];
    begin
        TestDraftExists();
        ProductConfig.Get(CreatedConfigurationNo);
        ProductConfigValue.Get(CreatedConfigurationNo, ParameterCode);
        ProductConfigValue.TestField(
            "Value Type",
            ProductConfigValue."Value Type"::Reference);
        ProductParameter.Get(ParameterCode);
        ProductParameter.TestField("Reference Type");
        FamilyParameter.Get(ProductConfig."Family Code", ParameterCode);

        if not ReferenceParameterMgt.LookupValue(
            ProductConfig,
            FamilyParameter,
            ProductParameter."Reference Type",
            ProductConfigValue."Reference SystemId",
            SelectedSystemId,
            SelectedKey,
            SelectedDisplayValue)
        then
            exit;

        ProductConfigValue.SetReferenceValue(
            SelectedSystemId,
            SelectedKey,
            SelectedDisplayValue);
        ProductConfigValue.Modify(true);
        RefreshValuesStep();
    end;

    local procedure UpdateConfigValue(
        ParameterCode: Code[30];
        ValueField: Text;
        NewValue: Text)
    var
        ProductConfigValue: Record "SI Product Config. Value";
        DecimalValue: Decimal;
        IntegerValue: Integer;
        BooleanValue: Boolean;
        DateValue: Date;
    begin
        TestDraftExists();
        ProductConfigValue.Get(CreatedConfigurationNo, ParameterCode);

        case ValueField of
            'Decimal Value':
                begin
                    if not Evaluate(DecimalValue, NewValue) then
                        Error(InvalidDecimalValueErr, NewValue);
                    ProductConfigValue.Validate("Decimal Value", DecimalValue);
                end;
            'Integer Value':
                begin
                    if not Evaluate(IntegerValue, NewValue) then
                        Error(InvalidIntegerValueErr, NewValue);
                    ProductConfigValue.Validate("Integer Value", IntegerValue);
                end;
            'Text Value':
                ProductConfigValue.Validate(
                    "Text Value",
                    CopyStr(NewValue, 1, MaxStrLen(ProductConfigValue."Text Value")));
            'Boolean Value':
                begin
                    BooleanValue := LowerCase(NewValue) = 'true';
                    ProductConfigValue.Validate("Boolean Value", BooleanValue);
                end;
            'Date Value':
                begin
                    if NewValue = '' then
                        DateValue := 0D
                    else
                        if not Evaluate(DateValue, NewValue, 9) then
                            Error(InvalidDateValueErr, NewValue);
                    ProductConfigValue.Validate("Date Value", DateValue);
                end;
            else
                Error(UnknownValueFieldErr, ValueField);
        end;

        ProductConfigValue.Modify(true);
        RefreshValuesStep();
    end;

    local procedure DeleteConfigValue(ParameterCode: Code[30])
    var
        ProductConfigValue: Record "SI Product Config. Value";
    begin
        TestDraftExists();
        if not ProductConfigValue.Get(CreatedConfigurationNo, ParameterCode) then
            exit;

        ProductConfigValue.Delete(true);
        RefreshValuesStep();
    end;

    local procedure LoadBaseItem()
    var
        ProductConfig: Record "SI Product Config.";
        Item: Record Item;
    begin
        Clear(Rec."Base Item No.");
        Clear(BaseItemDescription);

        if CreatedConfigurationNo = '' then
            exit;

        if not ProductConfig.Get(CreatedConfigurationNo) then
            exit;

        Rec."Base Item No." := ProductConfig."Base Item No.";
        Rec.Modify();

        if (Rec."Base Item No." <> '') and Item.Get(Rec."Base Item No.") then
            BaseItemDescription := Item.Description;

        DetermineConfigurationMode();
    end;

    local procedure TestBaseItem()
    begin
        // Base Item is optional. An empty value means New Item mode.
    end;

    local procedure UpdateNamePreview()
    begin
        Clear(PreviewDescriptionText);
        Clear(PreviewObjectTypeText);

        if (CurrentStep <> CurrentStep::Values) or (CreatedConfigurationNo = '') then
            exit;

        if Rec."Base Item No." = '' then
            PreviewObjectTypeText := 'Товар'
        else
            PreviewObjectTypeText := 'Варіант товару';

        ClearLastError();
        if not TryBuildNamePreview() then
            PreviewDescriptionText := '';
    end;

    [TryFunction]
    local procedure TryBuildNamePreview()
    var
        NamingEngine: Codeunit "SI Naming Engine";
    begin
        if Rec."Base Item No." = '' then
            PreviewDescriptionText :=
                CopyStr(
                    NamingEngine.BuildDescription(CreatedConfigurationNo),
                    1,
                    MaxStrLen(PreviewDescriptionText))
        else
            PreviewDescriptionText :=
                CopyStr(
                    NamingEngine.BuildDescription(CreatedConfigurationNo),
                    1,
                    MaxStrLen(PreviewDescriptionText));
    end;

    local procedure UpdateWizardState()
    begin
        FamilyStepVisible := CurrentStep = CurrentStep::Family;
        ValuesStepVisible := CurrentStep = CurrentStep::Values;
        ReviewStepVisible := CurrentStep = CurrentStep::Configuration;

        BackVisible := CurrentStep <> CurrentStep::Family;
        NextVisible := CurrentStep <> CurrentStep::Configuration;
        FinishVisible := CurrentStep = CurrentStep::Configuration;

        FamilyStepCurrent := CurrentStep = CurrentStep::Family;
        ValuesStepCurrent := CurrentStep = CurrentStep::Values;
        ReviewStepCurrent := CurrentStep = CurrentStep::Configuration;

        case CurrentStep of
            CurrentStep::Family:
                begin
                    FamilyStepText := '● 1. СІМЕЙСТВО';
                    ValuesStepText := '○ 2. ЗНАЧЕННЯ ПАРАМЕТРІВ';
                    ReviewStepText := '○ 3. ПЕРЕВІРКА';
                end;

            CurrentStep::Values:
                begin
                    FamilyStepText := '✓ 1. СІМЕЙСТВО';
                    ValuesStepText := '● 2. ЗНАЧЕННЯ ПАРАМЕТРІВ';
                    ReviewStepText := '○ 3. ПЕРЕВІРКА';
                end;

            CurrentStep::Configuration:
                begin
                    FamilyStepText := '✓ 1. СІМЕЙСТВО';
                    ValuesStepText := '✓ 2. ЗНАЧЕННЯ ПАРАМЕТРІВ';
                    ReviewStepText := '● 3. ПЕРЕВІРКА';
                end;
        end;
    end;

    var
        CurrentStep: Enum "SI Product Wizard Step";
        SelectedFamilyCode: Code[30];
        SelectedFamilyDescription: Text[100];
        SelectedFamilyItemCategoryCode: Code[20];
        SelectedFamilyNamePrefix: Text[50];
        CreatedConfigurationNo: Code[20];
        BaseItemDescription: Text[100];
        BaseItemAvailable: Boolean;
        VariantMode: Boolean;
        WizardCompleted: Boolean;
        ConfigValuesGridReady: Boolean;
        ShowNewConfigValueRow: Boolean;

        FamilyStepText: Text[100];
        ValuesStepText: Text[100];
        ReviewStepText: Text[100];
        FamilyInstructionText: Text[500];
        ValuesInstructionText: Text[500];
        ReviewInstructionText: Text[500];
        ReviewNoteText: Text[500];
        PreviewObjectTypeText: Text[30];
        PreviewDescriptionText: Text[250];

        FamilyStepVisible: Boolean;
        ValuesStepVisible: Boolean;
        ReviewStepVisible: Boolean;
        FamilyStepCurrent: Boolean;
        ValuesStepCurrent: Boolean;
        ReviewStepCurrent: Boolean;
        BackVisible: Boolean;
        NextVisible: Boolean;
        FinishVisible: Boolean;

        FamilyRequiredErr: Label 'Виберіть сімейство продукту.';
        BlockedFamilyErr: Label 'Сімейство %1 заблоковане й не може використовуватися.';
        ConfigurationDraftMissingErr: Label 'Чернетку конфігурації не створено. Поверніться до вибору сімейства.';
        ConfigurationCreatedMsg: Label 'Конфігурацію %1 створено. Назва: %2.';
        BaseItemRequiredErr: Label 'Для сімейства %1 конфігурація визначає варіант. Виберіть базовий товар із категорії %2.';
        FamilyCategoryRequiredErr: Label 'Для сімейства %1 не визначено категорію товару Business Central.';
        BaseItemBlockedErr: Label 'Базовий товар %1 заблокований.';
        BaseItemCategoryMismatchErr: Label 'Товар %1 належить до категорії %2, але потрібно вибрати товар категорії %3.';
        ParameterAlreadyAddedErr: Label 'Параметр %1 уже додано до цієї конфігурації.';
        InvalidDecimalValueErr: Label 'Значення «%1» не є коректним десятковим числом.';
        InvalidIntegerValueErr: Label 'Значення «%1» не є коректним цілим числом.';
        InvalidDateValueErr: Label 'Значення «%1» не є коректною датою.';
        UnknownValueFieldErr: Label 'Невідоме поле значення %1.';
}
