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
            EnsureSiteShipTo(Site);
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
        EnsureSiteShipTo(Site);
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
        EnsureSiteShipTo(NewSite);

        // Never return an in-memory buffer that was used for INSERT. Re-read the
        // persisted entity explicitly by the complete composite primary key.
        Clear(CreatedSite);
        if not CreatedSite.Get(ProjectNo, NewSiteCode) then
            Error('Створений будівельний майданчик %1 проєкту %2 не знайдено.', NewSiteCode, ProjectNo);
    end;

    procedure EnsureSiteShipTo(var Site: Record "SI Construction Site")
    var
        Project: Record Job;
        InternalCustomer: Record Customer;
        InternalCustomerMgt: Codeunit "SI Internal Customer Mgt.";
        ShipTo: Record "Ship-to Address";
        Candidate: Code[10];
        SequenceNo: Integer;
    begin
        Project.Get(Site."Project No.");
        InternalCustomerMgt.ValidateInternalSICustomer(Project, InternalCustomer);

        if Site."Ship-to Code" <> '' then begin
            if not ShipTo.Get(InternalCustomer."No.", Site."Ship-to Code") then
                Error('Адресу доставки %1 майданчика %2 не знайдено.', Site."Ship-to Code", Site."Site Code");
            if ShipTo."Location Code" <> Project."Location Code" then begin
                Project.TestField("Location Code");
                ShipTo.Validate("Location Code", Project."Location Code");
                ShipTo.Modify(true);
            end;
            exit;
        end;

        // Use a generated 10-character key, independent of Site Code[20].
        // Do not reuse any Ship-to record, including one created outside this module.
        for SequenceNo := 1 to 9999 do begin
            Candidate := CopyStr(StrSubstNo('SITE-%1', PadNumber(SequenceNo, 4)), 1, 10);
            if not ShipTo.Get(InternalCustomer."No.", Candidate) then
                break;
        end;
        if SequenceNo > 9999 then
            Error('Не вдалося сформувати код адреси доставки для проєкту %1.', Site."Project No.");

        ShipTo.Init();
        ShipTo.Validate("Customer No.", InternalCustomer."No.");
        ShipTo.Validate(Code, Candidate);
        ShipTo.Validate(Name, CopyStr(Site.Name, 1, MaxStrLen(ShipTo.Name)));
        // One-way transfer of legacy site address fields on initial creation.
        ShipTo.Address := CopyStr(Site.Address, 1, MaxStrLen(ShipTo.Address));
        ShipTo."Address 2" := CopyStr(Site."Address 2", 1, MaxStrLen(ShipTo."Address 2"));
        ShipTo.City := CopyStr(Site.City, 1, MaxStrLen(ShipTo.City));
        ShipTo."Post Code" := CopyStr(Site."Post Code", 1, MaxStrLen(ShipTo."Post Code"));
        ShipTo.County := CopyStr(Site.County, 1, MaxStrLen(ShipTo.County));
        ShipTo."Country/Region Code" := Site."Country/Region Code";
        Project.TestField("Location Code");
        ShipTo.Validate("Location Code", Project."Location Code");
        ShipTo.Insert(true);
        Site."Ship-to Code" := Candidate;
        Site.Modify(true);
    end;

    procedure OpenSiteShipTo(Site: Record "SI Construction Site")
    var
        Project: Record Job;
        InternalCustomer: Record Customer;
        InternalCustomerMgt: Codeunit "SI Internal Customer Mgt.";
        ShipTo: Record "Ship-to Address";
    begin
        Project.Get(Site."Project No.");
        InternalCustomerMgt.ValidateInternalSICustomer(Project, InternalCustomer);
        Site.TestField("Ship-to Code");
        ShipTo.Get(InternalCustomer."No.", Site."Ship-to Code");
        Page.RunModal(Page::"SI Site Delivery Address", ShipTo);
    end;

    procedure MigrateAllSiteAddresses(): Integer
    var
        Site: Record "SI Construction Site";
        Migrated: Integer;
    begin
        if Site.FindSet() then
            repeat
                if Site."Ship-to Code" = '' then begin
                    EnsureSiteShipTo(Site);
                    Migrated += 1;
                end;
            until Site.Next() = 0;
        exit(Migrated);
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
