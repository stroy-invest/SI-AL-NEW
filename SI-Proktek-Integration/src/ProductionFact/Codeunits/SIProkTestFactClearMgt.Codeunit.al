
codeunit 57181 "SI Prok Test Fact Clear Mgt."
{
    // No COMMIT: all deletions are atomic.
    // Raw JSON archive is deliberately preserved.

    procedure ClearTestFacts(
        DateFrom: Date;
        DateTo: Date;
        FilterByStatus: Boolean;
        FactStatus: Enum "SI Prok Prod Fact Status"): Integer
    begin
        // Backward-compatible entry point.
        exit(ClearFacts(
            DateFrom, DateTo, FilterByStatus, FactStatus,
            Enum::"SI Prok Capture Mode"::Test, 0));
    end;

    procedure ClearFacts(
        DateFrom: Date;
        DateTo: Date;
        FilterByStatus: Boolean;
        FactStatus: Enum "SI Prok Prod Fact Status";
        CaptureMode: Enum "SI Prok Capture Mode";
        ProductionIdFilter: BigInteger): Integer
    var
        Fact: Record "SI Prok Production Fact";
        Material: Record "SI Prok Prod Fact Material";
        EnvironmentInfo: Codeunit "Environment Information";
        MatchCount: Integer;
        DeletedCount: Integer;
    begin
        if (DateFrom = 0D) or (DateTo = 0D) then
            Error('Заповніть обидві дати періоду.');

        if DateFrom > DateTo then
            Error('Дата з не може бути пізнішою за дату по.');

        // Normal facts may only be deleted in Sandbox.
        // This check is server-side, not merely a page restriction.
        if CaptureMode = CaptureMode::Normal then
            if not EnvironmentInfo.IsSandbox() then
                Error(
                    'Очищення звичайних фактів дозволено лише в Sandbox.');

        ApplyFilters(
            Fact, DateFrom, DateTo, FilterByStatus,
            FactStatus, CaptureMode, ProductionIdFilter);

        MatchCount := Fact.Count();
        if MatchCount = 0 then
            exit(0);

        // Lock and re-evaluate the selection before deletion.
        Fact.LockTable();

        ApplyFilters(
            Fact, DateFrom, DateTo, FilterByStatus,
            FactStatus, CaptureMode, ProductionIdFilter);

        MatchCount := Fact.Count();
        if MatchCount = 0 then
            exit(0);

        if not Confirm(
            'Буде безповоротно видалено %1 фактів виробництва (режим: %2, Production ID: %3) за період %4–%5 разом із рядками матеріалів. Архів JSON залишиться без змін. Продовжити?',
            false,
            MatchCount,
            Format(CaptureMode),
            ProductionIdFilter,
            DateFrom,
            DateTo) then
            exit(0);

        if Fact.FindSet(true) then
            repeat
                // Defense in depth: never delete a different mode.
                if Fact."Capture Mode" <> CaptureMode then
                    Error('Режим факту не відповідає режиму очищення.');

                Material.Reset();
                Material.SetRange(
                    "Production Fact Entry No.", Fact."Entry No.");
                Material.DeleteAll(true);

                Fact.Delete(true);
                DeletedCount += 1;
            until Fact.Next() = 0;

        exit(DeletedCount);
    end;

    local procedure ApplyFilters(
        var Fact: Record "SI Prok Production Fact";
        DateFrom: Date;
        DateTo: Date;
        FilterByStatus: Boolean;
        FactStatus: Enum "SI Prok Prod Fact Status";
        CaptureMode: Enum "SI Prok Capture Mode";
        ProductionIdFilter: BigInteger)
    begin
        Fact.Reset();

        Fact.SetRange("Capture Mode", CaptureMode);

        Fact.SetFilter(
            "Production Date/Time",
            '%1..%2',
            CreateDateTime(DateFrom, 000000T),
            CreateDateTime(DateTo, 235959T));

        if FilterByStatus then
            Fact.SetRange(Status, FactStatus);

        if ProductionIdFilter <> 0 then
            Fact.SetRange("Production ID", ProductionIdFilter);
    end;
}
