using STROYINVEST.ConcreteRecipeEngine;

codeunit 57068 "SI Prok Order Projector"
{
    procedure BuildOrderPayload(ProdRequest: Record "SI Concrete Prod Request"): Text
    var
        Connection: Record "SI Prok Connection";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
        AuthMgt: Codeunit "SI Prok Auth Mgt.";
        SessionGuid: Guid;
        Root: JsonObject;
        OrderJson: JsonObject;
        CustomerJson: JsonObject;
        SiteJson: JsonObject;
        FormulaJson: JsonObject;
        PlantIds: JsonArray;
        Payload: Text;
    begin
        ValidateRequest(ProdRequest);
        ConnectionMgt.GetActive(Connection);
        SessionGuid := AuthMgt.GetSessionGuid(Connection);

        BuildCustomerJson(Connection, ProdRequest, CustomerJson);
        BuildSiteJson(Connection, ProdRequest, SiteJson);
        BuildFormulaJson(Connection, ProdRequest, FormulaJson);

        PlantIds.Add(1);

        OrderJson.Add('id', 0);
        OrderJson.Add('uuid', Format(EmptyGuid(), 0, 4));
        OrderJson.Add('orderDate', FormatProktekLocalDateTime(ProdRequest."Required Date/Time"));
        OrderJson.Add('plant_id', PlantIds);
        OrderJson.Add('customer', CustomerJson);
        OrderJson.Add('site', SiteJson);
        OrderJson.Add('mixDesign', FormulaJson);
        OrderJson.Add('totalAmount', ProdRequest.Quantity);
        OrderJson.Add('remainingAmount', ProdRequest.Quantity);
        OrderJson.Add('productionCycles', 0);
        OrderJson.Add('extraWater', 0);
        OrderJson.Add('price', 0);
        OrderJson.Add('description', BuildDescription(ProdRequest));
        OrderJson.Add('ticketNote', '');
        OrderJson.Add('invoiceNo', '');
        OrderJson.Add('isActive', true);
        OrderJson.Add('isClosed', false);
        OrderJson.Add('isErpOk', true);
        OrderJson.Add('user', UserId());
        OrderJson.Add('addOrderNo', BuildExternalOrderNo(ProdRequest));

        Root.Add('guid', Format(SessionGuid, 0, 4));
        Root.Add('order', OrderJson);
        Root.WriteTo(Payload);
        exit(Payload);
    end;

    local procedure BuildCustomerJson(
        Connection: Record "SI Prok Connection";
        ProdRequest: Record "SI Concrete Prod Request";
        var CustomerJson: JsonObject)
    var
        Customer: Record Customer;
        Mapping: Record "SI Prok Entity Mapping";
    begin
        Customer.Get(ProdRequest."Customer No.");

        if not Mapping.Get(Connection.Code, Mapping."Entity Type"::Customer, Customer.SystemId) then
            Error('Клієнт %1 (%2) не синхронізований з Proktek.', Customer."No.", Customer.Name);
        if Mapping."Proktek Internal Code" = 0 then
            Error('Для клієнта %1 у mapping відсутній Proktek kod.', Customer."No.");
        if Mapping."Proktek UUID" = EmptyGuid() then
            Error('Для клієнта %1 у mapping відсутній Proktek UUID.', Customer."No.");

        CustomerJson.Add('kod', Mapping."Proktek Internal Code");
        CustomerJson.Add('uuid', Format(Mapping."Proktek UUID", 0, 4));
        CustomerJson.Add('musteri_kod', Customer."No.");
        CustomerJson.Add('aktif', true);
        CustomerJson.Add('ad', GetCustomerDisplayName(ProdRequest, Customer));
    end;

    local procedure BuildSiteJson(
        Connection: Record "SI Prok Connection";
        ProdRequest: Record "SI Concrete Prod Request";
        var SiteJson: JsonObject)
    var
        Project: Record Job;
        Customer: Record Customer;
        SiteMapping: Record "SI Prok Entity Mapping";
        CustomerMapping: Record "SI Prok Entity Mapping";
        NamingMgt: Codeunit "SI Prok Naming Mgt.";
    begin
        ProdRequest.TestField("Project No.");
        Project.Get(ProdRequest."Project No.");

        if not SiteMapping.Get(Connection.Code, SiteMapping."Entity Type"::Site, Project.SystemId) then
            Error('Проєкт %1 (%2) не синхронізований як будмайданчик Proktek.', Project."No.", Project.Description);
        if SiteMapping."Proktek Internal Code" = 0 then
            Error('Для будмайданчика проєкту %1 у mapping відсутній Proktek kod.', Project."No.");
        if SiteMapping."Proktek UUID" = EmptyGuid() then
            Error('Для будмайданчика проєкту %1 у mapping відсутній Proktek UUID.', Project."No.");

        Customer.Get(ProdRequest."Customer No.");
        if not CustomerMapping.Get(Connection.Code, CustomerMapping."Entity Type"::Customer, Customer.SystemId) then
            Error('Клієнт %1 (%2) не синхронізований з Proktek.', Customer."No.", Customer.Name);

        SiteJson.Add('kod', SiteMapping."Proktek Internal Code");
        SiteJson.Add('uuid', Format(SiteMapping."Proktek UUID", 0, 4));
        SiteJson.Add('aktif', true);
        SiteJson.Add('ad', NamingMgt.BuildProjectSiteName(Project));
        SiteJson.Add('santiye_kod', Project."No.");
        SiteJson.Add('musteri_kod', CustomerMapping."Proktek Internal Code");
        SiteJson.Add('musteri_uuid', Format(CustomerMapping."Proktek UUID", 0, 4));
    end;

    local procedure GetCustomerDisplayName(
        ProdRequest: Record "SI Concrete Prod Request";
        Customer: Record Customer): Text
    var
        Project: Record Job;
        NamingMgt: Codeunit "SI Prok Naming Mgt.";
    begin
        if (ProdRequest."Project No." <> '') and Project.Get(ProdRequest."Project No.") then
            exit(NamingMgt.BuildProjectCustomerName(Project));

        exit(Customer.Name);
    end;

    local procedure BuildFormulaJson(
        Connection: Record "SI Prok Connection";
        ProdRequest: Record "SI Concrete Prod Request";
        var FormulaJson: JsonObject)
    var
        Mapping: Record "SI Prok Entity Mapping";
        Revision: Record "SI Concrete Recipe Revision";
        FormulaCode: Text;
    begin
        ProdRequest.TestField("Recipe No.");
        ProdRequest.TestField("Recipe Revision No.");
        if not Revision.Get(ProdRequest."Recipe No.", ProdRequest."Recipe Revision No.") then
            Error('Вибрану ревізію %1/%2 не знайдено.', ProdRequest."Recipe No.", ProdRequest."Recipe Revision No.");

        if not Mapping.Get(Connection.Code, Mapping."Entity Type"::Formula, Revision.SystemId) then
            Error('Ревізію %1 рецептури %2 ще не синхронізовано з Proktek.', Revision."Revision No.", Revision."Recipe No.");
        if Mapping."Proktek Internal Code" = 0 then
            Error('Для ревізії %1/%2 у mapping відсутній Proktek recete_index.', Revision."Recipe No.", Revision."Revision No.");
        if Mapping."Proktek UUID" = EmptyGuid() then
            Error('Для ревізії %1/%2 у mapping відсутній Proktek UUID.', Revision."Recipe No.", Revision."Revision No.");
        if Mapping."SI Formula Proj. Status" <> Mapping."SI Formula Proj. Status"::Published then
            Error('Formula для ревізії %1/%2 не має статусу «Опубліковано».', Revision."Recipe No.", Revision."Revision No.");
        if not Mapping."SI Proktek Active" then
            Error('Formula для ревізії %1/%2 не активована в Proktek. Order не створено.', Revision."Recipe No.", Revision."Revision No.");

        FormulaCode := Mapping."Proktek Code";
        if FormulaCode = '' then
            FormulaCode := ProdRequest."Formula Code";

        FormulaJson.Add('recete_index', Mapping."Proktek Internal Code");
        FormulaJson.Add('uuid', Format(Mapping."Proktek UUID", 0, 4));
        FormulaJson.Add('recete_kod', FormulaCode);
        FormulaJson.Add('ad', ProdRequest."Formula Description");
        FormulaJson.Add('aktif', true);
    end;

    local procedure ValidateRequest(ProdRequest: Record "SI Concrete Prod Request")
    begin
        ProdRequest.TestField("Customer No.");
        ProdRequest.TestField("Project No.");
        ProdRequest.TestField("Item No.");
        ProdRequest.TestField(Quantity);
        ProdRequest.TestField("Unit of Measure Code");
        ProdRequest.TestField("Required Date/Time");
        ProdRequest.TestField("Formula Code");

        if ProdRequest."Recipe Type" = ProdRequest."Recipe Type"::"Not Selected" then
            Error('У заявці не визначено рецептуру.');
        if ProdRequest.Quantity <= 0 then
            Error('Кількість у заявці повинна бути більшою за 0.');
    end;

    procedure BuildExternalOrderNo(ProdRequest: Record "SI Concrete Prod Request"): Text
    begin
        if (ProdRequest."Source No." <> '') and
           (ProdRequest."Supply Allocation Line No." <> 0)
        then
            exit(CopyStr(
                StrSubstNo(
                    '%1/%2/A%3',
                    ProdRequest."Source No.",
                    ProdRequest."Source Line No.",
                    ProdRequest."Supply Allocation Line No."),
                1,
                100));

        if ProdRequest."Source No." <> '' then
            exit(CopyStr(StrSubstNo('%1/%2', ProdRequest."Source No.", ProdRequest."Source Line No."), 1, 100));

        exit(CopyStr(StrSubstNo('CPR-%1', ProdRequest."Entry No."), 1, 100));
    end;

    local procedure FormatProktekLocalDateTime(Value: DateTime): Text
    begin
        if Value = 0DT then
            exit('');

        // Proktek SAVE-ORDER expects plant-local wall-clock time.
        // XML/ISO format 9 converts DateTime to UTC and adds Z, so do not use it here.
        exit(
            Format(
                Value,
                0,
                '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));
    end;

    local procedure BuildDescription(ProdRequest: Record "SI Concrete Prod Request"): Text
    begin
        exit(CopyStr(StrSubstNo('BC Production Request #%1 | %2', ProdRequest."Entry No.", ProdRequest.GetProductDescription()), 1, 250));
    end;

    local procedure EmptyGuid(): Guid
    var
        Empty: Guid;
    begin
        exit(Empty);
    end;
}
