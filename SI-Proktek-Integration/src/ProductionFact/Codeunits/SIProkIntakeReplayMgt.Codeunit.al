codeunit 57105 "SI Prok Intake Replay Mgt."
{
    procedure Replay(SourceEntryNo: Integer; MakeConflict: Boolean)
    var
        Source: Record "SI Prok Raw API Response";
        Archive: Record "SI Prok Raw API Response";
        Fact: Record "SI Prok Production Fact";
        Worker: Codeunit "SI Prok Fact Intake Worker";
        Canonical: Text;
        Root: JsonObject;
        Token: JsonToken;
        Qty: Decimal;
        Expected: Enum "SI Prok Intake Result";
        LabelText: Text;
    begin
        Source.Get(SourceEntryNo);
        if Source."Capture Mode" <> Source."Capture Mode"::Test then
            Error('Replay дозволено лише для архіву в режимі Test.');
        if Source."Production Fact Entry No." = 0 then
            Error('Архівний запис не має пов’язаного виробничого факту.');
        Fact.Get(Source."Production Fact Entry No.");
        if (Fact."Capture Mode" <> Fact."Capture Mode"::Test) or not Fact.Simulation then
            Error('Replay дозволено лише для симульованих фактів у режимі Test.');
        if Fact."Connection Code" <> Source."Connection Code" then
            Error('Профіль джерела не відповідає профілю факту.');
        if UpperCase(DelChr(Source."Production UUID", '=', '{}')) <>
           UpperCase(DelChr(Format(Fact."Production UUID"), '=', '{}')) then
            Error('Production UUID архіву не відповідає пов’язаному факту.');

        Canonical := Fact.GetCanonicalJson();
        if (Canonical = '') or not Root.ReadFrom(Canonical) then
            Error('Canonical JSON факту відсутній або некоректний.');
        if MakeConflict then begin
            if not Root.Get('quantityM3', Token) or not Token.IsValue() then
                Error('Canonical JSON не містить quantityM3.');
            Qty := Token.AsValue().AsDecimal();
            Root.Replace('quantityM3', Qty + 0.001);
            Root.WriteTo(Canonical);
            Expected := Expected::Conflict;
            LabelText := 'REPLAY-CONFLICT';
        end else begin
            Expected := Expected::Existing;
            LabelText := 'REPLAY-EXISTING';
        end;

        Archive.Init();
        Archive."Connection Code" := Source."Connection Code";
        Archive."API Operation" := CopyStr(LabelText, 1, MaxStrLen(Archive."API Operation"));
        Archive."Production UUID" := Source."Production UUID";
        Archive."Capture Mode" := Source."Capture Mode";
        Archive."Processing Status" := Archive."Processing Status"::Received;
        // Evidence is a copy of the original raw response; the worker consumes
        // the fact's canonical snapshot (or its deliberately mutated test copy).
        Archive.SetRaw(Source.GetRaw());
        Archive.Insert(true);
        Commit(); // Worker requires a durable archive row before Run.

        Worker.SetCanonical(Canonical);
        Worker.SetConfigurationArchive(0);
        if not Worker.Run(Archive) then begin
            Archive.Get(Archive."Entry No.");
            Archive."Processing Status" := Archive."Processing Status"::Error;
            Archive."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Archive."Error Message"));
            Archive.Modify(true);
            Commit();
            Error('Replay завершився помилкою. Архів №%1: %2', Archive."Entry No.", Archive."Error Message");
        end;
        Archive.Get(Archive."Entry No.");
        if Archive."Intake Result" <> Expected then
            Error('Replay №%1: очікували %2, отримали %3. Перевір архів.',
                Archive."Entry No.", Expected, Archive."Intake Result");
        Message('Replay №%1: %2. Факт №%3. Новий виробничий факт не створено.',
            Archive."Entry No.", Archive."Intake Result", Archive."Production Fact Entry No.");
    end;
}
