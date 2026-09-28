page 61010 "SI Supply Decision Lines"
{
    PageType = ListPart;
    SourceTable = "SI Supply Decision Line";
    ApplicationArea = All;
    Caption = 'Потреби до забезпечення';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(ConstructionSiteName; ConstructionSiteName)
                {
                    ApplicationArea = All;
                    Caption = 'Буд. майданчик';
                    Editable = false;
                }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
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

