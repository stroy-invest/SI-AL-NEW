page 53014 "SI Product Model Wizard"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    Caption = 'Майстер продуктової моделі';

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
                    ToolTip = 'Етап вибору або створення сімейства.';
                }

                field(ValuesStep; ValuesStepText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = ValuesStepCurrent;
                    ToolTip = 'Етап налаштування параметрів і допустимих значень.';
                }

                field(ConfigurationStep; ConfigurationStepText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = ConfigurationStepCurrent;
                    ToolTip = 'Етап створення конфігурації продукту.';
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

                field(FamilyModeField; FamilyMode)
                {
                    ApplicationArea = All;
                    Caption = 'Дія із сімейством';
                    Importance = Promoted;
                    ToolTip = 'Визначає, чи буде використано наявне сімейство, чи створено нове.';

                    trigger OnValidate()
                    begin
                        HandleFamilyModeChange();
                    end;
                }

                group(ExistingFamilyGroup)
                {
                    Caption = 'Наявне сімейство';
                    Visible = UseExistingFamily;

                    field(ExistingFamilyCodeField; ExistingFamilyCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Сімейство';
                        Editable = UseExistingFamily;
                        Importance = Promoted;
                        Lookup = true;
                        ToolTip = 'Виберіть або введіть код наявного сімейства продуктів.';

                        trigger OnValidate()
                        begin
                            LoadExistingFamily();
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if not LookupExistingFamily() then
                                exit(false);

                            Text := ExistingFamilyCode;
                            exit(true);
                        end;
                    }

                    field(ExistingFamilyDescriptionField;
                    ExistingFamilyDescription)
                    {
                        ApplicationArea = All;
                        Caption = 'Назва';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Визначає назву вибраного сімейства.';
                    }

                    field(ExistingFamilyPrefix;
                    ExistingFamilyNamePrefix)
                    {
                        ApplicationArea = All;
                        Caption = 'Префікс назви';
                        Editable = false;
                        ToolTip = 'Визначає префікс назв продуктів сімейства.';
                    }

                    field(ExistingSupportsRecipes;
                    ExistingFamilySupportsRecipes)
                    {
                        ApplicationArea = All;
                        Caption = 'Підтримує рецептури';
                        Editable = false;
                        ToolTip = 'Визначає, чи підтримує сімейство рецептури.';
                    }

                    field(ExistingFamilyCategoryCodeField;
                    ExistingFamilyItemCategoryCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Категорія товару BC';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Визначає категорію товару Business Central, до якої прив’язане сімейство.';
                    }

                    field(ExistingFamilyCategoryDescriptionField;
                    ExistingFamilyItemCategoryDescription)
                    {
                        ApplicationArea = All;
                        Caption = 'Назва категорії';
                        Editable = false;
                        ToolTip = 'Визначає назву категорії товару Business Central.';
                    }
                }

                group(NewFamilyGroup)
                {
                    Caption = 'Нове сімейство';
                    Visible = CreateNewFamily;

                    field(NewFamilyCodeField; NewFamilyCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Код';
                        Importance = Promoted;
                        ToolTip = 'Визначає стабільний корпоративний код нового сімейства.';
                    }

                    field(NewFamilyDescriptionField;
                    NewFamilyDescription)
                    {
                        ApplicationArea = All;
                        Caption = 'Назва';
                        Importance = Promoted;
                        ToolTip = 'Визначає назву нового сімейства.';
                    }

                    field(NewFamilyDescriptionENField;
                    NewFamilyDescriptionEN)
                    {
                        ApplicationArea = All;
                        Caption = 'Назва англійською';
                        ToolTip = 'Визначає англійську назву нового сімейства.';
                    }

                    field(NewFamilyNamePrefixField;
                    NewFamilyNamePrefix)
                    {
                        ApplicationArea = All;
                        Caption = 'Префікс назви продукту';
                        Importance = Promoted;
                        ToolTip = 'Визначає початковий текст сформованої назви продукту.';
                    }

                    field(NewFamilySupportsRecipesField;
                    NewFamilySupportsRecipes)
                    {
                        ApplicationArea = All;
                        Caption = 'Підтримує рецептури';
                        ToolTip = 'Визначає, чи підтримує нове сімейство рецептури.';
                    }

                    field(NewFamilyCategoryCodeField;
                    NewFamilySelectedCategoryCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Категорія, в якій створюється сімейство';
                        Importance = Promoted;
                        Lookup = true;
                        ToolTip = 'Виберіть категорію в ієрархії Business Central. Вона буде використана безпосередньо або стане батьківською для нової дочірньої категорії.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if not LookupNewFamilyCategory() then
                                exit(false);

                            Text := NewFamilySelectedCategoryCode;
                            exit(true);
                        end;
                    }

                    field(NewFamilyCategoryDescriptionField;
                    NewFamilySelectedCategoryDescription)
                    {
                        ApplicationArea = All;
                        Caption = 'Назва вибраної категорії';
                        Editable = false;
                        ToolTip = 'Визначає назву вибраної категорії товару Business Central.';
                    }

                    field(NewFamilyCategoryModeField;
                    NewFamilyCategoryMode)
                    {
                        ApplicationArea = All;
                        Caption = 'Спосіб розміщення сімейства';
                        Importance = Promoted;
                        ToolTip = 'Визначає, чи буде сімейство прив’язане до вибраної категорії, чи для нього буде створено нову дочірню категорію.';

                        trigger OnValidate()
                        begin
                            UpdateCategoryModeState();
                        end;
                    }

                    group(NewChildCategoryGroup)
                    {
                        Caption = 'Нова дочірня категорія';
                        Visible = CreateChildCategory;

                        field(NewChildCategoryCodeField;
                        NewChildCategoryCode)
                        {
                            ApplicationArea = All;
                            Caption = 'Код нової категорії';
                            Importance = Promoted;
                            ToolTip = 'Визначає код нової дочірньої категорії товару.';
                        }

                        field(NewChildCategoryDescriptionField;
                        NewChildCategoryDescription)
                        {
                            ApplicationArea = All;
                            Caption = 'Назва нової категорії';
                            Importance = Promoted;
                            ToolTip = 'Визначає назву нової дочірньої категорії товару.';
                        }
                    }


                    field(NewFamilyTemplateCodeField; NewFamilyTemplateCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Шаблон сімейства';
                        Importance = Promoted;
                        TableRelation = "SI Product Family Template".Code where(Blocked = const(false));
                        ToolTip = 'Визначає reusable шаблон параметрів для нового сімейства. Після створення шаблон буде застосовано без перезапису наявних параметрів.';
                    }

                    field(NewFamilyItemTemplateCodeField;
                    NewFamilyItemTemplateCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Шаблон товару';
                        Importance = Promoted;
                        ShowMandatory = true;
                        TableRelation = "Item Templ.".Code;
                        ToolTip = 'Визначає обов’язковий стандартний Item Template для майбутніх товарів цього сімейства. Використовується лише наявний, попередньо налаштований шаблон.';
                    }

                    field(NewFamilySortOrderField;
                    NewFamilySortOrder)
                    {
                        ApplicationArea = All;
                        Caption = 'Порядок сортування';
                        ToolTip = 'Визначає порядок відображення сімейства.';
                    }
                }
            }

            group(ValuesStepGroup)
            {
                Caption = 'Крок 2. Параметри та допустимі значення';
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

                group(ValuesFamilyContext)
                {
                    Caption = 'Поточне сімейство';

                    field(SelectedFamilyCodeField; SelectedFamilyCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Сімейство';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Визначає поточне сімейство продуктової моделі.';
                    }

                    field(SelectedFamilyDescriptionField;
                    SelectedFamilyDescription)
                    {
                        ApplicationArea = All;
                        Caption = 'Назва';
                        Editable = false;
                        ToolTip = 'Визначає назву поточного сімейства.';
                    }
                }

                group(ParameterSelection)
                {
                    Caption = 'Параметр сімейства';

                    grid(ParameterCommandGrid)
                    {
                        GridLayout = Columns;

                        field(SelectedParameterCodeField;
                        SelectedParameterCode)
                        {
                            ApplicationArea = All;
                            Caption = 'Параметр';
                            Importance = Promoted;
                            Lookup = true;
                            ToolTip = 'Виберіть параметр, уже доданий до поточного сімейства.';

                            trigger OnValidate()
                            begin
                                LoadSelectedParameter();
                            end;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                if not LookupFamilyParameter() then
                                    exit(false);

                                Text := SelectedParameterCode;
                                exit(true);
                            end;
                        }

                        field(CreateParameterCommand;
                        CreateParameterCommandText)
                        {
                            ApplicationArea = All;
                            ShowCaption = false;
                            Editable = false;
                            DrillDown = true;
                            Style = StrongAccent;
                            StyleExpr = true;
                            ToolTip = 'Створює новий корпоративний параметр і додає його до поточного сімейства.';

                            trigger OnDrillDown()
                            begin
                                CreateParameterForCurrentFamily();
                            end;
                        }

                        field(AddParameterCommand;
                        AddParameterCommandText)
                        {
                            ApplicationArea = All;
                            ShowCaption = false;
                            Editable = false;
                            DrillDown = true;
                            Style = StrongAccent;
                            StyleExpr = true;
                            ToolTip = 'Додає до поточного сімейства параметр із корпоративного довідника.';

                            trigger OnDrillDown()
                            begin
                                AddExistingParameterToCurrentFamily();
                            end;
                        }
                    }

                    field(SelectedParameterDescriptionField;
                    SelectedParameterDescription)
                    {
                        ApplicationArea = All;
                        Caption = 'Назва параметра';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Визначає назву вибраного параметра.';
                    }

                    field(SelectedParameterTypeField;
                    SelectedParameterValueType)
                    {
                        ApplicationArea = All;
                        Caption = 'Тип значення';
                        Editable = false;
                        ToolTip = 'Визначає тип значення вибраного параметра.';
                    }
                }

                part(ParameterValues; "SI Wiz. Param. Values")
                {
                    ApplicationArea = All;
                    Caption = 'Допустимі значення вибраного параметра';
                }
            }

            group(ConfigurationStepGroup)
            {
                Caption = 'Крок 3. Конфігурація';
                Visible = ConfigurationStepVisible;

                field(ConfigurationInstruction;
                ConfigurationInstructionText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    Style = StandardAccent;
                    StyleExpr = true;
                    ToolTip = 'Пояснює призначення фінального кроку.';
                }

                group(ConfigurationFamilyContext)
                {
                    Caption = 'Майбутня конфігурація';

                    field(ConfigFamilyCode; SelectedFamilyCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Сімейство';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Визначає сімейство майбутньої конфігурації.';
                    }

                    field(ConfigFamilyDescription;
                    SelectedFamilyDescription)
                    {
                        ApplicationArea = All;
                        Caption = 'Назва сімейства';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Визначає назву сімейства майбутньої конфігурації.';
                    }
                }

                field(ConfigurationNote; ConfigurationNoteText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    Style = Subordinate;
                    StyleExpr = true;
                    ToolTip = 'Пояснює майбутню реалізацію фінального кроку.';
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
                ToolTip = 'Закриває майстер. Уже збережені дані не видаляються.';

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }

            action(BackStep)
            {
                ApplicationArea = All;
                Caption = 'Назад';
                Image = PreviousRecord;
                InFooterBar = true;
                Visible = BackVisible;
                ToolTip = 'Повертає до попереднього кроку майстра.';

                trigger OnAction()
                begin
                    GoBack();
                end;
            }

            action(ContinueLater)
            {
                ApplicationArea = All;
                Caption = 'Продовжити пізніше';
                Image = Save;
                InFooterBar = true;
                Visible = ContinueLaterVisible;
                ToolTip = 'Зберігає завершені етапи й закриває майстер.';

                trigger OnAction()
                begin
                    SaveCurrentStep();
                    CurrPage.Close();
                end;
            }

            action(NextStep)
            {
                ApplicationArea = All;
                Caption = 'Далі';
                Image = NextRecord;
                InFooterBar = true;
                Visible = NextVisible;
                ToolTip = 'Зберігає поточний етап і переходить до наступного.';

                trigger OnAction()
                begin
                    GoNext();
                end;
            }

            action(FinishWizard)
            {
                ApplicationArea = All;
                Caption = 'Готово';
                Image = Approve;
                InFooterBar = true;
                Visible = FinishVisible;
                ToolTip = 'Завершує роботу майстра продуктової моделі.';

                trigger OnAction()
                begin
                    Message(
                        WizardFinishedMsg,
                        SelectedFamilyCode,
                        SelectedFamilyDescription);

                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        InitializeWizard();
    end;

    local procedure InitializeWizard()
    begin
        CurrentStep := CurrentStep::Family;
        FamilyMode := FamilyMode::"Use Existing";
        NewFamilyCategoryMode :=
            NewFamilyCategoryMode::"Use Selected Category";

        FamilyInstructionText :=
            'Виберіть наявне сімейство або створіть нове. ' +
            'Наступні кроки працюватимуть у контексті цього сімейства.';

        ValuesInstructionText :=
            'Виберіть параметр, уже доданий до сімейства, створіть новий ' +
            'або додайте наявний корпоративний параметр. Після цього ' +
            'налаштуйте його допустимі значення.';

        ConfigurationInstructionText :=
            'На фінальному кроці буде створено конкретну конфігурацію продукту.';

        ConfigurationNoteText :=
            'Наступним інкрементом тут буде підключено автоматичне створення ' +
            'заголовка конфігурації та рядків її параметрів.';

        CreateParameterCommandText := '+ Створити';
        AddParameterCommandText := '+ Додати наявний';

        HandleFamilyModeChange();
        UpdateCategoryModeState();
        UpdateWizardState();
    end;

    local procedure GoNext()
    begin
        case CurrentStep of
            CurrentStep::Family:
                begin
                    SaveFamilyStep();
                    PrepareValuesStep();
                    CurrentStep := CurrentStep::Values;
                end;

            CurrentStep::Values:
                begin
                    SaveValuesStep();
                    CurrentStep := CurrentStep::Configuration;
                end;
        end;

        UpdateWizardState();
        CurrPage.Update(false);
    end;

    local procedure GoBack()
    begin
        case CurrentStep of
            CurrentStep::Values:
                CurrentStep := CurrentStep::Family;

            CurrentStep::Configuration:
                begin
                    CurrentStep := CurrentStep::Values;
                    PrepareValuesStep();
                end;
        end;

        UpdateWizardState();
        CurrPage.Update(false);
    end;

    local procedure SaveCurrentStep()
    begin
        case CurrentStep of
            CurrentStep::Family:
                SaveFamilyStep();

            CurrentStep::Values:
                SaveValuesStep();
        end;
    end;

    local procedure SaveFamilyStep()
    begin
        ValidateFamilyStep();

        case FamilyMode of
            FamilyMode::"Use Existing":
                LoadExistingFamilyAsSelected();

            FamilyMode::"Create New":
                CreateNewFamilyRecord();
        end;
    end;

    local procedure SaveValuesStep()
    begin
        TestSelectedFamily();

        // Допустимі значення записуються безпосередньо
        // у таблицю SI Parameter Value через ListPart.
    end;

    local procedure PrepareValuesStep()
    var
        FamilyParameter: Record "SI Family Parameter";
    begin
        Clear(SelectedParameterCode);
        Clear(SelectedParameterDescription);
        Clear(SelectedParameterValueType);

        FamilyParameter.SetCurrentKey(
            "Family Code",
            "Parameter Order",
            "Parameter Code");

        FamilyParameter.SetRange(
            "Family Code",
            SelectedFamilyCode);

        FamilyParameter.SetRange(
            Blocked,
            false);

        if FamilyParameter.FindFirst() then begin
            SelectedParameterCode :=
                FamilyParameter."Parameter Code";

            LoadSelectedParameter();
        end else
            CurrPage.ParameterValues.Page.SetParameterFilter('');
    end;

    local procedure ValidateFamilyStep()
    var
        ProductConfigMgt: Codeunit "SI Product Config. Mgt.";
    begin
        case FamilyMode of
            FamilyMode::"Use Existing":
                begin
                    if ExistingFamilyCode = '' then
                        Error(ExistingFamilyRequiredErr);

                    LoadExistingFamily();
                end;

            FamilyMode::"Create New":
                begin
                    if NewFamilyCode = '' then
                        Error(NewFamilyCodeRequiredErr);

                    if NewFamilyDescription = '' then
                        Error(NewFamilyDescriptionRequiredErr);

                    if NewFamilySelectedCategoryCode = '' then
                        Error(NewFamilyCategoryRequiredErr);

                    if NewFamilyItemTemplateCode = '' then
                        if not ProductConfigMgt.PromptAssignExistingItemTemplate(
                            NewFamilyCode,
                            NewFamilyItemTemplateCode)
                        then
                            Error(NewFamilyItemTemplateRequiredErr);

                    if NewFamilyCategoryMode =
                       NewFamilyCategoryMode::"Create Child Category"
                    then begin
                        if NewChildCategoryCode = '' then
                            Error(NewChildCategoryCodeRequiredErr);

                        if NewChildCategoryDescription = '' then
                            Error(NewChildCategoryDescriptionRequiredErr);
                    end;
                end;
        end;
    end;

    local procedure LoadExistingFamily()
    var
        ProductFamily: Record "SI Product Family";
    begin
        Clear(ExistingFamilyDescription);
        Clear(ExistingFamilyNamePrefix);
        Clear(ExistingFamilySupportsRecipes);
        Clear(ExistingFamilyItemCategoryCode);
        Clear(ExistingFamilyItemCategoryDescription);

        if ExistingFamilyCode = '' then
            exit;

        if not ProductFamily.Get(ExistingFamilyCode) then
            Error(
                FamilyDoesNotExistErr,
                ExistingFamilyCode);

        if ProductFamily.Blocked then
            Error(
                FamilyBlockedErr,
                ProductFamily.Code);

        ExistingFamilyDescription :=
            ProductFamily.Description;

        ExistingFamilyNamePrefix :=
            ProductFamily."Name Prefix";

        ExistingFamilySupportsRecipes :=
            ProductFamily."Supports Recipes";

        ExistingFamilyItemCategoryCode :=
            ProductFamily."Item Category Code";

        LoadItemCategoryDescription(
            ExistingFamilyItemCategoryCode,
            ExistingFamilyItemCategoryDescription);
    end;

    local procedure LoadExistingFamilyAsSelected()
    begin
        LoadExistingFamily();

        SelectedFamilyCode := ExistingFamilyCode;
        SelectedFamilyDescription :=
            ExistingFamilyDescription;
    end;

    local procedure CreateNewFamilyRecord()
    var
        ProductFamily: Record "SI Product Family";
        ProductConfigMgt: Codeunit "SI Product Config. Mgt.";
        FamilyTemplateMgt: Codeunit "SI Family Template Mgt.";
    begin
        case NewFamilyCategoryMode of
            NewFamilyCategoryMode::"Use Selected Category":
                SelectedFamilyCode :=
                    ProductConfigMgt.CreateProductFamilyInCategory(
                        NewFamilyCode,
                        NewFamilyDescription,
                        NewFamilyDescriptionEN,
                        NewFamilyNamePrefix,
                        NewFamilySupportsRecipes,
                        NewFamilySortOrder,
                        NewFamilyItemTemplateCode,
                        NewFamilySelectedCategoryCode);

            NewFamilyCategoryMode::"Create Child Category":
                SelectedFamilyCode :=
                    ProductConfigMgt.CreateProductFamilyWithChildCategory(
                        NewFamilyCode,
                        NewFamilyDescription,
                        NewFamilyDescriptionEN,
                        NewFamilyNamePrefix,
                        NewFamilySupportsRecipes,
                        NewFamilySortOrder,
                        NewFamilyItemTemplateCode,
                        NewFamilySelectedCategoryCode,
                        NewChildCategoryCode,
                        NewChildCategoryDescription);
        end;

        ProductFamily.Get(SelectedFamilyCode);

        if NewFamilyTemplateCode <> '' then begin
            ProductFamily.Validate("Family Template Code", NewFamilyTemplateCode);
            ProductFamily.Modify(true);
            FamilyTemplateMgt.ApplyTemplate(ProductFamily.Code);
        end;

        SelectedFamilyDescription :=
            ProductFamily.Description;

        ExistingFamilyCode := ProductFamily.Code;
        ExistingFamilyDescription :=
            ProductFamily.Description;
        ExistingFamilyNamePrefix :=
            ProductFamily."Name Prefix";
        ExistingFamilySupportsRecipes :=
            ProductFamily."Supports Recipes";
        ExistingFamilyItemCategoryCode :=
            ProductFamily."Item Category Code";

        LoadItemCategoryDescription(
            ExistingFamilyItemCategoryCode,
            ExistingFamilyItemCategoryDescription);
    end;

    local procedure LookupExistingFamily(): Boolean
    var
        ProductFamily: Record "SI Product Family";
        ProductFamiliesPage: Page "SI Product Families";
    begin
        ProductFamily.Reset();
        ProductFamily.SetRange(Blocked, false);

        Clear(ProductFamiliesPage);
        ProductFamiliesPage.LookupMode(true);
        ProductFamiliesPage.SetTableView(ProductFamily);

        if ProductFamiliesPage.RunModal() <>
           Action::LookupOK
        then
            exit(false);

        ProductFamiliesPage.GetRecord(ProductFamily);

        ExistingFamilyCode := ProductFamily.Code;
        ExistingFamilyDescription :=
            ProductFamily.Description;
        ExistingFamilyNamePrefix :=
            ProductFamily."Name Prefix";
        ExistingFamilySupportsRecipes :=
            ProductFamily."Supports Recipes";
        ExistingFamilyItemCategoryCode :=
            ProductFamily."Item Category Code";

        LoadItemCategoryDescription(
            ExistingFamilyItemCategoryCode,
            ExistingFamilyItemCategoryDescription);

        CurrPage.Update(false);
        exit(true);
    end;

    local procedure HandleFamilyModeChange()
    begin
        UseExistingFamily :=
            FamilyMode = FamilyMode::"Use Existing";

        CreateNewFamily :=
            FamilyMode = FamilyMode::"Create New";

        if UseExistingFamily then begin
            Clear(NewFamilyCode);
            Clear(NewFamilyTemplateCode);
            Clear(NewFamilyDescription);
            Clear(NewFamilyDescriptionEN);
            Clear(NewFamilyNamePrefix);
            Clear(NewFamilySupportsRecipes);
            Clear(NewFamilySortOrder);
            Clear(NewFamilySelectedCategoryCode);
            Clear(NewFamilySelectedCategoryDescription);
            Clear(NewChildCategoryCode);
            Clear(NewChildCategoryDescription);
            NewFamilyCategoryMode :=
                NewFamilyCategoryMode::"Use Selected Category";
            UpdateCategoryModeState();
        end else begin
            Clear(ExistingFamilyCode);
            Clear(ExistingFamilyDescription);
            Clear(ExistingFamilyNamePrefix);
            Clear(ExistingFamilySupportsRecipes);
            Clear(ExistingFamilyItemCategoryCode);
            Clear(ExistingFamilyItemCategoryDescription);
        end;

        Clear(SelectedFamilyCode);
        Clear(SelectedFamilyDescription);
        Clear(SelectedParameterCode);
        Clear(SelectedParameterDescription);
        Clear(SelectedParameterValueType);

        CurrPage.Update(false);
    end;

    local procedure LookupNewFamilyCategory(): Boolean
    var
        CategoryTreeSelect: Page "SI Item Category Tree Select";
    begin
        Clear(CategoryTreeSelect);

        if NewFamilySelectedCategoryCode <> '' then
            CategoryTreeSelect.SetSelectedCategory(
                NewFamilySelectedCategoryCode);

        if CategoryTreeSelect.RunModal() <> Action::OK then
            exit(false);

        CategoryTreeSelect.GetSelectedCategory(
            NewFamilySelectedCategoryCode,
            NewFamilySelectedCategoryDescription);

        CurrPage.Update(false);
        exit(true);
    end;

    local procedure LoadItemCategoryDescription(
        ItemCategoryCode: Code[20];
        var ItemCategoryDescription: Text[100])
    var
        ItemCategory: Record "Item Category";
    begin
        Clear(ItemCategoryDescription);

        if ItemCategoryCode = '' then
            exit;

        if ItemCategory.Get(ItemCategoryCode) then
            ItemCategoryDescription :=
                ItemCategory.Description;
    end;

    local procedure UpdateCategoryModeState()
    begin
        CreateChildCategory :=
            NewFamilyCategoryMode =
            NewFamilyCategoryMode::"Create Child Category";

        if not CreateChildCategory then begin
            Clear(NewChildCategoryCode);
            Clear(NewChildCategoryDescription);
        end;

        CurrPage.Update(false);
    end;

    local procedure LookupFamilyParameter(): Boolean
    var
        FamilyParameter: Record "SI Family Parameter";
        FamilyParametersPage: Page "SI Wiz. Family Params";
    begin
        TestSelectedFamily();

        FamilyParameter.Reset();

        FamilyParameter.SetRange(
            "Family Code",
            SelectedFamilyCode);

        FamilyParameter.SetRange(
            Blocked,
            false);

        Clear(FamilyParametersPage);

        FamilyParametersPage.LookupMode(true);
        FamilyParametersPage.SetTableView(
            FamilyParameter);

        if FamilyParametersPage.RunModal() <>
           Action::LookupOK
        then
            exit(false);

        FamilyParametersPage.GetRecord(
            FamilyParameter);

        SelectedParameterCode :=
            FamilyParameter."Parameter Code";

        LoadSelectedParameter();

        CurrPage.Update(false);
        exit(true);
    end;

    local procedure LoadSelectedParameter()
    var
        FamilyParameter: Record "SI Family Parameter";
        ProductParameter: Record "SI Product Parameter";
    begin
        Clear(SelectedParameterDescription);
        Clear(SelectedParameterValueType);

        if SelectedParameterCode = '' then begin
            CurrPage.ParameterValues.Page.SetParameterFilter('');
            exit;
        end;

        TestSelectedFamily();

        if not FamilyParameter.Get(
            SelectedFamilyCode,
            SelectedParameterCode)
        then
            Error(
                ParameterNotInFamilyErr,
                SelectedParameterCode,
                SelectedFamilyCode);

        if FamilyParameter.Blocked then
            Error(
                FamilyParameterBlockedErr,
                SelectedParameterCode,
                SelectedFamilyCode);

        ProductParameter.Get(
            SelectedParameterCode);

        if ProductParameter.Blocked then
            Error(
                ProductParameterBlockedErr,
                SelectedParameterCode);

        SelectedParameterDescription :=
            ProductParameter.Description;

        SelectedParameterValueType :=
            ProductParameter."Value Type";

        CurrPage.ParameterValues.Page.SetParameterFilter(
            SelectedParameterCode);
    end;

    local procedure CreateParameterForCurrentFamily()
    var
        ParameterCard: Page "SI Wiz. Parameter Card";
    begin
        TestSelectedFamily();

        Clear(ParameterCard);

        ParameterCard.SetNewParameterContext(
            SelectedFamilyCode);

        ParameterCard.RunModal();

        if not ParameterCard.WasCreated() then
            exit;

        SelectParameter(
            ParameterCard.GetCreatedParameterCode());
    end;

    local procedure AddExistingParameterToCurrentFamily()
    var
        ProductParameter: Record "SI Product Parameter";
        AvailableParameters: Page "SI Wiz. Avail. Params";
        ParameterCard: Page "SI Wiz. Parameter Card";
    begin
        TestSelectedFamily();

        Clear(AvailableParameters);

        AvailableParameters.LoadForFamily(
            SelectedFamilyCode);

        AvailableParameters.LookupMode(true);

        if AvailableParameters.RunModal() <>
           Action::LookupOK
        then
            exit;

        AvailableParameters.GetRecord(
            ProductParameter);

        Clear(ParameterCard);

        ParameterCard.SetExistingParameterContext(
            SelectedFamilyCode,
            ProductParameter.Code);

        ParameterCard.RunModal();

        if not ParameterCard.WasCreated() then
            exit;

        SelectParameter(
            ParameterCard.GetCreatedParameterCode());
    end;

    local procedure SelectParameter(
        ParameterCode: Code[30])
    begin
        if ParameterCode = '' then
            exit;

        SelectedParameterCode := ParameterCode;

        LoadSelectedParameter();

        CurrPage.Update(false);
    end;

    local procedure TestSelectedFamily()
    var
        ProductFamily: Record "SI Product Family";
    begin
        if SelectedFamilyCode = '' then
            Error(SelectedFamilyMissingErr);

        ProductFamily.Get(
            SelectedFamilyCode);

        if ProductFamily.Blocked then
            Error(
                FamilyBlockedErr,
                SelectedFamilyCode);
    end;

    local procedure UpdateWizardState()
    begin
        FamilyStepVisible :=
            CurrentStep = CurrentStep::Family;

        ValuesStepVisible :=
            CurrentStep = CurrentStep::Values;

        ConfigurationStepVisible :=
            CurrentStep = CurrentStep::Configuration;

        BackVisible :=
            CurrentStep <> CurrentStep::Family;

        NextVisible :=
            CurrentStep <> CurrentStep::Configuration;

        ContinueLaterVisible :=
            CurrentStep <> CurrentStep::Configuration;

        FinishVisible :=
            CurrentStep = CurrentStep::Configuration;

        FamilyStepCurrent :=
            CurrentStep = CurrentStep::Family;

        ValuesStepCurrent :=
            CurrentStep = CurrentStep::Values;

        ConfigurationStepCurrent :=
            CurrentStep = CurrentStep::Configuration;

        case CurrentStep of
            CurrentStep::Family:
                begin
                    FamilyStepText :=
                        '● 1. СІМЕЙСТВО';

                    ValuesStepText :=
                        '○ 2. ДОПУСТИМІ ЗНАЧЕННЯ';

                    ConfigurationStepText :=
                        '○ 3. КОНФІГУРАЦІЯ';
                end;

            CurrentStep::Values:
                begin
                    FamilyStepText :=
                        '✓ 1. СІМЕЙСТВО';

                    ValuesStepText :=
                        '● 2. ДОПУСТИМІ ЗНАЧЕННЯ';

                    ConfigurationStepText :=
                        '○ 3. КОНФІГУРАЦІЯ';
                end;

            CurrentStep::Configuration:
                begin
                    FamilyStepText :=
                        '✓ 1. СІМЕЙСТВО';

                    ValuesStepText :=
                        '✓ 2. ДОПУСТИМІ ЗНАЧЕННЯ';

                    ConfigurationStepText :=
                        '● 3. КОНФІГУРАЦІЯ';
                end;
        end;
    end;

    var
        CurrentStep: Enum "SI Product Wizard Step";
        FamilyMode: Enum "SI Wizard Family Mode";

        ExistingFamilyCode: Code[30];
        ExistingFamilyDescription: Text[100];
        ExistingFamilyNamePrefix: Text[50];
        ExistingFamilySupportsRecipes: Boolean;
        ExistingFamilyItemCategoryCode: Code[20];
        ExistingFamilyItemCategoryDescription: Text[100];

        NewFamilyCode: Code[30];
        NewFamilyDescription: Text[100];
        NewFamilyDescriptionEN: Text[100];
        NewFamilyNamePrefix: Text[50];
        NewFamilySupportsRecipes: Boolean;
        NewFamilySortOrder: Integer;
        NewFamilyTemplateCode: Code[30];
        NewFamilyItemTemplateCode: Code[20];
        NewFamilySelectedCategoryCode: Code[20];
        NewFamilySelectedCategoryDescription: Text[100];
        NewFamilyCategoryMode: Enum "SI Family Category Mode";
        NewChildCategoryCode: Code[20];
        NewChildCategoryDescription: Text[100];
        CreateChildCategory: Boolean;

        SelectedFamilyCode: Code[30];
        SelectedFamilyDescription: Text[100];

        SelectedParameterCode: Code[30];
        SelectedParameterDescription: Text[100];
        SelectedParameterValueType:
            Enum "SI Param. Value Type";

        FamilyStepText: Text[50];
        ValuesStepText: Text[50];
        ConfigurationStepText: Text[50];

        FamilyInstructionText: Text[500];
        ValuesInstructionText: Text[500];
        ConfigurationInstructionText: Text[500];
        ConfigurationNoteText: Text[500];

        CreateParameterCommandText: Text[50];
        AddParameterCommandText: Text[50];

        FamilyStepVisible: Boolean;
        ValuesStepVisible: Boolean;
        ConfigurationStepVisible: Boolean;

        FamilyStepCurrent: Boolean;
        ValuesStepCurrent: Boolean;
        ConfigurationStepCurrent: Boolean;

        BackVisible: Boolean;
        NextVisible: Boolean;
        ContinueLaterVisible: Boolean;
        FinishVisible: Boolean;

        UseExistingFamily: Boolean;
        CreateNewFamily: Boolean;

        ExistingFamilyRequiredErr: Label
            'Виберіть наявне сімейство продуктів.';

        NewFamilyCodeRequiredErr: Label
            'Укажіть код нового сімейства продуктів.';

        NewFamilyDescriptionRequiredErr: Label
            'Укажіть назву нового сімейства продуктів.';

        NewFamilyCategoryRequiredErr: Label
            'Виберіть категорію товару Business Central для нового сімейства.';

        NewFamilyItemTemplateRequiredErr: Label
            'Не задано шаблон товару. Виберіть наявний Item Template перед створенням сімейства.';

        NewChildCategoryCodeRequiredErr: Label
            'Укажіть код нової дочірньої категорії товару.';

        NewChildCategoryDescriptionRequiredErr: Label
            'Укажіть назву нової дочірньої категорії товару.';

        SelectedFamilyMissingErr: Label
            'Не визначено сімейство поточної продуктової моделі.';


        FamilyDoesNotExistErr: Label
            'Сімейство продуктів %1 не існує.';

        FamilyBlockedErr: Label
            'Сімейство продуктів %1 заблоковане.';

        ParameterNotInFamilyErr: Label
            'Параметр %1 не налаштований для сімейства %2.';

        FamilyParameterBlockedErr: Label
            'Параметр %1 заблокований для сімейства %2.';

        ProductParameterBlockedErr: Label
            'Параметр %1 заблокований.';

        WizardFinishedMsg: Label
            'Демонстраційний цикл майстра завершено.\Сімейство: %1 — %2.';
}