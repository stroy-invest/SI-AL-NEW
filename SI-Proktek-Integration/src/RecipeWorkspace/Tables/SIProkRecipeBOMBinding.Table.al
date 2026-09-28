table 57023 "SI Prok Recipe BOM Binding"
{
    Caption = 'Recipe BOM Binding';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20]) { TableRelation = Item."No."; }
        field(2; "Variant Code"; Code[10]) { TableRelation = "Item Variant".Code where("Item No." = field("Item No.")); }
        field(3; "Production BOM No."; Code[20]) { TableRelation = "Production BOM Header"."No."; }
    }
    keys
    {
        key(PK; "Item No.", "Variant Code") { Clustered = true; }
        key(BOM; "Production BOM No.") { }
    }
}
