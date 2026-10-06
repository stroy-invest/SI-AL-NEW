page 50476 "SI EDS Health Check"
{
    PageType = List;
    SourceTable = "SI EDS Health Check Buffer";
    SourceTableTemporary = true;
    Caption = 'EDS — перевірка конфігурації';
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Checks)
            {
                field(Severity; Rec.Severity) { ApplicationArea = All; StyleExpr = SeverityStyle; }
                field(CheckArea; Rec."Check Area") { ApplicationArea = All; }
                field("Object Code"; Rec."Object Code") { ApplicationArea = All; }
                field(Check; Rec.Check) { ApplicationArea = All; }
                field(Result; Rec.Result) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CheckNow)
            {
                ApplicationArea = All;
                Caption = 'Перевірити зараз';
                Image = Refresh;
                trigger OnAction()
                begin
                    LoadChecks();
                end;
            }
            action(OpenSetup)
            {
                ApplicationArea = All;
                Caption = 'Перейти до налаштування';
                Image = Setup;
                trigger OnAction()
                begin
                    OpenSetupForCurrentRow();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadChecks();
    end;

    trigger OnAfterGetRecord()
    begin
        case Rec.Severity of
            Rec.Severity::Error: SeverityStyle := 'Unfavorable';
            Rec.Severity::Warning: SeverityStyle := 'Ambiguous';
            else SeverityStyle := 'Favorable';
        end;
    end;

    var
        SeverityStyle: Text;
        SeverityFilterValue: Integer;
        SeverityFilterEnabled: Boolean;
        ContextEnabled: Boolean;
        ContextServiceCode: Code[50];
        ContextOperationCode: Code[50];
        ContextProviderCode: Code[50];

    local procedure LoadChecks()
    var
        HealthCheck: Codeunit "SI EDS Health Check Mgt.";
    begin
        HealthCheck.Run(Rec);
        ApplyConfigurationContext();
        ApplySeverityFilter();
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    procedure SetConfigurationContext(ServiceCode: Code[50]; OperationCode: Code[50]; ProviderCode: Code[50])
    begin
        ContextServiceCode := ServiceCode;
        ContextOperationCode := OperationCode;
        ContextProviderCode := ProviderCode;
        ContextEnabled := true;
    end;

    local procedure ApplyConfigurationContext()
    begin
        if not ContextEnabled then
            exit;

        Rec.Reset();
        if Rec.FindSet() then
            repeat
                if not IsContextRow() then
                    Rec.Delete();
            until Rec.Next() = 0;
        Rec.Reset();
    end;

    local procedure IsContextRow(): Boolean
    var
        ServicePrefix: Text;
        OperationPrefix: Text;
        RoutePrefix: Text;
    begin
        ServicePrefix := ContextServiceCode + ' / ';
        OperationPrefix := ContextServiceCode + ' / ' + ContextOperationCode;
        RoutePrefix := OperationPrefix + ' / ' + ContextProviderCode;

        case Rec."Check Area" of
            Rec."Check Area"::Service:
                exit(Rec."Object Code" = ContextServiceCode);
            Rec."Check Area"::Operation:
                exit((Rec."Object Code" = OperationPrefix) or (StrPos(Rec."Object Code", OperationPrefix + ' / ') = 1));
            Rec."Check Area"::Provider, Rec."Check Area"::Endpoint, Rec."Check Area"::RateLimit:
                exit((Rec."Object Code" = ContextProviderCode) or (StrPos(Rec."Object Code", ContextProviderCode + ' / ') = 1));
            Rec."Check Area"::Route, Rec."Check Area"::Parameter, Rec."Check Area"::Credential:
                exit((Rec."Object Code" = RoutePrefix) or (StrPos(Rec."Object Code", RoutePrefix + ' / ') = 1));
        end;
        exit(false);
    end;

    procedure SetSeverityFilter(NewSeverityFilter: Integer)
    begin
        SeverityFilterValue := NewSeverityFilter;
        SeverityFilterEnabled := true;
    end;

    local procedure ApplySeverityFilter()
    begin
        if not SeverityFilterEnabled then begin
            Rec.SetRange(Severity);
            exit;
        end;

        case SeverityFilterValue of
            0:
                Rec.SetRange(Severity, Rec.Severity::OK);
            1:
                Rec.SetRange(Severity, Rec.Severity::Warning);
            2:
                Rec.SetRange(Severity, Rec.Severity::Error);
            else
                Rec.SetRange(Severity);
        end;
    end;

    local procedure OpenSetupForCurrentRow()
    begin
        case Rec."Check Area" of
            Rec."Check Area"::Service: OpenService();
            Rec."Check Area"::Operation: OpenOperation();
            Rec."Check Area"::Provider: OpenProvider();
            Rec."Check Area"::Endpoint: OpenEndpoint();
            Rec."Check Area"::Credential: OpenCredential();
            Rec."Check Area"::Route: OpenRoute();
            Rec."Check Area"::Parameter: OpenParameter();
            Rec."Check Area"::RateLimit: OpenRateLimits();
            Rec."Check Area"::AsyncWorker: OpenAsyncWorker();
        end;
    end;

    local procedure OpenService()
    var
        Service: Record "SI EDS Service";
    begin
        if (Rec."Object Code" <> '') and Service.Get(CopyStr(Rec."Object Code", 1, MaxStrLen(Service.Code))) then
            Page.Run(Page::"SI EDS Service Card", Service)
        else
            Page.Run(Page::"SI EDS Services");
    end;

    local procedure OpenOperation()
    var
        Operation: Record "SI EDS Operation";
        ServiceCode: Code[50];
        OperationCode: Code[50];
    begin
        Parse2(Rec."Object Code", ServiceCode, OperationCode);
        if (ServiceCode <> '') and (OperationCode <> '') and Operation.Get(ServiceCode, OperationCode) then
            Page.Run(Page::"SI EDS Operation Card", Operation)
        else begin
            Operation.SetRange("Service Code", ServiceCode);
            Page.Run(Page::"SI EDS Operations", Operation);
        end;
    end;

    local procedure OpenProvider()
    var
        Provider: Record "SI EDS Provider";
    begin
        if (Rec."Object Code" <> '') and Provider.Get(CopyStr(Rec."Object Code", 1, MaxStrLen(Provider.Code))) then
            Page.Run(Page::"SI EDS Provider Card", Provider)
        else
            Page.Run(Page::"SI EDS Providers");
    end;

    local procedure OpenEndpoint()
    var
        Endpoint: Record "SI EDS Endpoint";
        ProviderCode: Code[50];
    begin
        ProviderCode := CopyStr(FirstPart(Rec."Object Code"), 1, MaxStrLen(ProviderCode));
        Endpoint.SetRange("Provider Code", ProviderCode);
        if Rec.Check = 'Base URL' then
            Endpoint.SetRange("Base URL", '');
        if Endpoint.FindFirst() then
            Page.Run(Page::"SI EDS Endpoint Card", Endpoint)
        else
            Page.Run(Page::"SI EDS Endpoints", Endpoint);
    end;

    local procedure OpenCredential()
    var
        Parameter: Record "SI EDS Parameter";
        Credential: Record "SI EDS Credential";
        ServiceCode: Code[50];
        OperationCode: Code[50];
        ProviderCode: Code[50];
        ParameterCode: Code[50];
    begin
        Parse4(Rec."Object Code", ServiceCode, OperationCode, ProviderCode, ParameterCode);
        if Parameter.Get(ServiceCode, OperationCode, ProviderCode, ParameterCode) and
           (Parameter."Credential Code" <> '') and
           Credential.Get(ProviderCode, Parameter."Credential Code")
        then begin
            Page.Run(Page::"SI EDS Credential Card", Credential);
            exit;
        end;
        Credential.SetRange("Provider Code", ProviderCode);
        Page.Run(Page::"SI EDS Credentials", Credential);
    end;

    local procedure OpenRoute()
    var
        Route: Record "SI EDS Provider Route";
        ServiceCode: Code[50];
        OperationCode: Code[50];
        ProviderCode: Code[50];
    begin
        Parse3(Rec."Object Code", ServiceCode, OperationCode, ProviderCode);
        Route.SetRange("Service Code", ServiceCode);
        Route.SetRange("Operation Code", OperationCode);
        Route.SetRange("Provider Code", ProviderCode);
        if Route.FindFirst() then
            Page.Run(Page::"SI EDS Provider Route Card", Route)
        else
            Page.Run(Page::"SI EDS Provider Routes", Route);
    end;

    local procedure OpenParameter()
    var
        Parameter: Record "SI EDS Parameter";
        ServiceCode: Code[50];
        OperationCode: Code[50];
        ProviderCode: Code[50];
        ParameterCode: Code[50];
    begin
        Parse4(Rec."Object Code", ServiceCode, OperationCode, ProviderCode, ParameterCode);
        if Parameter.Get(ServiceCode, OperationCode, ProviderCode, ParameterCode) then
            Page.Run(Page::"SI EDS Parameter Card", Parameter)
        else begin
            Parameter.SetRange("Service Code", ServiceCode);
            Parameter.SetRange("Operation Code", OperationCode);
            Parameter.SetRange("Provider Code", ProviderCode);
            Page.Run(Page::"SI EDS Parameters", Parameter);
        end;
    end;

    local procedure OpenRateLimits()
    var
        Limit: Record "SI EDS Provider Rate Limit";
        ProviderCode: Code[50];
    begin
        ProviderCode := CopyStr(FirstPart(Rec."Object Code"), 1, MaxStrLen(ProviderCode));
        Limit.SetRange("Provider Code", ProviderCode);
        Page.Run(Page::"SI EDS Provider Rate Limits", Limit);
    end;

    local procedure OpenAsyncWorker()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"SI EDS Async Worker");
        if JobQueueEntry.FindFirst() then
            Page.Run(Page::"Job Queue Entries", JobQueueEntry)
        else
            Page.Run(Page::"Job Queue Entries");
    end;

    local procedure FirstPart(Value: Text): Text
    var
        SeparatorPos: Integer;
    begin
        SeparatorPos := StrPos(Value, ' / ');
        if SeparatorPos = 0 then
            exit(Value);
        exit(CopyStr(Value, 1, SeparatorPos - 1));
    end;

    local procedure TakePart(var Value: Text): Text
    var
        SeparatorPos: Integer;
        PartValue: Text;
    begin
        SeparatorPos := StrPos(Value, ' / ');
        if SeparatorPos = 0 then begin
            PartValue := Value;
            Clear(Value);
            exit(PartValue);
        end;
        PartValue := CopyStr(Value, 1, SeparatorPos - 1);
        Value := CopyStr(Value, SeparatorPos + 3);
        exit(PartValue);
    end;

    local procedure Parse2(Value: Text; var Part1: Code[50]; var Part2: Code[50])
    begin
        Part1 := CopyStr(TakePart(Value), 1, MaxStrLen(Part1));
        Part2 := CopyStr(TakePart(Value), 1, MaxStrLen(Part2));
    end;

    local procedure Parse3(Value: Text; var Part1: Code[50]; var Part2: Code[50]; var Part3: Code[50])
    begin
        Part1 := CopyStr(TakePart(Value), 1, MaxStrLen(Part1));
        Part2 := CopyStr(TakePart(Value), 1, MaxStrLen(Part2));
        Part3 := CopyStr(TakePart(Value), 1, MaxStrLen(Part3));
    end;

    local procedure Parse4(Value: Text; var Part1: Code[50]; var Part2: Code[50]; var Part3: Code[50]; var Part4: Code[50])
    begin
        Part1 := CopyStr(TakePart(Value), 1, MaxStrLen(Part1));
        Part2 := CopyStr(TakePart(Value), 1, MaxStrLen(Part2));
        Part3 := CopyStr(TakePart(Value), 1, MaxStrLen(Part3));
        Part4 := CopyStr(TakePart(Value), 1, MaxStrLen(Part4));
    end;
}
