page 63256 "SI Vehicle Models"
{
    PageType = List;
    SourceTable = "SI Vehicle Model";
    Caption = 'Моделі транспорту';
    ApplicationArea = All;
    UsageCategory = Lists;
    layout { area(Content) { repeater(Models) {
        field("Brand Code"; Rec."Brand Code") { ApplicationArea = All; }
        field(Code; Rec.Code) { ApplicationArea = All; }
        field(Name; Rec.Name) { ApplicationArea = All; }
        field("Vehicle Type Code"; Rec."Vehicle Type Code") { ApplicationArea = All; }
        field(Blocked; Rec.Blocked) { ApplicationArea = All; }
    } } }
}
