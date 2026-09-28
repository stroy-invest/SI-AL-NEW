table 57021 "SI Prok Recipe Snapshot Line"
{
    Caption = 'SI Proktek Recipe Snapshot Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Snapshot Entry No."; Integer)
        {
            Caption = 'Snapshot Entry No.';
            TableRelation = "SI Prok Recipe Snapshot"."Entry No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Матеріал';
            TableRelation = Item."No.";

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                Clear("Variant Code");
                Clear(Description);
                Clear("Unit of Measure Code");
                if "Item No." = '' then
                    exit;
                Item.Get("Item No.");
                Description := Item.Description;
                "Unit of Measure Code" := Item."Base Unit of Measure";
            end;
        }
        field(20; "Variant Code"; Code[10])
        {
            Caption = 'Варіант';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if "Variant Code" = '' then
                    exit;
                ItemVariant.Get("Item No.", "Variant Code");
                if ItemVariant.Description <> '' then
                    Description := ItemVariant.Description;
            end;
        }
        field(30; Description; Text[100])
        {
            Caption = 'Назва';
            Editable = false;
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Кількість';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if Quantity <= 0 then
                    Error('Кількість модифікатора має бути більшою за 0.');
            end;
        }
        field(50; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Од. виміру';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
    }

    keys
    {
        key(PK; "Snapshot Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
