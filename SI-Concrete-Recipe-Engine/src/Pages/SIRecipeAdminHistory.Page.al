namespace STROYINVEST.ConcreteRecipeEngine;

page 62110 "SI Recipe Admin History"
{
    PageType = List;
    SourceTable = "SI Recipe Admin History";
    Caption = 'Історія адміністративних дій рецептури';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(History)
            {
                field(Action; Rec.Action) { ApplicationArea = All; }
                field("Changed At"; Rec."Changed At") { ApplicationArea = All; }
                field("Changed By"; Rec."Changed By") { ApplicationArea = All; }
            }
        }
    }
}
