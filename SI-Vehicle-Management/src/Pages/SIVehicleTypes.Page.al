page 63252 "SI Vehicle Types"
{
    PageType = List;
    SourceTable = "SI Vehicle Type";
    Caption = 'Типи транспорту';
    ApplicationArea = All;
    UsageCategory = Lists;
    layout { area(Content) { repeater(Types) {
        field(Code; Rec.Code) { ApplicationArea = All; }
        field(Description; Rec.Description) { ApplicationArea = All; }
        field(Blocked; Rec.Blocked) { ApplicationArea = All; }
    } } }
}
