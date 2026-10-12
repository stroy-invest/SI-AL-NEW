page 50783 "SI EDS Transport Preview"
{
    PageType = List;
    SourceTable = "SI EDS Transport Preview";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Caption = 'EDS: перегляд пакета та відмінностей';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;
    layout
    {
        area(Content)
        {
            repeater(Details)
            {
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Entity Name"; Rec."Entity Name") { ApplicationArea = All; }
                field("Record Key"; Rec."Record Key") { ApplicationArea = All; }
                field("Field Caption"; Rec."Field Caption") { ApplicationArea = All; }
                field("Current Value"; Rec."Current Value") { ApplicationArea = All; }
                field("Package Value"; Rec."Package Value") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(OnlyChanges)
            {
                Caption = 'Тільки зміни';
                Image = FilterLines;
                trigger OnAction()
                begin
                    Rec.SetFilter(Status, '%1|%2', Rec.Status::Create, Rec.Status::Update);
                    CurrPage.Update(false);
                end;
            }
            action(AllFields)
            {
                Caption = 'Усі поля';
                Image = ClearFilter;
                trigger OnAction()
                begin
                    Rec.SetRange(Status);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
