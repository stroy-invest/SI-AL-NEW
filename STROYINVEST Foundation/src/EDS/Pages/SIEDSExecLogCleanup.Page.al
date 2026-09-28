page 50459 "SI EDS Exec Log Cleanup"
{
    PageType = StandardDialog;
    Caption = 'Очистити журнал EDS';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Фільтри';

                field(DateFrom; DateFrom)
                {
                    ApplicationArea = All;
                    Caption = 'Дата з';
                    ToolTip = 'Початкова дата записів журналу, які буде видалено.';
                    NotBlank = true;
                }

                field(DateTo; DateTo)
                {
                    ApplicationArea = All;
                    Caption = 'Дата по';
                    ToolTip = 'Кінцева дата записів журналу, які буде видалено.';
                    NotBlank = true;
                }

                field(ResultFilter; ResultFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Результат';
                    ToolTip = 'Визначає, які записи видаляти: усі, лише помилки або лише успішні.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        InitializeDates();
        ResultFilter := ResultFilter::All;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> Action::OK then
            exit(true);

        if DateFrom = 0D then
            Error('Вкажіть дату «Дата з».');

        if DateTo = 0D then
            Error('Вкажіть дату «Дата по».');

        if DateFrom > DateTo then
            Error('Дата «Дата з» не може бути пізнішою за «Дата по».');

        exit(true);
    end;

    procedure GetDateFrom(): Date
    begin
        exit(DateFrom);
    end;

    procedure GetDateTo(): Date
    begin
        exit(DateTo);
    end;

    procedure GetResultFilter(): Enum "SI EDS Log Cleanup Filter"
    begin
        exit(ResultFilter);
    end;

    local procedure InitializeDates()
    var
        ExecLog: Record "SI EDS Exec. Log";
    begin
        ExecLog.SetCurrentKey("Started At");

        if not ExecLog.FindFirst() then
            exit;

        DateFrom := DT2Date(ExecLog."Started At");

        if ExecLog.FindLast() then
            DateTo := DT2Date(ExecLog."Started At");
    end;

    var
        DateFrom: Date;
        DateTo: Date;
        ResultFilter: Enum "SI EDS Log Cleanup Filter";
}
