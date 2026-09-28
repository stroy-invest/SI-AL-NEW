table 61014 "SI Vendor Item Category"
{
    Caption = 'Постачальники за категоріями';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = '№ постачальника';
            TableRelation = Vendor."No." where(Blocked = const(" "));
        }
        field(2; "Item Category Code"; Code[20])
        {
            Caption = 'Категорія товару';
            TableRelation = "Item Category".Code;
        }
        field(10; "Vendor Name"; Text[100])
        {
            Caption = 'Постачальник';
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Editable = false;
        }
        field(20; Active; Boolean)
        {
            Caption = 'Активний';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Vendor No.", "Item Category Code") { Clustered = true; }
        key(Category; "Item Category Code", Active, "Vendor No.") { }
    }
}
