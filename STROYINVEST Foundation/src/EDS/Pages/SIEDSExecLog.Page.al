page 50456 "SI EDS Exec. Log"
{
    PageType = List;
    SourceTable = "SI EDS Exec. Log";
    Caption = 'EDS: журнал виконання';
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = false;
    CardPageId = "SI EDS Exec. Log Card";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Started At"; Rec."Started At") { ApplicationArea = All; }
                field("Service Code"; Rec."Service Code") { ApplicationArea = All; }
                field("Operation Code"; Rec."Operation Code") { ApplicationArea = All; }
                field("Provider Code"; Rec."Provider Code") { ApplicationArea = All; }
                field("Endpoint Code"; Rec."Endpoint Code") { ApplicationArea = All; }
                field("Request URL"; Rec."Request URL") { ApplicationArea = All; }
                field("HTTP Status Code"; Rec."HTTP Status Code") { ApplicationArea = All; }
                field("Result Type"; Rec."Result Type") { ApplicationArea = All; }
                field("Duration (ms)"; Rec."Duration (ms)") { ApplicationArea = All; }
                field("Error Code"; Rec."Error Code") { ApplicationArea = All; }
                field("Error Message"; Rec."Error Message") { ApplicationArea = All; }
                field("Correlation ID"; Rec."Correlation ID") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenEntry)
            {
                ApplicationArea = All;
                Caption = 'Відкрити запис';
                Image = View;
                RunObject = page "SI EDS Exec. Log Card";
                RunPageLink = "Entry No." = field("Entry No.");
                ToolTip = 'Відкрити картку запису журналу з технічними деталями та збереженим тілом відповіді.';
            }

            action(ClearLog)
            {
                ApplicationArea = All;
                Caption = 'Очистити журнал';
                Image = Delete;
                ToolTip = 'Видалити записи журналу EDS за вибраним періодом і результатом.';

                trigger OnAction()
                var
                    CleanupPage: Page "SI EDS Exec Log Cleanup";
                    ExecLog: Record "SI EDS Exec. Log";
                    DateFrom: Date;
                    DateTo: Date;
                    ResultFilter: Enum "SI EDS Log Cleanup Filter";
                    RecordsToDelete: Integer;
                begin
                    if CleanupPage.RunModal() <> Action::OK then
                        exit;

                    DateFrom := CleanupPage.GetDateFrom();
                    DateTo := CleanupPage.GetDateTo();
                    ResultFilter := CleanupPage.GetResultFilter();

                    ApplyCleanupFilters(ExecLog, DateFrom, DateTo, ResultFilter);
                    RecordsToDelete := ExecLog.Count();

                    if RecordsToDelete = 0 then begin
                        Message('За вибраними фільтрами записів для видалення немає.');
                        exit;
                    end;

                    if not Confirm(
                        'Буде видалено %1 записів журналу EDS за період %2–%3 з результатом «%4». Продовжити?',
                        false,
                        RecordsToDelete,
                        DateFrom,
                        DateTo,
                        Format(ResultFilter))
                    then
                        exit;

                    ExecLog.DeleteAll(true);
                    CurrPage.Update(false);

                    Message('Видалено записів журналу EDS: %1.', RecordsToDelete);
                end;
            }

            action(ExportToExcel)
            {
                ApplicationArea = All;
                Caption = 'Експортувати в Excel';
                Image = ExportToExcel;
                ToolTip = 'Експортувати записи журналу EDS у файл Excel за заданими фільтрами.';

                trigger OnAction()
                var
                    FilterPage: Page "SI EDS Exec Log Export Filter";
                    ExcelExport: Codeunit "SI EDS Exec Log Excel Export";
                begin
                    if FilterPage.RunModal() <> Action::OK then
                        exit;

                    ExcelExport.Export(
                        FilterPage.GetDateFrom(),
                        FilterPage.GetDateTo(),
                        FilterPage.GetServiceCode(),
                        FilterPage.GetOperationCode(),
                        FilterPage.GetProviderCode(),
                        FilterPage.GetEndpointCode(),
                        FilterPage.GetResultFilter());
                end;
            }
        }
    }

    local procedure ApplyCleanupFilters(
        var ExecLog: Record "SI EDS Exec. Log";
        DateFrom: Date;
        DateTo: Date;
        ResultFilter: Enum "SI EDS Log Cleanup Filter")
    var
        DateTimeFrom: DateTime;
        DateTimeToExclusive: DateTime;
    begin
        DateTimeFrom := CreateDateTime(DateFrom, 000000T);
        DateTimeToExclusive := CreateDateTime(CalcDate('<+1D>', DateTo), 000000T);

        ExecLog.SetFilter("Started At", '>=%1&<%2', DateTimeFrom, DateTimeToExclusive);

        case ResultFilter of
            ResultFilter::Success:
                ExecLog.SetRange("Result Type", ExecLog."Result Type"::Success);
            ResultFilter::Errors:
                ExecLog.SetFilter("Result Type", '<>%1', ExecLog."Result Type"::Success);
        end;
    end;

}
