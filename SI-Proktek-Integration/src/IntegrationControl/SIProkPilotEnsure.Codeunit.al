using STROYINVEST.ConcreteRecipeEngine;

codeunit 57075 "SI Prok Pilot Ensure"
{
    procedure EnsureForOrder(ProdRequest: Record "SI Concrete Prod Request")
    var
        Connection: Record "SI Prok Connection";
        Project: Record Job;
        Customer: Record Customer;
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
    begin
        ProdRequest.TestField("Project No.");
        Project.Get(ProdRequest."Project No.");
        ValidateProjectCustomer(Project, Customer);
        ConnectionMgt.GetActive(Connection);

        EnsureCustomer(Connection, Project, Customer);
        EnsureSite(Connection, Project, Customer);
        EnsureFormula(Connection, ProdRequest);
    end;

    local procedure ValidateProjectCustomer(Project: Record Job; var Customer: Record Customer)
    begin
        Project.TestField("SI Internal Customer No.");
        if not Customer.Get(Project."SI Internal Customer No.") then
            Error('Для проєкту %1 вказано внутрішнього клієнта %2, але такого Customer у BC не існує.', Project."No.", Project."SI Internal Customer No.");
        if Customer."SI Customer Type" <> Customer."SI Customer Type"::"Internal Project" then
            Error('Клієнт %1 проєкту %2 не має типу Internal Project.', Customer."No.", Project."No.");
    end;

    local procedure EnsureCustomer(var Connection: Record "SI Prok Connection"; var Project: Record Job; Customer: Record Customer)
    var
        Mapping: Record "SI Prok Entity Mapping";
        CustomerRead: Codeunit "SI Prok Customer Read";
        CustomerSync: Codeunit "SI Prok Customer Sync";
        InternalCode: BigInteger;
        ProktekUUID: Guid;
        ProktekCode: Text;
    begin
        if CustomerRead.ResolveCustomerIdentity(Connection, Customer."No.", InternalCode, ProktekUUID, ProktekCode) and
           (InternalCode > 0) and (not IsNullGuid(ProktekUUID))
        then begin
            UpsertMapping(Connection, Mapping."Entity Type"::Customer, Customer.SystemId, Customer."No.", InternalCode, ProktekUUID, ProktekCode);
            exit;
        end;

        CustomerSync.SyncProjectCustomerForConnection(Connection, Project, Mapping);

        Clear(InternalCode);
        Clear(ProktekUUID);
        Clear(ProktekCode);
        if not CustomerRead.ResolveCustomerIdentity(Connection, Customer."No.", InternalCode, ProktekUUID, ProktekCode) then
            Error('Customer %1 було передано в Proktek, але повторний GET-CUSTOMERS не підтвердив його існування. Order не створено.', Customer."No.");
        if (InternalCode <= 0) or IsNullGuid(ProktekUUID) then
            Error('GET-CUSTOMERS підтвердив Customer %1, але не повернув валідні kod/UUID. Order не створено.', Customer."No.");

        UpsertMapping(Connection, Mapping."Entity Type"::Customer, Customer.SystemId, Customer."No.", InternalCode, ProktekUUID, ProktekCode);
    end;

    local procedure EnsureSite(var Connection: Record "SI Prok Connection"; var Project: Record Job; Customer: Record Customer)
    var
        CustomerMapping: Record "SI Prok Entity Mapping";
        SiteMapping: Record "SI Prok Entity Mapping";
        SiteRead: Codeunit "SI Prok Site Read";
        SiteSync: Codeunit "SI Prok Site Sync";
        InternalCode: BigInteger;
        ProktekUUID: Guid;
        ProktekCode: Text;
    begin
        CustomerMapping.Get(Connection.Code, CustomerMapping."Entity Type"::Customer, Customer.SystemId);

        if SiteRead.ResolveSiteIdentity(Connection, CustomerMapping."Proktek UUID", Project."No.", InternalCode, ProktekUUID, ProktekCode) then begin
            UpsertMapping(Connection, SiteMapping."Entity Type"::Site, Project.SystemId, Project."No.", InternalCode, ProktekUUID, ProktekCode);
            exit;
        end;

        SiteSync.SyncSite(Connection, Project, CustomerMapping, SiteMapping);

        Clear(InternalCode);
        Clear(ProktekUUID);
        Clear(ProktekCode);
        if not SiteRead.ResolveSiteIdentity(Connection, CustomerMapping."Proktek UUID", Project."No.", InternalCode, ProktekUUID, ProktekCode) then
            Error('Будмайданчик проєкту %1 було передано в Proktek, але повторний GET-SITES не підтвердив його існування. Order не створено.', Project."No.");

        UpsertMapping(Connection, SiteMapping."Entity Type"::Site, Project.SystemId, Project."No.", InternalCode, ProktekUUID, ProktekCode);
    end;

    local procedure EnsureFormula(Connection: Record "SI Prok Connection"; ProdRequest: Record "SI Concrete Prod Request")
    var
        Readiness: Codeunit "SI Prok Prod Readiness";
    begin
        ProdRequest.TestField("Recipe No.");
        ProdRequest.TestField("Recipe Revision No.");
        Readiness.ValidateRecipeForConnection(Connection, ProdRequest."Recipe No.", ProdRequest."Recipe Revision No.");
    end;

    local procedure UpsertMapping(Connection: Record "SI Prok Connection"; EntityType: Enum "SI Prok Entity Type"; BCSystemId: Guid; BCNo: Code[20]; InternalCode: BigInteger; ProktekUUID: Guid; ProktekCode: Text)
    var
        Mapping: Record "SI Prok Entity Mapping";
    begin
        if not Mapping.Get(Connection.Code, EntityType, BCSystemId) then begin
            Mapping.Init();
            Mapping."Connection Code" := Connection.Code;
            Mapping."Entity Type" := EntityType;
            Mapping."BC SystemId" := BCSystemId;
            Mapping."BC No." := BCNo;
            Mapping.Insert(false);
        end;
        Mapping."Proktek Internal Code" := InternalCode;
        Mapping."Proktek UUID" := ProktekUUID;
        Mapping."Proktek Code" := CopyStr(ProktekCode, 1, MaxStrLen(Mapping."Proktek Code"));
        Mapping."Last Sync At" := CurrentDateTime();
        Mapping."Last Response Message" := 'Verified by Proktek read API';
        Mapping.Modify(false);
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    var
        EmptyGuid: Guid;
    begin
        exit(Value = EmptyGuid);
    end;
}
