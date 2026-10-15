page 50488 "SI EDS Wiz Operation Lines"
{
    PageType = ListPart;
    SourceTable = "SI EDS Wiz Operation Buffer";
    SourceTableTemporary = true;
    Caption = 'Підготовлені операції';
    ApplicationArea = All;
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Operation: Record "SI EDS Operation";
                    begin
                        if CurrentServiceCode = '' then
                            Error('Спочатку вкажіть сервіс.');
                        Operation.SetRange("Service Code", CurrentServiceCode);
                        if Page.RunModal(Page::"SI EDS Operations", Operation) <> Action::LookupOK then
                            exit(false);
                        Rec.Code := Operation.Code;
                        Rec.Description := Operation.Description;
                        Rec."HTTP Method" := Operation."HTTP Method";
                        Rec."Relative Path" := Operation."Relative Path";
                        Rec."Operation Group Code" := Operation."Operation Group Code";
                        Rec.Existing := true;
                        Rec.Enabled := Operation.Enabled;
                        Text := Operation.Code;
                        exit(true);
                    end;
                    trigger OnValidate()
                    var
                        Operation: Record "SI EDS Operation";
                    begin
                        if Operation.Get(CurrentServiceCode, Rec.Code) then begin
                            Rec.Description := Operation.Description;
                            Rec."HTTP Method" := Operation."HTTP Method";
                            Rec."Relative Path" := Operation."Relative Path";
                            Rec."Operation Group Code" := Operation."Operation Group Code";
                            Rec.Existing := true;
                            Rec.Enabled := Operation.Enabled;
                        end else
                            Rec.Existing := false;
                    end;
                }
                field(Description; Rec.Description) { ApplicationArea = All; Editable = not Rec.Existing; }
                field("Operation Group Code"; Rec."Operation Group Code")
                {
                    ApplicationArea = All;
                    Editable = not Rec.Existing;
                    ToolTip = 'Можна залишити порожнім. Код має належати сервісу; перевірка чернетки виконується на наступному етапі патча.';
                }
                field("HTTP Method"; Rec."HTTP Method") { ApplicationArea = All; Editable = not Rec.Existing; }
                field("Relative Path"; Rec."Relative Path") { ApplicationArea = All; Editable = not Rec.Existing; }
                field(Existing; Rec.Existing) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(AddOperation)
            {
                Caption = 'Додати операцію';
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
    procedure GetDraftOperations(var Draft: Record "SI EDS Wiz Operation Buffer" temporary)
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
