pageextension 55010 "SI Family Params Mfr. Ref." extends "SI Family Parameters"
{
    layout
    {
        addafter("Parameter Code")
        {
            field("SI Ref. Item No."; Rec."SI Ref. Item No.")
            {
                ApplicationArea = All;
                Caption = 'Товар для схвалених продуктів';
                ToolTip = 'Необов’язковий фільтр. Якщо заповнено, у виборі показуються схвалені продукти тільки цього товару. Якщо порожньо — показуються всі схвалені продукти.';
            }
            field("SI Ref. Variant Code"; Rec."SI Ref. Variant Code")
            {
                ApplicationArea = All;
                Caption = 'Варіант для схвалених продуктів';
                ToolTip = 'Необов’язковий додатковий фільтр варіанта. Використовується разом із полем «Товар для схвалених продуктів».';
            }
}
    }
}
