page 50301 "SI Legal Forms"
{
    PageType = List;
    SourceTable = "SI Legal Form";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Legal Forms';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the legal form.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the legal form.';
                }

                field("Short Name"; Rec."Short Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the short name of the legal form.';
                }

                field("Legal Form Group Desc."; Rec."Legal Form Group Desc.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the legal form group.';
                }

                field("Legal Form Group Code"; Rec."Legal Form Group Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the group to which the legal form belongs.';
                }
            }
        }
    }
}