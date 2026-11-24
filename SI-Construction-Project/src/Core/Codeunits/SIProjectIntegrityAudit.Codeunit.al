codeunit 60034 "SI Project Integrity Audit"
{
    // CP-08. Read-only diagnostic. No repair, writes or commits.
    // Findings are returned to the caller; the audit never creates a log entry.

    procedure Audit(ProjectNo: Code[20]; var Findings: List of [Text]): Boolean
    var
        Project: Record Job;
        Customer: Record Customer;
        Location: Record Location;
        Site: Record "SI Construction Site";
        OtherSite: Record "SI Construction Site";
        ShipTo: Record "Ship-to Address";
        Readiness: Codeunit "SI Site Delivery Readiness";
        CustomerNo: Code[20];
        ResolvedShipTo: Code[10];
        Reason: Text;
        DefaultCount: Integer;
    begin
        Clear(Findings);
        if not Project.Get(ProjectNo) then begin
            Findings.Add(StrSubstNo('Проєкт %1 не знайдено.', ProjectNo));
            exit(false);
        end;
        if not Project."SI Construction Project" then
            Findings.Add(StrSubstNo('Проєкт %1 не є будівельним проєктом SI.', ProjectNo));

        if Project."Location Code" = '' then
            Findings.Add('У проєкті не визначено Location Code.')
        else
            if not Location.Get(Project."Location Code") then
                Findings.Add(StrSubstNo('Склад %1 не знайдено.', Project."Location Code"));

        if Project."SI Internal Customer No." = '' then
            Findings.Add('У проєкті не визначено внутрішнього Customer.')
        else
            if not Customer.Get(Project."SI Internal Customer No.") then
                Findings.Add(StrSubstNo('Внутрішнього Customer %1 не знайдено.', Project."SI Internal Customer No."))
            else begin
                if Customer."SI Customer Type" <> Customer."SI Customer Type"::"Internal Project" then
                    Findings.Add(StrSubstNo('Customer %1 має некоректний тип.', Customer."No."));
                if Customer."SI Project No." <> ProjectNo then
                    Findings.Add(StrSubstNo('Customer %1 посилається на інший проєкт (%2).', Customer."No.", Customer."SI Project No."));
            end;

        Site.SetRange("Project No.", ProjectNo);
        if Site.FindSet() then
            repeat
                if Site."Default" then begin
                    DefaultCount += 1;
                    if Site.Status <> Site.Status::Active then
                        Findings.Add(StrSubstNo('Основний майданчик %1 неактивний.', Site."Site Code"));
                end;

                if Site."Ship-to Code" = '' then
                    Findings.Add(StrSubstNo('Майданчик %1 не має Ship-to Code.', Site."Site Code"))
                else begin
                    if Project."SI Internal Customer No." <> '' then begin
                        if not ShipTo.Get(Project."SI Internal Customer No.", Site."Ship-to Code") then
                            Findings.Add(StrSubstNo('Майданчик %1: Ship-to %2 відсутній у Customer %3.', Site."Site Code", Site."Ship-to Code", Project."SI Internal Customer No."))
                        else
                            if ShipTo."Location Code" <> Project."Location Code" then
                                Findings.Add(StrSubstNo('Майданчик %1: склад Ship-to %2 не збігається зі складом проєкту.', Site."Site Code", Site."Ship-to Code"));
                    end;
                    OtherSite.Reset();
                    OtherSite.SetRange("Project No.", ProjectNo);
                    OtherSite.SetRange("Ship-to Code", Site."Ship-to Code");
                    OtherSite.SetFilter("Site Code", '<%1', Site."Site Code");
                    if OtherSite.FindFirst() then
                        Findings.Add(StrSubstNo('Майданчики %1 і %2 використовують один Ship-to %3.', OtherSite."Site Code", Site."Site Code", Site."Ship-to Code"));
                end;

                if Site.Status = Site.Status::Active then
                    if not Readiness.TryCheck(ProjectNo, Site."Site Code", CustomerNo, ResolvedShipTo, Reason) then
                        Findings.Add(StrSubstNo('Готовність майданчика %1: %2', Site."Site Code", Reason));
            until Site.Next() = 0;

        if DefaultCount <> 1 then
            Findings.Add(StrSubstNo('Має бути рівно один основний майданчик; знайдено %1.', DefaultCount));
        exit(Findings.Count() = 0);
    end;
}
