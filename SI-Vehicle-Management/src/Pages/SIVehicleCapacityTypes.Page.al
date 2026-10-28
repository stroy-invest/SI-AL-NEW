page 63253 "SI Vehicle Capacity Types"
{
    PageType = List;
    SourceTable = "SI Vehicle Capacity Type";
    Caption = 'Типи характеристик транспорту';
    ApplicationArea = All;
    UsageCategory = Lists;
    layout { area(Content) { repeater(Types) {
        field(Code; Rec.Code) { ApplicationArea = All; }
        field(Description; Rec.Description) { ApplicationArea = All; }
        field("Required Semantic Code"; Rec."Required Semantic Code") { ApplicationArea = All; }
        field(Blocked; Rec.Blocked) { ApplicationArea = All; }
    } } }
}
