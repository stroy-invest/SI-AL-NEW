table 57142 "SI Prok Shipment"
{
    Caption = 'Відвантаження бетону Proktek';
    DataClassification = CustomerContent;
    LookupPageId = "SI Prok Shipments";
    DrillDownPageId = "SI Prok Shipments";
    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№ документа'; AutoIncrement = true; }
        field(10; Status; Enum "SI Prok Shipment Status") { Caption = 'Статус'; Editable = false; }
        field(20; "Production UUID"; Guid) { Caption = 'Production UUID'; Editable = false; }
        field(30; "Production Fact Entry No."; Integer) { Caption = 'Факт виробництва'; Editable = false; TableRelation = "SI Prok Production Fact"."Entry No."; }
        field(40; "Prod. Request Entry No."; Integer) { Caption = 'Виробнича заявка'; Editable = false; TableRelation = "SI Concrete Prod Request"."Entry No."; }
        field(50; "Source Order No."; Code[30]) { Caption = 'Замовлення / заявка'; Editable = false; }
        field(60; "BC Prod. Order No."; Code[20]) { Caption = 'Виробниче замовлення BC'; Editable = false; }
        field(70; "Item No."; Code[20]) { Caption = 'Продукт'; Editable = false; TableRelation = Item."No."; }
        field(80; "Variant Code"; Code[10]) { Caption = 'Варіант'; Editable = false; }
        field(90; "Recipe Name"; Text[150]) { Caption = 'Рецептура'; Editable = false; }
        field(100; "Quantity M3"; Decimal) { Caption = 'Кількість, м³'; DecimalPlaces = 0 : 5; Editable = false; }
        field(101; "Simulation Quantity"; Boolean) { Caption = 'Обсяг симуляції (не фактичний випуск)'; Editable = false; }
        field(110; "Truck Plate"; Text[50]) { Caption = 'Державний номер автомобіля'; Editable = false; }
        field(120; "Driver UUID"; Guid) { Caption = 'UUID водія Proktek'; Editable = false; }
        field(130; "Employee No."; Code[20]) { Caption = 'Водій (Employee)'; Editable = false; TableRelation = Employee."No."; }
        field(131; "Driver Name"; Text[100]) { Caption = 'Водій'; Editable = false; }
        field(140; "Shipment Date/Time"; DateTime) { Caption = 'Дата/час відвантаження'; Editable = false; }
        field(150; "Connection Code"; Code[50]) { Caption = 'Профіль Proktek'; Editable = false; }
        field(160; "Created At"; DateTime) { Caption = 'Створено'; Editable = false; }
        field(170; "Closed At"; DateTime) { Caption = 'Закрито'; Editable = false; }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Production; "Production UUID") { Unique = true; }
    }
    procedure CloseAfterPrint()
    begin
        if Status <> Status::Open then
            Error('Документ уже закрито. Скористайтеся дією «Повторити друк».');
        Status := Status::Closed;
        "Closed At" := CurrentDateTime();
        Modify(true);
    end;
}
