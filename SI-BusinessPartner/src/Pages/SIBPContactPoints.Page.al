page 54022 "SI BP Contact Points"
{
    PageType = List;
    SourceTable = "SI BP Contact Point";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Контакти контрагента';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Business Partner No."; Rec."Business Partner No.") { ApplicationArea = All; }
                field(Type; Rec.Type) { ApplicationArea = All; }
                field("Subtype Code"; Rec."Subtype Code") { ApplicationArea = All; }
                field(Value; Rec.Value) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Is Primary"; Rec."Is Primary") { ApplicationArea = All; }
                field(Active; Rec.Active) { ApplicationArea = All; }
                field(Verified; Rec.Verified) { ApplicationArea = All; }
            }
        }
    }
}
