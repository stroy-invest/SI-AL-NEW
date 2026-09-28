page 61048 "SI Proc. Plan Snapshot"
{
    PageType = List;
    SourceTable = "SI Proc. Plan Snapshot";
    Caption = 'Знімок плану закупівель';
    ApplicationArea = All;
    UsageCategory = Tasks;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(ProductName; ProductName)
                {
                    ApplicationArea = All;
                    Caption = 'Товар / матеріал';
                    DrillDown = true;
                    trigger OnDrillDown()
                    begin
                        OpenProduct();
                    end;
                }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; Caption = 'Треба закупити'; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; Caption = 'Од. вим.'; }
                field("Due Date"; Rec."Due Date") { ApplicationArea = All; Caption = 'Забезпечити до'; }
                field(LocationName; LocationName)
                {
                    ApplicationArea = All;
                    Caption = 'Склад';
                    DrillDown = true;
                    trigger OnDrillDown()
                    begin
                        OpenLocation();
                    end;
                }
                field("Order Date"; Rec."Order Date") { ApplicationArea = All; Caption = 'Замовити не пізніше'; }
                field("Action Message"; Rec."Action Message") { ApplicationArea = All; Caption = 'Рекомендація BC'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenDemandLinks)
            {
                Caption = 'Походження потреби';
                ApplicationArea = All;
                Image = Navigate;
                trigger OnAction()
                var
                    Link: Record "SI Proc. Plan Demand Link";
                begin
                    Link.SetRange("Run No.", Rec."Run No.");
                    Link.SetRange("Snapshot Line No.", Rec."Line No.");
                    Page.Run(Page::"SI Proc. Plan Demand Links", Link);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Location: Record Location;
    begin
        Clear(ProductName);
        Clear(LocationName);
        if (Rec."Variant Code" <> '') and ItemVariant.Get(Rec."Item No.", Rec."Variant Code") then
            ProductName := ItemVariant.Description
        else
            if Item.Get(Rec."Item No.") then
                ProductName := Item.Description;
        if ProductName = '' then
            ProductName := Rec.Description;
        if Location.Get(Rec."Location Code") then
            LocationName := Location.Name;
    end;

    local procedure OpenProduct()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if Rec."Variant Code" <> '' then begin
            if not ItemVariant.Get(Rec."Item No.", Rec."Variant Code") then
                exit;
            ItemVariant.SetRecFilter();
            Page.Run(Page::"Item Variants", ItemVariant);
            exit;
        end;
        if Item.Get(Rec."Item No.") then
            Page.Run(Page::"Item Card", Item);
    end;

    local procedure OpenLocation()
    var
        Location: Record Location;
    begin
        if Location.Get(Rec."Location Code") then
            Page.Run(Page::"Location Card", Location);
    end;

    var
        ProductName: Text[100];
        LocationName: Text[100];
}
