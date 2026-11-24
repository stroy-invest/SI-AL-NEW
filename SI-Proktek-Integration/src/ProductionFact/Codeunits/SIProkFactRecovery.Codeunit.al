codeunit 57992 "SI Prok Fact Recovery"
{
    procedure RecoverArchive(Source: Record "SI Prok Raw API Response")
    var
        Config: Record "SI Prok Raw API Response";
        Attempt: Record "SI Prok Raw API Response";
        Fact: Record "SI Prok Production Fact";
        Req: Record "SI Concrete Prod Request";
        ExportMgt: Codeunit "SI Prok Production Export Mgt.";
        Worker: Codeunit "SI Prok Recovery Worker";
        Codes: Dictionary of [Text, Text];
        Uuids: Dictionary of [Text, Text];
        Names: Dictionary of [Text, Text];
        Canonical: Text;
        Why: Text[250];
        Uuid: Guid;
    begin
        Source.Get(Source."Entry No.");
        if UpperCase(Source."API Operation") <> 'GETPRODUCTIONDETAILS' then
            Error('Виберіть архів GetProductionDetails.');
        if not Evaluate(Uuid, Source."Production UUID") then
            Error('Некоректний Production UUID.');
        Fact.SetRange("Production UUID", Uuid);
        if Fact.FindFirst() then begin
            if (Fact."Connection Code" <> Source."Connection Code") or (Fact."Capture Mode" <> Source."Capture Mode") then
                Error('Конфлікт походження факту.');
            RecoverFact(Fact);
            exit;
        end;
        Canonical := Source.GetRecoveryCanonical();
        if Canonical = '' then begin
            Config.SetRange("Connection Code", Source."Connection Code");
            Config.SetRange("Capture Mode", Source."Capture Mode");
            Config.SetRange("API Operation", 'GETMATERIALSCONFIG');
            Config.SetFilter("Entry No.", '<%1', Source."Entry No.");
            if not Config.FindLast() then
                Error('Не знайдено архів конфігурації матеріалів перед фактом.');
            if not Confirm('Використати архів конфігурації матеріалів №%1 від %2?', false, Config."Entry No.", Config."Received At") then
                exit;
            if not ExportMgt.TryParseCaptureMaterialConfigResponse(Config.GetRaw(), Codes, Uuids, Names) then
                Error('Не вдалося прочитати конфігурацію матеріалів: %1', GetLastErrorText());
            ExportMgt.BuildCaptureCanonicalFromDetails(Source.GetRaw(), Source."Production UUID", Codes, Uuids, Names, Canonical);
        end;
        if not SelectRequest(Req, Why) then exit;
        Attempt.Init();
        Attempt."Connection Code" := Source."Connection Code";
        Attempt."Capture Mode" := Source."Capture Mode";
        Attempt."API Operation" := 'RECOVERY';
        Attempt."Production UUID" := Source."Production UUID";
        Attempt."Config Archive Entry No." := Source."Config Archive Entry No.";
        if Config."Entry No." <> 0 then
            Attempt."Config Archive Entry No." := Config."Entry No.";
        Attempt.SetRaw(Source.GetRaw());
        Attempt.SetRecoveryCanonical(Canonical);
        Attempt."Error Message" := CopyStr(StrSubstNo('Джерело №%1; заявка №%2; %3', Source."Entry No.", Req."Entry No.", Why), 1, MaxStrLen(Attempt."Error Message"));
        Attempt.Insert(true);
        Commit();
        Worker.Setup(Canonical, Req."Entry No.", Why);
        if not Worker.Run(Attempt) then begin
            Attempt.Get(Attempt."Entry No.");
            Attempt."Processing Status" := Attempt."Processing Status"::Error;
            Attempt."Error Message" := CopyStr(Attempt."Error Message" + ' ' + GetLastErrorText(), 1, MaxStrLen(Attempt."Error Message"));
            Attempt.Modify(true);
            Commit();
            Error('%1', Attempt."Error Message");
        end;
        Message('Факт відновлено. Архів №%1.', Attempt."Entry No.");
    end;

    procedure RecoverFact(Fact: Record "SI Prok Production Fact")
    var Req: Record "SI Concrete Prod Request"; Why: Text[250];
    begin
        if not SelectRequest(Req, Why) then exit;
        Apply(Fact, Req."Entry No.", Why, 0);
        Message('Факт №%1 прив’язано до заявки №%2.', Fact."Entry No.", Req."Entry No.");
    end;

    local procedure SelectRequest(var Req: Record "SI Concrete Prod Request"; var Why: Text[250]): Boolean
    var Dialog: Page "SI Prok Recovery Reason"; Lookup: Page "SI Concrete Prod Req List";
    begin
        Req.SetFilter("Proktek Order ID", '>0');
        Lookup.SetTableView(Req);
        Lookup.LookupMode(true);
        if Lookup.RunModal() <> Action::LookupOK then exit(false);
        Lookup.GetRecord(Req);
        if Dialog.RunModal() <> Action::OK then exit(false);
        Why := Dialog.GetReason();
        if DelChr(Why, '=', ' ') = '' then Error('Вкажіть причину ручного зіставлення.');
        exit(Confirm('Прив’язати факт до заявки №%1 (%2), Proktek Order ID %3?', false, Req."Entry No.", Req."Source No.", Req."Proktek Order ID"));
    end;

    procedure Apply(var Fact: Record "SI Prok Production Fact"; RequestNo: Integer; Why: Text[250]; RawNo: Integer)
    var
        Req: Record "SI Concrete Prod Request";
        Revision: Record "SI Concrete Recipe Revision";
        Shipment: Record "SI Prok Shipment";
        JournalLink: Record "SI Prok Journal Link";
        PostingAttempt: Record "SI Prok Posting Attempt";
        Lifecycle: Codeunit "SI Prok Fact Lifecycle";
    begin
        Fact.LockTable();
        Fact.Get(Fact."Entry No.");
        Req.Get(RequestNo);
        if (Req."Proktek Order ID" <= 0) or IsNullGuid(Req."Proktek Order UUID") then
            Error('Заявка не має коректного Proktek Order.');
        // Order context is not a uniqueness constraint: many production facts may share one order.
        // Existing matching context and absent order IDs (including -1) are valid for recovery.
        if ((Fact."Prod. Request Entry No." <> 0) and (Fact."Prod. Request Entry No." <> RequestNo)) or
           (not IsNullGuid(Fact."Order UUID") and (Fact."Order UUID" <> Req."Proktek Order UUID")) or
           ((Fact."Order ID" > 0) and (Fact."Order ID" <> Req."Proktek Order ID")) then
            Error('Поточний факт містить контекст іншого замовлення.');
        if (Fact."Item No." <> Req."Item No.") or (Fact."Variant Code" <> Req."Variant Code") then
            Error('Бетон факту не відповідає вибраній заявці.');
        Revision.Get(Fact."Recipe No.", Fact."Recipe Revision No.");
        if Revision."Recipe Purpose" <> Revision."Recipe Purpose"::Commercial then
            Error('Рецептура факту не товарна.');
        Shipment.LockTable();
        Shipment.SetRange("Production UUID", Fact."Production UUID");
        if not Shipment.IsEmpty() then Error('Факт уже має Shipment. Потрібне окреме узгодження документів.');
        Shipment.Reset();
        Shipment.SetRange("Production Fact Entry No.", Fact."Entry No.");
        if not Shipment.IsEmpty() then Error('Факт уже має Shipment.');
        JournalLink.SetRange("Production UUID", Fact."Production UUID");
        if not JournalLink.IsEmpty() then Error('Факт має облікові зв’язки.');
        JournalLink.Reset();
        JournalLink.SetRange("Fact Entry No.", Fact."Entry No.");
        if not JournalLink.IsEmpty() then Error('Факт має облікові зв’язки.');
        PostingAttempt.SetRange("Production UUID", Fact."Production UUID");
        if not PostingAttempt.IsEmpty() then Error('Факт має спробу проведення.');
        if (Fact."BC Prod. Order No." <> '') or (Fact."Accounting Document No." <> '') then
            Error('Факт має виробничі або облікові документи.');
        Fact."Order UUID" := Req."Proktek Order UUID";
        Fact."Order ID" := Req."Proktek Order ID";
        Fact."Ordered Quantity M3" := Req.Quantity;
        Clear(Fact."Internal Customer No.");
        Fact."Recovery At" := CurrentDateTime();
        Fact."Recovery By" := CopyStr(UserId(), 1, MaxStrLen(Fact."Recovery By"));
        Fact."Recovery Reason" := Why;
        Fact."Recovery Raw Entry No." := RawNo;
        Fact.Modify(true);
        Lifecycle.AfterImported(Fact."Entry No.");
        Fact.Get(Fact."Entry No.");
        if Fact."BC Binding Status" = Fact."BC Binding Status"::Blocked then
            Error('%1', Fact."BC Binding Diagnostics");
        if Fact."Prod. Request Entry No." <> RequestNo then
            Error('Штатний pipeline не підтвердив зв’язок із вибраною заявкою.');
    end;
}
