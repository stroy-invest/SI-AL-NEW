page 61053 "SI PO Preparation"
{
    PageType = List;
    SourceTable = "SI PO Proposal Header";
    Caption = 'Підготовка замовлень постачальникам';
    ApplicationArea = All;
    UsageCategory = Tasks;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    CardPageId = "SI PO Proposal Card";

    layout
    {
        area(Content)
        {
            repeater(Groups)
            {
                field(VendorName; VendorName) { Caption = 'Постачальник'; ApplicationArea = All; DrillDown = true; trigger OnDrillDown() begin OpenVendor(); end; }
                field("Expected Receipt Date"; Rec."Expected Receipt Date") { Caption = 'Дата поставки'; ApplicationArea = All; }
                field(ShipmentMethodName; ShipmentMethodName) { Caption = 'Спосіб доставки'; ApplicationArea = All; }
                field(LocationName; LocationName) { Caption = 'Склад отримання'; ApplicationArea = All; DrillDown = true; trigger OnDrillDown() begin OpenLocation(); end; }
                field(CurrencyName; CurrencyName) { Caption = 'Валюта'; ApplicationArea = All; }
                field(LineCount; LineCount) { Caption = 'Позицій'; ApplicationArea = All; }
                field(ProposalStatus; Rec.Status) { Caption = 'Статус'; ApplicationArea = All; }
                field(PurchaseOrderDescription; PurchaseOrderDescription)
                {
                    Caption = 'Замовлення'; ApplicationArea = All; DrillDown = true;
                    trigger OnDrillDown() begin OpenPurchaseOrder(); end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Rebuild)
            {
                Caption = 'Сформувати пропозиції'; ApplicationArea = All; Image = Suggest;
                Promoted = true; PromotedCategory = Process;
                trigger OnAction()
                var Mgt: Codeunit "SI PO Proposal Mgt.";
                begin Mgt.RebuildCurrentRun(); LoadCurrentRun(); CurrPage.Update(false); end;
            }
            action(OpenProposal)
            {
                Caption = 'Переглянути пропозицію'; ApplicationArea = All; Image = View;
                Promoted = true; PromotedCategory = Process;
                trigger OnAction() begin Page.Run(Page::"SI PO Proposal Card", Rec); end;
            }
            action(CreatePurchaseOrder)
            {
                Caption = 'Створити замовлення'; ApplicationArea = All; Image = NewOrder;
                Promoted = true; PromotedCategory = Process;
                Enabled = CanCreatePurchaseOrder;
                trigger OnAction()
                var PurchaseOrderMgt: Codeunit "SI Purchase Order Mgt.";
                begin
                    if not Confirm(CreatePOQst, false, VendorName) then exit;
                    PurchaseOrderMgt.CreateFromProposal(Rec);
                    CurrPage.Update(false);
                    Message(POCreatedMsg);
                end;
            }
            action(OpenPurchaseOrderAction)
            {
                Caption = 'Відкрити замовлення'; ApplicationArea = All; Image = ViewOrder;
                Promoted = true; PromotedCategory = Process;
                Enabled = HasPurchaseOrder;
                trigger OnAction() begin OpenPurchaseOrder(); end;
            }
        }
    }

    trigger OnOpenPage() begin LoadCurrentRun(); end;
    trigger OnAfterGetRecord()
    begin
        LoadDisplayValues(); LoadTotals();
        CanCreatePurchaseOrder := (Rec.Status = Rec.Status::Draft) and (Rec."Purchase Order No." = '');
        HasPurchaseOrder := Rec."Purchase Order No." <> '';
        if HasPurchaseOrder then PurchaseOrderDescription := StrSubstNo(PurchaseOrderLbl, Rec."Purchase Order No.") else Clear(PurchaseOrderDescription);
    end;

    local procedure LoadCurrentRun()
    var Run: Record "SI Proc. Plan Run";
    begin
        Run.SetRange(Current, true);
        if not Run.FindLast() then Error(NoPlanErr);
        Rec.SetRange("Planning Run No.", Run."Run No.");
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

    local procedure LoadTotals()
    var Line: Record "SI PO Proposal Line";
    begin
        Clear(LineCount);
        Line.SetRange("Proposal Entry No.", Rec."Entry No.");
        LineCount := Line.Count();
    end;

    local procedure OpenVendor()
    var Vendor: Record Vendor;
    begin if Vendor.Get(Rec."Vendor No.") then Page.Run(Page::"Vendor Card", Vendor); end;
    local procedure OpenLocation()
    var Location: Record Location;
    begin if Location.Get(Rec."Location Code") then Page.Run(Page::"Location Card", Location); end;
    local procedure OpenPurchaseOrder()
    var PurchaseOrderMgt: Codeunit "SI Purchase Order Mgt.";
    begin
        if Rec."Purchase Order No." <> '' then PurchaseOrderMgt.OpenPurchaseOrder(Rec);
    end;

    var
        VendorName: Text[100]; LocationName: Text[100]; ShipmentMethodName: Text[100]; CurrencyName: Text[100]; PurchaseOrderDescription: Text[100];
        LineCount: Integer; CanCreatePurchaseOrder: Boolean; HasPurchaseOrder: Boolean;
        NoPlanErr: Label 'Немає актуального плану закупівель.'; LocalCurrencyLbl: Label 'Локальна валюта';
        PurchaseOrderLbl: Label 'Замовлення %1';
        CreatePOQst: Label 'Створити стандартне замовлення постачальнику для %1?';
        POCreatedMsg: Label 'Замовлення постачальнику створено.';
}
