table 61041 "SI Vendor Supply Capability"
{
    Caption = 'Канал постачання постачальника';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Код';
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = '№ постачальника';
            TableRelation = Vendor."No." where(Blocked = const(" "));

            trigger OnValidate()
            begin
                if "Vendor No." <> xRec."Vendor No." then
                    TestField(Status, Status::Draft);
            end;
        }
        field(3; "Item Category Code"; Code[20])
        {
            Caption = 'Категорія товару';
            TableRelation = "Item Category".Code;

            trigger OnValidate()
            begin
                if "Item Category Code" <> xRec."Item Category Code" then
                    TestField(Status, Status::Draft);
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Опис';

            trigger OnValidate()
            begin
                Description := DelChr(Description, '<>', ' ');
            end;
        }
        field(5; Status; Enum "SI VSC Status")
        {
            Caption = 'Статус';

            trigger OnValidate()
            begin
                if Status = Status::Active then
                    ValidateForActivation();
            end;
        }
        field(6; "Shipment Method Code"; Code[10])
        {
            Caption = 'Спосіб поставки';
            TableRelation = "Shipment Method".Code;
        }
        field(7; "UoM Code"; Code[10])
        {
            Caption = 'Од. виміру';
            TableRelation = "Unit of Measure".Code;
        }
        field(8; "Minimum Order Quantity"; Decimal)
        {
            Caption = 'Мінімальна кількість замовлення';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Minimum Order Quantity" > 0 then
                    TestField("UoM Code");
            end;
        }
        field(9; "Order Multiple"; Decimal)
        {
            Caption = 'Кратність замовлення';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Order Multiple" > 0 then
                    TestField("UoM Code");
            end;
        }
        field(10; "Lead Time Calculation"; DateFormula)
        {
            Caption = 'Строк постачання';
        }
        field(11; "Valid From"; Date)
        {
            Caption = 'Діє з';

            trigger OnValidate()
            begin
                ValidateValidityDates();
            end;
        }
        field(12; "Valid To"; Date)
        {
            Caption = 'Діє до';

            trigger OnValidate()
            begin
                ValidateValidityDates();
            end;
        }
        field(13; Notes; Text[250])
        {
            Caption = 'Примітки';
        }
        field(20; "Vendor Name"; Text[100])
        {
            Caption = 'Постачальник';
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Editable = false;
        }
        field(21; "Item Category Description"; Text[100])
        {
            Caption = 'Категорія';
            FieldClass = FlowField;
            CalcFormula = lookup("Item Category".Description where(Code = field("Item Category Code")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
        key(VendorCategory; "Vendor No.", "Item Category Code", Status) { }
        key(CategoryStatus; "Item Category Code", Status, "Vendor No.") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description, "Vendor No.", "Item Category Code", Status) { }
    }

    trigger OnInsert()
    var
        VSCMgt: Codeunit "SI VSC Mgt.";
    begin
        VSCMgt.InitCapabilityNo(Rec);
    end;

    local procedure ValidateForActivation()
    begin
        TestField("Vendor No.");
        TestField("Item Category Code");
        TestField(Description);
        ValidateValidityDates();

        if ("Minimum Order Quantity" > 0) or ("Order Multiple" > 0) then
            TestField("UoM Code");
    end;

    local procedure ValidateValidityDates()
    begin
        if ("Valid From" <> 0D) and ("Valid To" <> 0D) then
            if "Valid To" < "Valid From" then
                Error(ValidityDateErr, FieldCaption("Valid To"), FieldCaption("Valid From"));
    end;

    var
        ValidityDateErr: Label '%1 не може бути раніше за %2.';
}
