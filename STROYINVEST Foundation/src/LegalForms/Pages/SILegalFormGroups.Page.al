page 50300 "SI Legal Form Groups"
{
    PageType = List;
    SourceTable = "SI Legal Form Group";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Legal Form Groups';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the legal form group.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the legal form group.';
                }

                field("Is Independent"; Rec."Is Independent")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи є група незалежним суб''єктом господарювання.';
                }
            }
        }
    }
}