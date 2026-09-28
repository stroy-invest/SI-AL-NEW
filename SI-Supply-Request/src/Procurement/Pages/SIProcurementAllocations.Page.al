page 61051 "SI Procurement Allocations"
{
    PageType = List;
    SourceTable = "SI Procurement Allocation";
    Caption = 'Розподіл постачання';
    ApplicationArea = All;
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(VendorName; VendorName)
                {
                    Caption = 'Постачальник';
                    ApplicationArea = All;
                    Editable = false;
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        Vendor: Record Vendor;
                    begin
                        if Vendor.Get(Rec."Vendor No.") then
                            Page.Run(Page::"Vendor Card", Vendor);
                    end;
                }
                field(CapabilityName; CapabilityName)
                {
                    Caption = 'Категорія постачання';
                    ApplicationArea = All;
                    Editable = false;
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        Capability: Record "SI Vendor Supply Capability";
                    begin
                        if Capability.Get(Rec."Capability Code") then
                            Page.Run(Page::"SI Vendor Supply Cap. Card", Capability);
                    end;
                }
                field(ShipmentMethodName; ShipmentMethodName)
                {
                    Caption = 'Спосіб доставки';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Purchase Quantity"; Rec."Purchase Quantity")
                {
                    Caption = 'Кількість';
                    ApplicationArea = All;
                    Editable = IsDraft;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    Caption = 'Од. вим.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    Caption = 'Очікувана поставка';
                    ApplicationArea = All;
                    Editable = IsDraft;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ChangeSupply)
            {
                Caption = 'Змінити постачання';
                ApplicationArea = All;
                Image = Vendor;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = IsDraft;
                trigger OnAction()
                begin
                    ChangeSupplyForCurrentAllocation();
                    CurrPage.Update(false);
                end;
            }
            action(ConfirmAllocation)
            {
                Caption = 'Підтвердити розподіл';
                ApplicationArea = All;
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = IsDraft;
                trigger OnAction()
                var
                    AllocationMgt: Codeunit "SI Proc. Allocation Mgt.";
                begin
                    AllocationMgt.ConfirmAllocation(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CancelAllocation)
            {
                Caption = 'Скасувати розподіл';
                ApplicationArea = All;
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = CanCancel;
                trigger OnAction()
                var
                    AllocationMgt: Codeunit "SI Proc. Allocation Mgt.";
                begin
                    AllocationMgt.CancelAllocation(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadDisplayValues();
        SetState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetState();
    end;

    local procedure ChangeSupplyForCurrentAllocation()
    var
        Snapshot: Record "SI Proc. Plan Snapshot";
        Candidate: Record "SI VSC Candidate" temporary;
        SelectedCandidate: Record "SI VSC Candidate" temporary;
        Resolver: Codeunit "SI VSC Resolver";
        AllocationMgt: Codeunit "SI Proc. Allocation Mgt.";
        CandidatePage: Page "SI VSC Resolver Results";
        QtyToSource: Decimal;
    begin
        Rec.TestField(Status, Rec.Status::Draft);
        Snapshot.Get(Rec."Planning Run No.", Rec."Snapshot Line No.");

        QtyToSource := Snapshot.Quantity - AllocationMgt.GetAllocatedQuantityExcept(
            Rec."Planning Run No.", Rec."Snapshot Line No.", Rec."Entry No.");
        if QtyToSource <= 0 then
            QtyToSource := Rec."Purchase Quantity";

        Resolver.Resolve(Snapshot."Item No.", Snapshot."Variant Code", QtyToSource,
            Snapshot."Unit of Measure Code", Snapshot."Due Date", '', Candidate);
        if Candidate.IsEmpty() then
            Error(NoCandidatesErr, ProductNameFromSnapshot(Snapshot));

        CandidatePage.LoadCandidates(Candidate);
        CandidatePage.LookupMode(true);
        if CandidatePage.RunModal() <> Action::LookupOK then
            exit;
        if not CandidatePage.GetSelectedCandidate(SelectedCandidate) then
            exit;

        AllocationMgt.ChangeCandidate(Rec, SelectedCandidate, SelectedCandidate."Suggested Purchase Quantity");
    end;

    local procedure ProductNameFromSnapshot(Snapshot: Record "SI Proc. Plan Snapshot"): Text[100]
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if (Snapshot."Variant Code" <> '') and ItemVariant.Get(Snapshot."Item No.", Snapshot."Variant Code") then
            exit(ItemVariant.Description);
        if Item.Get(Snapshot."Item No.") then
            exit(Item.Description);
        exit(Snapshot.Description);
    end;

    local procedure LoadDisplayValues()
    var
        Vendor: Record Vendor;
        Capability: Record "SI Vendor Supply Capability";
        ShipmentMethod: Record "Shipment Method";
        ItemCategory: Record "Item Category";
    begin
        Clear(VendorName);
        Clear(CapabilityName);
        Clear(ShipmentMethodName);

        if Vendor.Get(Rec."Vendor No.") then
            VendorName := Vendor.Name;

        if Capability.Get(Rec."Capability Code") then begin
            if ItemCategory.Get(Capability."Item Category Code") then
                CapabilityName := ItemCategory.Description;
            if (Capability."Shipment Method Code" <> '') and ShipmentMethod.Get(Capability."Shipment Method Code") then
                ShipmentMethodName := ShipmentMethod.Description;
        end;
    end;

    local procedure SetState()
    begin
        IsDraft := Rec.Status = Rec.Status::Draft;
        CanCancel := Rec.Status <> Rec.Status::Cancelled;
    end;

    var
        VendorName: Text[100];
        CapabilityName: Text[100];
        ShipmentMethodName: Text[100];
        IsDraft: Boolean;
        CanCancel: Boolean;
        NoCandidatesErr: Label 'Для «%1» не знайдено доступних умов постачання.';
}
