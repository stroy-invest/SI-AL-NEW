page 53019 "SI Wiz. Avail. Params"
{
    PageType = List;
    SourceTable = "SI Product Parameter";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Caption = 'Додати наявний параметр';
    UsageCategory = None;

    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    SourceTableView = sorting(Code);

    layout
    {
        area(Content)
        {
            repeater(Parameters)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Код';
                    Importance = Promoted;
                    ToolTip = 'Визначає код корпоративного параметра.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Назва';
                    Importance = Promoted;
                    ToolTip = 'Визначає назву корпоративного параметра.';
                }

                field("Base Item Category Code"; Rec."Base Item Category Code")
                {
                    ApplicationArea = All;
                    Caption = 'Базова категорія товару';
                    ToolTip = 'Визначає базову категорію товарів параметра. Порожнє значення означає глобальний параметр.';
                }

                field("Value Type"; Rec."Value Type")
                {
                    ApplicationArea = All;
                    Caption = 'Тип значення';
                    ToolTip = 'Визначає тип значення параметра.';
                }
            }
        }
    }

    procedure LoadForFamily(FamilyCode: Code[30])
    var
        ProductParameter: Record "SI Product Parameter";
        ProductFamily: Record "SI Product Family";
        FamilyParameter: Record "SI Family Parameter";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        ProductFamily.Get(FamilyCode);
        ProductParameter.SetRange(Blocked, false);

        if ProductParameter.FindSet() then
            repeat
                if IsApplicableToCategory(
                    ProductParameter."Base Item Category Code",
                    ProductFamily."Item Category Code")
                then
                    if not FamilyParameter.Get(
                        FamilyCode,
                        ProductParameter.Code)
                    then begin
                        Rec.Init();
                        Rec.TransferFields(ProductParameter);
                        Rec.Insert();
                    end;
            until ProductParameter.Next() = 0;

        Rec.Reset();

        if Rec.FindFirst() then;
    end;

    local procedure IsApplicableToCategory(
        ParameterCategoryCode: Code[20];
        FamilyCategoryCode: Code[20]): Boolean
    var
        ItemCategory: Record "Item Category";
        CurrentCategoryCode: Code[20];
    begin
        if ParameterCategoryCode = '' then
            exit(true);

        CurrentCategoryCode := FamilyCategoryCode;

        while CurrentCategoryCode <> '' do begin
            if CurrentCategoryCode = ParameterCategoryCode then
                exit(true);

            if not ItemCategory.Get(CurrentCategoryCode) then
                exit(false);

            CurrentCategoryCode := ItemCategory."Parent Category";
        end;

        exit(false);
    end;
}