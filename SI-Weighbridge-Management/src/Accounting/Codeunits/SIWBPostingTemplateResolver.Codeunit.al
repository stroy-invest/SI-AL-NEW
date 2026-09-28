codeunit 59130 "SI WB Posting Templ. Resolver"
{
    procedure ResolveAndAssign(var Header: Record "SI Weighbridge Document"): Code[20]
    var
        Template: Record "SI WB Posting Template";
        BestTemplate: Record "SI WB Posting Template";
        BestScore: Integer;
        CandidateScore: Integer;
        BestCategoryDistance: Integer;
        CandidateCategoryDistance: Integer;
        BestPriority: Integer;
        DocumentDate: Date;
        ResolvedLocationCode: Code[10];
        Ambiguous: Boolean;
    begin
        EnsureCanResolve(Header);

        DocumentDate := GetDocumentDate(Header);
        BestScore := -1;
        BestCategoryDistance := 2147483647;
        BestPriority := -2147483647;
        Ambiguous := false;

        Template.SetRange(Enabled, true);
        if Template.FindSet() then
            repeat
                if IsValidOnDate(Template, DocumentDate) and
                   Matches(Header, Template, CandidateCategoryDistance)
                then begin
                    CandidateScore := SpecificityScore(Template);

                    if IsBetterCandidate(
                        CandidateScore,
                        CandidateCategoryDistance,
                        Template.Priority,
                        BestScore,
                        BestCategoryDistance,
                        BestPriority)
                    then begin
                        BestTemplate := Template;
                        BestScore := CandidateScore;
                        BestCategoryDistance := CandidateCategoryDistance;
                        BestPriority := Template.Priority;
                        Ambiguous := false;
                    end else
                        if IsSameRank(
                            CandidateScore,
                            CandidateCategoryDistance,
                            Template.Priority,
                            BestScore,
                            BestCategoryDistance,
                            BestPriority)
                        then
                            Ambiguous := true;
                end;
            until Template.Next() = 0;

        if BestScore < 0 then
            Error(
                'Для документа %1 не знайдено відповідного увімкненого шаблону обліку, чинного на дату %2.',
                Header."Document No.",
                DocumentDate);

        if Ambiguous then
            Error(
                'Для документа %1 знайдено кілька шаблонів обліку з однаковим пріоритетом, специфічністю та відстанню категорії. Уточніть критерії, період дії або пріоритет шаблонів.',
                Header."Document No.");

        ResolvedLocationCode := ResolveLocation(Header, BestTemplate);

        Header."Posting Template Code" := BestTemplate.Code;
        Header."Posting Template Resolved At" := CurrentDateTime();
        Header."Resolved Location Code" := ResolvedLocationCode;
        Clear(Header."Posting Template Applied At");
        Clear(Header."Posting Template Applied By");
        Header.Modify(true);

        exit(BestTemplate.Code);
    end;

    procedure ClearResolution(var Header: Record "SI Weighbridge Document")
    begin
        Clear(Header."Posting Template Code");
        Clear(Header."Posting Template Resolved At");
        Clear(Header."Resolved Location Code");
        Clear(Header."Posting Template Applied At");
        Clear(Header."Posting Template Applied By");
        Header.Modify(true);
    end;

    local procedure EnsureCanResolve(Header: Record "SI Weighbridge Document")
    begin
        if Header.Status <> "SI WB Document Status"::"Documents Created" then
            Error(
                'Шаблон обліку можна визначати після передачі документа до бухгалтерії. Поточний статус: %1.',
                Format(Header.Status));

        Header.TestField("Basis No.");

        if Header."Operation Type" = "SI WB Operation Type"::Undefined then
            Error('Операцію документа не визначено.');

        if Header."Shipment Scenario" = "SI WB Shipment Scenario"::Undefined then
            Error('Тип операції документа не визначено.');

        if Header."Basis Type" = "SI WB Basis Type"::Undefined then
            Error('Тип документа-підстави не визначено.');
    end;

    local procedure Matches(
        Header: Record "SI Weighbridge Document";
        Template: Record "SI WB Posting Template";
        var CategoryDistance: Integer): Boolean
    begin
        CategoryDistance := 2147483647;

        if (Template."Operation Type" <> "SI WB Operation Type"::Undefined) and
           (Template."Operation Type" <> Header."Operation Type")
        then
            exit(false);

        if (Template."Shipment Scenario" <> "SI WB Shipment Scenario"::Undefined) and
           (Template."Shipment Scenario" <> Header."Shipment Scenario")
        then
            exit(false);

        if (Template."Basis Type" <> "SI WB Basis Type"::Undefined) and
           (Template."Basis Type" <> Header."Basis Type")
        then
            exit(false);

        if Template."Item No." <> '' then
            if not AllDocumentLinesMatchItem(Header."Entry No.", Template."Item No.") then
                exit(false);

        if Template."Item Category Code" <> '' then begin
            if not AllDocumentLinesMatchCategory(
                Header."Entry No.",
                Template."Item Category Code",
                CategoryDistance)
            then
                exit(false);
        end;


        exit(true);
    end;

    local procedure AllDocumentLinesMatchItem(
        DocumentEntryNo: BigInteger;
        ItemNo: Code[20]): Boolean
    var
        Line: Record "SI Weighbridge Document Line";
        HasLine: Boolean;
    begin
        Line.SetRange("Document Entry No.", DocumentEntryNo);
        if Line.FindSet() then
            repeat
                HasLine := true;
                if Line."Item No." <> ItemNo then
                    exit(false);
            until Line.Next() = 0;

        exit(HasLine);
    end;

    local procedure AllDocumentLinesMatchCategory(
        DocumentEntryNo: BigInteger;
        TemplateCategoryCode: Code[20];
        var MaxCategoryDistance: Integer): Boolean
    var
        Line: Record "SI Weighbridge Document Line";
        Item: Record Item;
        LineDistance: Integer;
        HasLine: Boolean;
    begin
        MaxCategoryDistance := 0;

        Line.SetRange("Document Entry No.", DocumentEntryNo);
        if Line.FindSet() then
            repeat
                HasLine := true;

                if Line."Item No." = '' then
                    exit(false);

                if not Item.Get(Line."Item No.") then
                    exit(false);

                if Item."Item Category Code" = '' then
                    exit(false);

                if not TryGetCategoryDistance(
                    Item."Item Category Code",
                    TemplateCategoryCode,
                    LineDistance)
                then
                    exit(false);

                // For multi-line documents the template must cover every line.
                // The farthest line defines the category distance used for ranking.
                if LineDistance > MaxCategoryDistance then
                    MaxCategoryDistance := LineDistance;
            until Line.Next() = 0;

        exit(HasLine);
    end;

    local procedure TryGetCategoryDistance(
        ActualCategoryCode: Code[20];
        TemplateCategoryCode: Code[20];
        var Distance: Integer): Boolean
    var
        ItemCategory: Record "Item Category";
        CurrentCategoryCode: Code[20];
        SafetyCounter: Integer;
    begin
        Distance := 0;
        CurrentCategoryCode := ActualCategoryCode;

        while CurrentCategoryCode <> '' do begin
            if CurrentCategoryCode = TemplateCategoryCode then
                exit(true);

            if not ItemCategory.Get(CurrentCategoryCode) then
                exit(false);

            CurrentCategoryCode := ItemCategory."Parent Category";
            Distance += 1;

            // Protect the resolver from malformed cyclic category trees.
            SafetyCounter += 1;
            if SafetyCounter > 100 then
                Error(
                    'Виявлено некоректну циклічну ієрархію категорій товарів при перевірці категорії %1.',
                    ActualCategoryCode);
        end;

        exit(false);
    end;

    local procedure ResolveLocation(
        Header: Record "SI Weighbridge Document";
        Template: Record "SI WB Posting Template"): Code[10]
    var
        FallbackLocation: Code[10];
    begin
        // Location precedence contract:
        // 1) Template Location Code (historical physical field, shown as "Склад (критерій)")
        // 2) Template Default Location Code
        // 3) Receipt-location fallback configured on Location + category/item/variant rules.
        // Location Code no longer filters template matching; it is a destination value.
        if Template."Location Code" <> '' then
            exit(Template."Location Code");

        if Template."Default Location Code" <> '' then
            exit(Template."Default Location Code");

        if Header."Operation Type" <> "SI WB Operation Type"::Receipt then
            exit('');

        FallbackLocation := ResolveFallbackReceiptLoc(Header);
        if FallbackLocation = '' then
            Error(
                'Для документа %1 шаблон %2 не визначає склад, і в налаштуваннях складів не знайдено однозначного складу прибуткування за замовчуванням.',
                Header."Document No.",
                Template.Code);

        exit(FallbackLocation);
    end;

    local procedure ResolveFallbackReceiptLoc(
        Header: Record "SI Weighbridge Document"): Code[10]
    var
        Location: Record Location;
        BestLocationCode: Code[10];
        BestScore: Integer;
        BestCategoryDistance: Integer;
        BestPriority: Integer;
        CandidateScore: Integer;
        CandidateCategoryDistance: Integer;
        CandidatePriority: Integer;
        Ambiguous: Boolean;
    begin
        BestScore := -1;
        BestCategoryDistance := 2147483647;
        BestPriority := -2147483647;

        Location.SetRange("SI WB Default Receipt", true);
        if Location.FindSet() then
            repeat
                if GetBestLocRuleRank(
                    Header,
                    Location.Code,
                    CandidateScore,
                    CandidateCategoryDistance,
                    CandidatePriority)
                then begin
                    if IsBetterLocCandidate(
                        CandidateScore,
                        CandidateCategoryDistance,
                        CandidatePriority,
                        BestScore,
                        BestCategoryDistance,
                        BestPriority)
                    then begin
                        BestLocationCode := Location.Code;
                        BestScore := CandidateScore;
                        BestCategoryDistance := CandidateCategoryDistance;
                        BestPriority := CandidatePriority;
                        Ambiguous := false;
                    end else
                        if IsSameLocRank(
                            CandidateScore,
                            CandidateCategoryDistance,
                            CandidatePriority,
                            BestScore,
                            BestCategoryDistance,
                            BestPriority)
                        then
                            if BestLocationCode <> Location.Code then
                                Ambiguous := true;
                end;
            until Location.Next() = 0;

        if Ambiguous then
            Error(
                'Для документа %1 знайдено кілька однаково пріоритетних складів прибуткування за замовчуванням. Уточніть правила категорій/товарів/варіантів або їх пріоритет.',
                Header."Document No.");

        exit(BestLocationCode);
    end;

    local procedure GetBestLocRuleRank(
        Header: Record "SI Weighbridge Document";
        LocationCode: Code[10];
        var BestScore: Integer;
        var BestCategoryDistance: Integer;
        var BestPriority: Integer): Boolean
    var
        Rule: Record "SI WB Receipt Location Rule";
        CandidateScore: Integer;
        CandidateCategoryDistance: Integer;
        HasEnabledRule: Boolean;
        HasMatch: Boolean;
    begin
        BestScore := -1;
        BestCategoryDistance := 2147483647;
        BestPriority := -2147483647;

        Rule.SetRange("Location Code", LocationCode);
        Rule.SetRange(Enabled, true);
        if Rule.FindSet() then
            repeat
                HasEnabledRule := true;
                if LocRuleMatches(Header, Rule, CandidateCategoryDistance) then begin
                    HasMatch := true;
                    CandidateScore := LocRuleScore(Rule);

                    if (CandidateScore > BestScore) or
                       ((CandidateScore = BestScore) and (CandidateCategoryDistance < BestCategoryDistance)) or
                       ((CandidateScore = BestScore) and (CandidateCategoryDistance = BestCategoryDistance) and (Rule.Priority > BestPriority))
                    then begin
                        BestScore := CandidateScore;
                        BestCategoryDistance := CandidateCategoryDistance;
                        BestPriority := Rule.Priority;
                    end;
                end;
            until Rule.Next() = 0;

        // An enabled default-receipt Location with no enabled rule is a global fallback.
        if not HasEnabledRule then begin
            BestScore := 0;
            BestCategoryDistance := 2147483647;
            BestPriority := 0;
            exit(true);
        end;

        exit(HasMatch);
    end;

    local procedure LocRuleMatches(
        Header: Record "SI Weighbridge Document";
        Rule: Record "SI WB Receipt Location Rule";
        var CategoryDistance: Integer): Boolean
    begin
        CategoryDistance := 2147483647;

        if Rule."Item No." <> '' then
            if not AllDocumentLinesMatchItem(Header."Entry No.", Rule."Item No.") then
                exit(false);

        if Rule."Variant Code" <> '' then
            if not AllDocumentLinesMatchVariant(
                Header."Entry No.",
                Rule."Item No.",
                Rule."Variant Code")
            then
                exit(false);

        if Rule."Item Category Code" <> '' then begin
            if not AllDocumentLinesMatchCategory(
                Header."Entry No.",
                Rule."Item Category Code",
                CategoryDistance)
            then
                exit(false);
        end else
            CategoryDistance := 2147483647;

        exit(true);
    end;

    local procedure AllDocumentLinesMatchVariant(
        DocumentEntryNo: BigInteger;
        ItemNo: Code[20];
        VariantCode: Code[10]): Boolean
    var
        Line: Record "SI Weighbridge Document Line";
        HasLine: Boolean;
    begin
        Line.SetRange("Document Entry No.", DocumentEntryNo);
        if Line.FindSet() then
            repeat
                HasLine := true;
                if (Line."Item No." <> ItemNo) or
                   (Line."Variant Code" <> VariantCode)
                then
                    exit(false);
            until Line.Next() = 0;

        exit(HasLine);
    end;

    local procedure LocRuleScore(
        Rule: Record "SI WB Receipt Location Rule"): Integer
    var
        Score: Integer;
    begin
        if Rule."Item Category Code" <> '' then
            Score += 20;
        if Rule."Item No." <> '' then
            Score += 40;
        if Rule."Variant Code" <> '' then
            Score += 80;
        exit(Score);
    end;

    local procedure IsBetterLocCandidate(
        CandidateScore: Integer;
        CandidateCategoryDistance: Integer;
        CandidatePriority: Integer;
        BestScore: Integer;
        BestCategoryDistance: Integer;
        BestPriority: Integer): Boolean
    begin
        // For default-location rules specificity is primary; priority breaks ties.
        if CandidateScore <> BestScore then
            exit(CandidateScore > BestScore);
        if CandidateCategoryDistance <> BestCategoryDistance then
            exit(CandidateCategoryDistance < BestCategoryDistance);
        if CandidatePriority <> BestPriority then
            exit(CandidatePriority > BestPriority);
        exit(false);
    end;

    local procedure IsSameLocRank(
        CandidateScore: Integer;
        CandidateCategoryDistance: Integer;
        CandidatePriority: Integer;
        BestScore: Integer;
        BestCategoryDistance: Integer;
        BestPriority: Integer): Boolean
    begin
        exit(
            (CandidateScore = BestScore) and
            (CandidateCategoryDistance = BestCategoryDistance) and
            (CandidatePriority = BestPriority));
    end;

    local procedure GetBasisLocationCode(
        Header: Record "SI Weighbridge Document"): Code[10]
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        if Header."Destination Location Code" <> '' then
            exit(Header."Destination Location Code");

        case Header."Basis Type" of
            "SI WB Basis Type"::"Purchase Order":
                if PurchaseHeader.Get(
                    PurchaseHeader."Document Type"::Order,
                    Header."Basis No.")
                then
                    exit(PurchaseHeader."Location Code");

            "SI WB Basis Type"::"Sales Order":
                if SalesHeader.Get(
                    SalesHeader."Document Type"::Order,
                    Header."Basis No.")
                then
                    exit(SalesHeader."Location Code");
        end;

        exit('');
    end;

    local procedure GetDocumentDate(Header: Record "SI Weighbridge Document"): Date
    begin
        if Header."Weighing Date/Time" <> 0DT then
            exit(DT2Date(Header."Weighing Date/Time"));

        exit(WorkDate());
    end;

    local procedure IsValidOnDate(
        Template: Record "SI WB Posting Template";
        DocumentDate: Date): Boolean
    begin
        if (Template."Valid From" <> 0D) and
           (DocumentDate < Template."Valid From")
        then
            exit(false);

        if (Template."Valid To" <> 0D) and
           (DocumentDate > Template."Valid To")
        then
            exit(false);

        exit(true);
    end;

    local procedure IsBetterCandidate(
        CandidateScore: Integer;
        CandidateCategoryDistance: Integer;
        CandidatePriority: Integer;
        BestScore: Integer;
        BestCategoryDistance: Integer;
        BestPriority: Integer): Boolean
    begin
        // Priority is the explicit administrative override mechanism.
        // It is evaluated only after the candidate has passed all routing
        // criteria and validity checks. A higher number means higher priority.
        // This lets a time-bounded template override a permanent template
        // without changing the permanent BC master-data configuration.
        if CandidatePriority <> BestPriority then
            exit(CandidatePriority > BestPriority);

        // Among candidates with the same priority, prefer the more specific
        // routing rule, then the nearest matching item category ancestor.
        if CandidateScore <> BestScore then
            exit(CandidateScore > BestScore);

        if CandidateCategoryDistance <> BestCategoryDistance then
            exit(CandidateCategoryDistance < BestCategoryDistance);

        exit(false);
    end;

    local procedure IsSameRank(
        CandidateScore: Integer;
        CandidateCategoryDistance: Integer;
        CandidatePriority: Integer;
        BestScore: Integer;
        BestCategoryDistance: Integer;
        BestPriority: Integer): Boolean
    begin
        exit(
            (CandidateScore = BestScore) and
            (CandidateCategoryDistance = BestCategoryDistance) and
            (CandidatePriority = BestPriority));
    end;

    local procedure SpecificityScore(Template: Record "SI WB Posting Template"): Integer
    var
        Score: Integer;
    begin
        if Template."Operation Type" <> "SI WB Operation Type"::Undefined then
            Score += 100;

        if Template."Shipment Scenario" <> "SI WB Shipment Scenario"::Undefined then
            Score += 80;

        if Template."Basis Type" <> "SI WB Basis Type"::Undefined then
            Score += 60;

        if Template."Item No." <> '' then
            Score += 40;

        if Template."Item Category Code" <> '' then
            Score += 20;


        exit(Score);
    end;
}
