namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item;

pageextension 62500 "SI Item Variants Recipe Ext" extends "Item Variants"
{
    layout
    {
        addafter(Description)
        {
            field("SI Production BOM No."; Rec."SI Production BOM No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Вказує виробничу специфікацію, спроєктовану SI Concrete Recipe Engine для цього варіанта товару.';
            }
        }
    }
}
