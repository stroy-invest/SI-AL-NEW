pageextension 53090 "SI Item Hierarchy V2 Sem." extends "SI Item Hierarchy V2"
{
    layout
    {
        addlast(FactBoxes)
        {
            part(ItemParameters; "SI Semantic Parameters Part")
            {
                ApplicationArea = All;
                Caption = 'Параметри товару';
                Provider = GroupItems;
                SubPageLink = "Configuration No." = field("SI Configuration No.");
                SubPageView = where("SI ERP Projection Role" = filter(<> "Variant Identity"));
                UpdatePropagation = Both;
            }

            part(VariantParameters; "SI Semantic Parameters Part")
            {
                ApplicationArea = All;
                Caption = 'Параметри варіанта';
                Provider = ItemVariants;
                SubPageLink = "Configuration No." = field("SI Configuration No.");
                SubPageView = where("SI ERP Projection Role" = filter(<> "Item Identity"));
                UpdatePropagation = Both;
            }
        }
    }
}
