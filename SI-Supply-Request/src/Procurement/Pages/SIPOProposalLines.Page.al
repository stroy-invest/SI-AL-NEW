page 61054 "SI PO Proposal Lines"
{
    PageType = ListPart;
    SourceTable = "SI PO Proposal Line";
    Caption = 'Запропоновані позиції';
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
                field(ProductName; ProductName)
                {
                    Caption = 'Товар / матеріал'; ApplicationArea = All; DrillDown = true;
                    trigger OnDrillDown() begin OpenProduct(); end;
                }
                field(Quantity; Rec.Quantity) { Caption = 'Кількість'; ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { Caption = 'Од. вим.'; ApplicationArea = All; }
                field(SupplyCategoryName; SupplyCategoryName) { Caption = 'Категорія постачання'; ApplicationArea = All; }
                field(LocationName; LocationName) { Caption = 'Склад'; ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenOrigin)
            {
                Caption = 'Походження'; ApplicationArea = All; Image = Navigate;
                trigger OnAction()
                var
                    Link: Record "SI PO Proposal Alloc. Link";
                begin
                    Link.SetRange("Proposal Entry No.", Rec."Proposal Entry No.");
                    Link.SetRange("Proposal Line No.", Rec."Line No.");
                    Page.Run(Page::"SI PO Proposal Origins", Link);
                end;
            }
        }
    }

    trigger OnAfterGetRecord() begin LoadDisplayValues(); end;

    local procedure LoadDisplayValues()
    var
        Item: Record Item; Variant: Record "Item Variant"; Location: Record Location;
        Capability: Record "SI Vendor Supply Capability"; Category: Record "Item Category";
    begin
        Clear(ProductName); Clear(LocationName); Clear(SupplyCategoryName);
        if (Rec."Variant Code" <> '') and Variant.Get(Rec."Item No.", Rec."Variant Code") then
            ProductName := Variant.Description
        else if Item.Get(Rec."Item No.") then
            ProductName := Item.Description;
        if ProductName = '' then ProductName := Rec.Description;
        if Location.Get(Rec."Location Code") then LocationName := Location.Name;
        if Capability.Get(Rec."Capability Code") then
            if Category.Get(Capability."Item Category Code") then SupplyCategoryName := Category.Description;
    end;

    local procedure OpenProduct()
    var Item: Record Item; Variant: Record "Item Variant";
    begin
        if Rec."Variant Code" <> '' then begin
            if Variant.Get(Rec."Item No.", Rec."Variant Code") then begin Variant.SetRecFilter(); Page.Run(Page::"Item Variants", Variant); end;
            exit;
        end;
        if Item.Get(Rec."Item No.") then Page.Run(Page::"Item Card", Item);
    end;

    var ProductName: Text[100]; LocationName: Text[100]; SupplyCategoryName: Text[100];
}
