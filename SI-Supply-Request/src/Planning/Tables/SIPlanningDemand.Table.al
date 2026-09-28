table 61044 "SI Planning Demand"
{
    Caption = 'Єдиний реєстр планових потреб';
    DataClassification = CustomerContent;
    LookupPageId = "SI Planning Demands";
    DrillDownPageId = "SI Planning Demands";

    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№ запису'; AutoIncrement = true; }
        field(10; "Source Type"; Enum "SI Planning Demand Source") { Caption = 'Джерело'; }
        field(20; "Decision No."; Code[20]) { Caption = '№ рішення'; }
        field(21; "Decision Line No."; Integer) { Caption = '№ рядка рішення'; }
        field(22; "Allocation Line No."; Integer) { Caption = '№ розподілу'; }
        field(23; "Requirement Line No."; Integer) { Caption = '№ рядка потреби матеріалу'; }
        field(30; "Request No."; Code[20]) { Caption = '№ заявки'; }
        field(31; "Request Line No."; Integer) { Caption = '№ рядка заявки'; }
        field(40; "Project No."; Code[20]) { Caption = 'Проєкт'; TableRelation = Job."No."; }
        field(41; "Construction Site Code"; Code[20]) { Caption = 'Буд. майданчик'; }
        field(50; "Item No."; Code[20]) { Caption = 'Товар / матеріал'; TableRelation = Item."No."; }
        field(51; "Variant Code"; Code[10]) { Caption = 'Варіант'; TableRelation = "Item Variant".Code where("Item No." = field("Item No.")); }
        field(52; Description; Text[250]) { Caption = 'Опис'; }
        field(60; Quantity; Decimal) { Caption = 'Планова потреба'; DecimalPlaces = 0 : 5; }
        field(61; "Unit of Measure Code"; Code[10]) { Caption = 'Од. вим.'; }
        field(70; "Required on Site At"; DateTime) { Caption = 'Потрібно на об''єкті'; }
        field(71; "Planning Date"; Date) { Caption = 'Дата планування'; }
        field(80; "Target Location Code"; Code[10]) { Caption = 'Склад планування'; TableRelation = Location.Code; }
        field(90; "Source Status"; Enum "SI Supply Alloc Status") { Caption = 'Статус розподілу'; }
        field(91; "Planning Status"; Enum "SI Planning Demand Status") { Caption = 'Статус планування'; }
        field(100; "Last Rebuilt At"; DateTime) { Caption = 'Оновлено'; }
        field(101; "Rebuild Token"; Guid) { Caption = 'Токен перебудови'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Source; "Source Type", "Decision No.", "Decision Line No.", "Allocation Line No.", "Requirement Line No.") { Unique = true; }
        key(Planning; "Planning Status", "Planning Date", "Item No.", "Variant Code", "Target Location Code") { }
        key(Request; "Request No.", "Request Line No.") { }
        key(Project; "Project No.", "Construction Site Code") { }
    }
}
