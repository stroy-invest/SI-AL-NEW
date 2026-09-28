page 61052 "SI Procurement Supply Plan"
{
    PageType = List;
    SourceTable = "SI Procurement Allocation";
    Caption = 'План постачання';
    ApplicationArea = All;
    Editable = false;
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
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        Vendor: Record Vendor;
                    begin
                        if Vendor.Get(Rec."Vendor No.") then
                            Page.Run(Page::"Vendor Card", Vendor);
                    end;
                }
                field(ProductName; ProductName)
                {
                    Caption = 'Товар / матеріал';
                    ApplicationArea = All;
                    DrillDown = true;
                    trigger OnDrillDown()
                    begin
                        OpenProduct();
                    end;
                }
                field(CapabilityName; CapabilityName)
                {
                    Caption = 'Категорія постачання';
                    ApplicationArea = All;
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
                }
                field("Purchase Quantity"; Rec."Purchase Quantity")
                {
                    Caption = 'Кількість';
                    ApplicationArea = All;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    Caption = 'Од. вим.';
                    ApplicationArea = All;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    Caption = 'Очікувана поставка';
                    ApplicationArea = All;
                }
                field(LocationName; LocationName)
                {
                    Caption = 'Склад';
                    ApplicationArea = All;
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        Location: Record Location;
                    begin
                        if Snapshot.Get(Rec."Planning Run No.", Rec."Snapshot Line No.") then
                            if Location.Get(Snapshot."Location Code") then
                                Page.Run(Page::"Location Card", Location);
                    end;
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Статус';
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenAllocation)
            {
                Caption = 'Відкрити розподіл';
                ApplicationArea = All;
                Image = EditLines;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    Allocation: Record "SI Procurement Allocation";
                begin
                    Allocation.SetRange("Entry No.", Rec."Entry No.");
                    Page.Run(Page::"SI Procurement Allocations", Allocation);
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
    end;

    local procedure LoadDisplayValues()
    var
        Vendor: Record Vendor;
        Capability: Record "SI Vendor Supply Capability";
        ShipmentMethod: Record "Shipment Method";
        ItemCategory: Record "Item Category";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Location: Record Location;
    begin
        Clear(VendorName);
        Clear(ProductName);
        Clear(CapabilityName);
        Clear(ShipmentMethodName);
        Clear(LocationName);
        Clear(Snapshot);

        if Vendor.Get(Rec."Vendor No.") then
            VendorName := Vendor.Name;

        if Capability.Get(Rec."Capability Code") then begin
            if ItemCategory.Get(Capability."Item Category Code") then
                CapabilityName := ItemCategory.Description;
            if (Capability."Shipment Method Code" <> '') and ShipmentMethod.Get(Capability."Shipment Method Code") then
                ShipmentMethodName := ShipmentMethod.Description;
        end;

        if not Snapshot.Get(Rec."Planning Run No.", Rec."Snapshot Line No.") then
            exit;

        if (Snapshot."Variant Code" <> '') and ItemVariant.Get(Snapshot."Item No.", Snapshot."Variant Code") then
            ProductName := ItemVariant.Description
        else
            if Item.Get(Snapshot."Item No.") then
                ProductName := Item.Description;
        if ProductName = '' then
            ProductName := Snapshot.Description;

        if Location.Get(Snapshot."Location Code") then
            LocationName := Location.Name;
    end;

    local procedure OpenProduct()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if not Snapshot.Get(Rec."Planning Run No.", Rec."Snapshot Line No.") then
            exit;

        if Snapshot."Variant Code" <> '' then begin
            if not ItemVariant.Get(Snapshot."Item No.", Snapshot."Variant Code") then
                exit;
            ItemVariant.SetRecFilter();
            Page.Run(Page::"Item Variants", ItemVariant);
            exit;
        end;

        if Item.Get(Snapshot."Item No.") then
            Page.Run(Page::"Item Card", Item);
    end;

    var
        Snapshot: Record "SI Proc. Plan Snapshot";
        VendorName: Text[100];
        ProductName: Text[100];
        CapabilityName: Text[100];
        ShipmentMethodName: Text[100];
        LocationName: Text[100];
}
