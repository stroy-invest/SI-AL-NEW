page 57102 "SI Prok Production Plan Lines"
{
    PageType = ListPart;
    SourceTable = "SI Prok Production Plan Line";
    Caption = 'Нормативні матеріали';
    ApplicationArea = All;
    Editable = false;
    layout { area(Content) { repeater(Materials) {
        field("Item No."; Rec."Item No.") { ApplicationArea = All; }
        field(Description; Rec.Description) { ApplicationArea = All; }
        field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
        field("Quantity per"; Rec."Quantity per") { ApplicationArea = All; }
        field("Planned Quantity"; Rec."Planned Quantity") { ApplicationArea = All; }
        field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
    } } }
}
