namespace STROYINVEST.ConcreteRecipeEngine;

table 62025 "SI Recipe Admin History"
{
    Caption = 'Історія адміністративних дій рецептури';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = '№ запису';
            AutoIncrement = true;
        }
        field(10; "Recipe No."; Code[50])
        {
            Caption = 'Код рецептури';
            TableRelation = "SI Concrete Recipe"."Recipe No.";
        }
        field(11; "Revision No."; Integer)
        {
            Caption = '№ ревізії';
        }
        field(20; Action; Enum "SI Recipe Admin Action")
        {
            Caption = 'Дія';
        }
        field(30; "Changed At"; DateTime)
        {
            Caption = 'Змінено о';
        }
        field(31; "Changed By"; Guid)
        {
            Caption = 'Змінив';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(RecipeRevision; "Recipe No.", "Revision No.", "Entry No.")
        {
        }
    }
}
