table 57121 "SI Prok Journal Link"
{
    Caption = 'Зв’язок виробничого факту з журналом';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Fact Entry No."; Integer) { Caption = 'Факт'; TableRelation = "SI Prok Production Fact"."Entry No."; }
        field(2; "Link Line No."; Integer) { Caption = 'Рядок зв’язку'; }
        field(10; "Production UUID"; Guid) { Caption = 'Production UUID'; }
        field(11; "Material Line No."; Integer) { Caption = 'Рядок матеріалу (0 = Output)'; }
        field(20; "Journal Template"; Code[10]) { Caption = 'Шаблон'; }
        field(21; "Journal Batch"; Code[10]) { Caption = 'Пакет'; }
        field(22; "Journal Line No."; Integer) { Caption = 'Рядок журналу'; }
        field(23; "Document No."; Code[20]) { Caption = 'Номер документа'; }
        field(40; "Expected Entry Type"; Enum "Item Ledger Entry Type") { Caption = 'Очікуваний тип операції'; }
        field(41; "Expected Item No."; Code[20]) { Caption = 'Очікуваний товар'; }
        field(42; "Expected Variant Code"; Code[10]) { Caption = 'Очікуваний варіант'; }
        field(43; "Expected Location Code"; Code[10]) { Caption = 'Очікуваний склад'; }
        field(44; "Expected Bin Code"; Code[20]) { Caption = 'Очікувана комірка'; }
        field(45; "Expected Quantity"; Decimal) { Caption = 'Очікувана кількість'; DecimalPlaces = 0 : 5; }
        field(46; "Expected UoM"; Code[10]) { Caption = 'Очікувана одиниця'; }
        field(47; "Expected Posting Date"; Date) { Caption = 'Очікувана дата проведення'; }
        field(48; "Expected Order No."; Code[20]) { Caption = 'Очікуване виробниче замовлення'; }
        field(49; "Expected Order Line No."; Integer) { Caption = 'Очікуваний рядок замовлення'; }
        field(50; "Expected Component Line No."; Integer) { Caption = 'Очікуваний компонент'; }
        field(51; "Snapshot Available"; Boolean) { Caption = 'Контрольний знімок створено'; }
        field(52; "Reconciliation Status"; Enum "SI Prok Journal Recon Status") { Caption = 'Статус звіряння'; }
        field(53; "Reconciliation Details"; Text[500]) { Caption = 'Діагностика звіряння'; }
        field(54; "Reconciled At"; DateTime) { Caption = 'Перевірено'; }
        field(30; "Prepared At"; DateTime) { Caption = 'Створено'; }
        field(31; "Prepared By"; Code[50]) { Caption = 'Користувач'; }
    }
    keys
    {
        key(PK; "Fact Entry No.", "Link Line No.") { Clustered = true; }
        key(UUID; "Production UUID") { }
    }
}
