page 57141 "SI Prok Driver Mappings"
{
    PageType = List;
    SourceTable = "SI Prok Driver Mapping";
    Caption = 'Зіставлення водіїв Proktek';
    ApplicationArea = All;
    UsageCategory = Lists;
    layout
    {
        area(Content)
        {
            repeater(Drivers)
            {
                field("Connection Code"; Rec."Connection Code") { ApplicationArea = All; }
                field("Driver UUID"; Rec."Driver UUID") { ApplicationArea = All; }
                field("Employee No."; Rec."Employee No.") { ApplicationArea = All; }
                field("Driver Name"; Rec."Driver Name") { ApplicationArea = All; }
            }
        }
    }
}
