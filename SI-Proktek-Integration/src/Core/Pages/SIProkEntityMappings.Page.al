page 57010 "SI Prok Entity Mappings"
{
    PageType = List;
    SourceTable = "SI Prok Entity Mapping";
    Caption = 'Відповідності сутностей Proktek';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Connection Code"; Rec."Connection Code")
                {
                    ApplicationArea = All;
                }
                field("Entity Type"; Rec."Entity Type")
                {
                    ApplicationArea = All;
                }
                field("BC No."; Rec."BC No.")
                {
                    ApplicationArea = All;
                }
                field("BC SystemId"; Rec."BC SystemId")
                {
                    ApplicationArea = All;
                }
                field("Proktek Internal Code"; Rec."Proktek Internal Code")
                {
                    ApplicationArea = All;
                }
                field("Proktek UUID"; Rec."Proktek UUID")
                {
                    ApplicationArea = All;
                }
                field("Proktek Code"; Rec."Proktek Code")
                {
                    ApplicationArea = All;
                }
                field("Last Sync At"; Rec."Last Sync At")
                {
                    ApplicationArea = All;
                }
                field("Last Response Message"; Rec."Last Response Message")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
