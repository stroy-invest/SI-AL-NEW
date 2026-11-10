codeunit 57102 "SI Prok BC Prod Order Mgt."
{
    // PF-01.4: standard firm-planned production order from the immutable SI snapshot.
    // Never calls Proktek, never posts consumption/output, never recalculates BOM.
    procedure EnsureOrder(ProdRequest: Record "SI Concrete Prod Request")
    var
        Plan: Record "SI Prok Production Plan";
        PlanLine: Record "SI Prok Production Plan Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Component: Record "Prod. Order Component";
        Item: Record Item;
        ExistingOrder: Record "Production Order";
        ExistingLine: Record "Prod. Order Line";
        OrderDate: Date;
        CompCount: Integer;
    begin
        ProdRequest.TestField("Entry No.");
        if ProdRequest."Proktek Order ID" = 0 then
            Error('BC Production Order можна створити лише після підтвердження Order у Proktek. Заявка %1.', ProdRequest."Entry No.");
        if not Plan.Get(ProdRequest."Entry No.") then
            Error('Немає нормативного Production Plan для заявки %1.', ProdRequest."Entry No.");

        Plan.LockTable();
        Plan.Get(ProdRequest."Entry No.");
        if Plan."BC Prod. Order No." <> '' then begin
            if not ExistingOrder.Get(Plan."BC Prod. Order Status", Plan."BC Prod. Order No.") then
                Error('Заявка %1 уже пов''язана з BC Production Order %2 (%3), але документ не знайдено. Потрібна ручна перевірка.',
                    ProdRequest."Entry No.", Plan."BC Prod. Order No.", Plan."BC Prod. Order Status");
            ExistingLine.SetRange(Status, Plan."BC Prod. Order Status");
            ExistingLine.SetRange("Prod. Order No.", Plan."BC Prod. Order No.");
            if not ExistingLine.FindFirst() then
                Error('BC Production Order %1 існує, але не має рядка. Автоматичне відновлення заборонено.', Plan."BC Prod. Order No.");
            exit;
        end;

        Plan.TestField("Item No.");
        Plan.TestField("Unit of Measure Code");
        Plan.TestField("Production BOM No.");
        Plan.TestField("Production BOM Version Code");
        if Plan."Planned Quantity" <= 0 then
            Error('Некоректна кількість нормативного плану заявки %1.', ProdRequest."Entry No.");
        Item.Get(Plan."Item No.");
        Item.TestField("Replenishment System", Item."Replenishment System"::"Prod. Order");
        ProdRequest.TestField("Required Date/Time");
        OrderDate := DT2Date(ProdRequest."Required Date/Time");

        // Standard BC header numbering via Manufacturing Setup / No. Series.
        ProdOrder.Init();
        ProdOrder.Validate(Status, ProdOrder.Status::"Firm Planned");
        ProdOrder.Validate("Due Date", OrderDate);
        ProdOrder.Insert(true);
        ProdOrder.Validate("Source Type", ProdOrder."Source Type"::Item);
        ProdOrder.Validate("Source No.", Plan."Item No.");
        ProdOrder.Validate("Variant Code", Plan."Variant Code");
        ProdOrder.Validate(Quantity, Plan."Planned Quantity");
        if ProdRequest."Source Location Code" <> '' then
            ProdOrder.Validate("Location Code", ProdRequest."Source Location Code");
        ProdOrder.Modify(true);

        // Standard production-order line, with the exact BOM revision from the snapshot.
        ProdOrderLine.Init();
        ProdOrderLine.Status := ProdOrder.Status;
        ProdOrderLine."Prod. Order No." := ProdOrder."No.";
        ProdOrderLine."Line No." := 10000;
        ProdOrderLine.Validate("Item No.", Plan."Item No.");
        ProdOrderLine.Validate("Variant Code", Plan."Variant Code");
        ProdOrderLine.Validate("Location Code", ProdOrder."Location Code");
        ProdOrderLine.Validate("Unit of Measure Code", Plan."Unit of Measure Code");
        ProdOrderLine.Validate(Quantity, Plan."Planned Quantity");
        ProdOrderLine.Validate("Production BOM No.", Plan."Production BOM No.");
        ProdOrderLine.Validate("Production BOM Version Code", Plan."Production BOM Version Code");
        ProdOrderLine.Validate("Due Date", OrderDate);
        ProdOrderLine.Insert(true);

        // Components copied from immutable SI plan; no standard BOM re-explosion.
        PlanLine.SetRange("Prod. Request Entry No.", Plan."Prod. Request Entry No.");
        if not PlanLine.FindSet() then
            Error('Production Plan заявки %1 не має матеріалів.', ProdRequest."Entry No.");
        repeat
            PlanLine.TestField("Item No.");
            PlanLine.TestField("Unit of Measure Code");
            if PlanLine."Planned Quantity" <= 0 then
                Error('Матеріал %1 має недодатну планову кількість.', PlanLine."Item No.");
            Component.Init();
            Component.Status := ProdOrder.Status;
            Component."Prod. Order No." := ProdOrder."No.";
            Component."Prod. Order Line No." := ProdOrderLine."Line No.";
            Component."Line No." := PlanLine."Line No.";
            Component.Validate("Item No.", PlanLine."Item No.");
            Component.Validate("Variant Code", PlanLine."Variant Code");
            Component.Validate("Unit of Measure Code", PlanLine."Unit of Measure Code");
            Component.Validate("Location Code", ProdOrder."Location Code");
            Component.Validate("Quantity per", PlanLine."Planned Quantity" / Plan."Planned Quantity");
            Component.Validate("Expected Quantity", PlanLine."Planned Quantity");
            Component.Validate("Due Date", OrderDate);
            Component.Insert(true);
            CompCount += 1;
        until PlanLine.Next() = 0;
        if CompCount = 0 then
            Error('Виробниче замовлення BC не має компонентів.');

        Plan."BC Prod. Order Status" := ProdOrder.Status;
        Plan."BC Prod. Order No." := ProdOrder."No.";
        Plan.Modify(false);
    end;
}
