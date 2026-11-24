codeunit 60033 "SI Site Delivery Readiness"
{
    // CP-07: read-only delivery readiness contract.
    // No creation, synchronization or repair is performed by these methods.

    procedure TryCheck(ProjectNo: Code[20]; SiteCode: Code[20]; var CustomerNo: Code[20]; var ShipToCode: Code[10]; var Reason: Text): Boolean
    var
        Project: Record Job;
        Site: Record "SI Construction Site";
        OtherSite: Record "SI Construction Site";
        Customer: Record Customer;
        ShipTo: Record "Ship-to Address";
        Location: Record Location;
    begin
        Clear(CustomerNo);
        Clear(ShipToCode);
        Clear(Reason);

        if ProjectNo = '' then begin
            Reason := 'Не вказано номер проєкту.';
            exit(false);
        end;
        if not Project.Get(ProjectNo) then begin
            Reason := StrSubstNo('Проєкт %1 не знайдено.', ProjectNo);
            exit(false);
        end;
        if not Project."SI Construction Project" then begin
            Reason := StrSubstNo('Проєкт %1 не є будівельним проєктом SI.', ProjectNo);
            exit(false);
        end;
        if Project."Location Code" = '' then begin
            Reason := StrSubstNo('Для проєкту %1 не визначено склад.', ProjectNo);
            exit(false);
        end;
        if not Location.Get(Project."Location Code") then begin
            Reason := StrSubstNo('Склад %1 проєкту %2 не існує.', Project."Location Code", ProjectNo);
            exit(false);
        end;
        if SiteCode = '' then begin
            Reason := 'Не вказано код будівельного майданчика.';
            exit(false);
        end;
        if not Site.Get(ProjectNo, SiteCode) then begin
            Reason := StrSubstNo('Майданчик %1 проєкту %2 не знайдено.', SiteCode, ProjectNo);
            exit(false);
        end;
        if Site.Status <> Site.Status::Active then begin
            Reason := StrSubstNo('Майданчик %1 не є активним.', SiteCode);
            exit(false);
        end;

        CustomerNo := Project."SI Internal Customer No.";
        if CustomerNo = '' then begin
            Reason := StrSubstNo('Проєкт %1 не має внутрішнього SI-клієнта.', ProjectNo);
            exit(false);
        end;
        if not Customer.Get(CustomerNo) then begin
            Reason := StrSubstNo('Внутрішнього SI-клієнта %1 не знайдено.', CustomerNo);
            exit(false);
        end;
        if Customer."SI Customer Type" <> Customer."SI Customer Type"::"Internal Project" then begin
            Reason := StrSubstNo('Customer %1 має некоректний тип.', CustomerNo);
            exit(false);
        end;
        if Customer."SI Project No." <> ProjectNo then begin
            Reason := StrSubstNo('Customer %1 пов’язаний з іншим проєктом (%2).', CustomerNo, Customer."SI Project No.");
            exit(false);
        end;

        ShipToCode := Site."Ship-to Code";
        if ShipToCode = '' then begin
            Reason := StrSubstNo('Майданчик %1 не має коду адреси доставки.', SiteCode);
            exit(false);
        end;
        if not ShipTo.Get(CustomerNo, ShipToCode) then begin
            Reason := StrSubstNo('Адресу доставки %1 клієнта %2 не знайдено.', ShipToCode, CustomerNo);
            exit(false);
        end;

        OtherSite.SetRange("Project No.", ProjectNo);
        OtherSite.SetRange("Ship-to Code", ShipToCode);
        OtherSite.SetFilter("Site Code", '<>%1', SiteCode);
        if OtherSite.FindFirst() then begin
            Reason := StrSubstNo('Адреса доставки %1 також використовується майданчиком %2.', ShipToCode, OtherSite."Site Code");
            exit(false);
        end;

        if ShipTo."Location Code" <> Project."Location Code" then begin
            Reason := StrSubstNo('Склад адреси доставки %1 (%2) не відповідає складу проєкту (%3).',
                ShipToCode, ShipTo."Location Code", Project."Location Code");
            exit(false);
        end;
        if ShipTo.Address = '' then begin
            Reason := StrSubstNo('Для адреси доставки %1 не заповнено вулицю/адресу.', ShipToCode);
            exit(false);
        end;
        if ShipTo.City = '' then begin
            Reason := StrSubstNo('Для адреси доставки %1 не заповнено місто.', ShipToCode);
            exit(false);
        end;
        if ShipTo."Country/Region Code" = '' then begin
            Reason := StrSubstNo('Для адреси доставки %1 не заповнено країну.', ShipToCode);
            exit(false);
        end;
        exit(true);
    end;

    procedure AssertReady(ProjectNo: Code[20]; SiteCode: Code[20]; var CustomerNo: Code[20]; var ShipToCode: Code[10])
    var
        Reason: Text;
    begin
        if not TryCheck(ProjectNo, SiteCode, CustomerNo, ShipToCode, Reason) then
            Error('Майданчик не готовий до доставки: %1', Reason);
    end;
}
