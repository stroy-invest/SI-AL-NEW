table 55003 "SI Category Manufacturer"
{
    Caption = 'Дозволений виробник категорії';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item Category Code"; Code[20])
        {
            Caption = 'Код категорії товару';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "Item Category".Code;
        }

        field(2; "Manufacturer Code"; Code[20])
        {
            Caption = 'Код виробника';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "SI Manufacturer".Code;

            trigger OnValidate()
            var
                Manufacturer: Record "SI Manufacturer";
            begin
                if "Manufacturer Code" = '' then
                    exit;

                if not Manufacturer.Get("Manufacturer Code") then
                    exit;

                if Manufacturer.Blocked then
                    Error(
                        ManufacturerBlockedErr,
                        Manufacturer.Code);
            end;
        }

        field(10; "Item Category Description"; Text[100])
        {
            Caption = 'Категорія товару';
            FieldClass = FlowField;
            CalcFormula = lookup(
                "Item Category".Description
                where(Code = field("Item Category Code")));
        }

        field(20; "Manufacturer Name"; Text[100])
        {
            Caption = 'Виробник';
            FieldClass = FlowField;
            CalcFormula = lookup(
                "SI Manufacturer".Name
                where(Code = field("Manufacturer Code")));
        }
    }

    keys
    {
        key(PK; "Item Category Code", "Manufacturer Code")
        {
            Clustered = true;
        }

        key(Manufacturer; "Manufacturer Code")
        {
        }
    }

    var
        ManufacturerBlockedErr: Label
            'Виробника %1 заблоковано. Його не можна додати до переліку дозволених виробників категорії.';
}