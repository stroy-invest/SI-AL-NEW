page 50303 "SI Country Legal Forms"
{
    PageType = List;
    SourceTable = "SI Country Legal Form";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Country Legal Forms';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country or region for which the legal form is defined.';
                }

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the stable local code of the country legal form.';
                }

                field("Country Legal Form Name"; Rec."Country Legal Form Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the full local name of the country legal form.';
                }

                field("Short Name"; Rec."Short Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the local abbreviated name of the country legal form.';
                }

                field("Legal Form Desc."; Rec."Legal Form Desc.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the normalized corporate legal form description.';
                }

                field("Legal Form Code"; Rec."Legal Form Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the normalized corporate legal form code.';
                }
            }
        }
    }
}
