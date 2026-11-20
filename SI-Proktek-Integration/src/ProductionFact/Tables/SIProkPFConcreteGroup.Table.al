table 57230 "SI Prok PF Concrete Group"
{
    Caption = 'Група бетону для підсумкового звіту';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Group Key"; Text[250]) { Caption = 'Ключ групи'; }
        field(10; "Concrete Name"; Text[150]) { Caption = 'Бетон'; }
        field(20; "Recipe Name"; Text[150]) { Caption = 'Рецептура'; }
        field(30; "Planned M3"; Decimal) { Caption = 'План, м³'; DecimalPlaces = 0 : 5; }
        field(40; "Produced M3"; Decimal) { Caption = 'Факт, м³'; DecimalPlaces = 0 : 5; }
        field(50; "Missing Plan"; Boolean) { Caption = 'План неповний'; }
        field(60; "Missing Actual"; Boolean) { Caption = 'Факт неповний'; }
        field(70; "Mixed Recipes"; Boolean) { Caption = 'Кілька рецептур'; }
    }

    keys
    {
        key(PK; "Group Key") { Clustered = true; }
        key(Name; "Concrete Name") { }
    }
}
