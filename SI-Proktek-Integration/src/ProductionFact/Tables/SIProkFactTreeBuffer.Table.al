table 57220 "SI Prok Fact Tree Buffer"
{
    Caption = 'Ієрархія виробничих фактів';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№ рядка'; }
        field(10; "Node Type"; Option) { OptionMembers = Request,Fact,Party,Unlinked,Unmatched,BrokenLink; OptionCaption = 'Заявка,Факт,Партія,Без замовлення,Незіставлене замовлення,Помилка прив’язки'; }
        field(20; "Request Scope"; Option) { OptionMembers = None,SupplyRequest,ProductionRequest; OptionCaption = 'Немає,Заявка забезпечення,Виробнича заявка'; }
        field(30; Indentation; Integer) { Caption = 'Рівень'; }
        field(40; "Display Name"; Text[250]) { Caption = 'Заявка / факт / партія'; }
        field(50; "Source No."; Code[30]) { Caption = 'Заявка'; }
        field(60; "Prod. Request Entry No."; Integer) { Caption = 'Виробнича заявка'; }
        field(70; "Fact Entry No."; Integer) { Caption = 'Факт'; }
        field(80; "Production Date/Time"; DateTime) { Caption = 'Дата/час'; }
        field(90; "Truck Plate"; Text[50]) { Caption = 'Автоміксер'; }
        field(100; "Item No."; Code[20]) { Caption = 'Бетон'; }
        field(110; "Planned Quantity M3"; Decimal) { Caption = 'План, м³'; DecimalPlaces = 0 : 5; }
        field(120; "Actual Quantity M3"; Decimal) { Caption = 'Факт MES, м³'; DecimalPlaces = 0 : 5; }
        field(130; "Quantity Known"; Boolean) { Caption = 'Обсяг відомий'; }
        field(140; "Plan Display"; Text[40]) { Caption = 'План, м³'; }
        field(150; "Actual Display"; Text[40]) { Caption = 'Факт MES, м³'; }
        field(160; "Link State"; Enum "SI Prok PF Link State") { Caption = 'Стан прив’язки'; }
        field(180; "Proktek Order No."; Text[150]) { Caption = 'Order No. Proktek'; }
        field(190; "Has Facts"; Boolean) { Caption = 'Є факти'; }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
