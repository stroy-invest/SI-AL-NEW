codeunit 61052 "SI Proc. Plan Trace Context"
{
    SingleInstance = true;

    procedure BeginCapture(TemplateName: Code[10]; BatchName: Code[10])
    begin
        Clear(ForecastProfileLines);
        Clear(ForecastEntryNos);
        Active := true;
        ActiveTemplate := TemplateName;
        ActiveBatch := BatchName;
    end;

    procedure EndCapture()
    begin
        Active := false;
        ActiveTemplate := '';
        ActiveBatch := '';
        Clear(ForecastProfileLines);
        Clear(ForecastEntryNos);
    end;

    procedure IsActive(): Boolean
    begin
        exit(Active);
    end;

    procedure IsActiveFor(TemplateName: Code[10]; BatchName: Code[10]): Boolean
    begin
        exit(Active and (TemplateName = ActiveTemplate) and (BatchName = ActiveBatch));
    end;

    procedure GetActiveWorksheet(var TemplateName: Code[10]; var BatchName: Code[10]): Boolean
    begin
        if not Active then
            exit(false);
        TemplateName := ActiveTemplate;
        BatchName := ActiveBatch;
        exit(true);
    end;

    procedure BeginForecastProfile(ProfileLineNo: Integer)
    var
        i: Integer;
    begin
        if not Active then
            exit;

        // Inventory Profile line numbers are reused between item/variant planning
        // contexts. Remove the previous meaning before registering the current
        // aggregated forecast demand.
        for i := ForecastProfileLines.Count downto 1 do
            if ForecastProfileLines.Get(i) = ProfileLineNo then begin
                ForecastProfileLines.RemoveAt(i);
                ForecastEntryNos.RemoveAt(i);
            end;
    end;

    procedure RegisterForecastProfileEntry(ProfileLineNo: Integer; ForecastEntryNo: Integer)
    begin
        if not Active then
            exit;

        ForecastProfileLines.Add(ProfileLineNo);
        ForecastEntryNos.Add(ForecastEntryNo);
    end;

    procedure GetForecastEntries(ProfileLineNo: Integer; var Entries: List of [Integer])
    var
        i: Integer;
    begin
        Clear(Entries);
        if not Active then
            exit;

        for i := 1 to ForecastProfileLines.Count do
            if ForecastProfileLines.Get(i) = ProfileLineNo then
                Entries.Add(ForecastEntryNos.Get(i));
    end;

    var
        Active: Boolean;
        ActiveTemplate: Code[10];
        ActiveBatch: Code[10];
        ForecastProfileLines: List of [Integer];
        ForecastEntryNos: List of [Integer];
}
