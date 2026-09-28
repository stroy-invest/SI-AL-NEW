codeunit 59120 "SI WB Document Generation Mgt."
{
    procedure CreateDocuments(
        var Header: Record "SI Weighbridge Document")
    var
        UoMConversionMgt: Codeunit "SI WB UoM Conversion Mgt.";
        HeaderEntryNo: BigInteger;
    begin
        HeaderEntryNo := Header."Entry No.";

        EnsureManagerStage(Header);
        EnsureOutboundGenerationRoute(Header);
        UoMConversionMgt.EnsureCanAdvance(Header);
        EnsureBasisIsValid(Header);

        case Header."Basis Type" of
            "SI WB Basis Type"::"Sales Order":
                begin
                    PrepareSalesOrderContext(Header);
                    GenerateSalesShipmentPackage(Header);
                end;

            "SI WB Basis Type"::Request:
                Error(
                    'Заявки та внутрішні переміщення ще не підключені в поточному MVP.');

            else
                Error(
                    'Для маршруту %1 / %2 команда "Створити документи" не застосовується.',
                    Format(Header."Operation Type"),
                    Format(Header."Shipment Scenario"));
        end;

        // Supporting-document generation may update legacy fields on the
        // header. Reload before the final state transition so those values
        // are not overwritten by a stale in-memory record.
        Header.Get(HeaderEntryNo);

        Header."Documents Created At" := CurrentDateTime();
        Header."Documents Created By" := UserSecurityId();
        Header."Accounting Handoff At" := Header."Documents Created At";
        Header."Accounting Handoff By" := Header."Documents Created By";
        Header.Status := "SI WB Document Status"::"Documents Created";
        Header.Modify(true);

        OnAfterDocumentsCreated(Header);
    end;

    procedure HandoffReceiptToAccounting(
        var Header: Record "SI Weighbridge Document")
    var
        UoMConversionMgt: Codeunit "SI WB UoM Conversion Mgt.";
    begin
        EnsureManagerStage(Header);

        if Header."Operation Type" <> "SI WB Operation Type"::Receipt then
            Error(
                'Команда "Передати до бухгалтерії" без створення документів застосовується тільки до надходження.');

        if Header."Shipment Scenario" <> "SI WB Shipment Scenario"::Supply then
            Error('Для надходження очікується сценарій "Постачання".');

        UoMConversionMgt.EnsureCanAdvance(Header);
        EnsureBasisIsValid(Header);
        PreparePurchaseOrderContext(Header);

        Header."Accounting Handoff At" := CurrentDateTime();
        Header."Accounting Handoff By" := UserSecurityId();
        Header.Status := "SI WB Document Status"::"Documents Created";
        Header.Modify(true);

        OnAfterAccountingHandoff(Header);
    end;

    local procedure EnsureOutboundGenerationRoute(
        Header: Record "SI Weighbridge Document")
    begin
        if Header."Operation Type" <> "SI WB Operation Type"::Shipment then
            Error(
                'Команда "Створити документи" доступна тільки для відвантаження. Для надходження документи постачальника вносяться вручну.');

        if (Header."Shipment Scenario" <> "SI WB Shipment Scenario"::Sales) and
           (Header."Shipment Scenario" <> "SI WB Shipment Scenario"::"Internal Transfer")
        then
            Error('Для відвантаження не визначено допустимий сценарій створення документів.');
    end;

    local procedure EnsureManagerStage(
        Header: Record "SI Weighbridge Document")
    begin
        if Header.Status <> "SI WB Document Status"::Submitted then
            Error(
                'Створити документи можна тільки для документа у статусі "Передано менеджеру". Поточний статус: %1.',
                Format(Header.Status));
    end;

    local procedure EnsureBasisIsValid(
        var Header: Record "SI Weighbridge Document")
    begin
        Header.TestField("Basis Type");
        Header.TestField("Basis No.");

        // Re-run table validation against the current basis document.
        // This protects processing if the linked order was changed after
        // the manager originally selected it.
        Header.Validate("Basis No.", Header."Basis No.");
    end;

    local procedure PreparePurchaseOrderContext(
        var Header: Record "SI Weighbridge Document")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if Header."Operation Type" <> "SI WB Operation Type"::Receipt then
            Error('Purchase Order допускається тільки для операції "Надходження".');

        if Header."Shipment Scenario" <> "SI WB Shipment Scenario"::Supply then
            Error('Purchase Order допускається тільки для сценарію "Постачання".');

        if not PurchaseHeader.Get(
            PurchaseHeader."Document Type"::Order,
            Header."Basis No.")
        then
            Error('Purchase Order %1 не знайдено.', Header."Basis No.");

        Header."ERP Document Type" := 'Purchase Order';
        Header."ERP Document No." := PurchaseHeader."No.";
        Header.Modify(true);

        // Receipt/Supply uses the vendor's incoming documents. We do not
        // generate outbound TTN / delivery note / quality passport here.
    end;

    local procedure PrepareSalesOrderContext(
        var Header: Record "SI Weighbridge Document")
    var
        SalesHeader: Record "Sales Header";
    begin
        if Header."Operation Type" <> "SI WB Operation Type"::Shipment then
            Error('Sales Order допускається тільки для операції "Відвантаження".');

        if Header."Shipment Scenario" <> "SI WB Shipment Scenario"::Sales then
            Error('Sales Order допускається тільки для сценарію "Продаж".');

        if not SalesHeader.Get(
            SalesHeader."Document Type"::Order,
            Header."Basis No.")
        then
            Error('Sales Order %1 не знайдено.', Header."Basis No.");

        Header."ERP Document Type" := 'Sales Order';
        Header."ERP Document No." := SalesHeader."No.";
        Header.Modify(true);
    end;

    local procedure GenerateSalesShipmentPackage(
        var Header: Record "SI Weighbridge Document")
    var
        Setup: Record "SI WB Document Setup";
    begin
        Setup.GetOrCreate();

        // Current MVP outbound scope is ready-mix concrete. Therefore the
        // Sales shipment package consists of TTN + Delivery Note + Quality
        // Passport. Cargo-driven package rules will replace this hard MVP
        // resolver when additional outbound cargo classes are introduced.
        EnsureGeneratedDocument(
            Header,
            "SI WB Supporting Doc Type"::TTN,
            Setup."TTN Nos.",
            'ТТН');

        EnsureGeneratedDocument(
            Header,
            "SI WB Supporting Doc Type"::"Delivery Note",
            Setup."Delivery Note Nos.",
            'Видаткова накладна');

        EnsureGeneratedDocument(
            Header,
            "SI WB Supporting Doc Type"::"Product Passport",
            Setup."Product Passport Nos.",
            'Паспорт якості');
    end;

    local procedure EnsureGeneratedDocument(
        Header: Record "SI Weighbridge Document";
        DocumentType: Enum "SI WB Supporting Doc Type";
        NoSeriesCode: Code[20];
        DocumentCaption: Text)
    var
        SupportingDocsMgt: Codeunit "SI WB Supporting Docs Mgt.";
        SupportingDoc: Record "SI WB Supporting Document";
        NoSeries: Codeunit "No. Series";
        UsageDate: Date;
    begin
        SupportingDocsMgt.EnsureForDocument(Header);

        SupportingDoc.Reset();
        SupportingDoc.SetRange("Document Entry No.", Header."Entry No.");
        SupportingDoc.SetRange("Document Type", DocumentType);

        if not SupportingDoc.FindFirst() then
            Error(
                'Не вдалося підготувати рядок документа "%1" для %2.',
                DocumentCaption,
                Header."Document No.");

        if SupportingDoc."Document No." = '' then begin
            if NoSeriesCode = '' then
                Error(
                    'Не налаштовано серію номерів для документа "%1". Відкрийте "Налаштування документів вагової".',
                    DocumentCaption);

            UsageDate := SupportingDoc."Document Date";
            if UsageDate = 0D then
                UsageDate := WorkDate();

            SupportingDoc.Validate(
                "Document No.",
                NoSeries.GetNextNo(NoSeriesCode, UsageDate));
        end;

        SupportingDoc.Generated := true;
        SupportingDoc."Generated At" := CurrentDateTime();
        SupportingDoc."Generated By" := UserSecurityId();
        SupportingDoc.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountingHandoff(
        var Header: Record "SI Weighbridge Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDocumentsCreated(
        var Header: Record "SI Weighbridge Document")
    begin
    end;
}
