table 57091 "SI Prok Production Fact"
{
    Caption = 'Факт виробництва Proktek';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; Caption = '№ запису'; }
        field(10; "Production UUID"; Guid) { Caption = 'Production UUID'; }
        field(20; "Production ID"; BigInteger) { Caption = 'Production ID'; }
        field(30; "Production Date/Time"; DateTime) { Caption = 'Дата/час виробництва'; }
        field(40; "Plant ID"; Integer) { Caption = 'Plant ID'; }
        field(50; "Produced Quantity M3"; Decimal) { Caption = 'Вироблено, м³'; DecimalPlaces = 0 : 5; }
        field(60; "Order ID"; BigInteger) { Caption = 'Proktek Order ID'; }
        field(70; "Order UUID"; Guid) { Caption = 'Proktek Order UUID'; }
        field(80; "Order No."; Text[150]) { Caption = 'Order No.'; }
        field(90; "Prod. Request Entry No."; Integer) { Caption = 'Заявка на виробництво'; TableRelation = "SI Concrete Prod Request"."Entry No."; }
        field(100; "Supply Decision No."; Code[20]) { Caption = 'Рішення забезпечення'; }
        field(110; "Supply Decision Line No."; Integer) { Caption = 'Рядок рішення'; }
        field(120; "Supply Allocation Line No."; Integer) { Caption = 'Розподіл'; }
        field(130; "Project No."; Code[20]) { Caption = 'Проєкт'; TableRelation = Job."No."; }
        field(140; "Item No."; Code[20]) { Caption = 'Товар'; TableRelation = Item."No."; }
        field(150; "Variant Code"; Code[10]) { Caption = 'Варіант'; TableRelation = "Item Variant".Code where("Item No." = field("Item No.")); }
        field(160; "Recipe No."; Code[50]) { Caption = 'Рецептура'; }
        field(170; "Recipe Revision No."; Integer) { Caption = 'Ревізія'; }
        field(180; "Formula UUID"; Guid) { Caption = 'Formula UUID'; }
        field(190; "Formula Code"; Text[150]) { Caption = 'Formula Code'; }
        field(200; "Ordered Quantity M3"; Decimal) { Caption = 'Замовлено, м³'; DecimalPlaces = 0 : 5; }
        field(210; "Order Produced Total M3"; Decimal) { Caption = 'Вироблено по Order, м³'; DecimalPlaces = 0 : 5; }
        field(220; "Order Remaining M3"; Decimal) { Caption = 'Залишок по Order, м³'; DecimalPlaces = 0 : 5; }
        field(230; Status; Enum "SI Prok Prod Fact Status") { Caption = 'Статус'; }
        field(240; "Ready for Posting"; Boolean) { Caption = 'Готово до проведення'; }
        field(250; "Validation Message"; Text[250]) { Caption = 'Результат перевірки'; }
        field(260; "Received At"; DateTime) { Caption = 'Отримано'; Editable = false; }
        field(270; "Received By"; Text[100]) { Caption = 'Отримав'; Editable = false; }
        field(280; "Canonical JSON"; Blob) { Caption = 'Canonical JSON'; SubType = Memo; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ProductionUuid; "Production UUID") { Unique = true; }
        key(OrderUuid; "Order UUID", "Production Date/Time") { }
        key(Allocation; "Supply Decision No.", "Supply Decision Line No.", "Supply Allocation Line No.") { }
    }

    trigger OnInsert()
    begin
        if "Received At" = 0DT then
            "Received At" := CurrentDateTime();
        if "Received By" = '' then
            "Received By" := CopyStr(UserId(), 1, MaxStrLen("Received By"));
    end;

    procedure SetCanonicalJson(Value: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Canonical JSON");
        "Canonical JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Value);
    end;

    procedure GetCanonicalJson(): Text
    var
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        CalcFields("Canonical JSON");
        if not "Canonical JSON".HasValue() then
            exit('');
        "Canonical JSON".CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line;
        end;
        exit(Result);
    end;
}
