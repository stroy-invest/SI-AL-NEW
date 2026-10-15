page 57097 "SI Prok Material Audit"
{
    PageType = List;
    SourceTable = "SI Prok Material Audit";
    SourceTableTemporary = true;
    Caption = 'План / факт матеріалів за автоміксерами';
    ApplicationArea = All;
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Scope"; Rec."Scope") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field("Material Name"; Rec."Material Name") { ApplicationArea = All; }
                field("External Material Code"; Rec."External Material Code") { ApplicationArea = All; }
                field("Mix Count"; Rec."Mix Count") { ApplicationArea = All; }
                field("Produced M3"; Rec."Produced M3") { ApplicationArea = All; }
                field("Ordered M3"; Rec."Ordered M3") { ApplicationArea = All; }
                field("Recipe Kg Per M3"; Rec."Recipe Kg Per M3") { ApplicationArea = All; }
                field("BC Norm Kg"; Rec."BC Norm Kg") { ApplicationArea = All; }
                field("Proktek Plan Kg"; Rec."Proktek Plan Kg") { ApplicationArea = All; }
                field("Actual Kg"; Rec."Actual Kg") { ApplicationArea = All; }
                field("Variance Kg"; Rec."Variance Kg") { ApplicationArea = All; }
                field("Variance Percent"; Rec."Variance Percent") { ApplicationArea = All; }
                field("Plan Difference Kg"; Rec."Plan Difference Kg") { ApplicationArea = All; }
                field("Ordered Norm Kg"; Rec."Ordered Norm Kg") { ApplicationArea = All; }
                field("Recipe Material"; Rec."Recipe Material") { ApplicationArea = All; }
                field("BC Material Resolved"; Rec."BC Material Resolved") { ApplicationArea = All; }
                field("Check Result"; Rec."Check Result") { ApplicationArea = All; }
            }
        }
    }
    trigger OnOpenPage()
    var
        AuditMgt: Codeunit "SI Prok Material Audit Mgt";
    begin
        AuditMgt.BuildAudit(OrderUuid, Rec);
    end;
    procedure SetOrderUuid(NewOrderUuid: Guid)
    begin
        OrderUuid := NewOrderUuid;
    end;
    var
        OrderUuid: Guid;
}
