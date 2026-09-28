page 57022 "SI Prok Recipe Snapshots"
{
    PageType = List;
    SourceTable = "SI Prok Recipe Snapshot";
    Caption = 'Recipe Snapshots';
    ApplicationArea = All;
    UsageCategory = None;
    CardPageId = "SI Prok Recipe Snapshot Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Snapshots)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Caption = 'Варіант';
                }
                field(VariantDescription; VariantDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Назва варіанта';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Production BOM No."; Rec."Production BOM No.")
                {
                    ApplicationArea = All;
                }
                field("Derived Formula Code"; Rec."Derived Formula Code")
                {
                    ApplicationArea = All;
                }
                field("Proktek Formula Index"; Rec."Proktek Formula Index")
                {
                    ApplicationArea = All;
                }
                field("Proktek Formula UUID"; Rec."Proktek Formula UUID")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ItemVariant: Record "Item Variant";
    begin
        Clear(VariantDescription);
        if Rec."Variant Code" = '' then
            exit;

        if ItemVariant.Get(Rec."Item No.", Rec."Variant Code") then
            VariantDescription := ItemVariant.Description;
    end;

    var
        VariantDescription: Text[100];
}
