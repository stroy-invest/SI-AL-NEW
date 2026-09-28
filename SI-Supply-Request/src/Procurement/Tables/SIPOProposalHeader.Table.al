table 61053 "SI PO Proposal Header"
{
    Caption = 'Пропозиція замовлення постачальнику';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; Caption = '№ запису'; }
        field(2; "Planning Run No."; Integer) { Caption = 'План'; TableRelation = "SI Proc. Plan Run"."Run No."; }
        field(10; "Vendor No."; Code[20]) { Caption = 'Постачальник'; TableRelation = Vendor."No."; }
        field(11; "Location Code"; Code[10]) { Caption = 'Склад отримання'; TableRelation = Location.Code; }
        field(12; "Expected Receipt Date"; Date) { Caption = 'Дата поставки'; }
        field(13; "Shipment Method Code"; Code[10]) { Caption = 'Спосіб доставки'; TableRelation = "Shipment Method".Code; }
        field(14; "Currency Code"; Code[10]) { Caption = 'Валюта'; TableRelation = Currency.Code; }
        field(20; "Created At"; DateTime) { Caption = 'Сформовано'; Editable = false; }
        field(21; Status; Enum "SI PO Proposal Status") { Caption = 'Статус'; Editable = false; }
        field(22; "Purchase Order No."; Code[20]) { Caption = 'Замовлення постачальнику'; TableRelation = "Purchase Header"."No." where("Document Type" = const(Order)); Editable = false; }
        field(23; "PO Created At"; DateTime) { Caption = 'Замовлення створено'; Editable = false; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(GroupKey; "Planning Run No.", "Vendor No.", "Location Code", "Expected Receipt Date", "Shipment Method Code", "Currency Code") { }
    }

    trigger OnInsert()
    begin
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
    end;
}
