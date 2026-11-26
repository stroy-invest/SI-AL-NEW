page 53044 "SI Template Req. Groups"
{
    PageType = ListPart;
    SourceTable = "SI Template Req. Group";
    ApplicationArea = All;
    Caption = 'Групи обов’язковості';
    AutoSplitKey = false;
    layout
    {
        area(Content)
        {
            repeater(Groups)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Min Filled"; Rec."Min Filled") { ApplicationArea = All; }
                field("Max Filled"; Rec."Max Filled") { ApplicationArea = All; }
                field("ERP Projection Role"; Rec."ERP Projection Role") { ApplicationArea = All; }
            }
        }
    }
}
