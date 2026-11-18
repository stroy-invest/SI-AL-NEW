page 57144 "SI Prok Shipments"
{
    PageType = List;
    SourceTable = "SI Prok Shipment";
    CardPageId = "SI Prok Shipment Card";
    Caption = 'Документи відвантаження бетону';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(Shipments)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Source Order No."; Rec."Source Order No.") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field("Quantity M3"; Rec."Quantity M3") { ApplicationArea = All; }
                field("Truck Plate"; Rec."Truck Plate") { ApplicationArea = All; }
                field("Driver Name"; Rec."Driver Name") { ApplicationArea = All; }
                field("Shipment Date/Time"; Rec."Shipment Date/Time") { ApplicationArea = All; }
                field("Closed At"; Rec."Closed At") { ApplicationArea = All; Caption = 'Відвантажено (Shipped At)'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteZeroShipmentsSandbox)
            {
                Caption = 'Видалити нульові Shipment (Sandbox)';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Видаляє лише вибрані відкриті Shipment з нульовим обсягом без облікових операцій. Лише Sandbox. Факти виробництва не змінюються.';

                trigger OnAction()
                var
                    SelectedShipment: Record "SI Prok Shipment";
                    Shipment: Record "SI Prok Shipment";
                    EnvironmentInfo: Codeunit "Environment Information";
                    SelectedNos: List of [Integer];
                    ShipmentNo: Integer;
                    DeletedCount: Integer;
                begin
                    if not EnvironmentInfo.IsSandbox() then
                        Error('Видалення нульових Shipment дозволено лише в Sandbox.');

                    CurrPage.SetSelectionFilter(SelectedShipment);
                    if SelectedShipment.IsEmpty() then
                        Error('Виберіть документи для видалення.');

                    // Validate the entire selection before confirmation.
                    if SelectedShipment.FindSet() then
                        repeat
                            AssertZeroShipmentCanBeDeleted(SelectedShipment);
                            SelectedNos.Add(SelectedShipment."Entry No.");
                        until SelectedShipment.Next() = 0;

                    if not Confirm(
                        'Видалити %1 вибраних нульових Shipment у Sandbox? Факти виробництва залишаться без змін.',
                        false, SelectedNos.Count()) then
                        exit;

                    // Revalidate under a lock. Any error rolls back all deletions.
                    Shipment.LockTable();
                    foreach ShipmentNo in SelectedNos do begin
                        if not Shipment.Get(ShipmentNo) then
                            Error('Shipment №%1 уже відсутній. Операцію скасовано.', ShipmentNo);
                        AssertZeroShipmentCanBeDeleted(Shipment);
                        Shipment.Delete(true);
                        DeletedCount += 1;
                    end;

                    CurrPage.Update(false);
                    Message('Видалено нульових Shipment: %1. Факти виробництва не змінено.', DeletedCount);
                end;
            }
            action(RefreshOpenQuantities)
            {
                Caption = 'Оновити обсяги з фактів';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Оновити кількість відкритих документів за підтвердженими фактами виробництва. Закриті документи не змінюються.';
                trigger OnAction()
                var
                    SelectedShipment: Record "SI Prok Shipment";
                    ShipmentMgt: Codeunit "SI Prok Shipment Mgt.";
                    Updated: Integer;
                    Unchanged: Integer;
                begin
                    CurrPage.SetSelectionFilter(SelectedShipment);
                    if not Confirm('Оновити кількість для вибраних/відфільтрованих Shipment (%1 документів)? Закриті документи не змінюються.',
                        false, SelectedShipment.Count()) then
                        exit;
                    if SelectedShipment.FindSet() then
                        repeat
                            if ShipmentMgt.TryRefreshOpenQuantityFromFact(SelectedShipment."Entry No.") then
                                Updated += 1
                            else
                                Unchanged += 1;
                        until SelectedShipment.Next() = 0;
                    CurrPage.Update(false);
                    Message('Оновлено обсягів: %1; без змін або не підтверджено: %2.', Updated, Unchanged);
                end;
            }
        }
    }

    local procedure AssertZeroShipmentCanBeDeleted(Shipment: Record "SI Prok Shipment")
    var
        Attempt: Record "SI Prok Posting Attempt";
        JournalLink: Record "SI Prok Journal Link";
        Fact: Record "SI Prok Production Fact";
    begin
        if Shipment.Status <> Shipment.Status::Open then
            Error('Shipment №%1 не відкритий. Видалення заборонено.', Shipment."Entry No.");
        if Shipment."Quantity M3" <> 0 then
            Error('Shipment №%1 має ненульовий обсяг. Видалення заборонено.', Shipment."Entry No.");
        if Shipment."Closed At" <> 0DT then
            Error('Shipment №%1 має зафіксоване відвантаження. Видалення заборонено.', Shipment."Entry No.");

        if Attempt.Get(Shipment."Production UUID") then
            Error('Для Shipment №%1 існує спроба проведення. Видалення заборонено.', Shipment."Entry No.");

        JournalLink.SetRange("Production UUID", Shipment."Production UUID");
        if not JournalLink.IsEmpty() then
            Error('Для Shipment №%1 існують зв’язки з журналами. Видалення заборонено.', Shipment."Entry No.");

        Fact.SetRange("Production UUID", Shipment."Production UUID");
        if Fact.FindFirst() then
            if Fact."Accounting Document No." <> '' then
                Error('Для Shipment №%1 вже підготовлено обліковий документ. Видалення заборонено.', Shipment."Entry No.");
    end;
}
