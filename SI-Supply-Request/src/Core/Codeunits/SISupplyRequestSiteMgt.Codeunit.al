codeunit 61030 "SI Supply Request Site Mgt."
{
    procedure InitializeForProject(RequestNo: Code[20]; ProjectNo: Code[20])
    var
        Site: Record "SI Construction Site";
        RequestSite: Record "SI Supply Request Site";
        HasDefault: Boolean;
    begin
        if RequestNo = '' then
            Error('Не визначено номер заявки.');

        RequestSite.SetRange("Request No.", RequestNo);
        RequestSite.DeleteAll(true);

        if ProjectNo = '' then
            exit;

        Site.SetRange("Project No.", ProjectNo);
        Site.SetRange(Status, Site.Status::Active);
        if not Site.FindSet() then
            Error('Для проєкту %1 немає активних будівельних майданчиків.', ProjectNo);

        repeat
            RequestSite.Init();
            RequestSite."Request No." := RequestNo;
            RequestSite."Site Code" := Site."Site Code";
            RequestSite."Site Name" := Site.Name;
            RequestSite.Selected := Site.Default;
            RequestSite.Insert(true);

            if Site.Default then
                HasDefault := true;
        until Site.Next() = 0;

        if not HasDefault then
            Error('Для проєкту %1 не визначено активний основний будівельний майданчик.', ProjectNo);
    end;

    procedure OpenSelector(RequestNo: Code[20]): Boolean
    var
        SiteSelection: Page "SI Supply Site Selection";
    begin
        if RequestNo = '' then
            Error('Не визначено номер заявки.');

        SiteSelection.SetRequestNo(RequestNo);
        exit(SiteSelection.RunModal() = Action::OK);
    end;

    procedure EnsureSelectedSiteExists(RequestNo: Code[20])
    var
        RequestSite: Record "SI Supply Request Site";
    begin
        RequestSite.SetRange("Request No.", RequestNo);
        RequestSite.SetRange(Selected, true);
        if RequestSite.IsEmpty() then
            Error('Необхідно вибрати хоча б один будівельний майданчик для заявки.');
    end;

    procedure ClearSites(RequestNo: Code[20])
    var
        RequestSite: Record "SI Supply Request Site";
    begin
        RequestSite.SetRange("Request No.", RequestNo);
        RequestSite.DeleteAll(true);
    end;
}
