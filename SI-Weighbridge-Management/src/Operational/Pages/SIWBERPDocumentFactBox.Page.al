page 59104 "SI WB ERP Document FactBox"
{
    PageType = CardPart;
    SourceTable = "SI Weighbridge Document";

    Caption = 'Документ BC';

    layout
    {
        area(Content)
        {
            field("ERP Document Type"; Rec."ERP Document Type")
            {
                ApplicationArea = All;
                Caption = 'Тип документа BC';
                Editable = false;
            }

            field("ERP Document No."; Rec."ERP Document No.")
            {
                ApplicationArea = All;
                Caption = '№ документа BC';
                Editable = false;
            }
        }
    }
}