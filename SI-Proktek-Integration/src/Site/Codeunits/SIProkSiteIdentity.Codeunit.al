codeunit 57100 "SI Prok Site Identity"
{
    procedure ResolveForOrder(ProdRequest: Record "SI Concrete Prod Request"; var Site: Record "SI Construction Site")
    var
        Reason: Text;
    begin
        if not TryResolveForOrder(ProdRequest, Site, Reason) then
            Error('%1', Reason);
    end;

    // Shared authority for outbound Proktek Orders and inbound Shipment snapshots.
    // Only the explicit Supply Decision Line may select a construction site.
    procedure TryResolveForOrder(ProdRequest: Record "SI Concrete Prod Request"; var Site: Record "SI Construction Site"; var Reason: Text): Boolean
    var
        DecisionHeader: Record "SI Supply Decision Header";
        DecisionLine: Record "SI Supply Decision Line";
    begin
        Clear(Reason);
        Clear(Site);
        if ProdRequest."Project No." = '' then begin
            Reason := StrSubstNo('Заявка %1: проєкт не визначено.', ProdRequest."Entry No.");
            exit(false);
        end;
        if (ProdRequest."Supply Decision No." = '') or (ProdRequest."Supply Decision Line No." = 0) then begin
            Reason := StrSubstNo('Заявка %1: немає точного посилання на рядок рішення забезпечення.', ProdRequest."Entry No.");
            exit(false);
        end;
        if not DecisionHeader.Get(ProdRequest."Supply Decision No.") then begin
            Reason := 'Рішення забезпечення не знайдено.';
            exit(false);
        end;
        if DecisionHeader."Project No." <> ProdRequest."Project No." then begin
            Reason := 'Проєкт рішення забезпечення не збігається з проєктом виробничої заявки.';
            exit(false);
        end;
        if not DecisionLine.Get(ProdRequest."Supply Decision No.", ProdRequest."Supply Decision Line No.") then begin
            Reason := 'Рядок рішення забезпечення не знайдено.';
            exit(false);
        end;
        if DecisionLine."Construction Site Code" = '' then begin
            Reason := 'У рядку рішення забезпечення не визначено будівельний майданчик.';
            exit(false);
        end;
        if not Site.Get(ProdRequest."Project No.", DecisionLine."Construction Site Code") then begin
            Reason := 'Будівельний майданчик із рядка рішення забезпечення не знайдено.';
            exit(false);
        end;
        if Site.Status <> Site.Status::Active then begin
            Reason := 'Будівельний майданчик із рядка рішення забезпечення неактивний.';
            exit(false);
        end;
        exit(true);
    end;

    procedure ResolveDefault(ProjectNo: Code[20]; var Site: Record "SI Construction Site")
    begin
        Site.SetRange("Project No.", ProjectNo);
        Site.SetRange(Default, true);
        Site.SetRange(Status, Site.Status::Active);
        if not Site.FindFirst() then
            Error('Для проєкту %1 не визначено активного основного будмайданчика.', ProjectNo);
    end;

    procedure ResolveByCode(ProjectNo: Code[20]; SiteCode: Code[20]; var Site: Record "SI Construction Site")
    begin
        if not Site.Get(ProjectNo, SiteCode) then
            Error('Будмайданчик %1 не знайдено у проєкті %2.', SiteCode, ProjectNo);
        if Site.Status <> Site.Status::Active then
            Error('Будмайданчик %1 проєкту %2 не активний.', SiteCode, ProjectNo);
    end;

    procedure ExternalCode(Site: Record "SI Construction Site"): Text
    begin
        exit(StrSubstNo('%1-%2', Site."Project No.", Site."Site Code"));
    end;

    procedure ExternalName(Site: Record "SI Construction Site"): Text
    begin
        exit(CopyStr(StrSubstNo('%1 - %2', Site."Project No.", Site.Name), 1, 250));
    end;
}
