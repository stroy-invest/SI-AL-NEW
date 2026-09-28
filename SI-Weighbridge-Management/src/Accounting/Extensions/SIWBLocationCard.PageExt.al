pageextension 59151 "SI WB Location Card Ext" extends "Location Card"
{
    layout
    {
        addlast(Content)
        {
            group(SIWBReceiptDefaults)
            {
                Caption = 'Автоваги: прибуткування за замовчуванням';

                field("SI WB Default Receipt"; Rec."SI WB Default Receipt")
                {
                    ApplicationArea = All;
                }

                part(SIWBReceiptLocationRules; "SI WB Receipt Location Rules")
                {
                    ApplicationArea = All;
                    Caption = 'Категорії / товари / варіанти';
                    SubPageLink = "Location Code" = field(Code);
                    UpdatePropagation = Both;
                }
            }
        }
    }
}
