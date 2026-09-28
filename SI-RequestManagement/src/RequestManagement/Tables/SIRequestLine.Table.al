table 52006 "SI Request Line"
{
    Caption = 'SI Request Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Request No."; Code[20])
        {
            Caption = 'No. заявки';
            TableRelation = "SI Request Header"."No.";
        }

        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }

        field(10; "Item No."; Code[20])
        {
            Caption = 'Товар';
            TableRelation = Item."No.";

            trigger OnValidate()
            begin
                UpdateFromItem();
            end;
        }

        field(20; "Variant Code"; Code[10])
        {
            Caption = 'Варіант товару';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                UpdateFromVariant();
            end;
        }

        field(30; Description; Text[100])
        {
            Caption = 'Опис товару';
        }

        field(40; Quantity; Decimal)
        {
            Caption = 'Кількість';
            DecimalPlaces = 0 : 5;
            MinValue = 0.00001;

            trigger OnValidate()
            begin
                if Quantity <= 0 then
                    Error('Quantity must be greater than zero.');
            end;
        }

        field(50; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Од. вим.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }

        field(55; "SI Category Kind"; Enum "SI Category Kind")
        {
            Caption = 'Вид категорії';
            Editable = false;
        }

        field(60; Comment; Text[250])
        {
            Caption = 'Коментар';
        }
    }

    keys
    {
        key(PK; "Request No.", "Line No.")
        {
            Clustered = true;
        }

        key(Item; "Item No.")
        {
        }
    }

    trigger OnInsert()
    begin
        TestHeaderIsEditable();
    end;

    trigger OnModify()
    begin
        TestHeaderIsEditable();
    end;

    trigger OnDelete()
    begin
        TestHeaderIsEditable();
    end;

    local procedure TestHeaderIsEditable()
    var
        RequestHeader: Record "SI Request Header";
    begin
        if not RequestHeader.Get("Request No.") then
            exit;

        if not (RequestHeader.Status in
            [RequestHeader.Status::Draft, RequestHeader.Status::Returned])
        then
            Error(
                'Request %1 lines cannot be changed in status %2.',
                RequestHeader."No.",
                Format(RequestHeader.Status));
    end;

    local procedure UpdateFromItem()
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
    begin
        if "Item No." = '' then begin
            Description := '';
            "Variant Code" := '';
            "Unit of Measure Code" := '';
            "SI Category Kind" := "SI Category Kind"::Undefined;
            exit;
        end;

        Item.Get("Item No.");

        Description := Item.Description;
        "Variant Code" := '';
        "Unit of Measure Code" := Item."Base Unit of Measure";

        "SI Category Kind" := "SI Category Kind"::Undefined;

        if Item."Item Category Code" <> '' then
            if ItemCategory.Get(Item."Item Category Code") then
                "SI Category Kind" := ItemCategory."SI Category Kind";
    end;

    local procedure UpdateFromVariant()
    var
        ItemVariant: Record "Item Variant";
    begin
        if "Variant Code" = '' then begin
            UpdateFromItem();
            exit;
        end;

        TestField("Item No.");
        ItemVariant.Get("Item No.", "Variant Code");

        if ItemVariant.Description <> '' then
            Description := ItemVariant.Description;
    end;
}
