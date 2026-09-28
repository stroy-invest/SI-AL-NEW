codeunit 61043 "SI Planning Demand Mgt."
{
    procedure RebuildAll()
    var
        Allocation: Record "SI Supply Allocation";
        Demand: Record "SI Planning Demand";
        RebuildToken: Guid;
        RebuiltAt: DateTime;
        CountCreatedOrUpdated: Integer;
        CountSkippedOrphaned: Integer;
    begin
        RebuildToken := CreateGuid();
        RebuiltAt := CurrentDateTime();

        Allocation.Reset();
        if Allocation.FindSet() then
            repeat
                if IsPlanningEligible(Allocation) then
                    if HasValidRequestLineage(Allocation) then
                        case Allocation."Supply Method" of
                        Allocation."Supply Method"::Purchase:
                            begin
                                UpsertPurchaseDemand(Allocation, RebuildToken, RebuiltAt);
                                CountCreatedOrUpdated += 1;
                            end;
                            Allocation."Supply Method"::Production:
                                CountCreatedOrUpdated += UpsertProductionMaterialDemands(Allocation, RebuildToken, RebuiltAt);
                        end
                    else
                        CountSkippedOrphaned += 1;
            until Allocation.Next() = 0;

        Demand.Reset();
        Demand.SetFilter("Rebuild Token", '<>%1', RebuildToken);
        Demand.DeleteAll(true);

        if CountSkippedOrphaned = 0 then
            Message(RebuildDoneMsg, CountCreatedOrUpdated)
        else
            Message(RebuildDoneWithSkippedMsg, CountCreatedOrUpdated, CountSkippedOrphaned);
    end;


    local procedure HasValidRequestLineage(Allocation: Record "SI Supply Allocation"): Boolean
    var
        DecisionHeader: Record "SI Supply Decision Header";
        DecisionLine: Record "SI Supply Decision Line";
        RequestHeader: Record "SI Supply Req Header";
        RequestLine: Record "SI Supply Req Line";
    begin
        if not DecisionHeader.Get(Allocation."Decision No.") then
            exit(false);

        if not DecisionLine.Get(Allocation."Decision No.", Allocation."Decision Line No.") then
            exit(false);

        if DecisionHeader."Request No." = '' then
            exit(false);

        if not RequestHeader.Get(DecisionHeader."Request No.") then
            exit(false);

        if DecisionLine."Request Line No." = 0 then
            exit(false);

        if not RequestLine.Get(DecisionHeader."Request No.", DecisionLine."Request Line No.") then
            exit(false);

        // Only a controlled, approved business demand may enter standard BC Planning.
        // Draft/Pending requests are still mutable; Fulfilled/Cancelled are historical.
        if not (RequestHeader.Status in [
            RequestHeader.Status::Approved,
            RequestHeader.Status::"In Fulfillment",
            RequestHeader.Status::"Partially Fulfilled"])
        then
            exit(false);

        exit(true);
    end;

    local procedure IsPlanningEligible(Allocation: Record "SI Supply Allocation"): Boolean
    begin
        if Allocation.Quantity <= 0 then
            exit(false);

        if not (Allocation.Status in [Allocation.Status::Planned, Allocation.Status::Released, Allocation.Status::"In Progress"]) then
            exit(false);

        exit(Allocation."Supply Method" in [Allocation."Supply Method"::Purchase, Allocation."Supply Method"::Production]);
    end;

    local procedure UpsertPurchaseDemand(Allocation: Record "SI Supply Allocation"; RebuildToken: Guid; RebuiltAt: DateTime)
    var
        Demand: Record "SI Planning Demand";
    begin
        ValidateAllocationContext(Allocation);
        GetOrInitDemand(Demand, Demand."Source Type"::"Purchase Allocation", Allocation, 0);
        FillCommonContext(Demand, Allocation);
        Demand.Validate("Item No.", Allocation."Item No.");
        Demand.Validate("Variant Code", Allocation."Variant Code");
        Demand.Description := Allocation.Description;
        Demand.Quantity := Allocation.Quantity;
        Demand."Unit of Measure Code" := Allocation."Unit of Measure Code";
        Demand.Validate("Target Location Code", Allocation."Target Location Code");
        Demand."Planning Status" := Demand."Planning Status"::Active;
        Demand."Rebuild Token" := RebuildToken;
        Demand."Last Rebuilt At" := RebuiltAt;
        SaveDemand(Demand);
    end;

    local procedure UpsertProductionMaterialDemands(Allocation: Record "SI Supply Allocation"; RebuildToken: Guid; RebuiltAt: DateTime): Integer
    var
        MaterialReq: Record "SI Supply Material Req.";
        Demand: Record "SI Planning Demand";
        CountRows: Integer;
    begin
        ValidateAllocationContext(Allocation);
        MaterialReq.SetRange("Decision No.", Allocation."Decision No.");
        MaterialReq.SetRange("Decision Line No.", Allocation."Decision Line No.");
        MaterialReq.SetRange("Allocation Line No.", Allocation."Line No.");
        MaterialReq.SetFilter("Required Quantity", '>0');
        if MaterialReq.FindSet() then
            repeat
                MaterialReq.TestField("Item No.");
                MaterialReq.TestField("Unit of Measure Code");
                MaterialReq.TestField("Location Code");

                GetOrInitDemand(Demand, Demand."Source Type"::"Production Material", Allocation, MaterialReq."Line No.");
                FillCommonContext(Demand, Allocation);
                Demand.Validate("Item No.", MaterialReq."Item No.");
                Demand.Validate("Variant Code", MaterialReq."Variant Code");
                Demand.Description := CopyStr(MaterialReq.Description, 1, MaxStrLen(Demand.Description));
                Demand.Quantity := MaterialReq."Required Quantity";
                Demand."Unit of Measure Code" := MaterialReq."Unit of Measure Code";
                Demand.Validate("Target Location Code", MaterialReq."Location Code");
                Demand."Planning Status" := Demand."Planning Status"::Active;
                Demand."Rebuild Token" := RebuildToken;
                Demand."Last Rebuilt At" := RebuiltAt;
                SaveDemand(Demand);
                CountRows += 1;
            until MaterialReq.Next() = 0;
        exit(CountRows);
    end;

    local procedure GetOrInitDemand(var Demand: Record "SI Planning Demand"; SourceType: Enum "SI Planning Demand Source"; Allocation: Record "SI Supply Allocation"; RequirementLineNo: Integer)
    begin
        Demand.Reset();
        Demand.SetRange("Source Type", SourceType);
        Demand.SetRange("Decision No.", Allocation."Decision No.");
        Demand.SetRange("Decision Line No.", Allocation."Decision Line No.");
        Demand.SetRange("Allocation Line No.", Allocation."Line No.");
        Demand.SetRange("Requirement Line No.", RequirementLineNo);
        if Demand.FindFirst() then
            exit;

        // Init() does not reset primary-key fields. Demand is reused inside the
        // Material Requirement FindSet loop, so an Entry No. from the previous
        // iteration would make SaveDemand() Modify() that row instead of inserting
        // the next source line. Explicitly reset the AutoIncrement PK for a new source.
        Demand.Init();
        Demand."Entry No." := 0;
        Demand."Source Type" := SourceType;
        Demand."Decision No." := Allocation."Decision No.";
        Demand."Decision Line No." := Allocation."Decision Line No.";
        Demand."Allocation Line No." := Allocation."Line No.";
        Demand."Requirement Line No." := RequirementLineNo;
    end;

    local procedure FillCommonContext(var Demand: Record "SI Planning Demand"; Allocation: Record "SI Supply Allocation")
    var
        DecisionHeader: Record "SI Supply Decision Header";
        DecisionLine: Record "SI Supply Decision Line";
    begin
        if not DecisionHeader.Get(Allocation."Decision No.") then
            Error(DecisionNotFoundErr, Allocation."Decision No.");
        if not DecisionLine.Get(Allocation."Decision No.", Allocation."Decision Line No.") then
            Error(DecisionLineNotFoundErr, Allocation."Decision No.", Allocation."Decision Line No.");

        Demand."Request No." := DecisionHeader."Request No.";
        Demand."Request Line No." := DecisionLine."Request Line No.";
        Demand.Validate("Project No.", DecisionHeader."Project No.");
        Demand."Construction Site Code" := Allocation."Construction Site Code";
        Demand."Required on Site At" := Allocation."Required on Site At";
        Demand."Planning Date" := DT2Date(Allocation."Required on Site At");
        Demand."Source Status" := Allocation.Status;
    end;

    local procedure ValidateAllocationContext(Allocation: Record "SI Supply Allocation")
    begin
        Allocation.TestField("Item No.");
        Allocation.TestField("Unit of Measure Code");
        Allocation.TestField("Required on Site At");
        Allocation.TestField("Target Location Code");
    end;

    local procedure SaveDemand(var Demand: Record "SI Planning Demand")
    begin
        if Demand."Entry No." = 0 then
            Demand.Insert(true)
        else
            Demand.Modify(true);
    end;

    var
        RebuildDoneMsg: Label 'Єдиний реєстр планових потреб перебудовано. Створено або оновлено %1 активних рядків.';
        RebuildDoneWithSkippedMsg: Label 'Єдиний реєстр планових потреб перебудовано. Створено або оновлено %1 активних рядків. Виключено %2 осиротілих або закритих розподілів.';
        DecisionNotFoundErr: Label 'Не знайдено рішення %1 для планової потреби.';
        DecisionLineNotFoundErr: Label 'Не знайдено рядок рішення %1 / %2 для планової потреби.';
}
