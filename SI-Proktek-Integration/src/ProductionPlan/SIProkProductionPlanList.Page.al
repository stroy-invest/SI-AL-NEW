page 57104 "SI Prok Production Plan List"
{
    PageType = List;
    SourceTable = "SI Prok Production Plan";
    Caption = 'Плани виробництва бетону';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    CardPageId = "SI Prok Production Plan Card";

    layout
    {
        area(Content)
        {
            repeater(Plans)
            {
                field("Prod. Request Entry No."; Rec."Prod. Request Entry No.") { ApplicationArea = All; }
                field("Source No."; Rec."Source No.") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field("Planned Quantity"; Rec."Planned Quantity") { ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field("Production BOM No."; Rec."Production BOM No.") { ApplicationArea = All; }
                field("Production BOM Version Code"; Rec."Production BOM Version Code") { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
            }
        }
    }
}
