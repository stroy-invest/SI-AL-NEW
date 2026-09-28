page 61019 "SI Vendor Item Categories"
{
    PageType = List;
    SourceTable = "SI Vendor Item Category";
    Caption = 'Постачальники за категоріями';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Item Category Code"; Rec."Item Category Code")
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemCategory: Record "Item Category";
                        CategoryTree: Page "SI Item Category Tree";
                    begin
                        CategoryTree.LookupMode(true);
                        if CategoryTree.RunModal() <> Action::LookupOK then
                            exit(true);
                        CategoryTree.GetRecord(ItemCategory);
                        Rec.Validate("Item Category Code", ItemCategory.Code);
                        CurrPage.SaveRecord();
                        Text := ItemCategory.Code;
                        CurrPage.Update(false);
                        exit(true);
                    end;
                }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Vendor Name"; Rec."Vendor Name") { ApplicationArea = All; }
                field(Active; Rec.Active) { ApplicationArea = All; }
            }
        }
    }
}
