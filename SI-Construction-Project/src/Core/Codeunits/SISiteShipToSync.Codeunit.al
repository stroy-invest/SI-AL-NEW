codeunit 60028 "SI Site ShipTo Sync"
{
    Permissions = tabledata "Ship-to Address" = rim;

    procedure Sync(var Site: Record "SI Construction Site")
    var
        Project: Record Job;
        ShipTo: Record "Ship-to Address";
        SiteMgt: Codeunit "SI Construction Site Mgt.";
        CustomerMgt: Codeunit "SI Internal Customer Mgt.";
        InternalCustomer: Record Customer;
        EmployeeNo: Code[20];
        Changed: Boolean;
    begin
        Project.Get(Site."Project No.");
        Project.TestField("Location Code");
        CustomerMgt.ValidateInternalSICustomer(Project, InternalCustomer);
        SiteMgt.EnsureSiteShipTo(Site);
        ShipTo.Get(InternalCustomer."No.", Site."Ship-to Code");
        if ShipTo."Location Code" <> Project."Location Code" then begin
            ShipTo.Validate("Location Code", Project."Location Code");
            Changed := true;
        end;
        // Never overwrite a manually selected employee. Only initialize empty contact.
        if (ShipTo."SI Contact Employee No." = '') and (ShipTo.Contact = '') then begin
            EmployeeNo := FindSupervisor(Site);
            if EmployeeNo <> '' then begin
                ShipTo.Validate("SI Contact Employee No.", EmployeeNo);
                Changed := true;
            end;
        end;
        // Legacy reconciliation: the default site's missing address values
        // inherit from the parent project. Never overwrite entered site data.
        // Additional sites have independent delivery addresses.
        if Site."Default" then
            if FillMissingDefaultAddress(Project, ShipTo) then
                Changed := true;
        if Changed then
            ShipTo.Modify(true);
    end;

    local procedure FillMissingDefaultAddress(Project: Record Job; var ShipTo: Record "Ship-to Address"): Boolean
    var
        Changed: Boolean;
    begin
        if (ShipTo."Country/Region Code" = '') and (Project."SI Country/Region Code" <> '') then begin
            ShipTo."Country/Region Code" := Project."SI Country/Region Code";
            Changed := true;
        end;
        if (ShipTo."Post Code" = '') and (Project."SI Post Code" <> '') then begin
            ShipTo."Post Code" := CopyStr(Project."SI Post Code", 1, MaxStrLen(ShipTo."Post Code"));
            Changed := true;
        end;
        if (ShipTo.County = '') and (Project."SI County" <> '') then begin
            ShipTo.County := CopyStr(Project."SI County", 1, MaxStrLen(ShipTo.County));
            Changed := true;
        end;
        if (ShipTo."SI District" = '') and (Project."SI District" <> '') then begin
            ShipTo."SI District" := Project."SI District";
            Changed := true;
        end;
        if (ShipTo.City = '') and (Project."SI City" <> '') then begin
            ShipTo.City := CopyStr(Project."SI City", 1, MaxStrLen(ShipTo.City));
            Changed := true;
        end;
        if (ShipTo.Address = '') and (Project."SI Address" <> '') then begin
            ShipTo.Address := CopyStr(Project."SI Address", 1, MaxStrLen(ShipTo.Address));
            Changed := true;
        end;
        exit(Changed);
    end;

    procedure FindSupervisor(Site: Record "SI Construction Site"): Code[20]
    var
        Assignment: Record "SI Site Assignment";
        Role: Record "SI Project Role";
        Preferred: Code[20];
    begin
        Assignment.SetRange("Project No.", Site."Project No.");
        Assignment.SetRange("Site Code", Site."Site Code");
        Assignment.SetFilter("Employee No.", '<>%1', '');
        if Assignment.FindSet() then
            repeat
                if Role.Get(Assignment."Role Code") then
                    if (Role.Purpose = Role.Purpose::SiteSupervisor) and Role.Active and
                       ((Assignment."Valid From" = 0D) or (Assignment."Valid From" <= WorkDate())) and
                       ((Assignment."Valid To" = 0D) or (Assignment."Valid To" >= WorkDate())) then begin
                        if Assignment.Primary then
                            exit(Assignment."Employee No.");
                        if Preferred = '' then
                            Preferred := Assignment."Employee No.";
                    end;
            until Assignment.Next() = 0;
        exit(Preferred);
    end;
}
