codeunit 59131 "SI WB Posting Templ. Applier"
{
    procedure Apply(var Header: Record "SI Weighbridge Document")
    var
        Resolver: Codeunit "SI WB Posting Templ. Resolver";
        Template: Record "SI WB Posting Template";
    begin
        EnsureCanApply(Header);

        // Always resolve immediately before Apply. This guarantees that
        // validity dates, priority overrides and location fallback rules
        // are evaluated against the current configuration.
        Resolver.ResolveAndAssign(Header);

        Header.TestField("Posting Template Code");
        if not Template.Get(Header."Posting Template Code") then
            Error(
                'Шаблон обліку %1, визначений для документа %2, більше не існує.',
                Header."Posting Template Code",
                Header."Document No.");

        case Header."Basis Type" of
            "SI WB Basis Type"::"Purchase Order":
                ApplyToPurchaseOrder(Header, Template);

            "SI WB Basis Type"::"Sales Order":
                ApplyToSalesOrder(Header, Template);

            "SI WB Basis Type"::Request:
                Error(
                    'Застосування шаблону до заявки / внутрішнього переміщення ще не реалізовано в поточному MVP.');

            else
                Error(
                    'Для документа %1 не визначено підтримуваний тип документа-підстави.',
                    Header."Document No.");
        end;

        Header."Posting Template Applied At" := CurrentDateTime();
        Header."Posting Template Applied By" := UserSecurityId();
        Header.Modify(true);

        OnAfterPostingTemplateApplied(Header, Template);
    end;

    local procedure EnsureCanApply(Header: Record "SI Weighbridge Document")
    begin
        if Header.Status <> "SI WB Document Status"::"Documents Created" then
            Error(
                'Шаблон обліку можна застосовувати тільки після передачі документа до бухгалтерії. Поточний статус: %1.',
                Format(Header.Status));

        Header.TestField("Basis No.");

        if Header."Operation Type" = "SI WB Operation Type"::Undefined then
            Error('Операцію документа не визначено.');

        if Header."Shipment Scenario" = "SI WB Shipment Scenario"::Undefined then
            Error('Тип операції документа не визначено.');

        if Header."Basis Type" = "SI WB Basis Type"::Undefined then
            Error('Тип документа-підстави не визначено.');
    end;

    local procedure ApplyToPurchaseOrder(
        var Header: Record "SI Weighbridge Document";
        Template: Record "SI WB Posting Template")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if Header."Operation Type" <> "SI WB Operation Type"::Receipt then
            Error('Purchase Order допускається тільки для операції "Надходження".');

        if Header."Shipment Scenario" <> "SI WB Shipment Scenario"::Supply then
            Error('Purchase Order допускається тільки для сценарію "Постачання".');

        if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Header."Basis No.") then
            Error('Purchase Order %1 не знайдено.', Header."Basis No.");

        if (Header."Vendor No." <> '') and
           (PurchaseHeader."Buy-from Vendor No." <> Header."Vendor No.")
        then
            Error(
                'Purchase Order %1 належить постачальнику %2, а ваговий документ %3 — постачальнику %4.',
                PurchaseHeader."No.",
                PurchaseHeader."Buy-from Vendor No.",
                Header."Document No.",
                Header."Vendor No.");

        PurchaseHeader.SetHideValidationDialog(true);
        ApplyPurchaseHeaderDefaults(PurchaseHeader, Header, Template);
        PurchaseHeader.Modify(true);

        ApplyPurchaseLineDefaults(Header, PurchaseHeader, Template);

        Header."ERP Document Type" := 'Purchase Order';
        Header."ERP Document No." := PurchaseHeader."No.";
    end;

    local procedure ApplyPurchaseHeaderDefaults(
        var PurchaseHeader: Record "Purchase Header";
        Header: Record "SI Weighbridge Document";
        Template: Record "SI WB Posting Template")
    begin
        if Template."Vendor Posting Group" <> '' then
            PurchaseHeader.Validate("Vendor Posting Group", Template."Vendor Posting Group");

        if Template."Gen. Bus. Posting Group" <> '' then
            PurchaseHeader.Validate("Gen. Bus. Posting Group", Template."Gen. Bus. Posting Group");

        if Template."VAT Bus. Posting Group" <> '' then
            PurchaseHeader.Validate("VAT Bus. Posting Group", Template."VAT Bus. Posting Group");

        if Header."Resolved Location Code" <> '' then
            PurchaseHeader.Validate("Location Code", Header."Resolved Location Code");

        if Template."Shortcut Dimension 1 Code" <> '' then
            PurchaseHeader.Validate("Shortcut Dimension 1 Code", Template."Shortcut Dimension 1 Code");

        if Template."Shortcut Dimension 2 Code" <> '' then
            PurchaseHeader.Validate("Shortcut Dimension 2 Code", Template."Shortcut Dimension 2 Code");
    end;

    local procedure ApplyPurchaseLineDefaults(
        var Header: Record "SI Weighbridge Document";
        PurchaseHeader: Record "Purchase Header";
        Template: Record "SI WB Posting Template")
    var
        WBLine: Record "SI Weighbridge Document Line";
        PurchaseLine: Record "Purchase Line";
    begin
        WBLine.SetRange("Document Entry No.", Header."Entry No.");
        if not WBLine.FindSet(true) then
            Error('Документ %1 не містить товарних рядків.', Header."Document No.");

        repeat
            WBLine.TestField("Item No.");
            FindUniquePurchaseLine(PurchaseHeader, WBLine, PurchaseLine);

            if Header."Resolved Location Code" <> '' then
                PurchaseLine.Validate("Location Code", Header."Resolved Location Code");

            if Template."Gen. Bus. Posting Group" <> '' then
                PurchaseLine.Validate("Gen. Bus. Posting Group", Template."Gen. Bus. Posting Group");

            if Template."Gen. Prod. Posting Group" <> '' then
                PurchaseLine.Validate("Gen. Prod. Posting Group", Template."Gen. Prod. Posting Group");

            if Template."VAT Bus. Posting Group" <> '' then
                PurchaseLine.Validate("VAT Bus. Posting Group", Template."VAT Bus. Posting Group");

            if Template."VAT Prod. Posting Group" <> '' then
                PurchaseLine.Validate("VAT Prod. Posting Group", Template."VAT Prod. Posting Group");

            if Template."Shortcut Dimension 1 Code" <> '' then
                PurchaseLine.Validate("Shortcut Dimension 1 Code", Template."Shortcut Dimension 1 Code");

            if Template."Shortcut Dimension 2 Code" <> '' then
                PurchaseLine.Validate("Shortcut Dimension 2 Code", Template."Shortcut Dimension 2 Code");

            PurchaseLine.Modify(true);

            WBLine."ERP Line No." := PurchaseLine."Line No.";
            WBLine.Modify(true);
        until WBLine.Next() = 0;
    end;

    local procedure FindUniquePurchaseLine(
        PurchaseHeader: Record "Purchase Header";
        WBLine: Record "SI Weighbridge Document Line";
        var PurchaseLine: Record "Purchase Line")
    var
        MatchCount: Integer;
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", WBLine."Item No.");
        PurchaseLine.SetRange("Variant Code", WBLine."Variant Code");

        MatchCount := PurchaseLine.Count();
        if MatchCount = 0 then
            Error(
                'У Purchase Order %1 не знайдено рядок товару %2, варіант %3, для рядка вагового документа %4.',
                PurchaseHeader."No.",
                WBLine."Item No.",
                WBLine."Variant Code",
                WBLine."Line No.");

        if MatchCount > 1 then
            Error(
                'У Purchase Order %1 знайдено %2 рядків товару %3, варіант %4. Автоматично визначити ERP Line No. для рядка вагового документа %5 неможливо.',
                PurchaseHeader."No.",
                MatchCount,
                WBLine."Item No.",
                WBLine."Variant Code",
                WBLine."Line No.");

        PurchaseLine.FindFirst();
    end;

    local procedure ApplyToSalesOrder(
        var Header: Record "SI Weighbridge Document";
        Template: Record "SI WB Posting Template")
    var
        SalesHeader: Record "Sales Header";
    begin
        if Header."Operation Type" <> "SI WB Operation Type"::Shipment then
            Error('Sales Order допускається тільки для операції "Відвантаження".');

        if Header."Shipment Scenario" <> "SI WB Shipment Scenario"::Sales then
            Error('Sales Order допускається тільки для сценарію "Продаж".');

        if not SalesHeader.Get(SalesHeader."Document Type"::Order, Header."Basis No.") then
            Error('Sales Order %1 не знайдено.', Header."Basis No.");

        if (Header."Customer No." <> '') and
           (SalesHeader."Sell-to Customer No." <> Header."Customer No.")
        then
            Error(
                'Sales Order %1 належить клієнту %2, а ваговий документ %3 — клієнту %4.',
                SalesHeader."No.",
                SalesHeader."Sell-to Customer No.",
                Header."Document No.",
                Header."Customer No.");

        SalesHeader.SetHideValidationDialog(true);
        ApplySalesHeaderDefaults(SalesHeader, Header, Template);
        SalesHeader.Modify(true);

        ApplySalesLineDefaults(Header, SalesHeader, Template);

        Header."ERP Document Type" := 'Sales Order';
        Header."ERP Document No." := SalesHeader."No.";
    end;

    local procedure ApplySalesHeaderDefaults(
        var SalesHeader: Record "Sales Header";
        Header: Record "SI Weighbridge Document";
        Template: Record "SI WB Posting Template")
    begin
        if Template."Customer Posting Group" <> '' then
            SalesHeader.Validate("Customer Posting Group", Template."Customer Posting Group");

        if Template."Gen. Bus. Posting Group" <> '' then
            SalesHeader.Validate("Gen. Bus. Posting Group", Template."Gen. Bus. Posting Group");

        if Template."VAT Bus. Posting Group" <> '' then
            SalesHeader.Validate("VAT Bus. Posting Group", Template."VAT Bus. Posting Group");

        if Header."Resolved Location Code" <> '' then
            SalesHeader.Validate("Location Code", Header."Resolved Location Code");

        if Template."Shortcut Dimension 1 Code" <> '' then
            SalesHeader.Validate("Shortcut Dimension 1 Code", Template."Shortcut Dimension 1 Code");

        if Template."Shortcut Dimension 2 Code" <> '' then
            SalesHeader.Validate("Shortcut Dimension 2 Code", Template."Shortcut Dimension 2 Code");
    end;

    local procedure ApplySalesLineDefaults(
        var Header: Record "SI Weighbridge Document";
        SalesHeader: Record "Sales Header";
        Template: Record "SI WB Posting Template")
    var
        WBLine: Record "SI Weighbridge Document Line";
        SalesLine: Record "Sales Line";
    begin
        WBLine.SetRange("Document Entry No.", Header."Entry No.");
        if not WBLine.FindSet(true) then
            Error('Документ %1 не містить товарних рядків.', Header."Document No.");

        repeat
            WBLine.TestField("Item No.");
            FindUniqueSalesLine(SalesHeader, WBLine, SalesLine);

            if Header."Resolved Location Code" <> '' then
                SalesLine.Validate("Location Code", Header."Resolved Location Code");

            if Template."Gen. Bus. Posting Group" <> '' then
                SalesLine.Validate("Gen. Bus. Posting Group", Template."Gen. Bus. Posting Group");

            if Template."Gen. Prod. Posting Group" <> '' then
                SalesLine.Validate("Gen. Prod. Posting Group", Template."Gen. Prod. Posting Group");

            if Template."VAT Bus. Posting Group" <> '' then
                SalesLine.Validate("VAT Bus. Posting Group", Template."VAT Bus. Posting Group");

            if Template."VAT Prod. Posting Group" <> '' then
                SalesLine.Validate("VAT Prod. Posting Group", Template."VAT Prod. Posting Group");

            if Template."Shortcut Dimension 1 Code" <> '' then
                SalesLine.Validate("Shortcut Dimension 1 Code", Template."Shortcut Dimension 1 Code");

            if Template."Shortcut Dimension 2 Code" <> '' then
                SalesLine.Validate("Shortcut Dimension 2 Code", Template."Shortcut Dimension 2 Code");

            SalesLine.Modify(true);

            WBLine."ERP Line No." := SalesLine."Line No.";
            WBLine.Modify(true);
        until WBLine.Next() = 0;
    end;

    local procedure FindUniqueSalesLine(
        SalesHeader: Record "Sales Header";
        WBLine: Record "SI Weighbridge Document Line";
        var SalesLine: Record "Sales Line")
    var
        MatchCount: Integer;
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", WBLine."Item No.");
        SalesLine.SetRange("Variant Code", WBLine."Variant Code");

        MatchCount := SalesLine.Count();
        if MatchCount = 0 then
            Error(
                'У Sales Order %1 не знайдено рядок товару %2, варіант %3, для рядка вагового документа %4.',
                SalesHeader."No.",
                WBLine."Item No.",
                WBLine."Variant Code",
                WBLine."Line No.");

        if MatchCount > 1 then
            Error(
                'У Sales Order %1 знайдено %2 рядків товару %3, варіант %4. Автоматично визначити ERP Line No. для рядка вагового документа %5 неможливо.',
                SalesHeader."No.",
                MatchCount,
                WBLine."Item No.",
                WBLine."Variant Code",
                WBLine."Line No.");

        SalesLine.FindFirst();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostingTemplateApplied(
        var Header: Record "SI Weighbridge Document";
        Template: Record "SI WB Posting Template")
    begin
    end;
}
