tableextension 55010 "SI Family Param. Mfr. Ref." extends "SI Family Parameter"
{
    fields
    {
        field(55000; "SI Ref. Item No."; Code[20])
        {
            Caption = 'Товар для вибору схваленого продукту';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";

            trigger OnValidate()
            begin
                if "SI Ref. Item No." <> xRec."SI Ref. Item No." then
                    Clear("SI Ref. Variant Code");
            end;
        }

        field(55001; "SI Ref. Variant Code"; Code[10])
        {
            Caption = 'Варіант для вибору схваленого продукту';
            DataClassification = CustomerContent;
            TableRelation = "Item Variant".Code where("Item No." = field("SI Ref. Item No."));
        }


        field(55002; "SI Show Manufacturer in Name"; Boolean)
        {
            Caption = 'Виводити назву виробника';
            DataClassification = CustomerContent;
            InitValue = false;
        }
    }
}
