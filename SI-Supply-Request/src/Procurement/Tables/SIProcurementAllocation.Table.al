table 61052 "SI Procurement Allocation"
{
    Caption = 'Розподіл закупівлі';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№ запису'; AutoIncrement = true; }
        field(2; "Planning Run No."; Integer) { Caption = 'План'; TableRelation = "SI Proc. Plan Run"."Run No."; }
        field(3; "Snapshot Line No."; Integer) { Caption = 'Рядок плану'; }
        field(10; "Vendor No."; Code[20]) { Caption = 'Постачальник'; TableRelation = Vendor."No."; }
        field(11; "Capability Code"; Code[20]) { Caption = 'Канал постачання'; TableRelation = "SI Vendor Supply Capability".Code; }
        field(12; "Purchase Quantity"; Decimal) { Caption = 'Кількість закупівлі'; DecimalPlaces = 0 : 5; MinValue = 0; }
        field(13; "Unit of Measure Code"; Code[10]) { Caption = 'Од. вим.'; TableRelation = "Unit of Measure".Code; }
        field(14; "Required Date"; Date) { Caption = 'Забезпечити до'; }
        field(15; "Expected Receipt Date"; Date) { Caption = 'Очікувана дата поставки'; }
        field(16; Status; Enum "SI Proc. Allocation Status") { Caption = 'Статус'; }
        field(17; "Created At"; DateTime) { Caption = 'Створено'; Editable = false; }
        field(18; "Created By"; Guid) { Caption = 'Створив'; Editable = false; }
        field(20; "Purchase Order No."; Code[20]) { Caption = 'Замовлення постачальнику'; Editable = false; }
        field(21; "Purchase Line No."; Integer) { Caption = 'Рядок замовлення'; Editable = false; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Snapshot; "Planning Run No.", "Snapshot Line No.", Status) { SumIndexFields = "Purchase Quantity"; }
    }

    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
        if IsNullGuid("Created By") then
            "Created By" := UserSecurityId();
    end;

    trigger OnModify()
    begin
        if AllowPOTransition then
            exit;

        if xRec.Status = xRec.Status::Cancelled then
            Error(CancelledLockedErr);

        if xRec.Status = xRec.Status::Confirmed then begin
            if (Status <> Status::Cancelled) and (Status <> Status::"Sent to PO") then
                EnsureBusinessFieldsUnchanged();
        end;

        if xRec.Status = xRec.Status::"Sent to PO" then
            Error(SentToPOLockedErr);
    end;

    procedure MarkSentToPurchaseOrder(PurchaseOrderNo: Code[20]; PurchaseLineNo: Integer)
    begin
        TestField(Status, Status::Confirmed);
        TestField("Purchase Order No.", '');
        if PurchaseOrderNo = '' then
            Error(PurchaseOrderRequiredErr);
        if PurchaseLineNo = 0 then
            Error(PurchaseLineRequiredErr);

        "Purchase Order No." := PurchaseOrderNo;
        "Purchase Line No." := PurchaseLineNo;
        Status := Status::"Sent to PO";

        AllowPOTransition := true;
        Modify(true);
        AllowPOTransition := false;
    end;

    local procedure EnsureBusinessFieldsUnchanged()
    begin
        if ("Vendor No." <> xRec."Vendor No.") or
           ("Capability Code" <> xRec."Capability Code") or
           ("Purchase Quantity" <> xRec."Purchase Quantity") or
           ("Unit of Measure Code" <> xRec."Unit of Measure Code") or
           ("Required Date" <> xRec."Required Date") or
           ("Expected Receipt Date" <> xRec."Expected Receipt Date")
        then
            Error(ConfirmedLockedErr);
    end;

    var
        ConfirmedLockedErr: Label 'Підтверджений розподіл не можна змінювати. За потреби скасуйте його та створіть новий.';
        CancelledLockedErr: Label 'Скасований розподіл не можна змінювати.';
        SentToPOLockedErr: Label 'Розподіл уже передано в замовлення постачальнику і не може бути змінений.';
        PurchaseOrderRequiredErr: Label 'Не вказано замовлення постачальнику.';
        PurchaseLineRequiredErr: Label 'Не вказано рядок замовлення постачальнику.';
        AllowPOTransition: Boolean;
}
