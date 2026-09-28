page 50186 "SI New Item Category"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Створити категорію товару';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(CategoryCode; CategoryCode)
                {
                    ApplicationArea = All;
                    Caption = 'Код';
                    ToolTip = 'Вкажіть унікальний код нової категорії товару.';

                    trigger OnValidate()
                    begin
                        CategoryCode := UpperCase(DelChr(CategoryCode, '=', ' '));
                    end;
                }

                field(CategoryDescription; CategoryDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Назва';
                    ToolTip = 'Вкажіть назву нової категорії товару.';
                }

                field(ParentCategoryCode; ParentCategoryCode)
                {
                    ApplicationArea = All;
                    Caption = 'Батьківська категорія';
                    Editable = false;
                    ToolTip = 'Визначає батьківську категорію відповідно до вибраного контексту створення.';
                }

                field(BaseUoMCode; BaseUoMCode)
                {
                    ApplicationArea = All;
                    Caption = 'Базова одиниця виміру';
                    Editable = BaseUoMEditable;
                    TableRelation = "Unit of Measure".Code;
                    ToolTip = 'Визначає базову одиницю виміру. Для дочірньої категорії значення успадковується від батьківської; для кореневої категорії його можна вибрати вручну.';
                }
            }

            group(CategoryAttributesGroup)
            {
                Caption = 'Успадковані атрибути';

                part(CategoryAttributes; "SI New Item Cat. Attrs")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.CategoryAttributes.Page.InitializeForParent(ParentCategoryCode);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        NewItemCategory: Record "Item Category";
    begin
        if CloseAction <> Action::OK then
            exit(true);

        CategoryCode := UpperCase(DelChr(CategoryCode, '=', ' '));
        if CategoryCode = '' then
            Error(CategoryCodeRequiredErr);

        CategoryDescription := NormalizeEnteredDescription(CategoryDescription);
        if CategoryDescription = '' then
            Error(CategoryDescriptionRequiredErr);

        if NewItemCategory.Get(CategoryCode) then
            Error(CategoryCodeAlreadyExistsErr, CategoryCode);

        NewItemCategory.Init();
        NewItemCategory.Validate("Parent Category", ParentCategoryCode);
        NewItemCategory.Validate("SI Default Base UoM Code", BaseUoMCode);
        NewItemCategory.Validate(Code, CategoryCode);
        NewItemCategory.Validate(Description, CategoryDescription);
        NewItemCategory.Insert(true);

        CreatedCategory := true;

        exit(true);
    end;

    procedure InitializeContext(NewParentCategoryCode: Code[20]; NewBaseUoMCode: Code[10])
    begin
        Clear(CategoryCode);
        Clear(CategoryDescription);
        Clear(CreatedCategory);
        ParentCategoryCode := NewParentCategoryCode;
        BaseUoMCode := NewBaseUoMCode;
        BaseUoMEditable := ParentCategoryCode = '';
    end;

    procedure GetCategoryCode(): Code[20]
    begin
        exit(CategoryCode);
    end;

    procedure CategoryWasCreated(): Boolean
    begin
        exit(CreatedCategory);
    end;

    local procedure NormalizeEnteredDescription(Value: Text[100]): Text[100]
    begin
        Value := DelChr(Value, '<>', ' ');
        while StrPos(Value, '  ') > 0 do
            Value := Value.Replace('  ', ' ');

        exit(CopyStr(Value, 1, MaxStrLen(CategoryDescription)));
    end;

    var
        CategoryCode: Code[20];
        CategoryDescription: Text[100];
        ParentCategoryCode: Code[20];
        BaseUoMCode: Code[10];
        BaseUoMEditable: Boolean;
        CreatedCategory: Boolean;
        CategoryCodeRequiredErr: Label 'Вкажіть код нової категорії.';
        CategoryDescriptionRequiredErr: Label 'Вкажіть назву нової категорії.';
        CategoryCodeAlreadyExistsErr: Label 'Категорія з кодом %1 уже існує. Вкажіть інший код.';
}
