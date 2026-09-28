page 61055 "SI PO Proposal Origins"
{
    PageType = List;
    SourceTable = "SI PO Proposal Alloc. Link";
    Caption = 'Походження позиції';
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
                field(VendorName; VendorName) { Caption = 'Постачальник'; ApplicationArea = All; }
                field(ProductName; ProductName) { Caption = 'Товар / матеріал'; ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { Caption = 'Кількість'; ApplicationArea = All; }
                field("Unit of Measure Code"; UnitOfMeasureCode) { Caption = 'Од. вим.'; ApplicationArea = All; }
                field(RequiredDate; RequiredDate) { Caption = 'Забезпечити до'; ApplicationArea = All; }
                field(ExpectedReceiptDate; ExpectedReceiptDate) { Caption = 'Очікувана поставка'; ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord() begin LoadDisplayValues(); end;

    local procedure LoadDisplayValues()
    var
        Allocation: Record "SI Procurement Allocation"; Snapshot: Record "SI Proc. Plan Snapshot";
        Vendor: Record Vendor; Item: Record Item; Variant: Record "Item Variant";
    begin
        Clear(VendorName); Clear(ProductName); Clear(UnitOfMeasureCode); Clear(RequiredDate); Clear(ExpectedReceiptDate);
        if not Allocation.Get(Rec."Allocation Entry No.") then exit;
        UnitOfMeasureCode := Allocation."Unit of Measure Code";
        RequiredDate := Allocation."Required Date";
        ExpectedReceiptDate := Allocation."Expected Receipt Date";
        if Vendor.Get(Allocation."Vendor No.") then VendorName := Vendor.Name;
        if not Snapshot.Get(Allocation."Planning Run No.", Allocation."Snapshot Line No.") then exit;
        if (Snapshot."Variant Code" <> '') and Variant.Get(Snapshot."Item No.", Snapshot."Variant Code") then
            ProductName := Variant.Description
        else if Item.Get(Snapshot."Item No.") then
            ProductName := Item.Description;
        if ProductName = '' then ProductName := Snapshot.Description;
    end;

    var
        VendorName: Text[100]; ProductName: Text[100]; UnitOfMeasureCode: Code[10]; RequiredDate: Date; ExpectedReceiptDate: Date;
}
