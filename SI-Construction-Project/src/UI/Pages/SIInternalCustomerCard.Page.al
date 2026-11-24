page 60038 "SI Internal Customer Card"
{
    Caption = 'Картка внутрішнього клієнта';
    PageType = Card;
    SourceTable = Customer;
    SourceTableView = where("SI Customer Type" = filter("Internal Project" | "Internal Operations"));
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';
                field("No."; Rec."No.") { ApplicationArea = All; Editable = false; }
                field(Name; Rec.Name) { ApplicationArea = All; Editable = IsOperations; }
                field("SI Customer Type"; Rec."SI Customer Type") { ApplicationArea = All; Editable = false; }
                field("SI Project No."; Rec."SI Project No.") { ApplicationArea = All; Editable = false; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; Editable = IsOperations; }
            }
        }
    }
    var
        IsOperations: Boolean;
    trigger OnAfterGetCurrRecord()
    begin
        IsOperations := Rec."SI Customer Type" = Rec."SI Customer Type"::"Internal Operations";
    end;
}
