page 61014 "SI Supply Decision Line Card"
{
    PageType = Card;
    SourceTable = "SI Supply Decision Line";
    Caption = 'Рядок рішення щодо забезпечення';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(Context)
            {
                Caption = 'Контекст';
                field("Decision No."; Rec."Decision No.") { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Request Line No."; Rec."Request Line No.") { ApplicationArea = All; }
                field("Line Type"; Rec."Line Type") { ApplicationArea = All; }
                field(ConstructionSiteName; ConstructionSiteName)
                {
                    ApplicationArea = All;
                    Caption = 'Буд. майданчик';
                    Editable = false;
                }
            }
            group(Demand)
            {
                Caption = 'Потреба';
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; MultiLine = true; }
                field("Demand Quantity"; Rec."Demand Quantity") { ApplicationArea = All; }
                field("Allocated Quantity"; Rec."Allocated Quantity") { ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field("Required on Site At"; Rec."Required on Site At") { ApplicationArea = All; }
                field("Target Location Code"; Rec."Target Location Code") { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ConstructionSiteName := Rec.GetConstructionSiteName();
    end;

    var
        ConstructionSiteName: Text[100];
}

