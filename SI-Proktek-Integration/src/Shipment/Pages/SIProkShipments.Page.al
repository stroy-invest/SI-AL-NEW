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
}
