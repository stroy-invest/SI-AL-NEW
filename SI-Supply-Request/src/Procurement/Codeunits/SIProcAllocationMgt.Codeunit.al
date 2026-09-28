codeunit 61055 "SI Proc. Allocation Mgt."
{
    procedure GetAllocatedQuantity(RunNo: Integer; SnapshotLineNo: Integer): Decimal
    var
        Allocation: Record "SI Procurement Allocation";
    begin
        Allocation.SetRange("Planning Run No.", RunNo);
        Allocation.SetRange("Snapshot Line No.", SnapshotLineNo);
        Allocation.SetFilter(Status, '<>%1', Allocation.Status::Cancelled);
        Allocation.CalcSums("Purchase Quantity");
        exit(Allocation."Purchase Quantity");
    end;

    procedure GetAllocatedQuantityExcept(RunNo: Integer; SnapshotLineNo: Integer; ExceptEntryNo: Integer): Decimal
    var
        Allocation: Record "SI Procurement Allocation";
    begin
        Allocation.SetRange("Planning Run No.", RunNo);
        Allocation.SetRange("Snapshot Line No.", SnapshotLineNo);
        Allocation.SetFilter("Entry No.", '<>%1', ExceptEntryNo);
        Allocation.SetFilter(Status, '<>%1', Allocation.Status::Cancelled);
        Allocation.CalcSums("Purchase Quantity");
        exit(Allocation."Purchase Quantity");
    end;

    procedure CreateFromCandidate(Snapshot: Record "SI Proc. Plan Snapshot"; Candidate: Record "SI VSC Candidate" temporary; PurchaseQty: Decimal)
    var
        Allocation: Record "SI Procurement Allocation";
    begin
        if PurchaseQty <= 0 then
            Error(QuantityErr);

        Allocation.Init();
        Allocation.Validate("Planning Run No.", Snapshot."Run No.");
        Allocation.Validate("Snapshot Line No.", Snapshot."Line No.");
        ApplyCandidate(Allocation, Candidate, PurchaseQty);
        Allocation.Validate("Unit of Measure Code", Snapshot."Unit of Measure Code");
        Allocation.Validate("Required Date", Snapshot."Due Date");
        Allocation.Validate(Status, Allocation.Status::Draft);
        Allocation.Insert(true);
    end;

    procedure ChangeCandidate(var Allocation: Record "SI Procurement Allocation"; Candidate: Record "SI VSC Candidate" temporary; PurchaseQty: Decimal)
    begin
        Allocation.TestField(Status, Allocation.Status::Draft);
        if PurchaseQty <= 0 then
            Error(QuantityErr);

        ApplyCandidate(Allocation, Candidate, PurchaseQty);
        Allocation.Modify(true);
    end;

    procedure ConfirmAllocation(var Allocation: Record "SI Procurement Allocation")
    var
        Capability: Record "SI Vendor Supply Capability";
        Vendor: Record Vendor;
    begin
        Allocation.TestField(Status, Allocation.Status::Draft);
        Allocation.TestField("Vendor No.");
        Allocation.TestField("Capability Code");
        Allocation.TestField("Purchase Quantity");
        Allocation.TestField("Unit of Measure Code");
        Allocation.TestField("Expected Receipt Date");

        if Allocation."Purchase Quantity" <= 0 then
            Error(QuantityErr);

        Vendor.Get(Allocation."Vendor No.");
        if Vendor.Blocked <> Vendor.Blocked::" " then
            Error(VendorBlockedErr, Vendor.Name);

        Capability.Get(Allocation."Capability Code");
        Capability.TestField(Status, Capability.Status::Active);
        if Capability."Vendor No." <> Allocation."Vendor No." then
            Error(CapabilityVendorErr);
        if (Capability."UoM Code" <> '') and (Capability."UoM Code" <> Allocation."Unit of Measure Code") then
            Error(CapabilityUoMErr);

        if (Allocation."Required Date" <> 0D) and
           (Allocation."Expected Receipt Date" > Allocation."Required Date")
        then
            if not Confirm(LateReceiptQst, false, Allocation."Expected Receipt Date", Allocation."Required Date") then
                exit;

        Allocation.Validate(Status, Allocation.Status::Confirmed);
        Allocation.Modify(true);
    end;

    procedure CancelAllocation(var Allocation: Record "SI Procurement Allocation")
    begin
        if Allocation.Status = Allocation.Status::Cancelled then
            Error(AlreadyCancelledErr);

        if not Confirm(CancelQst, false) then
            exit;

        Allocation.Validate(Status, Allocation.Status::Cancelled);
        Allocation.Modify(true);
    end;

    local procedure ApplyCandidate(var Allocation: Record "SI Procurement Allocation"; Candidate: Record "SI VSC Candidate" temporary; PurchaseQty: Decimal)
    begin
        Allocation.Validate("Vendor No.", Candidate."Vendor No.");
        Allocation.Validate("Capability Code", Candidate."Capability Code");
        Allocation.Validate("Purchase Quantity", PurchaseQty);
        Allocation.Validate("Expected Receipt Date", Candidate."Earliest Delivery Date");
    end;

    var
        QuantityErr: Label 'Кількість закупівлі має бути більшою за нуль.';
        VendorBlockedErr: Label 'Постачальник «%1» заблокований і не може використовуватися для закупівлі.';
        CapabilityVendorErr: Label 'Канал постачання не належить вибраному постачальнику.';
        CapabilityUoMErr: Label 'Одиниця виміру каналу постачання не відповідає одиниці виміру закупівлі.';
        AlreadyCancelledErr: Label 'Розподіл уже скасовано.';
        LateReceiptQst: Label 'Очікувана поставка %1 пізніше дати забезпечення %2. Все одно підтвердити розподіл?';
        CancelQst: Label 'Скасувати цей розподіл постачання?';
}
