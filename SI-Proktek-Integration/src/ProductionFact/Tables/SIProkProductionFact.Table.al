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
        field(300; "Formula ERP Code"; Text[150]) { Caption = 'ERP Code рецептури Proktek'; Editable = false; }
        field(301; "Production BOM No."; Code[20]) { Caption = 'Виробнича специфікація'; Editable = false; }
        field(302; "Production BOM Version Code"; Code[20]) { Caption = 'Версія виробничої специфікації'; Editable = false; }
        field(303; "Formula ID"; BigInteger) { Caption = 'Formula ID Proktek'; Editable = false; }
        field(304; "Formula Name"; Text[150]) { Caption = 'Назва формули Proktek'; Editable = false; }
        field(305; "Recipe Resolution Note"; Text[250]) { Caption = 'Визначення рецептури'; Editable = false; }
        field(200; "Ordered Quantity M3"; Decimal) { Caption = 'Замовлено, м³'; DecimalPlaces = 0 : 5; }
        field(210; "Order Produced Total M3"; Decimal) { Caption = 'Вироблено по Order, м³'; DecimalPlaces = 0 : 5; }
        field(220; "Order Remaining M3"; Decimal) { Caption = 'Залишок по Order, м³'; DecimalPlaces = 0 : 5; }
        field(230; Status; Enum "SI Prok Prod Fact Status") { Caption = 'Статус'; }
        field(240; "Ready for Posting"; Boolean)
        {
            Caption = 'Готово до проведення';
            trigger OnValidate()
            begin
                AssertTestFactNotPostingReady();
            end;
        }
        field(250; "Validation Message"; Text[250]) { Caption = 'Результат перевірки'; }
        field(260; "Received At"; DateTime) { Caption = 'Отримано'; Editable = false; }
        field(270; "Received By"; Text[100]) { Caption = 'Отримав'; Editable = false; }
        field(281; "Simulation"; Boolean) { Caption = 'Симуляція'; Editable = false; }
        field(282; "Truck UUID"; Text[50]) { Caption = 'UUID автоміксера'; Editable = false; }
        field(283; "Truck Code"; Text[100]) { Caption = 'Код автоміксера'; Editable = false; }
        field(284; "Truck Plate"; Text[50]) { Caption = 'Номер автоміксера'; Editable = false; }
        field(291; "Connection Code"; Code[50])
        {
            Caption = 'Підключення Proktek';
            TableRelation = "SI Prok Connection".Code;
            Editable = false;
        }
        field(290; "Capture Mode"; Enum "SI Prok Capture Mode") { Caption = 'Режим приймання'; Editable = false; }
        field(292; "Reported Quantity M3"; Decimal) { Caption = 'Заявлено MES, м³'; DecimalPlaces = 0 : 5; Editable = false; }
        field(293; "Verification Status"; Enum "SI Prok Fact Verification") { Caption = 'Достовірність обсягу'; Editable = false; }
        field(294; "Verification Message"; Text[2048]) { Caption = 'Діагностика достовірності'; Editable = false; }
        field(295; "Execution Evidence"; Enum "SI Prok Execution Evidence") { Caption = 'Ознаки виконання'; Editable = false; }
        field(296; "Reported Quantity Present"; Boolean) { Caption = 'Обсяг MES передано'; Editable = false; }
        field(310; "Technical Validation"; Enum "SI Prok Technical Validation") { Caption = 'Технічна повнота'; Editable = false; }
        field(311; "Technical Diagnostics"; Text[2048]) { Caption = 'Діагностика технічної перевірки'; Editable = false; }
        // PF-02.1: local-only binding; not a posting state.
        field(320; "BC Prod. Order Status"; Enum "Production Order Status") { Caption = 'Статус замовлення BC'; Editable = false; }
        field(321; "BC Prod. Order No."; Code[20]) { Caption = 'Виробниче замовлення BC'; Editable = false; }
        field(322; "BC Prod. Order Line No."; Integer) { Caption = 'Рядок замовлення BC'; Editable = false; }
        field(323; "BC Binding Status"; Enum "SI Prok BC Binding Status") { Caption = 'Статус зв’язування BC'; Editable = false; }
        field(324; "BC Binding Diagnostics"; Text[2048]) { Caption = 'Діагностика зв’язування BC'; Editable = false; }
        field(325; "BC Bound At"; DateTime) { Caption = 'Час зв’язування BC'; Editable = false; }
        // PF-02.2A: accounting readiness is independent of BC binding and never posts.
        field(330; "Accounting Readiness"; Enum "SI Prok Accounting Readiness") { Caption = 'Готовність до обліку'; Editable = false; }
        field(331; "Accounting Prep Mode"; Enum "SI Prok Accounting Prep Mode") { Caption = 'Режим облікової перевірки'; Editable = false; }
        field(332; "Accounting Diagnostics"; Text[2048]) { Caption = 'Діагностика облікової перевірки'; Editable = false; }
        field(333; "Accounting Checked At"; DateTime) { Caption = 'Час облікової перевірки'; Editable = false; }
        field(334; "Accounting Output Qty"; Decimal) { Caption = 'Підготовлений обсяг, м³'; DecimalPlaces = 0 : 5; Editable = false; }
        field(335; "Accounting Material Lines"; Integer) { Caption = 'Перевірено матеріалів'; Editable = false; }
        // TC-01: test fixture only. Real plan must come from a verified MES batch source.
        field(336; "Planned Quantity M3"; Decimal) { Caption = 'План партії, м³'; DecimalPlaces = 0 : 5; Editable = false; }
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
        AssertTestFactNotPostingReady();
        if "Received At" = 0DT then
            "Received At" := CurrentDateTime();
        if "Received By" = '' then
            "Received By" := CopyStr(UserId(), 1, MaxStrLen("Received By"));
    end;

    trigger OnModify()
    begin
        AssertTestFactNotPostingReady();
        if (xRec."Connection Code" <> '') and ("Connection Code" <> xRec."Connection Code") then
            Error('Підключення Proktek для збереженого факту змінювати заборонено.');
        if "Capture Mode" <> xRec."Capture Mode" then
            Error('Режим приймання збереженого факту змінювати заборонено.');
    end;

    procedure AssertAllowedForPosting()
    begin
        if "Verification Status" <> "Verification Status"::Verified then
            Error('Обсяг виробничого факту не підтверджено.');
        if not "Ready for Posting" then
            Error('Факт виробництва %1 не готовий до проведення.', "Production UUID");
    end;

    local procedure AssertTestFactNotPostingReady()
    begin
        if "Ready for Posting" and ("Verification Status" <> "Verification Status"::Verified) then
            Error('Непідтверджений факт не може бути готовим до проведення.');
    end;

    procedure GetProducedQuantityText(): Text
    begin
        if "Verification Status" = "Verification Status"::NotAssessed then
            exit('Перевірку не виконано');
        if "Verification Status" <> "Verification Status"::Verified then
            exit('Не підтверджено');
        exit(Format("Produced Quantity M3"));
    end;

    procedure GetReportedPresenceText(): Text
    begin
        if "Verification Status" = "Verification Status"::NotAssessed then
            exit('Не оцінено (історія)');
        exit(Format("Reported Quantity Present"));
    end;

    procedure GetReportedQuantityText(): Text
    var
        Quantity: Decimal;
    begin
        if TryReadReportedQuantity(Quantity) then
            exit(Format(Quantity));
        exit('Невідомо');
    end;

    procedure TryReadReportedQuantity(var Quantity: Decimal): Boolean
    var
        Root: JsonObject;
        Compare: Codeunit "SI Prok Fact Content Compare";
    begin
        Clear(Quantity);
        if "Verification Status" <> "Verification Status"::NotAssessed then begin
            Quantity := "Reported Quantity M3";
            exit("Reported Quantity Present");
        end;
        // Read historical canonical without persisting inferred values.
        if Root.ReadFrom(GetCanonicalJson()) then
            exit(Compare.ReadDecimal(Root, 'quantityM3', Quantity));
        exit(false);
    end;

    procedure GetConfirmedOrderTotal(): Decimal
    var
        OtherFact: Record "SI Prok Production Fact";
        Total: Decimal;
    begin
        if IsNullGuid("Order UUID") or ("Connection Code" = '') then
            exit(0);
        OtherFact.SetRange("Order UUID", "Order UUID");
        OtherFact.SetRange("Connection Code", "Connection Code");
        OtherFact.SetRange("Verification Status", OtherFact."Verification Status"::Verified);
        if OtherFact.FindSet() then
            repeat
                Total += OtherFact."Produced Quantity M3";
            until OtherFact.Next() = 0;
        exit(Total);
    end;

    procedure GetOrderTotalText(): Text
    begin
        if Simulation then
            exit(Format("Order Produced Total M3") + ' (симуляція)');
        if IsNullGuid("Order UUID") or ("Connection Code" = '') then
            exit('Невідомо');
        exit(Format(GetConfirmedOrderTotal()));
    end;

    procedure GetOrderRemainingText(): Text
    var
        Remaining: Decimal;
    begin
        if Simulation then
            exit(Format("Order Remaining M3") + ' (симуляція)');
        if ("Ordered Quantity M3" <= 0) or IsNullGuid("Order UUID") or ("Connection Code" = '') then
            exit('Невідомо');
        Remaining := "Ordered Quantity M3" - GetConfirmedOrderTotal();
        if Remaining < 0 then
            Remaining := 0;
        exit(Format(Remaining));
    end;

    procedure GetReportedOrderTotalText(): Text
    var
        OtherFact: Record "SI Prok Production Fact";
        Quantity: Decimal;
        Total: Decimal;
        Missing: Boolean;
    begin
        if IsNullGuid("Order UUID") or ("Connection Code" = '') then
            exit('Невідомо');
        OtherFact.SetRange("Order UUID", "Order UUID");
        OtherFact.SetRange("Connection Code", "Connection Code");
        OtherFact.SetRange("Capture Mode", "Capture Mode");
        OtherFact.SetRange(Simulation, Simulation);
        if OtherFact.FindSet() then
            repeat
                if OtherFact.TryReadReportedQuantity(Quantity) then
                    Total += Quantity
                else
                    Missing := true;
            until OtherFact.Next() = 0;
        if Missing then
            exit(Format(Total) + ' (дані неповні)');
        exit(Format(Total));
    end;

    procedure GetReportedOrderSummaryText(): Text
    begin
        // The historical truck simulation stores the simulated order total
        // in Order Produced Total M3; individual MES readings are per batch.
        if Simulation then
            exit(Format("Order Produced Total M3") + ' (симуляція)');
        exit(GetReportedOrderTotalText());
    end;

    procedure GetOrderDeviationText(): Text
    var
        Total: Decimal;
        Difference: Decimal;
        OtherFact: Record "SI Prok Production Fact";
    begin
        if "Ordered Quantity M3" <= 0 then
            exit('Невідомо');
        if Simulation then
            Total := "Order Produced Total M3"
        else begin
            if IsNullGuid("Order UUID") or ("Connection Code" = '') then
                exit('Невідомо');
            OtherFact.SetRange("Order UUID", "Order UUID");
            OtherFact.SetRange("Connection Code", "Connection Code");
                    OtherFact.SetRange("Verification Status", OtherFact."Verification Status"::Verified);
            if OtherFact.IsEmpty() then
                exit('Невідомо');
            Total := GetConfirmedOrderTotal();
        end;
        Difference := Total - "Ordered Quantity M3";
        if Difference > 0 then
            exit('+' + Format(Difference) + GetSimulationSuffix());
        exit(Format(Difference) + GetSimulationSuffix());
    end;

    local procedure GetSimulationSuffix(): Text
    begin
        if Simulation then
            exit(' (симуляція)');
        exit('');
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
