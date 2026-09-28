table 57022 "SI Concrete Prod Request"
{
    Caption = 'Заявка на виробництво бетону';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = '№ запису';
            AutoIncrement = true;
        }
        field(10; Status; Enum "SI Concrete Prod Req Status")
        {
            Caption = 'Статус';
        }
        field(20; "Source Type"; Enum "SI Concrete Demand Source")
        {
            Caption = 'Джерело потреби';
        }
        field(30; "Source No."; Code[30])
        {
            Caption = '№ документа-джерела';
        }
        field(40; "Source Line No."; Integer)
        {
            Caption = '№ рядка джерела';
        }
        field(50; "Customer No."; Code[20])
        {
            Caption = 'Клієнт';
            TableRelation = Customer."No.";
        }
        field(60; "Item No."; Code[20])
        {
            Caption = 'Товар';
            TableRelation = Item."No.";

            trigger OnValidate()
            begin
                if "Item No." <> xRec."Item No." then begin
                    Clear("Variant Code");
                    Clear("Unit of Measure Code");
                    Clear("Recipe Snapshot Entry No.");
                    Clear("Formula Code");
                    Clear("Formula Description");
                    "Recipe Type" := "Recipe Type"::"Not Selected";
                end;

                SetDefaultUoM();
            end;
        }
        field(70; "Variant Code"; Code[10])
        {
            Caption = 'Варіант';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if "Variant Code" <> '' then
                    ItemVariant.Get("Item No.", "Variant Code");

                if "Variant Code" <> xRec."Variant Code" then begin
                    Clear("Recipe Snapshot Entry No.");
                    Clear("Formula Code");
                    Clear("Formula Description");
                    "Recipe Type" := "Recipe Type"::"Not Selected";
                end;
            end;
        }
        field(80; Quantity; Decimal)
        {
            Caption = 'Кількість';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if Quantity < 0 then
                    Error('Кількість не може бути від''ємною.');
            end;
        }
        field(90; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Од. виміру';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(100; "Required Date/Time"; DateTime)
        {
            Caption = 'Потрібно на дату/час';
        }
        field(110; "Location Code"; Code[10])
        {
            Caption = 'Майданчик / Location';
            TableRelation = Location.Code;
        }
        field(120; "Recipe Snapshot Entry No."; Integer)
        {
            Caption = 'Recipe Snapshot';
            TableRelation = "SI Prok Recipe Snapshot"."Entry No." where("Item No." = field("Item No."), "Variant Code" = field("Variant Code"));
        }
        field(130; "Formula Code"; Text[150])
        {
            Caption = 'Formula Code';
        }
        field(140; Description; Text[100])
        {
            Caption = 'Опис';
        }
        field(150; "Created At"; DateTime)
        {
            Caption = 'Створено';
            Editable = false;
        }
        field(160; "Created By"; Text[100])
        {
            Caption = 'Створив';
            Editable = false;
        }
        field(170; "Recipe Type"; Enum "SI Concrete Recipe Type")
        {
            Caption = 'Тип рецептури';
            Editable = false;
        }
        field(180; "Formula Description"; Text[150])
        {
            Caption = 'Рецептура';
            Editable = false;
        }
        field(190; "Supply Decision No."; Code[20])
        {
            Caption = '№ рішення забезпечення';
            Editable = false;
        }
        field(200; "Supply Decision Line No."; Integer)
        {
            Caption = '№ рядка рішення забезпечення';
            Editable = false;
        }
        field(210; "Supply Allocation Line No."; Integer)
        {
            Caption = '№ розподілу забезпечення';
            Editable = false;
        }
        field(220; "Request Type"; Enum "SI Supply Req Type")
        {
            Caption = 'Тип заявки';
            Editable = false;
        }
        field(230; "Project No."; Code[20])
        {
            Caption = 'Проєкт';
            TableRelation = Job."No.";
            Editable = false;
        }
        field(240; "Project Location Code"; Code[10])
        {
            Caption = 'Склад / майданчик проєкту';
            TableRelation = Location.Code;
            Editable = false;
        }
        field(250; "Integration Customer No."; Code[20])
        {
            Caption = 'Інтеграційний клієнт';
            TableRelation = Customer."No.";
            Editable = false;
        }
        field(260; "Source Location Code"; Code[10])
        {
            Caption = 'Склад-джерело';
            TableRelation = Location.Code;
            Editable = false;
        }
        field(270; "Supply Method"; Enum "SI Supply Method")
        {
            Caption = 'Спосіб забезпечення';
            Editable = false;
        }
        field(280; "Recipe No."; Code[50])
        {
            Caption = 'Рецептура';
            Editable = false;
        }
        field(290; "Recipe Revision No."; Integer)
        {
            Caption = '№ ревізії рецептури';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Source; "Source Type", "Source No.", "Source Line No.")
        {
        }
        key(Product; "Item No.", "Variant Code")
        {
        }
        key(SupplyAllocation; "Supply Decision No.", "Supply Decision Line No.", "Supply Allocation Line No.")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
        if "Created By" = '' then
            "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
        SetDefaultUoM();
    end;

    procedure GetProductDescription(): Text[150]
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if "Item No." = '' then
            exit('');

        if not Item.Get("Item No.") then
            exit("Item No.");

        if ("Variant Code" <> '') and ItemVariant.Get("Item No.", "Variant Code") and (ItemVariant.Description <> '') then
            exit(CopyStr(ItemVariant.Description, 1, 150));

        exit(CopyStr(Item.Description, 1, 150));
    end;

    procedure GetCustomerDescription(): Text[150]
    var
        Customer: Record Customer;
    begin
        if ("Customer No." <> '') and Customer.Get("Customer No.") then
            exit(CopyStr(Customer.Name, 1, 150));
        exit("Customer No.");
    end;

    procedure GetLocationDescription(): Text[150]
    var
        Location: Record Location;
    begin
        if ("Location Code" <> '') and Location.Get("Location Code") then
            exit(CopyStr(Location.Name, 1, 150));
        exit("Location Code");
    end;

    local procedure SetDefaultUoM()
    var
        Item: Record Item;
    begin
        if ("Item No." = '') or ("Unit of Measure Code" <> '') then
            exit;

        if Item.Get("Item No.") then
            "Unit of Measure Code" := Item."Base Unit of Measure";
    end;
}
