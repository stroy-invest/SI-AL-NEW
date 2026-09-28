page 57090 "SI Prok Formula Sync Status"
{
    PageType = Card;
    SourceTable = "SI Prok Entity Mapping";
    Caption = 'Стан синхронізації Formula Proktek';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Recipe)
            {
                Caption = 'Рецептура BC';
                field("Connection Code"; Rec."Connection Code") { ApplicationArea = All; }
                field("SI Recipe No."; Rec."SI Recipe No.") { ApplicationArea = All; }
                field("SI Recipe Revision No."; Rec."SI Recipe Revision No.") { ApplicationArea = All; }
                field("BC SystemId"; Rec."BC SystemId") { ApplicationArea = All; }
            }
            group(Proktek)
            {
                Caption = 'Proktek Formula';
                field("SI Formula Proj. Status"; Rec."SI Formula Proj. Status") { ApplicationArea = All; }
                field("SI Proktek Active"; Rec."SI Proktek Active") { ApplicationArea = All; }
                field("Proktek Internal Code"; Rec."Proktek Internal Code") { ApplicationArea = All; Caption = 'Formula Index'; }
                field("Proktek UUID"; Rec."Proktek UUID") { ApplicationArea = All; Caption = 'Formula UUID'; }
                field("Proktek Code"; Rec."Proktek Code") { ApplicationArea = All; }
            }
            group(Audit)
            {
                Caption = 'Синхронізація';
                field("Last Sync At"; Rec."Last Sync At") { ApplicationArea = All; }
                field("SI Last Sync By"; Rec."SI Last Sync By") { ApplicationArea = All; }
                field("Last Response Message"; Rec."Last Response Message") { ApplicationArea = All; MultiLine = true; }
                field("SI Last Error"; Rec."SI Last Error") { ApplicationArea = All; MultiLine = true; }
            }
        }
    }
}
