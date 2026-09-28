table 59101 "SI Weighbridge Document Line"
{
    Caption = 'Рядок операційного документа вагової';
    DataClassification = CustomerContent;

    fields
    {
        // ------------------------------------------------------------
        // Primary key / parent document
        // ------------------------------------------------------------

        field(1; "Document Entry No."; BigInteger)
        {
            Caption = '№ запису документа';

            TableRelation =
                "SI Weighbridge Document"."Entry No.";

            NotBlank = true;
        }

        field(2; "Line No."; Integer)
        {
            Caption = '№ рядка';
        }

        // ------------------------------------------------------------
        // Product
        // ------------------------------------------------------------

        field(10; "Item No."; Code[20])
        {
            Caption = 'Товар';
            TableRelation = Item."No.";

            trigger OnValidate()
            var
                UoMConversionMgt: Codeunit "SI WB UoM Conversion Mgt.";
            begin
                if "Item No." = xRec."Item No." then
                    exit;

                // Variant belongs to a specific Item,
                // therefore it must not survive Item change.
                Clear("Variant Code");

                UoMConversionMgt.RecalculateLine(Rec);
            end;
        }

        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Варіант';

            TableRelation =
            "Item Variant".Code
            where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                UoMConversionMgt: Codeunit "SI WB UoM Conversion Mgt.";
            begin
                if "Variant Code" = xRec."Variant Code" then
                    exit;

                UoMConversionMgt.RecalculateLine(Rec);
            end;
        }

        // ------------------------------------------------------------
        // Physical weight allocation
        //
        // Header.Net Weight = immutable physical fact.
        // Line.Allocated Weight = editable business allocation
        // of that physical fact.
        // ------------------------------------------------------------

        field(20; "Allocated Weight"; Decimal)
        {
            Caption = 'Розподілена вага, кг';
            DecimalPlaces = 0 : 3;

            trigger OnValidate()
            var
                UoMConversionMgt: Codeunit "SI WB UoM Conversion Mgt.";
            begin
                if "Allocated Weight" < 0 then
                    Error(
                        'Розподілена вага не може бути від''ємною.');

                if "Allocated Weight" = xRec."Allocated Weight" then
                    exit;

                UoMConversionMgt.RecalculateLine(Rec);
            end;
        }

        field(21; "Weight UoM Code"; Code[10])
        {
            Caption = 'Од. вим. ваги';
            TableRelation = "Unit of Measure".Code;
            Editable = false;
        }

        // ------------------------------------------------------------
        // ERP / Item quantity
        //
        // Calculated from Allocated Weight using the applicable
        // UoM conversion rule.
        // ------------------------------------------------------------

        field(30; Quantity; Decimal)
        {
            Caption = 'Кількість';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(31; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Од. вим. товару';
            TableRelation = "Unit of Measure".Code;
            Editable = false;
        }

        // ------------------------------------------------------------
        // UoM conversion diagnostics / provenance
        // ------------------------------------------------------------

        field(40; "UoM Error Text"; Text[2048])
        {
            Caption = 'Помилка перерахунку од. вим.';
            Editable = false;
        }

        field(41; "Conversion Source Type"; Code[30])
        {
            Caption = 'Тип джерела перерахунку';
            Editable = false;
        }

        field(42; "Conversion Source Description"; Text[150])
        {
            Caption = 'Джерело перерахунку';
            Editable = false;
        }

        field(43; "Conversion Factor"; Decimal)
        {
            Caption = 'Коефіцієнт перерахунку';
            DecimalPlaces = 0 : 10;
            Editable = false;
        }

        field(44; "Conversion Factor UoM Code"; Code[10])
        {
            Caption = 'Од. вим. коефіцієнта';
            TableRelation = "Unit of Measure".Code;
            Editable = false;
        }

        // ------------------------------------------------------------
        // Resulting ERP document traceability
        //
        // Header stores ERP Document Type / No.
        // Line stores the corresponding ERP line number.
        // ------------------------------------------------------------

        field(50; "ERP Line No."; Integer)
        {
            Caption = '№ рядка документа BC';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Document Entry No.", "Line No.")
        {
            Clustered = true;
        }

        key(ItemKey; "Item No.", "Variant Code")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Document Entry No.");

        if "Line No." = 0 then
            Error(
                '№ рядка операційного документа не задано.');

        EnsureWeightUoM();
    end;

    trigger OnModify()
    begin
        EnsureWeightUoM();
    end;

    procedure EnsureWeightUoM()
    var
        WeightUoM: Code[10];
    begin
        WeightUoM := WeightUoMCode();

        if "Weight UoM Code" = '' then
            "Weight UoM Code" := WeightUoM;

        if "Weight UoM Code" <> WeightUoM then
            Error(
                'Фізична вага документа вагової повинна зберігатися в %1.',
                WeightUoM);
    end;

    procedure WeightUoMCode(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.Get('KG') then
            exit('KG');

        if UnitOfMeasure.Get('КГ') then
            exit('КГ');

        Error(
            'Не знайдено одиницю виміру ваги. У таблиці "Одиниці виміру" має існувати код KG або КГ.');
    end;

    procedure ClearCalculatedValues()
    begin
        Clear(Quantity);
        Clear("Unit of Measure Code");
        Clear("UoM Error Text");
        Clear("Conversion Source Type");
        Clear("Conversion Source Description");
        Clear("Conversion Factor");
        Clear("Conversion Factor UoM Code");
    end;
}