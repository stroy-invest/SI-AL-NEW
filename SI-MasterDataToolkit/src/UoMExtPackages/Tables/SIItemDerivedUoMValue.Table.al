table 58002 "SI Item Derived UoM Value"
{
    Caption = 'Похідні фізичні параметри товару';
    DataClassification = CustomerContent;
    LookupPageId = "SI Item Derived UoM Values";
    DrillDownPageId = "SI Item Derived UoM Values";

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Товар';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Варіант';
            DataClassification = CustomerContent;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(3; "Derived UoM Code"; Code[10])
        {
            Caption = 'Похідна одиниця';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure".Code where("SI UoM Kind" = const(Derived), "SI Blocked" = const(false));

            trigger OnValidate()
            var
                UoM: Record "Unit of Measure";
                UoMMgt: Codeunit "SI UoM Mgt.";
            begin
                if "Derived UoM Code" = '' then
                    exit;

                UoM.Get("Derived UoM Code");
                UoMMgt.ValidateUoM(UoM);
            end;
        }
        field(4; Value; Decimal)
        {
            Caption = 'Значення';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 10;

            trigger OnValidate()
            begin
                if Value <= 0 then
                    Error('Значення фізичного параметра має бути більшим за нуль.');
            end;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Опис';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Item No.", "Variant Code", "Derived UoM Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        TestField("Item No.");
        TestField("Derived UoM Code");
        TestField(Value);
    end;

    trigger OnModify()
    begin
        TestField("Item No.");
        TestField("Derived UoM Code");
        TestField(Value);
    end;
}
