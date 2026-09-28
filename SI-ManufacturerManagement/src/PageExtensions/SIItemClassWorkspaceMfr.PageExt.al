pageextension 55012 "SI Item Class Workspace Mfr." extends "SI Item Class. Workspace"
{
    layout
    {
        addlast(FactBoxes)
        {
            part(ItemApprovedProducts; "SI Approved Mfr. Products FB")
            {
                ApplicationArea = All;
                Caption = 'Схвалені продукти товару';
                Provider = GroupItems;
                SubPageLink = "Item No." = field("No.");
                SubPageView = where("Variant Code" = const(''));
                UpdatePropagation = Both;
            }

            part(VariantApprovedProducts; "SI Approved Mfr. Products FB")
            {
                ApplicationArea = All;
                Caption = 'Схвалені продукти варіанта';
                Provider = ItemVariants;
                SubPageLink =
                    "Item No." = field("Item No."),
                    "Variant Code" = field(Code);
                UpdatePropagation = Both;
            }
        }
    }
}
