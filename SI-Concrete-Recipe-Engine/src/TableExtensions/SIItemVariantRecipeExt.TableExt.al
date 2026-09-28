namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;

tableextension 62400 "SI Item Variant Recipe Ext" extends "Item Variant"
{
    fields
    {
        field(62000; "SI Production BOM No."; Code[20])
        {
            Caption = 'Код виробничої специфікації SI';
            TableRelation = "Production BOM Header"."No.";
            DataClassification = CustomerContent;
            ToolTip = 'Вказує виробничу специфікацію, спроєктовану SI Concrete Recipe Engine для цього варіанта товару.';
        }
    }
}
