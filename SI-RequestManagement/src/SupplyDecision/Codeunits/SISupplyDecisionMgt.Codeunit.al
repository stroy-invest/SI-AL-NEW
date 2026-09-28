codeunit 52047 "SI Supply Decision Mgt."
{
    procedure OpenOrCreateFromRequest(var RequestHeader: Record "SI Request Header")
    var
        DecisionHeader: Record "SI Supply Decision Header";
    begin
        RequestHeader.TestField(Status, RequestHeader.Status::Approved);

        DecisionHeader.SetRange("Request No.", RequestHeader."No.");
        if not DecisionHeader.FindFirst() then
            CreateFromRequest(RequestHeader, DecisionHeader);

        Page.Run(Page::"SI Supply Decision Card", DecisionHeader);
    end;

    procedure CreateFromRequest(
        var RequestHeader: Record "SI Request Header";
        var DecisionHeader: Record "SI Supply Decision Header")
    var
        RequestLine: Record "SI Request Line";
        DecisionLine: Record "SI Supply Decision Line";
    begin
        RequestHeader.TestField(Status, RequestHeader.Status::Approved);

        DecisionHeader.SetRange("Request No.", RequestHeader."No.");
        if DecisionHeader.FindFirst() then
            exit;

        DecisionHeader.Init();
        DecisionHeader."No." := RequestHeader."No.";
        DecisionHeader."Request No." := RequestHeader."No.";
        DecisionHeader.Status := DecisionHeader.Status::Draft;
        DecisionHeader."Construction Object No." := RequestHeader."Construction Object No.";
        DecisionHeader."Required Date" := RequestHeader."Execution Date";
        DecisionHeader.Insert(true);

        RequestLine.SetRange("Request No.", RequestHeader."No.");
        if not RequestLine.FindSet() then
            Error(RequestHasNoLinesErr, RequestHeader."No.");

        repeat
            DecisionLine.Init();
            DecisionLine."Document No." := DecisionHeader."No.";
            DecisionLine."Line No." := RequestLine."Line No.";
            DecisionLine."Request Line No." := RequestLine."Line No.";
            DecisionLine."Item No." := RequestLine."Item No.";
            DecisionLine."Variant Code" := RequestLine."Variant Code";
            DecisionLine.Description := RequestLine.Description;
            DecisionLine."Requested Quantity" := RequestLine.Quantity;
            DecisionLine."Unit of Measure Code" := RequestLine."Unit of Measure Code";
            DecisionLine."Required Date" := RequestHeader."Execution Date";
            DecisionLine.Insert(true);
        until RequestLine.Next() = 0;
    end;

    procedure ValidateDecision(var DecisionHeader: Record "SI Supply Decision Header")
    var
        RequestHeader: Record "SI Request Header";
        DecisionLine: Record "SI Supply Decision Line";
        Allocation: Record "SI Supply Allocation";
        Item: Record Item;
    begin
        DecisionHeader.TestField(Status, DecisionHeader.Status::Draft);

        RequestHeader.Get(DecisionHeader."Request No.");
        RequestHeader.TestField(Status, RequestHeader.Status::Approved);

        DecisionLine.SetRange("Document No.", DecisionHeader."No.");
        if not DecisionLine.FindSet() then
            Error(DecisionHasNoLinesErr, DecisionHeader."No.");

        repeat
            DecisionLine.TestField("Item No.");
            DecisionLine.TestField("Requested Quantity");

            DecisionLine.CalcFields("Allocated Quantity");
            if DecisionLine."Allocated Quantity" <> DecisionLine."Requested Quantity" then
                Error(
                    QuantityNotFullyAllocatedErr,
                    DecisionLine."Line No.",
                    DecisionLine."Requested Quantity",
                    DecisionLine."Allocated Quantity");

            Allocation.SetRange("Document No.", DecisionLine."Document No.");
            Allocation.SetRange("Decision Line No.", DecisionLine."Line No.");
            if not Allocation.FindSet() then
                Error(LineHasNoAllocationsErr, DecisionLine."Line No.");

            repeat
                Allocation.TestField("Supply Method", Allocation."Supply Method"::Production);
                Allocation.TestField(Quantity);
                Allocation.TestField("Production Date");
                Allocation.TestField("Item No.");

                if Allocation."Created Document No." <> '' then
                    Error(
                        DocumentAlreadyCreatedErr,
                        Allocation."Line No.",
                        Allocation."Created Document No.");

                Item.Get(Allocation."Item No.");
                Item.TestField("Replenishment System", Item."Replenishment System"::"Prod. Order");
                Item.TestField("Production BOM No.");
                //Item.TestField("Routing No.");

                if Allocation."Unit of Measure Code" <> Item."Base Unit of Measure" then
                    Error(
                        BaseUoMRequiredErr,
                        Allocation."Item No.",
                        Item."Base Unit of Measure",
                        Allocation."Unit of Measure Code");
            until Allocation.Next() = 0;
        until DecisionLine.Next() = 0;
    end;

    procedure CreateDocuments(var DecisionHeader: Record "SI Supply Decision Header")
    var
        ProgressDialog: Dialog;
        ResultPage: Page "SI Supply Creation Result";
        ErrorText: Text;
    begin
        ValidateDecision(DecisionHeader);
        Clear(CreatedProdOrderNos);
        CreatedDocumentCount := 0;

        ProgressDialog.Open(
            CreatingDocumentsDlg +
            CurrentStageDlg);
        ProgressDialog.Update(1, ProductionOrdersStageLbl);

        if TryCreateProductionDocuments(DecisionHeader) then begin
            ProgressDialog.Close();

            DecisionHeader.Status := DecisionHeader.Status::Completed;
            DecisionHeader."Completed By" :=
                CopyStr(UserId(), 1, MaxStrLen(DecisionHeader."Completed By"));
            DecisionHeader."Completed At" := CurrentDateTime();
            DecisionHeader.Modify(true);
            //--- Обходимо transaction error на модалі
            Commit();
            //
            ResultPage.SetSuccess(CreatedDocumentCount);
            ResultPage.RunModal();
            exit;
        end;

        ErrorText := GetLastErrorText();
        Message(GetLastErrorText());
        ClearLastError();
        ProgressDialog.Close();

        CleanupCreatedProductionOrders(DecisionHeader);
        //--- Обходимо transaction error на модалі
        Commit();
        //
        ResultPage.SetError(ErrorText);
        ResultPage.RunModal();
    end;

    [TryFunction]
    local procedure TryCreateProductionDocuments(
        var DecisionHeader: Record "SI Supply Decision Header")
    var
        Allocation: Record "SI Supply Allocation";
    begin
        Allocation.SetRange("Document No.", DecisionHeader."No.");
        Allocation.SetRange("Supply Method", Allocation."Supply Method"::Production);
        Allocation.SetRange("Created Document No.", '');

        if not Allocation.FindSet(true) then
            Error(NoProductionAllocationsErr);

        repeat
            CreateFirmPlannedProductionOrder(Allocation);
        until Allocation.Next() = 0;
    end;

    local procedure CreateFirmPlannedProductionOrder(
        var Allocation: Record "SI Supply Allocation")
    var
        ProdOrder: Record "Production Order";
        RefreshProdOrder: Report "Refresh Production Order";
        Direction: Option Forward,Backward;
    begin
        ProdOrder.Init();
        ProdOrder.Status := ProdOrder.Status::"Firm Planned";
        ProdOrder.Insert(true);

        CreatedProdOrderNos.Add(ProdOrder."No.");

        ProdOrder.Validate("Source Type", ProdOrder."Source Type"::Item);
        ProdOrder.Validate("Source No.", Allocation."Item No.");
        ProdOrder.Validate("Variant Code", Allocation."Variant Code");

        if Allocation."Location Code" <> '' then
            ProdOrder.Validate("Location Code", Allocation."Location Code");

        ProdOrder.Validate(Quantity, Allocation.Quantity);
        ProdOrder.Validate("Due Date", Allocation."Production Date");
        ProdOrder.Modify(true);

        Direction := Direction::Backward;
        ProdOrder.SetRecFilter();

        RefreshProdOrder.SetTableView(ProdOrder);
        RefreshProdOrder.InitializeRequest(
            Direction,
            true,
            false, // Без валідації Routing (для MVP)
            true,
            false);
        RefreshProdOrder.SetHideValidationDialog(true);
        RefreshProdOrder.UseRequestPage(false);
        RefreshProdOrder.RunModal();

        Allocation."Created Document Type" :=
            Allocation."Created Document Type"::"Production Order";

        Allocation."Created Document No." := ProdOrder."No.";

        // Старе поле поки теж заповнюємо для сумісності зі схемою.
        Allocation."Production Order No." := ProdOrder."No.";

        Allocation.Modify(true);

        CreatedDocumentCount += 1;
    end;

    local procedure CleanupCreatedProductionOrders(
        var DecisionHeader: Record "SI Supply Decision Header")
    var
        Allocation: Record "SI Supply Allocation";
        ProdOrder: Record "Production Order";
        ProdOrderNo: Code[20];
    begin
        foreach ProdOrderNo in CreatedProdOrderNos do begin
            if ProdOrder.Get(ProdOrder.Status::"Firm Planned", ProdOrderNo) then
                ProdOrder.Delete(true);

            Allocation.SetRange("Document No.", DecisionHeader."No.");
            Allocation.SetRange("Created Document Type", Allocation."Created Document Type"::"Production Order");
            Allocation.SetRange("Created Document No.", ProdOrderNo);
            if Allocation.FindSet(true) then
                repeat
                    Allocation."Created Document Type" :=
                        Allocation."Created Document Type"::" ";

                    Allocation."Created Document No." := '';
                    Allocation."Production Order No." := '';

                    Allocation.Modify(true);
                until Allocation.Next() = 0;

            Allocation.Reset();
        end;
    end;

    var
        CreatedProdOrderNos: List of [Code[20]];
        CreatedDocumentCount: Integer;

        RequestHasNoLinesErr: Label 'Заявка %1 не містить рядків.';
        DecisionHasNoLinesErr: Label 'Рішення щодо забезпечення %1 не містить рядків.';
        QuantityNotFullyAllocatedErr: Label 'Для рядка %1 заявлено %2, а розподілено %3. Перед створенням документів кількість має бути розподілена повністю.';
        LineHasNoAllocationsErr: Label 'Для рядка %1 не створено жодного способу забезпечення.';
        DocumentAlreadyCreatedErr: Label 'Для рядка розподілу %1 вже створено документ %2.';
        BaseUoMRequiredErr: Label 'Для товару %1 у MVP дозволена лише базова одиниця виміру %2. У розподілі зазначено %3.';
        NoProductionAllocationsErr: Label 'Не знайдено рядків забезпечення способом «Виробництво».';

        CreatingDocumentsDlg: Label 'Створення документів...\';
        CurrentStageDlg: Label 'Поточний етап: #1############################';
        ProductionOrdersStageLbl: Label 'Створення виробничих замовлень';
}
