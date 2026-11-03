codeunit 57181 "SI Prok Test Fact Clear Mgt."
{
    // Deliberately no COMMIT: a failure rolls back all deletions in this action.
    procedure ClearTestFacts(DateFrom: Date; DateTo: Date; FilterByStatus: Boolean; FactStatus: Enum "SI Prok Prod Fact Status"): Integer
    var
        Fact: Record "SI Prok Production Fact";
        Material: Record "SI Prok Prod Fact Material";
        MatchCount: Integer;
        DeletedCount: Integer;
    begin
        if (DateFrom = 0D) or (DateTo = 0D) then
            Error('Заповніть обидві дати періоду.');
        if DateFrom > DateTo then
            Error('Дата з не може бути пізнішою за дату по.');

        ApplyFilters(Fact, DateFrom, DateTo, FilterByStatus, FactStatus);
        MatchCount := Fact.Count();
        if MatchCount = 0 then
            exit(0);

        if not Confirm(
            'Буде безповоротно видалено %1 тестових фактів виробництва та всі їхні рядки матеріалів за період %2–%3. Архів JSON залишиться без змін. Продовжити?',
            false, MatchCount, DateFrom, DateTo) then
            exit(0);

        // Lock before selecting rows. Repeat the Test guard for every record.
        Fact.LockTable();
        ApplyFilters(Fact, DateFrom, DateTo, FilterByStatus, FactStatus);
        if Fact.FindSet(true) then
            repeat
                if Fact."Capture Mode" <> Fact."Capture Mode"::Test then
                    Error('Очищення дозволено лише для тестових фактів.');
                Material.Reset();
                Material.SetRange("Production Fact Entry No.", Fact."Entry No.");
                Material.DeleteAll(true);
                Fact.Delete(true);
                DeletedCount += 1;
            until Fact.Next() = 0;
        exit(DeletedCount);
    end;

    local procedure ApplyFilters(var Fact: Record "SI Prok Production Fact"; DateFrom: Date; DateTo: Date; FilterByStatus: Boolean; FactStatus: Enum "SI Prok Prod Fact Status")
    begin
        Fact.Reset();
        Fact.SetRange("Capture Mode", Fact."Capture Mode"::Test);
        Fact.SetFilter("Production Date/Time", '%1..%2', CreateDateTime(DateFrom, 000000T), CreateDateTime(DateTo, 235959T));
        if FilterByStatus then
            Fact.SetRange(Status, FactStatus);
    end;
}
