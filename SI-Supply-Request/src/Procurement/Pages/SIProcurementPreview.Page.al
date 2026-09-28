page 61021 "SI Procurement Preview"
{
    PageType = List;
    SourceTable = "SI Procurement Line";
    SourceTableView = sorting("Batch No.", "Vendor No.", "Item No.");
    Caption = 'Підготовка закупівлі';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Vendor Name"; Rec."Vendor Name") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Item Category Code"; Rec."Item Category Code") { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RemoveLine)
            {
                ApplicationArea = All;
                Caption = 'Видалити з підготовки';
                Image = Delete;
                trigger OnAction()
                begin
                    Rec.Delete(true);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
