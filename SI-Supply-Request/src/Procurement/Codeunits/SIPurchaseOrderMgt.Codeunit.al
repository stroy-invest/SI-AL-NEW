codeunit 61057 "SI Purchase Order Mgt."
{
    procedure CreateFromProposal(var Proposal: Record "SI PO Proposal Header")
    var
        PurchaseHeader: Record "Purchase Header";
        ProposalLine: Record "SI PO Proposal Line";
    begin
        Proposal.TestField(Status, Proposal.Status::Draft);
        Proposal.TestField("Vendor No.");
        Proposal.TestField("Location Code");
        Proposal.TestField("Expected Receipt Date");

        if Proposal."Purchase Order No." <> '' then
            Error(AlreadyCreatedErr);

        ValidateProposalAllocations(Proposal);

        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", Proposal."Vendor No.");
        PurchaseHeader.Validate("Location Code", Proposal."Location Code");
        if Proposal."Shipment Method Code" <> PurchaseHeader."Shipment Method Code" then
            PurchaseHeader.Validate("Shipment Method Code", Proposal."Shipment Method Code");
        if Proposal."Currency Code" <> PurchaseHeader."Currency Code" then
            PurchaseHeader.Validate("Currency Code", Proposal."Currency Code");
        PurchaseHeader.Modify(true);

        ProposalLine.SetRange("Proposal Entry No.", Proposal."Entry No.");
        if not ProposalLine.FindSet(true) then
            Error(NoLinesErr);

        repeat
            CreatePurchaseLine(PurchaseHeader, Proposal, ProposalLine);
        until ProposalLine.Next() = 0;

        MarkAllocationsSent(Proposal, PurchaseHeader."No.");

        Proposal.Status := Proposal.Status::"Purchase Order Created";
        Proposal."Purchase Order No." := PurchaseHeader."No.";
        Proposal."PO Created At" := CurrentDateTime();
        Proposal.Modify(true);
    end;

    procedure OpenPurchaseOrder(Proposal: Record "SI PO Proposal Header")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Proposal.TestField("Purchase Order No.");
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Proposal."Purchase Order No.");
        Page.Run(Page::"Purchase Order", PurchaseHeader);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; Proposal: Record "SI PO Proposal Header"; var ProposalLine: Record "SI PO Proposal Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        ProposalLine.TestField("Item No.");
        ProposalLine.TestField("Unit of Measure Code");
        ProposalLine.TestField(Quantity);

        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := ProposalLine."Line No.";
        PurchaseLine.Insert(true);

        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Validate("No.", ProposalLine."Item No.");
        if ProposalLine."Variant Code" <> '' then
            PurchaseLine.Validate("Variant Code", ProposalLine."Variant Code");
        PurchaseLine.Validate("Location Code", ProposalLine."Location Code");
        PurchaseLine.Validate("Unit of Measure Code", ProposalLine."Unit of Measure Code");
        PurchaseLine.Validate(Quantity, ProposalLine.Quantity);
        PurchaseLine.Validate("Expected Receipt Date", Proposal."Expected Receipt Date");
        PurchaseLine.Modify(true);

        ProposalLine."Purchase Order No." := PurchaseHeader."No.";
        ProposalLine."Purchase Line No." := PurchaseLine."Line No.";
        ProposalLine.Modify(true);
    end;

    local procedure ValidateProposalAllocations(Proposal: Record "SI PO Proposal Header")
    var
        Link: Record "SI PO Proposal Alloc. Link";
        Allocation: Record "SI Procurement Allocation";
    begin
        Link.SetRange("Proposal Entry No.", Proposal."Entry No.");
        if not Link.FindSet() then
            Error(NoOriginsErr);

        repeat
            Allocation.Get(Link."Allocation Entry No.");
            if Allocation.Status <> Allocation.Status::Confirmed then
                Error(AllocationNotConfirmedErr);
            if Allocation."Vendor No." <> Proposal."Vendor No." then
                Error(AllocationChangedErr);
            if Allocation."Purchase Order No." <> '' then
                Error(AllocationAlreadySentErr);
        until Link.Next() = 0;
    end;

    local procedure MarkAllocationsSent(Proposal: Record "SI PO Proposal Header"; PurchaseOrderNo: Code[20])
    var
        Link: Record "SI PO Proposal Alloc. Link";
        Allocation: Record "SI Procurement Allocation";
        ProposalLine: Record "SI PO Proposal Line";
    begin
        Link.SetRange("Proposal Entry No.", Proposal."Entry No.");
        if Link.FindSet() then
            repeat
                Allocation.Get(Link."Allocation Entry No.");
                ProposalLine.Get(Link."Proposal Entry No.", Link."Proposal Line No.");
                Allocation.MarkSentToPurchaseOrder(PurchaseOrderNo, ProposalLine."Purchase Line No.");
            until Link.Next() = 0;
    end;

    var
        AlreadyCreatedErr: Label 'Для цієї пропозиції замовлення постачальнику вже створено.';
        NoLinesErr: Label 'У пропозиції немає позицій для створення замовлення.';
        NoOriginsErr: Label 'Для пропозиції не знайдено підтверджених розподілів постачання.';
        AllocationNotConfirmedErr: Label 'Один із розподілів постачання вже не має статусу Підтверджено. Оновіть підготовку замовлень.';
        AllocationChangedErr: Label 'Постачальник у розподілі не відповідає пропозиції. Оновіть підготовку замовлень.';
        AllocationAlreadySentErr: Label 'Один із розподілів уже передано в замовлення постачальнику.';
}
