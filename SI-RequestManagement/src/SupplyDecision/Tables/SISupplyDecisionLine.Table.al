table 52041 "SI Supply Decision Line"
{
    Caption = 'Рядок рішення щодо забезпечення';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = '№ документа';
            TableRelation = "SI Supply Decision Header"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = '№ рядка';
        }
        field(10; "Request Line No."; Integer)
        {
            Caption = '№ рядка заявки';
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Товар';
            TableRelation = Item."No.";
            Editable = false;
        }
        field(30; "Variant Code"; Code[10])
        {
            Caption = 'Варіант товару';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
            Editable = false;
        }
        field(40; Description; Text[100])
        {
            Caption = 'Опис товару';
            Editable = false;
        }
        field(50; "Requested Quantity"; Decimal)
        {
            Caption = 'Заявлена кількість';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(60; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Од. вим.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
            Editable = false;
        }
        field(70; "Required Date"; Date)
        {
            Caption = 'Дата потреби';
            Editable = false;
        }
        field(80; "Location Code"; Code[10])
        {
            Caption = 'Код складу';
            TableRelation = Location.Code;
        }
        field(90; Comment; Text[250])
        {
            Caption = 'Коментар';
        }
        field(100; "Allocated Quantity"; Decimal)
        {
            Caption = 'Розподілена кількість';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("SI Supply Allocation".Quantity where(
                "Document No." = field("Document No."),
                "Decision Line No." = field("Line No.")));
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(RequestLine; "Document No.", "Request Line No.")
        {
            Unique = true;
        }
        key(Item; "Item No.")
        {
        }
    }

    trigger OnModify()
    begin
        TestDecisionIsDraft();
    end;

    trigger OnDelete()
    var
        Allocation: Record "SI Supply Allocation";
    begin
        TestDecisionIsDraft();

        Allocation.SetRange("Document No.", "Document No.");
        Allocation.SetRange("Decision Line No.", "Line No.");
        Allocation.DeleteAll(true);
    end;

    procedure GetRemainingQuantity(): Decimal
    begin
        CalcFields("Allocated Quantity");
        exit("Requested Quantity" - "Allocated Quantity");
    end;

    local procedure TestDecisionIsDraft()
    var
        DecisionHeader: Record "SI Supply Decision Header";
    begin
        DecisionHeader.Get("Document No.");
        DecisionHeader.TestField(Status, DecisionHeader.Status::Draft);
    end;
}
