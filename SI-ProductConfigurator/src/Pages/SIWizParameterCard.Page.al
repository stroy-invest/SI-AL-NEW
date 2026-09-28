page 53017 "SI Wiz. Parameter Card"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Параметр сімейства';

    layout
    {
        area(Content)
        {
            group(Parameter)
            {
                Caption = 'Параметр';

                field(ParameterCode; ProductParameterBuffer.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Код';
                    Importance = Promoted;
                    Editable = ParameterIdentityEditable;
                    ToolTip = 'Визначає стабільний корпоративний код параметра.';
                }

                field(ParameterDescription;
                ProductParameterBuffer.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Назва';
                    Importance = Promoted;
                    Editable = ParameterIdentityEditable;
                    ToolTip = 'Визначає назву параметра.';
                }

                field(ParameterBaseItemCategory;
                ProductParameterBuffer."Base Item Category Code")
                {
                    ApplicationArea = All;
                    Caption = 'Базова категорія товару';
                    Importance = Promoted;
                    Editable = ParameterIdentityEditable;
                    ToolTip = 'Визначає базову категорію товарів, для якої призначений параметр. Порожнє значення означає глобальний параметр.';
                }

                field(ParameterDescriptionEN;
                ProductParameterBuffer."Description EN")
                {
                    ApplicationArea = All;
                    Caption = 'Назва англійською';
                    Editable = ParameterIdentityEditable;
                    Visible = false;
                    ToolTip = 'Визначає англійську назву параметра.';
                }

                field(ParameterValueType;
                ProductParameterBuffer."Value Type")
                {
                    ApplicationArea = All;
                    Caption = 'Тип значення';
                    Importance = Promoted;
                    Editable = ParameterIdentityEditable;
                    ToolTip = 'Визначає спосіб зберігання значення параметра.';
                }
            }

            group(FamilyUsage)
            {
                Caption = 'Використання в сімействі';

                field(FamilyCodeField; FamilyCode)
                {
                    ApplicationArea = All;
                    Caption = 'Сімейство';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Визначає сімейство, до якого додається параметр.';
                }

                field(ParameterOrder;
                FamilyParameterBuffer."Parameter Order")
                {
                    ApplicationArea = All;
                    Caption = 'Порядок параметра';
                    Importance = Promoted;
                    ToolTip = 'Визначає порядок параметра в моделі сімейства.';

                    trigger OnValidate()
                    begin
                        ApplyOrderDefaults();
                    end;
                }

                field(Mandatory;
                FamilyParameterBuffer.Mandatory)
                {
                    ApplicationArea = All;
                    Caption = 'Обов’язковий';
                    ToolTip = 'Визначає, чи має значення параметра бути обов’язково задане.';
                }

                field(ERPProjectionRole;
                FamilyParameterBuffer."ERP Projection Role")
                {
                    ApplicationArea = All;
                    Caption = 'Роль в ERP-проєкції';
                    Importance = Promoted;
                    ToolTip = 'Визначає роль параметра у формуванні товару або варіанта.';
                }

                field(IncludeInDescription;
                FamilyParameterBuffer."Include in Description")
                {
                    ApplicationArea = All;
                    Caption = 'Входить у назву';
                    ToolTip = 'Визначає, чи входить значення параметра до сформованої назви продукту.';

                    trigger OnValidate()
                    begin
                        if FamilyParameterBuffer."Include in Description" then begin
                            if FamilyParameterBuffer."Description Order" = 0 then
                                FamilyParameterBuffer."Description Order" :=
                                    FamilyParameterBuffer."Parameter Order";
                        end else
                            FamilyParameterBuffer."Description Order" := 0;

                        UpdateEditableState();
                        CurrPage.Update(false);
                    end;
                }

                field(DescriptionOrder;
                FamilyParameterBuffer."Description Order")
                {
                    ApplicationArea = All;
                    Caption = 'Порядок у назві';
                    Editable = DescriptionOrderEditable;
                    ToolTip = 'Визначає порядок значення параметра у сформованій назві.';
                }

                field(IncludeInSearch;
                FamilyParameterBuffer."Include in Search")
                {
                    ApplicationArea = All;
                    Caption = 'Входить у пошук';
                    ToolTip = 'Визначає, чи входить параметр до пошукового представлення.';
                }

                field(RecipeRelevant;
                FamilyParameterBuffer."Recipe Relevant")
                {
                    ApplicationArea = All;
                    Caption = 'Значущий для рецептури';
                    ToolTip = 'Визначає, чи впливає параметр на вибір або формування рецептури.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdatePageState();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> Action::OK then
            exit(true);

        CreateOrAttachParameter();
        exit(true);
    end;

    procedure SetNewParameterContext(NewFamilyCode: Code[30])
    begin
        ClearPageState();

        FamilyCode := NewFamilyCode;
        ExistingParameterMode := false;

        ProductParameterBuffer.Init();
        FamilyParameterBuffer.Init();

        InitializeParameterCategory();
        InitializeDefaults();
        UpdatePageState();
    end;

    procedure SetExistingParameterContext(
        NewFamilyCode: Code[30];
        ExistingParameterCode: Code[30])
    var
        ProductParameter: Record "SI Product Parameter";
    begin
        ClearPageState();

        FamilyCode := NewFamilyCode;
        ExistingParameterMode := true;

        ProductParameter.Get(ExistingParameterCode);

        ProductParameterBuffer.Init();
        ProductParameterBuffer.TransferFields(ProductParameter);

        FamilyParameterBuffer.Init();
        FamilyParameterBuffer."Family Code" := NewFamilyCode;
        FamilyParameterBuffer."Parameter Code" :=
            ExistingParameterCode;

        InitializeDefaults();
        UpdatePageState();
    end;

    procedure WasCreated(): Boolean
    begin
        exit(CreationSucceeded);
    end;

    procedure GetCreatedParameterCode(): Code[30]
    begin
        exit(CreatedParameterCode);
    end;

    local procedure CreateOrAttachParameter()
    var
        ProductConfigMgt: Codeunit "SI Product Config. Mgt.";
    begin
        ValidateInput();

        if ExistingParameterMode then
            CreatedParameterCode :=
                ProductConfigMgt.AddExistingParameterToFamily(
                    FamilyCode,
                    ProductParameterBuffer.Code,
                    FamilyParameterBuffer)
        else
            CreatedParameterCode :=
                ProductConfigMgt.CreateParameterForFamily(
                    FamilyCode,
                    ProductParameterBuffer,
                    FamilyParameterBuffer);

        CreationSucceeded := true;
    end;

    local procedure InitializeParameterCategory()
    var
        ProductFamily: Record "SI Product Family";
    begin
        if FamilyCode = '' then
            exit;

        ProductFamily.Get(FamilyCode);
        ProductParameterBuffer."Base Item Category Code" :=
            ProductFamily."Item Category Code";
    end;

    local procedure InitializeDefaults()
    begin
        FamilyParameterBuffer."Family Code" :=
            FamilyCode;

        FamilyParameterBuffer."Parameter Code" :=
            ProductParameterBuffer.Code;

        FamilyParameterBuffer."Parameter Order" :=
            GetNextParameterOrder();

        FamilyParameterBuffer.Mandatory := true;
        FamilyParameterBuffer."ERP Projection Role" :=
            FamilyParameterBuffer."ERP Projection Role"::"Item Identity";

        FamilyParameterBuffer."Include in Description" := true;
        FamilyParameterBuffer."Description Order" :=
            FamilyParameterBuffer."Parameter Order";

        FamilyParameterBuffer."Include in Search" := true;

        UpdateEditableState();
    end;

    local procedure ApplyOrderDefaults()
    begin
        if FamilyParameterBuffer."Include in Description" then
            FamilyParameterBuffer."Description Order" :=
                FamilyParameterBuffer."Parameter Order";

        CurrPage.Update(false);
    end;

    local procedure UpdatePageState()
    begin
        ParameterIdentityEditable :=
            not ExistingParameterMode;

        UpdateEditableState();
    end;

    local procedure UpdateEditableState()
    begin
        DescriptionOrderEditable :=
            FamilyParameterBuffer."Include in Description";
    end;

    local procedure GetNextParameterOrder(): Integer
    var
        FamilyParameter: Record "SI Family Parameter";
    begin
        FamilyParameter.SetCurrentKey(
            "Family Code",
            "Parameter Order",
            "Parameter Code");

        FamilyParameter.SetRange(
            "Family Code",
            FamilyCode);

        if FamilyParameter.FindLast() then
            exit(FamilyParameter."Parameter Order" + 10);

        exit(10);
    end;

    local procedure ValidateInput()
    begin
        if FamilyCode = '' then
            Error(FamilyRequiredErr);

        ProductParameterBuffer.TestField(Code);
        ProductParameterBuffer.TestField(Description);

        FamilyParameterBuffer."Family Code" :=
            FamilyCode;

        FamilyParameterBuffer."Parameter Code" :=
            ProductParameterBuffer.Code;

        FamilyParameterBuffer.TestField(
            "Parameter Order");

        if FamilyParameterBuffer."Include in Description" then
            FamilyParameterBuffer.TestField(
                "Description Order");
    end;

    local procedure ClearPageState()
    begin
        Clear(ProductParameterBuffer);
        Clear(FamilyParameterBuffer);

        Clear(FamilyCode);
        Clear(CreatedParameterCode);

        Clear(ExistingParameterMode);
        Clear(CreationSucceeded);

        Clear(ParameterIdentityEditable);
        Clear(DescriptionOrderEditable);
    end;

    var
        ProductParameterBuffer:
            Record "SI Product Parameter" temporary;

        FamilyParameterBuffer:
            Record "SI Family Parameter" temporary;

        FamilyCode: Code[30];
        CreatedParameterCode: Code[30];

        ExistingParameterMode: Boolean;
        CreationSucceeded: Boolean;

        ParameterIdentityEditable: Boolean;
        DescriptionOrderEditable: Boolean;

        FamilyRequiredErr: Label
            'Не визначено сімейство продуктів.';
}