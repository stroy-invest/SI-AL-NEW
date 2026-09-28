page 50181 "SI Group Items Part"
{
    PageType = ListPart;
    SourceTable = Item;
    Caption = 'Items';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(ProviderRecord)
            {
                Visible = false;
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    procedure SetCategoryFilter(ItemCategoryCode: Code[20])
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Item Category Code");
        Rec.SetRange("No.");

        if ItemCategoryCode <> '' then
            Rec.SetRange("Item Category Code", ItemCategoryCode)
        else
            Rec.SetRange("Item Category Code", '');

        Rec.FilterGroup(0);
        CurrPage.Update(false);
    end;

    procedure SetSelectedItem(ItemNo: Code[20])
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("No.");
        if ItemNo <> '' then
            Rec.SetRange("No.", ItemNo)
        else
            Rec.SetRange("No.", '');
        Rec.FilterGroup(0);

        if ItemNo <> '' then
            Rec.FindFirst();

        CurrPage.Update(false);
    end;

    procedure GetCurrentItemNo(): Code[20]
    begin
        exit(Rec."No.");
    end;
}
