page 61034 "SI Project Selection"
{
    PageType = List;
    SourceTable = Job;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Вибір проєкту';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Projects)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Проєкт';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = '№';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange("SI Construction Project", true);
    end;

    procedure GetSelectedProjectNo(): Code[20]
    begin
        exit(Rec."No.");
    end;
}
