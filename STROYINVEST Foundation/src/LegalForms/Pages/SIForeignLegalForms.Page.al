page 50302 "SI Foreign Legal Forms"
{
    PageType = List;
    SourceTable = "SI Legal Form Foreign";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Foreign Legal Forms';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country or region of the foreign legal form.';
                }

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the foreign legal form.';
                }

                field("Foreign Legal Form Name"; Rec."Foreign Legal Form Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the full foreign legal form name.';
                }

                field("Short Name"; Rec."Short Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the short name of the foreign legal form.';
                }

                field("Legal Form Desc."; Rec."Legal Form Desc.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the corresponding Ukrainian legal form.';
                }

                field("Legal Form Code"; Rec."Legal Form Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the corresponding Ukrainian legal form.';
                }
            }
        }
    }
}