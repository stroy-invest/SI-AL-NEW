codeunit 57197 "SI Prok Shipment Snapshot"
{
    // Populate only open documents. Never silently refresh snapshots on viewing.
    procedure InitializeOpen(var Shipment: Record "SI Prok Shipment"; ResolveOperator: Boolean)
    var
        Site: Record "SI Construction Site";
        ItemRec: Record Item;
        Variant: Record "Item Variant";
        Employee: Record Employee;
        EmployeeNo: Code[20];
        AsOfDate: Date;
        SiteReady: Boolean;
        SiteIssue: Text;
        AddressIssue: Text;
        AddressText: Text[250];
    begin
        if Shipment.Status <> Shipment.Status::Open then
            exit;

        // Preserve the first saved product label; never show a technical code instead.
        if Shipment."Concrete Description" = '' then begin
            if (Shipment."Variant Code" <> '') and
               Variant.Get(Shipment."Item No.", Shipment."Variant Code") and
               (Variant.Description <> '') then
                Shipment."Concrete Description" := CopyStr(Variant.Description, 1, MaxStrLen(Shipment."Concrete Description"))
            else
                if ItemRec.Get(Shipment."Item No.") then
                    Shipment."Concrete Description" := CopyStr(ItemRec.Description, 1, MaxStrLen(Shipment."Concrete Description"));
        end;

        // The outbound Proktek Order uses the Supply Decision Line's site.
        // Reuse that exact authority here; allocation is an integrity check,
        // not an alternative source of the delivery site.
        SiteReady := TryResolveShipmentSite(Shipment, Site, SiteIssue);
        if SiteReady then begin
            if (Shipment."Delivery Site Code" <> '') and
               ((Shipment."Delivery Site Code" <> Site."Site Code") or
                (Shipment."Delivery Project No." <> Site."Project No.")) then begin
                SiteReady := false;
                SiteIssue := 'Збережений майданчик Shipment суперечить підтвердженому рядку рішення.';
            end else begin
                Shipment."Delivery Project No." := Site."Project No.";
                Shipment."Delivery Site Code" := Site."Site Code";
                Shipment."Delivery Site Name" := Site.Name;
                if Shipment."Delivery Address" = '' then
                    if TryGetSiteAddress(Site, AddressText, AddressIssue) then
                        Shipment."Delivery Address" := AddressText;
            end;
        end;

        if Shipment."Shipment Date/Time" <> 0DT then
            AsOfDate := DT2Date(Shipment."Shipment Date/Time")
        else
            AsOfDate := WorkDate();

        if ResolveOperator and (Shipment."Shipped By Employee No." = '') then begin
            EmployeeNo := FindUserEmployee(AsOfDate);
            if (EmployeeNo <> '') and Employee.Get(EmployeeNo) then begin
                Shipment."Shipped By Employee No." := EmployeeNo;
                Shipment."Shipped By Name" := ShortName(Employee);
            end;
        end;

        if SiteReady and (Shipment."Received By Employee No." = '') then begin
            EmployeeNo := FindSupervisor(Site, AsOfDate);
            if EmployeeNo = '' then
                EmployeeNo := FindProjectManager(Site."Project No.", AsOfDate);
            if (EmployeeNo <> '') and Employee.Get(EmployeeNo) then begin
                Shipment."Received By Employee No." := EmployeeNo;
                Shipment."Received By Name" := ShortName(Employee);
            end;
        end;

        if not SiteReady then
            Shipment."Document Snapshot Status" := 'SITE_UNRESOLVED'
        else
            if Shipment."Delivery Address" = '' then
                Shipment."Document Snapshot Status" := 'ADDRESS_MISSING'
            else
                if (Shipment."Shipped By Name" = '') or (Shipment."Received By Name" = '') then
                    Shipment."Document Snapshot Status" := 'SIGNATORY_MISSING'
                else
                    Shipment."Document Snapshot Status" := 'READY';

        if Shipment."Snapshot Created At" = 0DT then
            Shipment."Snapshot Created At" := CurrentDateTime();
    end;

    // Explicit refresh of mutable delivery details. Never called on page open.
    procedure RefreshDeliveryExistingOpen(ShipmentEntryNo: Integer)
    var
        Shipment: Record "SI Prok Shipment";
        Site: Record "SI Construction Site";
        Issue: Text;
        AddressText: Text[250];
    begin
        Shipment.Get(ShipmentEntryNo);
        if Shipment.Status <> Shipment.Status::Open then
            Error('Оновлювати реквізити можна лише у відкритому документі.');
        if not TryResolveShipmentSite(Shipment, Site, Issue) then
            Error('Не вдалося визначити майданчик: %1', Issue);
        if not TryGetSiteAddress(Site, AddressText, Issue) then
            Error('Не вдалося визначити адресу доставки: %1', Issue);

        Shipment."Delivery Project No." := Site."Project No.";
        Shipment."Delivery Site Code" := Site."Site Code";
        Shipment."Delivery Site Name" := Site.Name;
        Shipment."Delivery Address" := AddressText;
        // Do not replace manual signatories or modify closed documents.
        InitializeOpen(Shipment, true);
        Shipment.Modify(true);
    end;

    procedure InitializeExistingOpen(ShipmentEntryNo: Integer)
    var
        Shipment: Record "SI Prok Shipment";
    begin
        if not Shipment.Get(ShipmentEntryNo) then
            exit;
        if Shipment.Status <> Shipment.Status::Open then
            exit;
        InitializeOpen(Shipment, true);
        Shipment.Modify(true);
    end;

    procedure OverrideSignatory(ShipmentEntryNo: Integer; IsShipper: Boolean; EmployeeNo: Code[20])
    var
        Shipment: Record "SI Prok Shipment";
        Employee: Record Employee;
    begin
        Shipment.Get(ShipmentEntryNo);
        if Shipment.Status <> Shipment.Status::Open then
            Error('Змінювати підписантів можна лише у відкритому документі.');
        Employee.Get(EmployeeNo);
        if IsShipper then begin
            Shipment."Shipped By Employee No." := Employee."No.";
            Shipment."Shipped By Name" := ShortName(Employee);
            Shipment."Shipped By Manual" := true;
        end else begin
            Shipment."Received By Employee No." := Employee."No.";
            Shipment."Received By Name" := ShortName(Employee);
            Shipment."Received By Manual" := true;
        end;
        InitializeOpen(Shipment, true);
        Shipment.Modify(true);
    end;

    // A shipment may have an incomplete allocation link, but the exact
    // decision line used to create its Proktek Order is still authoritative.
    // Reject contradictory identities rather than selecting a default site.
    procedure TryResolveShipmentSite(Shipment: Record "SI Prok Shipment"; var Site: Record "SI Construction Site"; var Reason: Text): Boolean
    var
        Fact: Record "SI Prok Production Fact";
        ProdRequest: Record "SI Concrete Prod Request";
        Allocation: Record "SI Supply Allocation";
        SiteIdentity: Codeunit "SI Prok Site Identity";
    begin
        Clear(Reason);
        Clear(Site);
        if Shipment."Prod. Request Entry No." = 0 then begin
            Reason := 'Відсутня прив’язка до виробничої заявки.';
            exit(false);
        end;
        if not ProdRequest.Get(Shipment."Prod. Request Entry No.") then begin
            Reason := 'Пов’язану виробничу заявку не знайдено.';
            exit(false);
        end;
        if not Fact.Get(Shipment."Production Fact Entry No.") then begin
            Reason := 'Пов’язаний виробничий факт не знайдено.';
            exit(false);
        end;
        if (Fact."Production UUID" <> Shipment."Production UUID") or
           (Fact."Prod. Request Entry No." <> ProdRequest."Entry No.") or
           (Fact."Order UUID" <> ProdRequest."Proktek Order UUID") then begin
            Reason := 'Ідентифікатори факту, Shipment і виробничої заявки суперечать один одному.';
            exit(false);
        end;
        if not SiteIdentity.TryResolveForOrder(ProdRequest, Site, Reason) then
            exit(false);
        if Shipment."Allocation Binding Status" = 'BOUND' then begin
            if not Allocation.Get(Shipment."Supply Decision No.", Shipment."Supply Decision Line No.", Shipment."Supply Allocation Line No.") then begin
                Reason := 'Підтверджений рядок розподілу більше не існує.';
                exit(false);
            end;
            if (Allocation.SystemId <> Shipment."Supply Allocation System ID") or
               (Allocation."Decision No." <> ProdRequest."Supply Decision No.") or
               (Allocation."Decision Line No." <> ProdRequest."Supply Decision Line No.") or
               (Allocation."Line No." <> ProdRequest."Supply Allocation Line No.") then begin
                Reason := 'Ідентичність рядка розподілу не підтверджена.';
                exit(false);
            end;
            if (Allocation."Construction Site Code" <> '') and
               (Allocation."Construction Site Code" <> Site."Site Code") then begin
                Reason := 'Майданчик у розподілі суперечить майданчику рішення забезпечення.';
                exit(false);
            end;
        end else
            if (Shipment."Allocation Binding Status" = 'ALLOCATION_NOT_FOUND') or
               (Shipment."Allocation Binding Status" = 'EXECUTION_MISMATCH') or
               (Shipment."Allocation Binding Status" = 'REQUEST_NOT_FOUND') then begin
                Reason := StrSubstNo('Помилка зв’язку з розподілом: %1.', Shipment."Allocation Binding Status");
                exit(false);
            end;
        exit(true);
    end;

    local procedure TryGetSiteAddress(Site: Record "SI Construction Site"; var AddressText: Text[250]; var Reason: Text): Boolean
    var
        Project: Record Job;
        ShipTo: Record "Ship-to Address";
    begin
        Clear(AddressText);
        Clear(Reason);
        if not Project.Get(Site."Project No.") then begin
            Reason := 'Проєкт будмайданчика не знайдено.';
            exit(false);
        end;
        if (Project."SI Internal Customer No." = '') or (Site."Ship-to Code" = '') then begin
            Reason := 'У проєкті або будмайданчику не задано посилання на Ship-to Address.';
            exit(false);
        end;
        if not ShipTo.Get(Project."SI Internal Customer No.", Site."Ship-to Code") then begin
            Reason := 'Адресу Ship-to Address не знайдено.';
            exit(false);
        end;
        AddressText := MakeAddress(ShipTo.City, ShipTo.Address, ShipTo."Address 2");
        if AddressText = '' then begin
            Reason := 'Адреса Ship-to Address порожня.';
            exit(false);
        end;
        exit(true);
    end;

    local procedure FindUserEmployee(AsOfDate: Date): Code[20]
    var
        Assignment: Record "SI User Identity Assignment";
        Candidate: Code[20];
    begin
        Assignment.SetRange("User Security ID", UserSecurityId());
        if Assignment.FindSet() then
            repeat
                if (Assignment."Employee No." <> '') and
                   (Assignment."Valid From" <= AsOfDate) and
                   ((Assignment."Valid To" = 0D) or (Assignment."Valid To" >= AsOfDate)) then begin
                    if (Candidate <> '') and (Candidate <> Assignment."Employee No.") then
                        exit(''); // Ambiguous, do not guess.
                    Candidate := Assignment."Employee No.";
                end;
            until Assignment.Next() = 0;
        exit(Candidate);
    end;

    local procedure FindSupervisor(Site: Record "SI Construction Site"; AsOfDate: Date): Code[20]
    var
        Assignment: Record "SI Site Assignment";
        Role: Record "SI Project Role";
        PrimaryNo: Code[20];
        Candidate: Code[20];
        Ambiguous: Boolean;
    begin
        Assignment.SetRange("Project No.", Site."Project No.");
        Assignment.SetRange("Site Code", Site."Site Code");
        if Assignment.FindSet() then
            repeat
                if Role.Get(Assignment."Role Code") then
                    if Role.Active and (Role.Purpose = Role.Purpose::SiteSupervisor) and
                       (Assignment."Employee No." <> '') and
                       ((Assignment."Valid From" = 0D) or (Assignment."Valid From" <= AsOfDate)) and
                       ((Assignment."Valid To" = 0D) or (Assignment."Valid To" >= AsOfDate)) then begin
                        if Assignment.Primary then begin
                            if (PrimaryNo <> '') and (PrimaryNo <> Assignment."Employee No.") then
                                exit('');
                            PrimaryNo := Assignment."Employee No.";
                        end;
                        if (Candidate <> '') and (Candidate <> Assignment."Employee No.") then
                            Ambiguous := true;
                        Candidate := Assignment."Employee No.";
                    end;
            until Assignment.Next() = 0;
        if PrimaryNo <> '' then
            exit(PrimaryNo);
        if Ambiguous then
            exit('');
        exit(Candidate);
    end;

    // SH-03.3.1: fallback to a valid ProjectManager assignment on shipment date.
    // Prefer a single primary assignment; never pick arbitrarily if ambiguous.
    local procedure FindProjectManager(ProjectNo: Code[20]; AsOfDate: Date): Code[20]
    var
        Assignment: Record "SI Project Assignment";
        Role: Record "SI Project Role";
        PrimaryNo: Code[20];
        Candidate: Code[20];
        Ambiguous: Boolean;
    begin
        Assignment.SetRange("Project No.", ProjectNo);
        if Assignment.FindSet() then
            repeat
                if Role.Get(Assignment."Role Code") then
                    if Role.Active and (Role.Purpose = Role.Purpose::ProjectManager) and
                       (Assignment."Employee No." <> '') and
                       ((Assignment."Valid From" = 0D) or (Assignment."Valid From" <= AsOfDate)) and
                       ((Assignment."Valid To" = 0D) or (Assignment."Valid To" >= AsOfDate)) then begin
                        if Assignment.Primary then begin
                            if (PrimaryNo <> '') and (PrimaryNo <> Assignment."Employee No.") then
                                exit('');
                            PrimaryNo := Assignment."Employee No.";
                        end;
                        if (Candidate <> '') and (Candidate <> Assignment."Employee No.") then
                            Ambiguous := true;
                        Candidate := Assignment."Employee No.";
                    end;
            until Assignment.Next() = 0;
        if PrimaryNo <> '' then
            exit(PrimaryNo);
        if Ambiguous then
            exit('');
        exit(Candidate);
    end;

    // Clear only the selected signatory. Do not auto-resolve during this action.
    // A subsequent explicit document refresh may populate empty signatories again.
    procedure ClearSignatory(ShipmentEntryNo: Integer; IsShipper: Boolean)
    var
        Shipment: Record "SI Prok Shipment";
    begin
        Shipment.Get(ShipmentEntryNo);
        if Shipment.Status <> Shipment.Status::Open then
            Error('Очищати підписантів можна лише у відкритому документі.');

        if IsShipper then begin
            Clear(Shipment."Shipped By Employee No.");
            Clear(Shipment."Shipped By Name");
            Shipment."Shipped By Manual" := false;
        end else begin
            Clear(Shipment."Received By Employee No.");
            Clear(Shipment."Received By Name");
            Shipment."Received By Manual" := false;
        end;

        // No InitializeOpen here: it would immediately refill the cleared field.
        if Shipment."Delivery Site Code" = '' then
            Shipment."Document Snapshot Status" := 'SITE_UNRESOLVED'
        else
            if Shipment."Delivery Address" = '' then
                Shipment."Document Snapshot Status" := 'ADDRESS_MISSING'
            else
                if (Shipment."Shipped By Name" = '') or
                   (Shipment."Received By Name" = '') then
                    Shipment."Document Snapshot Status" := 'SIGNATORY_MISSING'
                else
                    Shipment."Document Snapshot Status" := 'READY';

        Shipment.Modify(true);
    end;

    local procedure ShortName(Employee: Record Employee): Text[100]
    var
        InitialsText: Text;
        ResultText: Text;
    begin
        InitialsText := Employee.Initials.Trim();
        if InitialsText = '' then begin
            if Employee."First Name".Trim() <> '' then
                InitialsText := CopyStr(Employee."First Name".Trim(), 1, 1) + '.';
            if Employee."Middle Name".Trim() <> '' then
                InitialsText += CopyStr(Employee."Middle Name".Trim(), 1, 1) + '.';
        end;
        ResultText := Employee."Last Name".Trim();
        if InitialsText <> '' then begin
            if ResultText <> '' then
                ResultText += ' ';
            ResultText += InitialsText;
        end;
        exit(CopyStr(ResultText, 1, 100));
    end;

    local procedure MakeAddress(City: Text; Address: Text; Address2: Text): Text[250]
    var
        ResultText: Text;
    begin
        if City.Trim() <> '' then
            ResultText := City.Trim();
        if Address.Trim() <> '' then begin
            if ResultText <> '' then
                ResultText += ', ';
            ResultText += Address.Trim();
        end;
        if Address2.Trim() <> '' then begin
            if ResultText <> '' then
                ResultText += ', ';
            ResultText += Address2.Trim();
        end;
        exit(CopyStr(ResultText, 1, 250));
    end;
}