codeunit 57100 "SI Prok Site Identity"
{
    procedure ResolveForOrder(ProdRequest: Record "SI Concrete Prod Request"; var Site: Record "SI Construction Site")
    var
        DecisionLine: Record "SI Supply Decision Line";
    begin
        ProdRequest.TestField("Project No.");
        ProdRequest.TestField("Supply Decision No.");
        if ProdRequest."Supply Decision Line No." = 0 then
            Error('Для виробничої потреби %1 не визначено рядок рішення постачання.', ProdRequest."Entry No.");
        if not DecisionLine.Get(ProdRequest."Supply Decision No.", ProdRequest."Supply Decision Line No.") then
            Error('Не знайдено рядок %1 рішення %2.', ProdRequest."Supply Decision Line No.", ProdRequest."Supply Decision No.");
        DecisionLine.TestField("Construction Site Code");
        ResolveByCode(ProdRequest."Project No.", DecisionLine."Construction Site Code", Site);
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
