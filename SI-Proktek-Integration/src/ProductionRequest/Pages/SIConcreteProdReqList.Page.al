page 57024 "SI Concrete Prod Req List"
{
    PageType = List;
    SourceTable = "SI Concrete Prod Request";
    CardPageId = "SI Concrete Prod Req Card";
    Caption = 'Заявки на виробництво бетону';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Requests)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Source Type"; Rec."Source Type") { ApplicationArea = All; }
                field("Source No."; Rec."Source No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field("Required Date/Time"; Rec."Required Date/Time") { ApplicationArea = All; }
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field("Recipe Snapshot Entry No."; Rec."Recipe Snapshot Entry No.") { ApplicationArea = All; }
                field("Formula Code"; Rec."Formula Code") { ApplicationArea = All; }
            }
        }
    }
}
