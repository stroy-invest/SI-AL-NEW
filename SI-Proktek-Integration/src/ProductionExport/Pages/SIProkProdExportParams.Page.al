page 57081 "SI Prok Prod Export Params"
{
    PageType = StandardDialog;
    Caption = 'Сформувати експорт виробництва Proktek';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(ConnectionGroup)
            {
                Caption = 'Підключення';

                field(ConnectionCode; ConnectionCode)
                {
                    ApplicationArea = All;
                    Caption = 'Профіль Proktek';
                    TableRelation = "SI Prok Connection".Code;
                    ToolTip = 'Визначає профіль Proktek, через який буде виконано експорт. Вибір не змінює глобальний активний профіль інтеграції.';
                }
            }
            group(Period)
            {
                Caption = 'Період';

                field(DateFrom; DateFrom)
                {
                    ApplicationArea = All;
                    Caption = 'Дата з';
                }
                field(DateTo; DateTo)
                {
                    ApplicationArea = All;
                    Caption = 'Дата по';
                }
            }
        }
    }

    procedure SetDefaults(NewDateFrom: Date; NewDateTo: Date; NewConnectionCode: Code[50])
    begin
        DateFrom := NewDateFrom;
        DateTo := NewDateTo;
        ConnectionCode := NewConnectionCode;
    end;

    procedure GetDateFrom(): Date
    begin
        exit(DateFrom);
    end;

    procedure GetDateTo(): Date
    begin
        exit(DateTo);
    end;

    procedure GetConnectionCode(): Code[50]
    begin
        exit(ConnectionCode);
    end;

    var
        DateFrom: Date;
        DateTo: Date;
        ConnectionCode: Code[50];
}
