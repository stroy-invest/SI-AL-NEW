tableextension 53000 "SI Item Variant Sem. Context" extends "Item Variant"
{
    fields
    {
        field(53000; "SI Configuration No."; Code[20])
        {
            Caption = 'Конфігурація продукту';
            FieldClass = FlowField;
            CalcFormula = lookup("SI Config. ERP Projection"."Configuration No." where("Item No." = field("Item No."), "Variant Code" = field(Code)));
            Editable = false;
        }

        field(53001; "SI Item Configuration No."; Code[20])
        {
            Caption = 'Конфігурація базового товару';
            FieldClass = FlowField;
            CalcFormula = lookup("SI Config. ERP Projection"."Configuration No." where("Item No." = field("Item No."), "Variant Code" = const('')));
            Editable = false;
        }
    }
}
