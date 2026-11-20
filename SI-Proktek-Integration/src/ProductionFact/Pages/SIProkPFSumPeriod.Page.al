page 57231 "SI Prok PF Sum Period"
{
    PageType = NavigatePage;
    Caption = 'Підсумковий план/факт за період';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Period)
            {
                Caption = 'Період виробництва';
                field(FromDate; FromDate)
                {
                    ApplicationArea = All;
                    Caption = 'Початкова дата';
                    ShowMandatory = true;
                }
                field(ToDate; ToDate)
                {
                    ApplicationArea = All;
                    Caption = 'Кінцева дата';
                    ShowMandatory = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Generate)
            {
                ApplicationArea = All;
                Caption = 'ОК';
                InFooterBar = true;
                Image = Approve;
                trigger OnAction()
                begin
                    if FromDate = 0D then
                        Error('Укажіть початкову дату.');
                    if ToDate = 0D then
                        Error('Укажіть кінцеву дату.');
                    if ToDate < FromDate then
                        Error('Кінцева дата не може бути ранішою за початкову.');
                    Accepted := true;
                    CurrPage.Close();
                end;
            }
            action(CloseDialog)
            {
                ApplicationArea = All;
                Caption = 'Закрити';
                InFooterBar = true;
                Image = Cancel;
                trigger OnAction()
                begin
                    Accepted := false;
                    CurrPage.Close();
                end;
            }
        }
    }

    procedure SetDefaults(NewFromDate: Date; NewToDate: Date)
    begin
        FromDate := NewFromDate;
        ToDate := NewToDate;
        Accepted := false;
    end;

    procedure WasAccepted(): Boolean
    begin
        exit(Accepted);
    end;

    procedure GetFromDate(): Date
    begin
        exit(FromDate);
    end;

    procedure GetToDate(): Date
    begin
        exit(ToDate);
    end;

    var
        FromDate: Date;
        ToDate: Date;
        Accepted: Boolean;
}
