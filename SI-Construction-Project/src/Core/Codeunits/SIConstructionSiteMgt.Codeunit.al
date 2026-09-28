codeunit 60003 "SI Construction Site Mgt."
{
    Permissions =
        tabledata "SI Construction Site" = rim;

    procedure EnsureDefaultSite(Project: Record Job; var Site: Record "SI Construction Site")
    begin
        Project.TestField("No.");
        if not Project."SI Construction Project" then
            Error('Проєкт %1 не є будівельним проєктом SI.', Project."No.");

        if FindDefaultSite(Project."No.", Site) then begin
            if Site.Status <> Site.Status::Active then
                Error('Основний будівельний майданчик %1 проєкту %2 не є активним.', Site."Site Code", Project."No.");
            exit;
        end;

        Site.Reset();
        Site.Init();
        Site.Validate("Project No.", Project."No.");
        Site."Site Code" := GetNextSiteCode(Project."No.");
        Site.Name := 'Основний буд. майданчик';
        Site.Status := Site.Status::Active;
        Site."Default" := true;
        Site.Insert(true);
    end;

    procedure CreateSite(ProjectNo: Code[20]; SiteName: Text[100]; SiteDescription: Text[250]; var CreatedSite: Record "SI Construction Site")
    var
        Project: Record Job;
        NewSite: Record "SI Construction Site";
        NewSiteCode: Code[20];
    begin
        Project.Get(ProjectNo);
        if not Project."SI Construction Project" then
            Error('Проєкт %1 не є будівельним проєктом SI.', ProjectNo);
        if SiteName = '' then
            Error('Вкажіть назву будівельного майданчика.');

        // Creation must never reuse the caller/page record buffer. Build the new
        // entity in an isolated local record and address it by its full PK.
        Clear(NewSite);
        NewSite.Init();
        NewSite.Validate("Project No.", ProjectNo);
        NewSiteCode := GetNextSiteCode(ProjectNo);
        NewSite."Site Code" := NewSiteCode;
        NewSite.Name := SiteName;
        NewSite.Description := SiteDescription;
        NewSite."Default" := false;
        NewSite.Status := NewSite.Status::Active;
        NewSite.Insert(true);

        // Never return an in-memory buffer that was used for INSERT. Re-read the
        // persisted entity explicitly by the complete composite primary key.
        Clear(CreatedSite);
        if not CreatedSite.Get(ProjectNo, NewSiteCode) then
            Error('Створений будівельний майданчик %1 проєкту %2 не знайдено.', NewSiteCode, ProjectNo);
    end;

    procedure FindDefaultSite(ProjectNo: Code[20]; var Site: Record "SI Construction Site"): Boolean
    begin
        Site.Reset();
        Site.SetRange("Project No.", ProjectNo);
        Site.SetRange("Default", true);
        exit(Site.FindFirst());
    end;

    procedure SetDefaultSite(var Site: Record "SI Construction Site")
    var
        CurrentDefault: Record "SI Construction Site";
    begin
        Site.TestField("Project No.");
        if Site.Status <> Site.Status::Active then
            Error('Основним може бути лише активний будівельний майданчик.');

        CurrentDefault.SetRange("Project No.", Site."Project No.");
        CurrentDefault.SetRange("Default", true);
        if CurrentDefault.FindFirst() then
            if CurrentDefault."Site Code" <> Site."Site Code" then begin
                CurrentDefault."Default" := false;
                CurrentDefault.Modify(true);
            end;

        if not Site."Default" then begin
            Site."Default" := true;
            Site.Modify(true);
        end;
    end;

    procedure ValidateProjectSites(Project: Record Job)
    var
        Site: Record "SI Construction Site";
        DefaultCount: Integer;
    begin
        Project.TestField("No.");
        if not Project."SI Construction Project" then
            exit;

        Site.SetRange("Project No.", Project."No.");
        Site.SetRange("Default", true);
        if Site.FindSet() then
            repeat
                DefaultCount += 1;
                if Site.Status <> Site.Status::Active then
                    Error('Основний будівельний майданчик %1 проєкту %2 не є активним.', Site."Site Code", Project."No.");
            until Site.Next() = 0;

        if DefaultCount <> 1 then
            Error('Проєкт %1 повинен мати рівно один активний основний будівельний майданчик. Знайдено: %2.', Project."No.", DefaultCount);
    end;

    procedure MigrateProjectForemenToDefaultSite(Project: Record Job)
    var
        DefaultSite: Record "SI Construction Site";
        ProjectAssignment: Record "SI Project Assignment";
        SiteAssignment: Record "SI Site Assignment";
        LastSiteAssignment: Record "SI Site Assignment";
        AssignmentMgt: Codeunit "SI Project Assignment Mgt.";
        NextLineNo: Integer;
    begin
        if not Project."SI Construction Project" then
            exit;

        AssignmentMgt.EnsureDefaultRoles();
        if not FindDefaultSite(Project."No.", DefaultSite) then
            exit;

        ProjectAssignment.SetRange("Project No.", Project."No.");
        ProjectAssignment.SetRange("Role Code", 'FOREMAN');
        while ProjectAssignment.FindFirst() do begin
            LastSiteAssignment.Reset();
            LastSiteAssignment.SetRange("Project No.", Project."No.");
            LastSiteAssignment.SetRange("Site Code", DefaultSite."Site Code");
            if LastSiteAssignment.FindLast() then
                NextLineNo := LastSiteAssignment."Line No." + 10000
            else
                NextLineNo := 10000;

            SiteAssignment.Init();
            SiteAssignment."Project No." := ProjectAssignment."Project No.";
            SiteAssignment."Site Code" := DefaultSite."Site Code";
            SiteAssignment."Line No." := NextLineNo;
            SiteAssignment."Role Code" := 'FOREMAN';
            SiteAssignment."Employee No." := ProjectAssignment."Employee No.";
            SiteAssignment."Valid From" := ProjectAssignment."Valid From";
            SiteAssignment."Valid To" := ProjectAssignment."Valid To";
            SiteAssignment.Primary := ProjectAssignment.Primary;
            SiteAssignment.Insert(true);

            ProjectAssignment.Delete(true);
        end;
    end;

    procedure GetNextSiteCode(ProjectNo: Code[20]): Code[20]
    var
        Site: Record "SI Construction Site";
        Candidate: Code[20];
        SequenceNo: Integer;
    begin
        for SequenceNo := 1 to 9999 do begin
            Candidate := CopyStr(StrSubstNo('SITE-%1', PadNumber(SequenceNo, 3)), 1, MaxStrLen(Site."Site Code"));
            if not Site.Get(ProjectNo, Candidate) then
                exit(Candidate);
        end;

        Error('Для проєкту %1 не вдалося сформувати новий код будівельного майданчика.', ProjectNo);
    end;

    local procedure PadNumber(Number: Integer; Length: Integer): Text
    var
        Value: Text;
    begin
        Value := Format(Number, 0, '<Integer>');
        while StrLen(Value) < Length do
            Value := '0' + Value;
        exit(Value);
    end;
}
