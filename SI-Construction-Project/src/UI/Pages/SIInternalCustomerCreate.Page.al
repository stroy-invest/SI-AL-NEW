page 60039 "SI Internal Customer Create"
{
    Caption = 'Новий внутрішній клієнт';
    PageType = StandardDialog;
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            field(CustomerNo; CustomerNo) { ApplicationArea = All; Caption = 'Код'; ShowMandatory = true; }
            field(CustomerName; CustomerName) { ApplicationArea = All; Caption = 'Назва'; ShowMandatory = true; }
        }
    }
    var
        CustomerNo: Code[20];
        CustomerName: Text[100];
    procedure GetValues(var NewNo: Code[20]; var NewName: Text[100])
    begin
        NewNo := CustomerNo;
        NewName := CustomerName;
    end;
}
