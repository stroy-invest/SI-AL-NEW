page 54021 "SI BP Addresses Part"
{
    PageType = ListPart;
    SourceTable = "SI BP Address";
    ApplicationArea = All;
    Caption = 'Адреси';
    DelayedInsert = true;
    PopulateAllFields = true;
    CardPageId = "SI BP Address Card";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Address Type"; Rec."Address Type")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("Raw Address"; Rec."Raw Address")
                {
                    ApplicationArea = All;
                    Caption = 'Адреса з реєстру';
                    ToolTip = 'Повна адреса, отримана із зовнішнього реєстру без структурного розбору.';
                    Editable = false;
                }
                field("Region/State"; Rec."Region/State")
                {
                    ApplicationArea = All;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = All;
                }
                field(Street; Rec.Street)
                {
                    ApplicationArea = All;
                }
                field("Building No."; Rec."Building No.")
                {
                    ApplicationArea = All;
                }
                field("Office/Apartment"; Rec."Office/Apartment")
                {
                    ApplicationArea = All;
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = All;
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = All;
                }
                field("Is Primary"; Rec."Is Primary")
                {
                    ApplicationArea = All;
                }
                field(Verified; Rec.Verified)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

}
