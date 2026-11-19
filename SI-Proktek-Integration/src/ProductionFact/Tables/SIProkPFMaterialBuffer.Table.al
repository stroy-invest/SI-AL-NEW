table 57221 "SI Prok PF Material Buffer"
{
    Caption = 'Буфер матеріалів звіту план/факт';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Material Key"; Text[250]) { Caption = 'Ключ матеріалу'; }
        field(10; "Item No."; Code[20]) { Caption = 'Товар BC'; }
        field(20; "Variant Code"; Code[10]) { Caption = 'Варіант'; }
        field(30; "Material Name"; Text[150]) { Caption = 'Матеріал'; }
        field(40; "Norm Kg"; Decimal) { Caption = 'Норма на фактичний обсяг, кг'; DecimalPlaces = 0 : 5; }
        field(50; "MES Requested Kg"; Decimal) { Caption = 'План MES, кг'; DecimalPlaces = 0 : 5; }
        field(60; "Actual Kg"; Decimal) { Caption = 'Факт MES, кг'; DecimalPlaces = 0 : 5; }
        field(70; "Has Norm"; Boolean) { Caption = 'У нормативі'; }
        field(80; "Has Actual Line"; Boolean) { Caption = 'Є рядок MES'; }
        field(90; "Unmapped"; Boolean) { Caption = 'Не зіставлено з BC'; }
    }
    keys
    {
        key(PK; "Material Key") { Clustered = true; }
    }
}
