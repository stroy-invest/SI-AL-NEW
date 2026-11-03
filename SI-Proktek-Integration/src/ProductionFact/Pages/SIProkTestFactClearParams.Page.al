page 57181 "SI Prok Test Fact Clear Params"
{
    PageType = StandardDialog;
    Caption = 'Очистити тестові факти Proktek';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Period)
            {
                Caption = 'Період виробництва';
                field(DateFrom; DateFrom) { ApplicationArea = All; Caption = 'Дата з'; }
                field(DateTo; DateTo) { ApplicationArea = All; Caption = 'Дата по'; }
            }
            group(StatusFilter)
            {
                Caption = 'Додатковий фільтр';
                field(FilterByStatus; FilterByStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Фільтрувати за статусом';
                }
                field(FactStatus; FactStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Статус';
                    Enabled = FilterByStatus;
                }
            }
            group(Scope)
            {
                Caption = 'Обмеження';
                field(CaptureModeLabel; CaptureModeLabel)
                {
                    ApplicationArea = All;
                    Caption = 'Режим приймання';
                    Editable = false;
                }
            }
        }
    }

    procedure SetDefaults(NewDateFrom: Date; NewDateTo: Date)
    begin
        DateFrom := NewDateFrom;
        DateTo := NewDateTo;
        CaptureModeLabel := 'Тест (тільки)';
    end;

    procedure GetDateFrom(): Date begin exit(DateFrom); end;
    procedure GetDateTo(): Date begin exit(DateTo); end;
    procedure GetFilterByStatus(): Boolean begin exit(FilterByStatus); end;
    procedure GetStatus(): Enum "SI Prok Prod Fact Status" begin exit(FactStatus); end;

    var
        DateFrom: Date;
        DateTo: Date;
        FilterByStatus: Boolean;
        FactStatus: Enum "SI Prok Prod Fact Status";
        CaptureModeLabel: Text[30];
}
