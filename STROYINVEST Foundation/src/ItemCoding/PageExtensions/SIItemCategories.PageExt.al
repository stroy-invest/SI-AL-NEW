pageextension 50101 "SI Item Categories Ext." extends "Item Categories"
{
    layout
    {
        addlast(Control1)
        {
            field("SI Category Kind"; Rec."SI Category Kind")
            {
                ApplicationArea = All;
                Caption = 'Вид категорії';
                ToolTip = 'Визначає функціональний вид категорії товарів.';
            }

            field("SI Finished Type"; Rec."SI Finished Type")
            {
                ApplicationArea = All;
                Caption = 'Вид готової продукції';
                ToolTip = 'Визначає вид готової продукції для цієї категорії.';
            }

            field("SI Item No. Series Code"; Rec."SI Item No. Series Code")
            {
                ApplicationArea = All;
                ToolTip = 'Визначає серію номерів, яка використовується для автоматичного формування номера товару цієї категорії.';
            }
        }
    }
}