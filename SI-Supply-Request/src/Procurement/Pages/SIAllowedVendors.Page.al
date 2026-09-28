page 61022 "SI Allowed Vendors"
{
    PageType = List;
    SourceTable = "SI Vendor Item Category";
    SourceTableTemporary = true;
    Caption = 'Дозволені постачальники';
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
                field("Item Category Code"; Rec."Item Category Code")
                {
                    ApplicationArea = All;
                    Caption = 'Правило категорії';
                    ToolTip = 'Категорія, з якої успадковано дозвіл постачальника.';
                }
            }
        }
    }

    procedure LoadAllowedVendors(ItemCategoryCode: Code[20])
    var
        ItemCategory: Record "Item Category";
        VendorCategory: Record "SI Vendor Item Category";
        CurrentCategoryCode: Code[20];
    begin
        Rec.Reset();
        Rec.DeleteAll();

        CurrentCategoryCode := ItemCategoryCode;
        while CurrentCategoryCode <> '' do begin
            VendorCategory.Reset();
            VendorCategory.SetRange("Item Category Code", CurrentCategoryCode);
            VendorCategory.SetRange(Active, true);
            if VendorCategory.FindSet() then
                repeat
                    Rec.Reset();
                    Rec.SetRange("Vendor No.", VendorCategory."Vendor No.");
                    if Rec.IsEmpty() then begin
                        Rec.Init();
                        Rec.TransferFields(VendorCategory, true);
                        Rec.Insert();
                    end;
                until VendorCategory.Next() = 0;

            if not ItemCategory.Get(CurrentCategoryCode) then
                CurrentCategoryCode := ''
            else
                CurrentCategoryCode := ItemCategory."Parent Category";
        end;
        Rec.Reset();
    end;
}
