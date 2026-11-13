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
        // SH-03.2: immutable source identity, copied from the production request.
        field(180; "Supply Decision No."; Code[20]) { Caption = 'Рішення забезпечення'; Editable = false; }
        field(181; "Supply Decision Line No."; Integer) { Caption = 'Рядок рішення'; Editable = false; }
        field(182; "Supply Allocation Line No."; Integer) { Caption = 'Рядок розподілу'; Editable = false; }
        field(183; "Supply Allocation System ID"; Guid) { Caption = 'SystemId розподілу'; Editable = false; }
        field(184; "Allocation Binding Status"; Code[30]) { Caption = 'Статус зв’язку з розподілом'; Editable = false; }


        // SH-03.3: document snapshots (never calculated dynamically on reprint).
        field(190; "Concrete Description"; Text[150]) { Caption = 'Бетон'; Editable = false; }
        field(191; "Delivery Project No."; Code[20]) { Caption = 'Проєкт доставки'; Editable = false; }
        field(192; "Delivery Site Code"; Code[20]) { Caption = 'Код майданчика'; Editable = false; }
        field(193; "Delivery Site Name"; Text[100]) { Caption = 'Точка розвантаження'; Editable = false; }
        field(194; "Delivery Address"; Text[250]) { Caption = 'Адреса'; Editable = false; }
        field(195; "Shipped By Employee No."; Code[20]) { Caption = 'Відвантажив (Employee)'; Editable = false; TableRelation = Employee."No."; }
        field(196; "Shipped By Name"; Text[100]) { Caption = 'Відвантажив'; Editable = false; }
        field(197; "Received By Employee No."; Code[20]) { Caption = 'Прийняв (Employee)'; Editable = false; TableRelation = Employee."No."; }
        field(198; "Received By Name"; Text[100]) { Caption = 'Прийняв'; Editable = false; }
        field(199; "Shipped By Manual"; Boolean) { Caption = 'Відвантажив: ручний вибір'; Editable = false; }
        field(200; "Received By Manual"; Boolean) { Caption = 'Прийняв: ручний вибір'; Editable = false; }
        field(201; "Document Snapshot Status"; Code[30]) { Caption = 'Стан реквізитів'; Editable = false; }
        field(202; "Snapshot Created At"; DateTime) { Caption = 'Реквізити зафіксовано'; Editable = false; }
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
