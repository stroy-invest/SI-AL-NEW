page 54023 "SI BP Contact Points Part"
{
    PageType = ListPart;
    SourceTable = "SI BP Contact Point";
    ApplicationArea = All;
    Caption = 'Communication';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Type; Rec.Type) { ApplicationArea = All; ShowMandatory = true; }
                field("Subtype Code"; Rec."Subtype Code") { ApplicationArea = All; }
                field(Value; Rec.Value) { ApplicationArea = All; ShowMandatory = true; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Is Primary"; Rec."Is Primary") { ApplicationArea = All; }
                field(Active; Rec.Active) { ApplicationArea = All; }
                field(Verified; Rec.Verified) { ApplicationArea = All; Editable = false; }
            }
        }
    }
}
