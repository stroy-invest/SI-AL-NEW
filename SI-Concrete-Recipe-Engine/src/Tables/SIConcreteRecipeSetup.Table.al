namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;

table 62023 "SI Concrete Recipe Setup"
{
    Caption = 'Налаштування рецептур бетону';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Первинний ключ';
        }
        field(10; "Recipe Nos."; Code[20])
        {
            Caption = 'Нумерація рецептур';
            TableRelation = "No. Series".Code;
            ToolTip = 'Вказує серію номерів для присвоєння кодів рецептур.';
        }
        field(20; "Default Permanent End Date"; Date)
        {
            Caption = 'Стандартна кінцева дата постійної ревізії';
            ToolTip = 'Вказує технічну кінцеву дату, що призначається постійній ревізії рецептури.';
        }
        field(30; "Default Line Increment"; Integer)
        {
            Caption = 'Стандартний крок рядків';
            MinValue = 1;
            ToolTip = 'Вказує стандартний крок нумерації рядків рецептури.';
        }
        field(40; "Concrete Root Category Code"; Code[20])
        {
            Caption = 'Коренева категорія бетону';
            TableRelation = "Item Category".Code;
            ToolTip = 'Вказує кореневу категорію товарів, дочірні товари та варіанти якої можна вибирати для рецептур бетону.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if "Default Permanent End Date" = 0D then
            "Default Permanent End Date" := DMY2Date(31, 12, 2999);
        if "Default Line Increment" = 0 then
            "Default Line Increment" := 10000;
    end;
}
