table 57097 "SI Prok Material Audit"
{
    Caption = 'Аудит матеріалів Proktek';
    DataClassification = CustomerContent;
    TableType = Temporary;
    fields
    {
        field(1; "Line No."; Integer) { Caption = '№ рядка'; }
        field(10; "Scope"; Text[30]) { Caption = 'Автоміксер / підсумок'; }
        field(20; "Item No."; Code[20]) { Caption = 'Товар BC'; }
        field(30; "Variant Code"; Code[10]) { Caption = 'Варіант'; }
        field(40; "Material Name"; Text[150]) { Caption = 'Матеріал'; }
        field(50; "External Material Code"; Text[150]) { Caption = 'Код Proktek'; }
        field(60; "Produced M3"; Decimal) { Caption = 'Випуск, м³'; DecimalPlaces = 0 : 5; }
        field(70; "Ordered M3"; Decimal) { Caption = 'Замовлено, м³'; DecimalPlaces = 0 : 5; }
        field(80; "Recipe Kg Per M3"; Decimal) { Caption = 'Рецептура, кг/м³'; DecimalPlaces = 0 : 5; }
        field(90; "BC Norm Kg"; Decimal) { Caption = 'Норма BC на випуск, кг'; DecimalPlaces = 0 : 5; }
        field(100; "Proktek Plan Kg"; Decimal) { Caption = 'План Proktek, кг'; DecimalPlaces = 0 : 5; }
        field(110; "Actual Kg"; Decimal) { Caption = 'Факт Proktek, кг'; DecimalPlaces = 0 : 5; }
        field(120; "Variance Kg"; Decimal) { Caption = 'Факт − норма, кг'; DecimalPlaces = 0 : 5; }
        field(130; "Variance Percent"; Decimal) { Caption = 'Факт − норма, %'; DecimalPlaces = 0 : 5; }
        field(140; "Plan Difference Kg"; Decimal) { Caption = 'План Proktek − BC, кг'; DecimalPlaces = 0 : 5; }
        field(150; "Ordered Norm Kg"; Decimal) { Caption = 'Норма на замовлення, кг'; DecimalPlaces = 0 : 5; }
        field(160; "Recipe Material"; Boolean) { Caption = 'У рецептурі'; }
        field(170; "BC Material Resolved"; Boolean) { Caption = 'Матеріал визначено'; }
        field(180; "Check Result"; Text[100]) { Caption = 'Результат'; }
        field(190; "Mix Count"; Integer) { Caption = 'Замісів'; }
    }
    keys { key(PK; "Line No.") { Clustered = true; } }
}
