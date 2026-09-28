tableextension 53002 "SI Item Semantic Context" extends Item
{
    fields
    {
        field(53000; "SI Configuration No."; Code[20])
        {
            Caption = 'Конфігурація продукту';
            FieldClass = FlowField;
            CalcFormula = lookup("SI Config. ERP Projection"."Configuration No." where("Item No." = field("No."), "Variant Code" = const('')));
            Editable = false;
        }
    }
}
