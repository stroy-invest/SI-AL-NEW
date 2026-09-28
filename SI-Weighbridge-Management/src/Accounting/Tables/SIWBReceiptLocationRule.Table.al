table 59132 "SI WB Receipt Location Rule"
{
    Caption = 'Правило складу прибуткування';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = '№';
            AutoIncrement = true;
        }

        field(2; "Location Code"; Code[10])
        {
            Caption = 'Склад';
            TableRelation = Location.Code;
            NotBlank = true;
        }

        field(3; Enabled; Boolean)
        {
            Caption = 'Увімкнено';
            InitValue = true;
        }

        field(4; Priority; Integer)
        {
            Caption = 'Пріоритет';
            ToolTip = 'Більше число означає вищий пріоритет серед однаково придатних правил складу.';
        }

        field(10; "Item Category Code"; Code[20])
        {
            Caption = 'Категорія товару';
            TableRelation = "Item Category".Code;
            ToolTip = 'Категорія може бути будь-яким предком фактичної категорії товару. Дочірні категорії успадковують правило.';
        }

        field(11; "Item No."; Code[20])
        {
            Caption = 'Товар';
            TableRelation = Item."No.";

            trigger OnValidate()
            begin
                if "Item No." = '' then
                    Clear("Variant Code");
            end;
        }

        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Варіант';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                if ("Variant Code" <> '') and ("Item No." = '') then
                    Error('Для правила за варіантом спочатку виберіть товар.');
            end;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(LocationEnabled; "Location Code", Enabled, Priority)
        {
        }
    }
    trigger OnInsert()
    begin
        TestField("Location Code");
    end;

}
