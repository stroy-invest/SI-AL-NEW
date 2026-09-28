table 52042 "SI Supply Allocation"
{
    Caption = 'Розподіл забезпечення';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = '№ документа';
            TableRelation = "SI Supply Decision Header"."No.";
        }
        field(2; "Decision Line No."; Integer)
        {
            Caption = '№ рядка рішення';
            TableRelation = "SI Supply Decision Line"."Line No." where(
                "Document No." = field("Document No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = '№ рядка';
        }
        field(10; "Supply Method"; Enum "SI Supply Method")
        {
            Caption = 'Спосіб забезпечення';

            trigger OnValidate()
            begin
                if "Supply Method" in ["Supply Method"::" ", "Supply Method"::Production] then
                    exit;

                Error(OnlyProductionSupportedErr);
            end;
        }
        field(20; Quantity; Decimal)
        {
            Caption = 'Кількість';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if Quantity <= 0 then
                    Error(QuantityMustBePositiveErr);

                CheckTotalQuantity();
            end;
        }
        field(30; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Од. вим.';
            TableRelation = "Item Unit of Measure".Code where(
                "Item No." = field("Item No."));
            Editable = false;
        }
        field(40; "Production Date"; Date)
        {
            Caption = 'Дата виробництва';
        }
        field(50; "Location Code"; Code[10])
        {
            Caption = 'Код складу';
            TableRelation = Location.Code;
        }
        field(60; "Item No."; Code[20])
        {
            Caption = 'Товар';
            TableRelation = Item."No.";
            Editable = false;
        }
        field(70; "Variant Code"; Code[10])
        {
            Caption = 'Варіант товару';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
            Editable = false;
        }
        field(80; Description; Text[100])
        {
            Caption = 'Опис товару';
            Editable = false;
        }

        // Field 90 previously contained Production Order No.
        // The ID and data type are preserved for safe schema synchronization.
        field(90; "Production Order No."; Code[20])
        {
            Caption = '№ виробничого замовлення';
            TableRelation = "Production Order"."No." where(Status = const("Firm Planned"));
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Замінено універсальними полями Created Document Type і Created Document No.';
            ObsoleteTag = '1.0.0.0';
        }

        field(95; "Created Document Type"; Enum "SI Created Document Type")
        {
            Caption = 'Тип створеного документа';
            Editable = false;
        }

        field(96; "Created Document No."; Code[20])
        {
            Caption = '№ створеного документа';
            Editable = false;
        }

        field(100; "Created By"; Code[50])
        {
            Caption = 'Створено користувачем';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(110; "Created At"; DateTime)
        {
            Caption = 'Дата й час створення';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Document No.", "Decision Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(CreatedDocument; "Created Document Type", "Created Document No.")
        {
        }
    }

    trigger OnInsert()
    begin
        TestDecisionIsDraft();
        CopyFromDecisionLine();

        if "Created By" = '' then
            "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));

        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
    end;

    trigger OnModify()
    begin
        TestDecisionIsDraft();

        if "Created Document No." <> '' then
            Error(CreatedAllocationCannotBeChangedErr);
    end;

    trigger OnDelete()
    begin
        TestDecisionIsDraft();

        if "Created Document No." <> '' then
            Error(CreatedAllocationCannotBeDeletedErr);
    end;

    local procedure CopyFromDecisionLine()
    var
        DecisionLine: Record "SI Supply Decision Line";
    begin
        DecisionLine.Get("Document No.", "Decision Line No.");

        "Item No." := DecisionLine."Item No.";
        "Variant Code" := DecisionLine."Variant Code";
        Description := DecisionLine.Description;
        "Unit of Measure Code" := DecisionLine."Unit of Measure Code";

        if "Production Date" = 0D then
            "Production Date" := DecisionLine."Required Date";

        if "Location Code" = '' then
            "Location Code" := DecisionLine."Location Code";
    end;

    local procedure CheckTotalQuantity()
    var
        DecisionLine: Record "SI Supply Decision Line";
        Allocation: Record "SI Supply Allocation";
        AllocatedQty: Decimal;
    begin
        if ("Document No." = '') or ("Decision Line No." = 0) then
            exit;

        DecisionLine.Get("Document No.", "Decision Line No.");

        Allocation.SetRange("Document No.", "Document No.");
        Allocation.SetRange("Decision Line No.", "Decision Line No.");
        Allocation.SetFilter("Line No.", '<>%1', "Line No.");
        Allocation.CalcSums(Quantity);
        AllocatedQty := Allocation.Quantity + Quantity;

        if AllocatedQty > DecisionLine."Requested Quantity" then
            Error(
                AllocatedQtyExceedsRequestedErr,
                AllocatedQty,
                DecisionLine."Requested Quantity");
    end;

    local procedure TestDecisionIsDraft()
    var
        DecisionHeader: Record "SI Supply Decision Header";
    begin
        DecisionHeader.Get("Document No.");
        DecisionHeader.TestField(Status, DecisionHeader.Status::Draft);
    end;

    var
        OnlyProductionSupportedErr: Label 'На поточному етапі підтримується лише спосіб забезпечення «Виробництво».';
        QuantityMustBePositiveErr: Label 'Кількість має бути більшою за нуль.';
        AllocatedQtyExceedsRequestedErr: Label 'Розподілена кількість %1 перевищує заявлену кількість %2.';
        CreatedAllocationCannotBeChangedErr: Label 'Рядок не можна змінити, оскільки для нього вже створено документ.';
        CreatedAllocationCannotBeDeletedErr: Label 'Рядок не можна видалити, оскільки для нього вже створено документ.';
}
