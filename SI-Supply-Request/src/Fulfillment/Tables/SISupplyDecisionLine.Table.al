table 61011 "SI Supply Decision Line"
{
    Caption = 'Рядок рішення щодо забезпечення';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Decision No."; Code[20])
        {
            Caption = '№ рішення';
            TableRelation = "SI Supply Decision Header"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = '№ рядка';
        }
        field(10; "Request Line No."; Integer)
        {
            Caption = '№ рядка заявки';
            Editable = false;
        }
        field(20; "Line Type"; Enum "SI Supply Line Type")
        {
            Caption = 'Тип рядка';
            Editable = false;
        }
        field(30; "Item No."; Code[20])
        {
            Caption = 'Товар';
            TableRelation = Item."No.";
            Editable = false;
        }
        field(40; "Variant Code"; Code[10])
        {
            Caption = 'Варіант';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
            Editable = false;
        }
        field(50; Description; Text[250])
        {
            Caption = 'Опис потреби';
            Editable = false;
        }
        field(60; "Demand Quantity"; Decimal)
        {
            Caption = 'Кількість до забезпечення';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(70; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Од. вим.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
            Editable = false;
        }
        field(80; "Required on Site At"; DateTime)
        {
            Caption = 'Потрібно на об''єкті';
            Editable = false;
        }
        field(85; "Construction Site Code"; Code[20])
        {
            Caption = 'Буд. майданчик';
            Editable = false;
        }
        field(90; "Target Location Code"; Code[10])
        {
            Caption = 'Склад призначення';
            TableRelation = Location.Code;
            Editable = false;
        }
        field(100; "Allocated Quantity"; Decimal)
        {
            Caption = 'Розподілена кількість';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("SI Supply Allocation".Quantity where(
                "Decision No." = field("Decision No."),
                "Decision Line No." = field("Line No."),
                "Counts as Allocated" = const(true)));
        }
    }

    keys
    {
        key(PK; "Decision No.", "Line No.") { Clustered = true; }
        key(RequestLine; "Decision No.", "Request Line No.") { Unique = true; }
    }

    trigger OnModify()
    begin
        TestDecisionEditable();
    end;

    trigger OnDelete()
    var
        Allocation: Record "SI Supply Allocation";
    begin
        TestDecisionEditable();
        Allocation.SetRange("Decision No.", "Decision No.");
        Allocation.SetRange("Decision Line No.", "Line No.");
        Allocation.DeleteAll(true);
    end;

    procedure GetRemainingQuantity(): Decimal
    begin
        CalcFields("Allocated Quantity");
        exit("Demand Quantity" - "Allocated Quantity");
    end;

    procedure GetConstructionSiteName(): Text[100]
    var
        Header: Record "SI Supply Decision Header";
        Site: Record "SI Construction Site";
    begin
        if "Construction Site Code" = '' then
            exit('');
        if not Header.Get("Decision No.") then
            exit("Construction Site Code");
        if not Site.Get(Header."Project No.", "Construction Site Code") then
            exit("Construction Site Code");
        exit(Site.Name);
    end;

    local procedure TestDecisionEditable()
    var
        Header: Record "SI Supply Decision Header";
    begin
        if Header.Get("Decision No.") then
            Header.TestEditable();
    end;
}
