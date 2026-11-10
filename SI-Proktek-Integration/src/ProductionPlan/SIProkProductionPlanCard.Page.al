page 57103 "SI Prok Production Plan Card"
{
    PageType = Card;
    SourceTable = "SI Prok Production Plan";
    Caption = 'План виробництва';
    ApplicationArea = All;
    Editable = false;
    layout { area(Content) {
        group(General) { Caption = 'Загальне';
            field("Prod. Request Entry No."; Rec."Prod. Request Entry No.") { ApplicationArea = All; }
            field("Source No."; Rec."Source No.") { ApplicationArea = All; }
            field("Item No."; Rec."Item No.") { ApplicationArea = All; }
            field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
            field("Planned Quantity"; Rec."Planned Quantity") { ApplicationArea = All; }
            field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
            field("Recipe No."; Rec."Recipe No.") { ApplicationArea = All; }
            field("Recipe Revision No."; Rec."Recipe Revision No.") { ApplicationArea = All; }
            field("Production BOM No."; Rec."Production BOM No.") { ApplicationArea = All; }
            field("Production BOM Version Code"; Rec."Production BOM Version Code") { ApplicationArea = All; }
            field("Created At"; Rec."Created At") { ApplicationArea = All; }
        }
        part(Materials; "SI Prok Production Plan Lines") {
            ApplicationArea = All;
            SubPageLink = "Prod. Request Entry No." = field("Prod. Request Entry No.");
        }
    } }
}
