page 54020 "SI BP Addresses"
{
    PageType = List;
    SourceTable = "SI BP Address";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Business Partner Addresses';
    CardPageId = "SI BP Address Card";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Business Partner No."; Rec."Business Partner No.") { ApplicationArea = All; }
                field("Address Type"; Rec."Address Type") { ApplicationArea = All; }
                field("Country/Region Code"; Rec."Country/Region Code") { ApplicationArea = All; }
                field("Region/State"; Rec."Region/State") { ApplicationArea = All; }
                field(City; Rec.City) { ApplicationArea = All; }
                field("Post Code"; Rec."Post Code") { ApplicationArea = All; }
                field(Street; Rec.Street) { ApplicationArea = All; }
                field("Building No."; Rec."Building No.") { ApplicationArea = All; }
                field("Office/Apartment"; Rec."Office/Apartment") { ApplicationArea = All; }
                field("Valid From"; Rec."Valid From") { ApplicationArea = All; }
                field("Valid To"; Rec."Valid To") { ApplicationArea = All; }
                field("Is Primary"; Rec."Is Primary") { ApplicationArea = All; }
                field(Verified; Rec.Verified) { ApplicationArea = All; Editable = false; }
            }
        }
    }
}
