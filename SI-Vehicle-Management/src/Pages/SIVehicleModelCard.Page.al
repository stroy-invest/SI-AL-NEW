page 63258 "SI Vehicle Model Card"
{
    PageType = Card;
    SourceTable = "SI Vehicle Model";
    Caption = 'Картка моделі транспорту';
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Основне';
                field("Brand Code"; Rec."Brand Code") { ApplicationArea = All; }
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field("Vehicle Type Code"; Rec."Vehicle Type Code") { ApplicationArea = All; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; }
            }
            part(ModelCapacities; "SI Vehicle Model Capacities")
            {
                ApplicationArea = All;
                Caption = 'Характеристики моделі';
                SubPageLink = "Brand Code" = field("Brand Code"), "Model Code" = field(Code);
            }
        }
    }
}
