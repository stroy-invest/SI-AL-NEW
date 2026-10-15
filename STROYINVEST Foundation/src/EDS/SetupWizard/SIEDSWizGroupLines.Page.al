page 50487 "SI EDS Wiz Group Lines"
{
    PageType = ListPart;
    SourceTable = "SI EDS Wiz Group Buffer";
    SourceTableTemporary = true;
    Caption = 'Підготовлені групи';
    ApplicationArea = All;
    AutoSplitKey = false;
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Path Prefix"; Rec."Path Prefix") { ApplicationArea = All; }
                field(Sequence; Rec.Sequence) { ApplicationArea = All; }
                field(Enabled; Rec.Enabled) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(AddGroup)
            {
                Caption = 'Додати групу';
                ApplicationArea = All;
                Image = New;
                trigger OnAction()
                begin
                    if CurrentServiceCode = '' then
                        Error('Спочатку вкажіть сервіс.');
                    Rec.Init();
                    Rec."Service Code" := CurrentServiceCode;
                    Rec.Enabled := true;
                    Rec.Insert(true);
                end;
            }
        }
    }
    procedure GetDraftGroups(var Draft: Record "SI EDS Wiz Group Buffer" temporary)
    begin
        Draft.Copy(Rec, true);
    end;

    procedure SetServiceCode(NewServiceCode: Code[50])
    begin
        CurrentServiceCode := NewServiceCode;
        Rec.SetRange("Service Code", CurrentServiceCode);
    end;
    var
        CurrentServiceCode: Code[50];
}
