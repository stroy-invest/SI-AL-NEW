page 61056 "SI PO Proposal Card"
{
    PageType = Card;
    SourceTable = "SI PO Proposal Header";
    Caption = 'Пропозиція замовлення постачальнику';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Умови постачання';
                field(VendorName; VendorName) { Caption = 'Постачальник'; ApplicationArea = All; }
                field("Expected Receipt Date"; Rec."Expected Receipt Date") { Caption = 'Дата поставки'; ApplicationArea = All; }
                field(ShipmentMethodName; ShipmentMethodName) { Caption = 'Спосіб доставки'; ApplicationArea = All; }
                field(LocationName; LocationName) { Caption = 'Склад отримання'; ApplicationArea = All; }
                field(CurrencyName; CurrencyName) { Caption = 'Валюта'; ApplicationArea = All; }
            }
            group(Document)
            {
                Caption = 'Замовлення постачальнику';
                field(ProposalStatus; Rec.Status) { Caption = 'Статус'; ApplicationArea = All; }
                field(PurchaseOrderDescription; PurchaseOrderDescription)
                {
                    Caption = 'Замовлення'; ApplicationArea = All; DrillDown = true;
                    trigger OnDrillDown() begin OpenPurchaseOrder(); end;
                }
            }
            part(Lines; "SI PO Proposal Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Proposal Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreatePurchaseOrder)
            {
                Caption = 'Створити замовлення постачальнику'; ApplicationArea = All; Image = NewOrder;
                Promoted = true; PromotedCategory = Process;
                Enabled = CanCreatePurchaseOrder;
                trigger OnAction()
                var
                    PurchaseOrderMgt: Codeunit "SI Purchase Order Mgt.";
                begin
                    if not Confirm(CreatePOQst, false, VendorName) then
                        exit;
                    PurchaseOrderMgt.CreateFromProposal(Rec);
                    CurrPage.Update(false);
                    Message(POCreatedMsg);
                end;
            }
            action(OpenPO)
            {
                Caption = 'Відкрити замовлення'; ApplicationArea = All; Image = ViewOrder;
                Promoted = true; PromotedCategory = Process;
                Enabled = HasPurchaseOrder;
                trigger OnAction() begin OpenPurchaseOrder(); end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadDisplayValues();
        CanCreatePurchaseOrder := (Rec.Status = Rec.Status::Draft) and (Rec."Purchase Order No." = '');
        HasPurchaseOrder := Rec."Purchase Order No." <> '';
        if HasPurchaseOrder then
            PurchaseOrderDescription := StrSubstNo(PurchaseOrderLbl, Rec."Purchase Order No.")
        else
            Clear(PurchaseOrderDescription);
    end;

    local procedure LoadDisplayValues()
    var Vendor: Record Vendor; Location: Record Location; ShipmentMethod: Record "Shipment Method"; Currency: Record Currency;
    begin
        Clear(VendorName); Clear(LocationName); Clear(ShipmentMethodName); Clear(CurrencyName);
        if Vendor.Get(Rec."Vendor No.") then VendorName := Vendor.Name;
        if Location.Get(Rec."Location Code") then LocationName := Location.Name;
        if (Rec."Shipment Method Code" <> '') and ShipmentMethod.Get(Rec."Shipment Method Code") then ShipmentMethodName := ShipmentMethod.Description;
        if Rec."Currency Code" = '' then CurrencyName := LocalCurrencyLbl
        else if Currency.Get(Rec."Currency Code") then CurrencyName := Currency.Description;
        if (CurrencyName = '') and (Rec."Currency Code" <> '') then CurrencyName := Rec."Currency Code";
    end;

    local procedure OpenPurchaseOrder()
    var
        PurchaseOrderMgt: Codeunit "SI Purchase Order Mgt.";
    begin
        PurchaseOrderMgt.OpenPurchaseOrder(Rec);
    end;

    var
        VendorName: Text[100]; LocationName: Text[100]; ShipmentMethodName: Text[100]; CurrencyName: Text[100];
        PurchaseOrderDescription: Text[100];
        CanCreatePurchaseOrder: Boolean; HasPurchaseOrder: Boolean;
        LocalCurrencyLbl: Label 'Локальна валюта';
        PurchaseOrderLbl: Label 'Замовлення %1';
        CreatePOQst: Label 'Створити стандартне замовлення постачальнику для %1?';
        POCreatedMsg: Label 'Замовлення постачальнику створено.';
}
