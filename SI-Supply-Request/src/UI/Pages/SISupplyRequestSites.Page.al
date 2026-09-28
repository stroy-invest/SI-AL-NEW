page 61032 "SI Supply Request Sites"
{
    PageType = List;
    SourceTable = "SI Supply Request Site";
    Caption = 'Будівельні майданчики заявки';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Sites)
            {
                field("Site Name"; Rec."Site Name")
                {
                    ApplicationArea = All;
                    Caption = 'Будівельний майданчик';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if RequestNoContext = '' then
            Error('Не визначено заявку для вибору будівельного майданчика.');

        Rec.Reset();
        Rec.SetRange("Request No.", RequestNoContext);
        Rec.SetRange(Selected, true);
    end;

    procedure SetRequestNo(RequestNo: Code[20])
    begin
        RequestNoContext := RequestNo;
    end;

    var
        RequestNoContext: Code[20];
}
