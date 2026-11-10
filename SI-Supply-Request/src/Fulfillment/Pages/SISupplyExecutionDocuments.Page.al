page 61080 "SI Supply Exec. Documents"
{
    PageType = List;
    SourceTable = "SI Supply Allocation";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Документи виконання за заявкою';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Documents)
            {
                field("Decision No."; Rec."Decision No.") { ApplicationArea = All; }
                field("Decision Line No."; Rec."Decision Line No.") { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Supply Method"; Rec."Supply Method") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Execution Reference"; Rec."Execution Reference") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewExecutionDocument)
            {
                ApplicationArea = All;
                Caption = 'Переглянути документ виконання';
                Image = ViewDetails;
                trigger OnAction()
                var
                    Navigation: Codeunit "SI Supply Exec. Navigation";
                begin
                    Navigation.OpenExecution(Rec);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetFilter("Execution System ID", '<>%1', EmptyGuid);
    end;

    var
        EmptyGuid: Guid;
}
