codeunit 57116 "SI Prok Accounting Prep Mgt."
{
    // PF-02.2A: validate only. Never create Item Journal Line, post or change MES facts.
    procedure CheckFact(var Fact: Record "SI Prok Production Fact"; Mode: Enum "SI Prok Accounting Prep Mode")
    var
        Binding: Codeunit "SI Prok Fact BC Binding Mgt.";
        Order: Record "Production Order";
        ProdLine: Record "Prod. Order Line";
        Material: Record "SI Prok Prod Fact Material";
        Component: Record "Prod. Order Component";
        Item: Record Item;
        ItemUoM: Record "Item Unit of Measure";
        Issues: Text;
        OutputQty: Decimal;
        MaterialCount: Integer;
        ComponentCount: Integer;
    begin
        Fact.Get(Fact."Entry No.");
        // Reconcile standard Firm Planned -> Released transition before checking readiness.
        // BindFact preserves UUID/request/line identity and reports any ambiguity as Blocked.
        Binding.RevalidateBinding(Fact);
        Fact.Get(Fact."Entry No.");

        if IsNullGuid(Fact."Production UUID") then
            AddIssue(Issues, 'Production UUID не визначено.');
        if IsNullGuid(Fact."Order UUID") then
            AddIssue(Issues, 'Proktek Order UUID не визначено.');
        if Fact."Prod. Request Entry No." = 0 then
            AddIssue(Issues, 'Немає зв’язку з виробничою заявкою.');
        if Fact."BC Prod. Order No." = '' then
            AddIssue(Issues, 'Не визначено виробниче замовлення BC.');
        if Fact."BC Prod. Order Line No." = 0 then
            AddIssue(Issues, 'Не визначено рядок виробничого замовлення BC.');

        if Fact."BC Binding Status" <> Fact."BC Binding Status"::Bound then
            AddIssue(Issues, 'BC Binding Status повинен бути Bound.');
        if Fact."Verification Status" <> Fact."Verification Status"::Verified then
            AddIssue(Issues, 'Обсяг випуску не підтверджений.');
        if Fact."Technical Validation" <> Fact."Technical Validation"::Complete then
            AddIssue(Issues, 'Технічна перевірка не Complete.');
        OutputQty := Fact."Produced Quantity M3";
        if OutputQty <= 0 then
            AddIssue(Issues, 'Немає додатної кількості випуску для обраного режиму.');

        if Fact."BC Prod. Order No." <> '' then begin
            if not Order.Get(Fact."BC Prod. Order Status", Fact."BC Prod. Order No.") then
                AddIssue(Issues, 'Виробниче замовлення за збереженим статусом не знайдено.')
            else begin
                if Order.Status <> Order.Status::Released then
                    AddIssue(Issues, 'Для обліку виробниче замовлення має бути Released.');
                if not ProdLine.Get(Order.Status, Order."No.", Fact."BC Prod. Order Line No.") then
                    AddIssue(Issues, 'Рядок виробничого замовлення BC не знайдено.')
                else begin
                    if (ProdLine."Item No." <> Fact."Item No.") or (ProdLine."Variant Code" <> Fact."Variant Code") then
                        AddIssue(Issues, 'Товар/варіант випуску не відповідає виробничому рядку.');
                    if ProdLine."Unit of Measure Code" <> 'M3' then
                        AddIssue(Issues, 'Одиниця випуску не M3: конверсію слід узгодити до PF-02.2B.');
                end;
            end;
        end;

        Material.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if not Material.FindSet() then
            AddIssue(Issues, 'Немає рядків фактичного споживання.')
        else
            repeat
                MaterialCount += 1;
                if not Material."BC Material Resolved" or (Material."Item No." = '') then
                    AddIssue(Issues, StrSubstNo('Матеріал %1: не визначено товар BC.', Material."Line No."));
                if not Material."UoM Normalized" then
                    AddIssue(Issues, StrSubstNo('Матеріал %1: одиницю виміру не нормалізовано.', Material."Line No."));
                if Material."Actual Observed Slot Count" = 0 then
                    AddIssue(Issues, StrSubstNo('Матеріал %1: немає фактичних показників бункерів.', Material."Line No."));
                if Material."Actual Base Qty" < 0 then
                    AddIssue(Issues, StrSubstNo('Матеріал %1: від’ємна фактична кількість.', Material."Line No."));
                if (Material."Item No." <> '') and Item.Get(Material."Item No.") then begin
                    if Material."BC Base UoM" <> Item."Base Unit of Measure" then
                        AddIssue(Issues, StrSubstNo('Матеріал %1: базова ОВ не відповідає Item.', Material."Line No."));
                end else
                    AddIssue(Issues, StrSubstNo('Матеріал %1: товар BC не знайдено.', Material."Line No."));

                if (Order."No." <> '') and (Order.Status = Order.Status::Released) and (Material."Item No." <> '') then begin
                    Component.Reset();
                    Component.SetRange(Status, Order.Status);
                    Component.SetRange("Prod. Order No.", Order."No.");
                    Component.SetRange("Prod. Order Line No.", Fact."BC Prod. Order Line No.");
                    Component.SetRange("Item No.", Material."Item No.");
                    Component.SetRange("Variant Code", Material."Variant Code");
                    ComponentCount := Component.Count();
                    if ComponentCount <> 1 then
                        AddIssue(Issues, StrSubstNo('Матеріал %1: знайдено %2 компонентів BC, потрібен рівно один.', Material."Line No.", ComponentCount))
                    else begin
                        Component.FindFirst();
                        if not ItemUoM.Get(Material."Item No.", Component."Unit of Measure Code") then
                            AddIssue(Issues, StrSubstNo('Матеріал %1: відсутня ОВ компонента BC.', Material."Line No."))
                        else
                            if ItemUoM."Qty. per Unit of Measure" <= 0 then
                                AddIssue(Issues, StrSubstNo('Матеріал %1: некоректний коефіцієнт ОВ.', Material."Line No."));
                    end;
                end;
            until Material.Next() = 0;

        Fact."Accounting Prep Mode" := Fact."Accounting Prep Mode"::Production;
        Fact."Accounting Checked At" := CurrentDateTime();
        Fact."Accounting Output Qty" := OutputQty;
        Fact."Accounting Material Lines" := MaterialCount;
        if Issues = '' then begin
            Fact."Accounting Readiness" := Fact."Accounting Readiness"::Ready;
            Fact."Accounting Diagnostics" := 'Облікові перевірки пройдено. Журнали ще не створено.';
        end else begin
            Fact."Accounting Readiness" := Fact."Accounting Readiness"::Blocked;
            Fact."Accounting Diagnostics" := CopyStr(Issues, 1, MaxStrLen(Fact."Accounting Diagnostics"));
        end;
        Fact.Modify(true);
    end;

    local procedure AddIssue(var Issues: Text; Issue: Text)
    begin
        if Issues <> '' then
            Issues += ' ';
        Issues += Issue;
    end;
}
