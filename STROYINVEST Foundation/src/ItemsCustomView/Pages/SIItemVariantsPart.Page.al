page 50183 "SI Item Variants Part"
{
    PageType = ListPart;
    SourceTable = "Item Variant";
    Caption = 'Item Variants';
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
                field(Code; Rec.Code) { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
            }
        }
    }

    procedure SetItemContext(ItemNo: Code[20])
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Item No.");
        Rec.SetRange(Code);

        if ItemNo <> '' then begin
            Rec.SetRange("Item No.", ItemNo);
            Rec.SetRange(Code, '');
        end else
            Rec.SetRange("Item No.", '');

        Rec.FilterGroup(0);
        CurrPage.Update(false);
    end;

    procedure SetSelectedVariant(ItemNo: Code[20]; VariantCode: Code[10])
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Item No.");
        Rec.SetRange(Code);

        if (ItemNo <> '') and (VariantCode <> '') then begin
            Rec.SetRange("Item No.", ItemNo);
            Rec.SetRange(Code, VariantCode);
        end else begin
            Rec.SetRange("Item No.", '');
            Rec.SetRange(Code, '');
        end;

        Rec.FilterGroup(0);

        if (ItemNo <> '') and (VariantCode <> '') then
            Rec.FindFirst();

        CurrPage.Update(false);
    end;
}
