namespace STROYINVEST.ConcreteRecipeEngine;

page 62105 "SI Recipe Setup"
{
    PageType = Card;
    SourceTable = "SI Concrete Recipe Setup";
    Caption = 'Налаштування рецептур бетону';
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Concrete Root Category Code"; Rec."Concrete Root Category Code")
                {
                    ApplicationArea = All;
                }
                field("Default Permanent End Date"; Rec."Default Permanent End Date")
                {
                    ApplicationArea = All;
                }
                field("Default Line Increment"; Rec."Default Line Increment")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get('') then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert(true);
        end;
    end;
}
