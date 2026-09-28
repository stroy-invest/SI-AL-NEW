codeunit 50432 "SI EDS Exec Log Excel Export"
{
    procedure Export(
        DateFrom: Date;
        DateTo: Date;
        ServiceCode: Code[50];
        OperationCode: Code[50];
        ProviderCode: Code[50];
        EndpointCode: Code[50];
        ResultFilter: Enum "SI EDS Exec Log Result Filter")
    var
        ExecLog: Record "SI EDS Exec. Log";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        RowCount: Integer;
        SheetNameLbl: Label 'EDS Exec Log';
        FileNameLbl: Label 'EDS_Execution_Log_%1.xlsx';
        NoDataErr: Label 'За заданими фільтрами записів журналу EDS не знайдено.';
    begin
        ApplyFilters(ExecLog, DateFrom, DateTo, ServiceCode, OperationCode, ProviderCode, EndpointCode, ResultFilter);

        if ExecLog.IsEmpty() then
            Error(NoDataErr);

        AddHeader(TempExcelBuffer, ExecLog);

        if ExecLog.FindSet() then
            repeat
                AddDataRow(TempExcelBuffer, ExecLog);
                RowCount += 1;
            until ExecLog.Next() = 0;

        TempExcelBuffer.CreateNewBook(SheetNameLbl);
        TempExcelBuffer.WriteSheet(SheetNameLbl, CompanyName, UserId);
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.SetFriendlyFilename(StrSubstNo(FileNameLbl, Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2>_<Hours24,2><Minutes,2><Seconds,2>')));
        TempExcelBuffer.OpenExcel();
    end;

    local procedure ApplyFilters(
        var ExecLog: Record "SI EDS Exec. Log";
        DateFrom: Date;
        DateTo: Date;
        ServiceCode: Code[50];
        OperationCode: Code[50];
        ProviderCode: Code[50];
        EndpointCode: Code[50];
        ResultFilter: Enum "SI EDS Exec Log Result Filter")
    var
        DateTimeFrom: DateTime;
        DateTimeToExclusive: DateTime;
    begin
        if DateFrom <> 0D then
            DateTimeFrom := CreateDateTime(DateFrom, 000000T);
        if DateTo <> 0D then
            DateTimeToExclusive := CreateDateTime(DateTo + 1, 000000T);

        if (DateFrom <> 0D) and (DateTo <> 0D) then
            ExecLog.SetFilter("Started At", '>=%1&<%2', DateTimeFrom, DateTimeToExclusive)
        else
            if DateFrom <> 0D then
                ExecLog.SetFilter("Started At", '>=%1', DateTimeFrom)
            else
                if DateTo <> 0D then
                    ExecLog.SetFilter("Started At", '<%1', DateTimeToExclusive);

        if ServiceCode <> '' then
            ExecLog.SetRange("Service Code", ServiceCode);
        if OperationCode <> '' then
            ExecLog.SetRange("Operation Code", OperationCode);
        if ProviderCode <> '' then
            ExecLog.SetRange("Provider Code", ProviderCode);
        if EndpointCode <> '' then
            ExecLog.SetRange("Endpoint Code", EndpointCode);

        ApplyResultFilter(ExecLog, ResultFilter);
    end;

    local procedure ApplyResultFilter(var ExecLog: Record "SI EDS Exec. Log"; ResultFilter: Enum "SI EDS Exec Log Result Filter")
    begin
        case ResultFilter of
            ResultFilter::All:
                exit;
            ResultFilter::Undefined:
                ExecLog.SetRange("Result Type", ExecLog."Result Type"::Undefined);
            ResultFilter::Success:
                ExecLog.SetRange("Result Type", ExecLog."Result Type"::Success);
            ResultFilter::"Business Not Found":
                ExecLog.SetRange("Result Type", ExecLog."Result Type"::"Business Not Found");
            ResultFilter::"Business Rejected":
                ExecLog.SetRange("Result Type", ExecLog."Result Type"::"Business Rejected");
            ResultFilter::"Technical Failure":
                ExecLog.SetRange("Result Type", ExecLog."Result Type"::"Technical Failure");
            ResultFilter::"Authentication Failure":
                ExecLog.SetRange("Result Type", ExecLog."Result Type"::"Authentication Failure");
            ResultFilter::"Rate Limited":
                ExecLog.SetRange("Result Type", ExecLog."Result Type"::"Rate Limited");
            ResultFilter::"Invalid Response":
                ExecLog.SetRange("Result Type", ExecLog."Result Type"::"Invalid Response");
        end;
    end;

    local procedure AddHeader(var TempExcelBuffer: Record "Excel Buffer" temporary; ExecLog: Record "SI EDS Exec. Log")
    begin
        TempExcelBuffer.NewRow();
        AddTextColumn(TempExcelBuffer, ExecLog.FieldCaption("Entry No."), true);
        AddTextColumn(TempExcelBuffer, ExecLog.FieldCaption("Started At"), true);
        AddTextColumn(TempExcelBuffer, ExecLog.FieldCaption("Service Code"), true);
        AddTextColumn(TempExcelBuffer, ExecLog.FieldCaption("Operation Code"), true);
        AddTextColumn(TempExcelBuffer, ExecLog.FieldCaption("Provider Code"), true);
        AddTextColumn(TempExcelBuffer, ExecLog.FieldCaption("Endpoint Code"), true);
        AddTextColumn(TempExcelBuffer, ExecLog.FieldCaption("Request URL"), true);
        AddTextColumn(TempExcelBuffer, ExecLog.FieldCaption("HTTP Status Code"), true);
        AddTextColumn(TempExcelBuffer, ExecLog.FieldCaption("Result Type"), true);
        AddTextColumn(TempExcelBuffer, ExecLog.FieldCaption("Duration (ms)"), true);
        AddTextColumn(TempExcelBuffer, ExecLog.FieldCaption("Error Code"), true);
        AddTextColumn(TempExcelBuffer, ExecLog.FieldCaption("Error Message"), true);
        AddTextColumn(TempExcelBuffer, ExecLog.FieldCaption("Correlation ID"), true);
    end;

    local procedure AddDataRow(var TempExcelBuffer: Record "Excel Buffer" temporary; ExecLog: Record "SI EDS Exec. Log")
    begin
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddColumn(ExecLog."Entry No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
        AddTextColumn(TempExcelBuffer, Format(ExecLog."Started At"), false);
        AddTextColumn(TempExcelBuffer, ExecLog."Service Code", false);
        AddTextColumn(TempExcelBuffer, ExecLog."Operation Code", false);
        AddTextColumn(TempExcelBuffer, ExecLog."Provider Code", false);
        AddTextColumn(TempExcelBuffer, ExecLog."Endpoint Code", false);
        AddTextColumn(TempExcelBuffer, ExecLog."Request URL", false);
        TempExcelBuffer.AddColumn(ExecLog."HTTP Status Code", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
        AddTextColumn(TempExcelBuffer, Format(ExecLog."Result Type"), false);
        TempExcelBuffer.AddColumn(ExecLog."Duration (ms)", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
        AddTextColumn(TempExcelBuffer, ExecLog."Error Code", false);
        AddTextColumn(TempExcelBuffer, ExecLog."Error Message", false);
        AddTextColumn(TempExcelBuffer, Format(ExecLog."Correlation ID"), false);
    end;

    local procedure AddTextColumn(var TempExcelBuffer: Record "Excel Buffer" temporary; Value: Text; IsBold: Boolean)
    begin
        TempExcelBuffer.AddColumn(Value, false, '', IsBold, false, false, '', TempExcelBuffer."Cell Type"::Text);
    end;
}
