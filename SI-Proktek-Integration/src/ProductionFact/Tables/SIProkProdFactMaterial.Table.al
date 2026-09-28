table 57092 "SI Prok Prod Fact Material"
{
    Caption = 'Матеріал факту виробництва Proktek';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Production Fact Entry No."; Integer) { Caption = 'Факт виробництва'; TableRelation = "SI Prok Production Fact"."Entry No."; }
        field(2; "Line No."; Integer) { Caption = '№ рядка'; }
        field(10; "Material UUID"; Guid) { Caption = 'Material UUID'; }
        field(20; "External Material Code"; Text[150]) { Caption = 'Код матеріалу Proktek'; }
        field(30; "Material Name"; Text[150]) { Caption = 'Матеріал'; }
        field(40; "Item No."; Code[20]) { Caption = 'Товар BC'; TableRelation = Item."No."; }
        field(50; "Variant Code"; Code[10]) { Caption = 'Варіант'; TableRelation = "Item Variant".Code where("Item No." = field("Item No.")); }
        field(60; "Requested Kg"; Decimal) { Caption = 'План Proktek, кг'; DecimalPlaces = 0 : 5; }
        field(70; "Adjusted Kg"; Decimal) { Caption = 'Скоригований план, кг'; DecimalPlaces = 0 : 5; }
        field(80; "Actual Kg"; Decimal) { Caption = 'Факт, кг'; DecimalPlaces = 0 : 5; }
        field(90; "Variance Kg"; Decimal) { Caption = 'Відхилення, кг'; DecimalPlaces = 0 : 5; }
        field(100; "Variance %"; Decimal) { Caption = 'Відхилення, %'; DecimalPlaces = 0 : 5; }
        field(110; "Recipe Material"; Boolean) { Caption = 'Матеріал рецептури'; }
        field(120; "BC Material Resolved"; Boolean) { Caption = 'Матеріал BC визначено'; }
    }

    keys
    {
        key(PK; "Production Fact Entry No.", "Line No.") { Clustered = true; }
        key(Material; "Production Fact Entry No.", "Item No.", "Variant Code") { }
    }
}
