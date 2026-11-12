codeunit 60032 "SI Project Reconcile"
{
    Permissions = tabledata "SI Project Reconcile Log" = rim;

    procedure RunProject(ProjectNo: Code[20]; RunId: Guid)
    var
        Project: Record Job;
        Site: Record "SI Construction Site";
        ErrorText: Text;
    begin
        Project.Get(ProjectNo);
        ClearLastError();
        if not Codeunit.Run(Codeunit::"SI Project Repair Runner", Project) then begin
            ErrorText := GetLastErrorText();
            WriteLog(RunId, ProjectNo, '', false, ErrorText);
            Commit(); // Close the log transaction before processing another project.
            exit;
        end;
        WriteLog(RunId, ProjectNo, '', true, 'Перевірено основні зв’язки проєкту.');
        Commit(); // Codeunit.Run(Boolean) requires no active write transaction.
        Site.SetRange("Project No.", ProjectNo);
        if Site.FindSet() then
            repeat
                ClearLastError();
                if Codeunit.Run(Codeunit::"SI Site Reconcile Runner", Site) then
                    WriteLog(RunId, ProjectNo, Site."Site Code", true, 'Адресу доставки та склад перевірено.')
                else begin
                    ErrorText := GetLastErrorText();
                    WriteLog(RunId, ProjectNo, Site."Site Code", false, ErrorText);
                end;
                Commit(); // Each site and its log are finalized before the next runner.
            until Site.Next() = 0;
    end;

    local procedure WriteLog(RunId: Guid; ProjectNo: Code[20]; SiteCode: Code[20]; Success: Boolean; Details: Text)
    var
        Log: Record "SI Project Reconcile Log";
    begin
        Log.Init();
        Log."Run ID" := RunId;
        Log."Created At" := CurrentDateTime();
        Log."Project No." := ProjectNo;
        Log."Site Code" := SiteCode;
        if Success then
            Log.Result := Log.Result::Success
        else
            Log.Result := Log.Result::Error;
        Log.Details := CopyStr(Details, 1, MaxStrLen(Log.Details));
        Log.Insert(true);
    end;
}
