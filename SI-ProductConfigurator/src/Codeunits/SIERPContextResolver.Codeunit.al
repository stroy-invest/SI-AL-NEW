codeunit 53005 "SI ERP Context Resolver"
{
    /***************************************
            'Визначення ERP-контексту'
    ***************************************/
    /*
        Головна процедура сервісу
        Отримує temporary preview buffer і послідовно визначає:
        ---
        Product Configuration
                ↓
        Product Family
                ↓
        Item Category
                ↓
        Item Template
                ↓
        Base UoM
        ---
        Виклик у майбутньому SI ERP Projection Mgt. : ERPContextResolver.ResolveContext(PrevBuffer);
    */
    procedure ResolveContext(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ProductConfig: Record "SI Product Config.";
        ProductFamily: Record "SI Product Family";
        ManualUoMCode: Code[10];
    begin
        PrevBuffer.TestField("Configuration No.");

        ProductConfig.Get(PrevBuffer."Configuration No.");
        ProductFamily.Get(ProductConfig."Family Code");

        PreserveManualUoM(
            PrevBuffer,
            ManualUoMCode);

        SetFamilyContext(
            PrevBuffer,
            ProductFamily);

        ResolveItemCategory(
            ProductFamily,
            PrevBuffer);

        if ProductConfig."Base Item No." = '' then
            ResolveItemTemplate(
                ProductFamily,
                PrevBuffer)
        else begin
            Clear(PrevBuffer."Item Template Code");
            Clear(PrevBuffer."Item Template Description");
        end;

        ResolveBaseUoM(
            PrevBuffer,
            ManualUoMCode);
    end;
    //------------------------------------
    /*
        Заповнює:
        "Item Category Code"
        "Item Category Description"
        Джерело: ProductFamily."Item Category Code"
        Якщо поле порожнє або категорії не існує, Resolver не викликає Error. Він залишає дані неповними
        Це навмисно: повідомлення про неготовність формуватиме майбутній SI ERP Projection Validator
    */
    procedure ResolveItemCategory(
        ProductFamily: Record "SI Product Family";
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ItemCategory: Record "Item Category";
    begin
        Clear(PrevBuffer."Item Category Code");
        Clear(PrevBuffer."Item Category Description");

        if ProductFamily."Item Category Code" = '' then
            exit;

        PrevBuffer."Item Category Code" :=
            ProductFamily."Item Category Code";

        if not ItemCategory.Get(
            ProductFamily."Item Category Code")
        then
            exit;

        PrevBuffer."Item Category Description" :=
            ItemCategory.Description;
    end;
    //------------------------------------
    /*
		Заповнює:
		"Item Template Code"
		"Item Template Description"
		Template на Sprint 1 залишається рекомендованим, але не обов’язковим
	*/
    procedure ResolveItemTemplate(
        ProductFamily: Record "SI Product Family";
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary)
    var
        ItemTemplate: Record "Item Templ.";
        MatchingTemplateCount: Integer;
    begin
        Clear(PrevBuffer."Item Template Code");
        Clear(PrevBuffer."Item Template Description");

        // 1. Explicit family setup always has priority.
        if ProductFamily."Item Template Code" <> '' then begin
            PrevBuffer."Item Template Code" :=
                ProductFamily."Item Template Code";

            if ItemTemplate.Get(ProductFamily."Item Template Code") then
                PrevBuffer."Item Template Description" :=
                    ItemTemplate.Description;

            exit;
        end;

        // 2. Fallback to the standard Item Template directory by Item Category.
        if PrevBuffer."Item Category Code" = '' then
            exit;

        ItemTemplate.Reset();
        ItemTemplate.SetRange(
            "Item Category Code",
            PrevBuffer."Item Category Code");

        MatchingTemplateCount := ItemTemplate.Count();

        if MatchingTemplateCount = 0 then
            exit;

        if MatchingTemplateCount > 1 then
            Error(
                MultipleCategoryTemplatesErr,
                PrevBuffer."Item Category Code",
                MatchingTemplateCount,
                ProductFamily.Code);

        ItemTemplate.FindFirst();
        PrevBuffer."Item Template Code" := ItemTemplate.Code;
        PrevBuffer."Item Template Description" := ItemTemplate.Description;
    end;
    //------------------------------------
    /*	
		Реалізує зафіксований пріоритет:
		1. Item Category
		2. Item Template
		3. Manual

		Тобто:
		Category UoM знайдена
			→ використати її
			→ Template і Manual ігноруються
		Category UoM відсутня
		Template UoM знайдена
			→ використати Template
		Category і Template UoM відсутні
		Manual UoM задана
			→ зберегти Manual
		Нічого не визначено
			→ Source = None

		Для категорії Resolver використовує вже задеплоєний Foundation-сервіс:
		Codeunit "SI Item UoM Mgt."
	*/
    procedure ResolveBaseUoM(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        ManualUoMCode: Code[10])
    var
        ItemUoMMgt: Codeunit "SI Item UoM Mgt.";
        ItemTemplate: Record "Item Templ.";
        BaseUoMCode: Code[10];
    begin
        Clear(PrevBuffer."Base UoM Code");
        PrevBuffer."Base UoM Source" :=
            PrevBuffer."Base UoM Source"::None;

        if ItemUoMMgt.TryGetCategoryDefaultBaseUoM(
            PrevBuffer."Item Category Code",
            BaseUoMCode)
        then begin
            PrevBuffer.SetAutomaticBaseUoM(
                BaseUoMCode,
                PrevBuffer."Base UoM Source"::"Item Category");
            exit;
        end;

        if PrevBuffer."Item Template Code" <> '' then
            if ItemTemplate.Get(
                PrevBuffer."Item Template Code")
            then
                if ItemTemplate."Base Unit of Measure" <> '' then begin
                    PrevBuffer.SetAutomaticBaseUoM(
                        ItemTemplate."Base Unit of Measure",
                        PrevBuffer."Base UoM Source"::"Item Template");
                    exit;
                end;

        if ManualUoMCode <> '' then
            PrevBuffer.SetManualBaseUoM(ManualUoMCode);
    end;
    //------------------------------------
    /*
        Процедура знадобиться Validator-у для правила:
        Family Item Category = terminal leaf
        Вона повертає true, якщо в категорії є дочірні вузли.
        Назви всіх нових об’єктів, процедур і змінних не перевищують 30 символів.
    */
    procedure HasChildCategories(
        ItemCategoryCode: Code[20]): Boolean
    var
        ChildCategory: Record "Item Category";
    begin
        if ItemCategoryCode = '' then
            exit(false);

        ChildCategory.SetRange(
            "Parent Category",
            ItemCategoryCode);

        exit(not ChildCategory.IsEmpty());
    end;

    /*	
        Збереження Manual UoM
        -----------------------------------
        Перед повторним resolution процедура запам’ятовує ручне значення: PreserveManualUoM(...)
        Це необхідно для сценарію:

        користувач вибрав Manual UoM
                ↓
        натиснув «Оновити»
                ↓
        manual value не повинна зникнути

        Але автоматичне джерело має пріоритет.
        Наприклад, якщо після зміни master data категорія отримала Default UoM:
        Manual = KG
        Category = PCS
        --->  після refresh результат буде:
        Base UoM = PCS
        Source = Item Category
        Це відповідає поточному resolution contract	
    */
    local procedure SetFamilyContext(
        var PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        ProductFamily: Record "SI Product Family")
    begin
        PrevBuffer."Family Code" :=
            ProductFamily.Code;

        PrevBuffer."Family Description" :=
            ProductFamily.Description;
    end;

    local procedure PreserveManualUoM(
        PrevBuffer: Record "SI ERP Projection Prev Buffer" temporary;
        var ManualUoMCode: Code[10])
    begin
        Clear(ManualUoMCode);

        if PrevBuffer."Base UoM Source" <>
           PrevBuffer."Base UoM Source"::Manual
        then
            exit;

        ManualUoMCode :=
            PrevBuffer."Base UoM Code";
    end;


    var
        MultipleCategoryTemplatesErr: Label
            'Для категорії товару %1 знайдено %2 шаблони товару. Для однозначного вибору вкажіть шаблон безпосередньо в налаштуваннях сімейства %3.';
}
