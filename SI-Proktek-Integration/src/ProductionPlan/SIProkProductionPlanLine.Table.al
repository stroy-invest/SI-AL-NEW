table 57100 "SI Prok Production Plan Line"
{
    Caption = 'Матеріал плану виробництва';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Prod. Request Entry No."; Integer) { Caption = '№ виробничої заявки'; TableRelation = "SI Prok Production Plan"."Prod. Request Entry No."; }
        field(2; "Line No."; Integer) { Caption = '№ рядка'; }
        field(10; "Item No."; Code[20]) { Caption = 'Матеріал'; Editable = false; }
        field(20; Description; Text[100]) { Caption = 'Опис'; Editable = false; }
        field(30; "Variant Code"; Code[10]) { Caption = 'Варіант'; Editable = false; }
        field(40; "Unit of Measure Code"; Code[10]) { Caption = 'Одиниця виміру'; Editable = false; }
        field(50; "Quantity per"; Decimal) { Caption = 'Норма на одиницю'; DecimalPlaces = 0 : 5; Editable = false; }
        field(60; "Planned Quantity"; Decimal) { Caption = 'Планова кількість'; DecimalPlaces = 0 : 5; Editable = false; }
    }
    keys { key(PK; "Prod. Request Entry No.", "Line No.") { Clustered = true; } }
}
