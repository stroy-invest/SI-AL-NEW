page 63255 "SI Vehicle Brands"
{
    PageType = List;
    SourceTable = "SI Vehicle Brand";
    Caption = 'Бренди транспорту';
    ApplicationArea = All;
    UsageCategory = Lists;
    layout { area(Content) { repeater(Brands) {
        field(Code; Rec.Code) { ApplicationArea = All; }
        field(Name; Rec.Name) { ApplicationArea = All; }
        field("Manufacturer Code"; Rec."Manufacturer Code") { ApplicationArea = All; }
        field(Blocked; Rec.Blocked) { ApplicationArea = All; }
    } } }
}
