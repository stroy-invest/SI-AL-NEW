namespace STROYINVEST.ConcreteRecipeEngine;

table 62024 "SI Recipe Resolver Result"
{
    TableType = Temporary;
    Caption = 'Результат визначення рецептури';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№ запису'; }
        field(10; "Recipe No."; Code[50]) { Caption = 'Код рецептури'; }
        field(11; "Revision No."; Integer) { Caption = '№ ревізії'; }
        field(12; "Recipe Description"; Text[100]) { Caption = 'Опис рецептури'; }
        field(13; "Recipe Type"; Enum "SI Recipe Type") { Caption = 'Тип рецептури'; }
        field(14; "Item No."; Code[20]) { Caption = 'Код товару'; }
        field(15; "Variant Code"; Code[10]) { Caption = 'Код варіанта'; }
        field(16; "Match Type"; Enum "SI Recipe Match Type") { Caption = 'Тип відповідності'; }
        field(20; "Validity Type"; Enum "SI Recipe Validity Type") { Caption = 'Тип валідності'; }
        field(21; "Valid From"; Date) { Caption = 'Чинна з'; }
        field(22; "Valid To"; Date) { Caption = 'Чинна до'; }
        field(23; Applicability; Enum "SI Recipe Applicability") { Caption = 'Актуальність'; }
        field(30; "Projection Status"; Enum "SI Recipe Projection Status") { Caption = 'Статус проєкції'; }
        field(31; "Production BOM No."; Code[20]) { Caption = 'Код виробничої специфікації'; }
        field(32; "Production BOM Version Code"; Code[20]) { Caption = 'Код версії виробничої специфікації'; }
        field(33; "Projection Ready"; Boolean) { Caption = 'Готово до проєкції'; }
        field(40; "Target Date"; Date) { Caption = 'Цільова дата'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(RecipeRevision; "Recipe No.", "Revision No.") { }
    }
}
