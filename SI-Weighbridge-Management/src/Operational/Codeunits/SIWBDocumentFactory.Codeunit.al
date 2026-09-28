codeunit 59102 "SI WB Document Factory"
{
    procedure EnsureDocumentForWeighing(
        WeighingRecord: Record "SI Weighing Record";
        var WeighbridgeDocument: Record "SI Weighbridge Document")
    var
        OperationType: Enum "SI WB Operation Type";
    begin
        OperationType := ResolveOperationType(WeighingRecord);

        WeighbridgeDocument.Reset();
        WeighbridgeDocument.SetRange(
            "Weighing Entry No.",
            WeighingRecord."Entry No.");

        if WeighbridgeDocument.FindFirst() then begin
            EnsureExistingOperationType(
                WeighbridgeDocument,
                OperationType);

            EnsureBusinessScenario(
                WeighbridgeDocument,
                OperationType);

            EnsureDefaultLine(WeighbridgeDocument);
            exit;
        end;

        CreateDocument(
            WeighingRecord,
            OperationType,
            WeighbridgeDocument);

        EnsureDefaultLine(WeighbridgeDocument);
    end;

    local procedure CreateDocument(
        WeighingRecord: Record "SI Weighing Record";
        OperationType: Enum "SI WB Operation Type";
        var WeighbridgeDocument: Record "SI Weighbridge Document")
    begin
        WeighbridgeDocument.Init();

        WeighbridgeDocument."Weighing Entry No." :=
            WeighingRecord."Entry No.";

        WeighbridgeDocument."Operation Type" :=
            OperationType;

        case OperationType of
            "SI WB Operation Type"::Receipt:
                WeighbridgeDocument."Shipment Scenario" :=
                    "SI WB Shipment Scenario"::Supply;

            "SI WB Operation Type"::Shipment:
                WeighbridgeDocument."Shipment Scenario" :=
                    "SI WB Shipment Scenario"::Undefined;
        end;

        WeighbridgeDocument."Weighing Date/Time" :=
            WeighingRecord."Event Date/Time";

        WeighbridgeDocument."Gross Weight" :=
            WeighingRecord."Gross Weight";

        WeighbridgeDocument."Tare Weight" :=
            WeighingRecord."Tare Weight";

        WeighbridgeDocument."Net Weight" :=
            WeighingRecord."Net Weight";

        WeighbridgeDocument."Vehicle Plate" :=
            WeighingRecord."Vehicle Plate";

        WeighbridgeDocument."Trailer Plate" :=
            WeighingRecord."Trailer Plate";

        WeighbridgeDocument."Site Code" :=
            WeighingRecord."Site Code";

        WeighbridgeDocument."Scale No." :=
            WeighingRecord."Scale No.";

        WeighbridgeDocument.Status :=
            "SI WB Document Status"::New;

        WeighbridgeDocument.Insert(true);
    end;

    local procedure ResolveOperationType(
        WeighingRecord: Record "SI Weighing Record")
        OperationType: Enum "SI WB Operation Type"
    begin
        if not WeighingRecord."Source Operation Type Present" then
            Error(
                'Тип операції PromSoft відсутній для зважування %1.',
                WeighingRecord."Entry No.");

        case WeighingRecord."Source Operation Type" of
            0:
                exit("SI WB Operation Type"::Receipt);
            1:
                exit("SI WB Operation Type"::Shipment);
            else
                Error(
                    'Некоректний тип операції PromSoft %1 для зважування %2. Очікується 0 або 1.',
                    WeighingRecord."Source Operation Type",
                    WeighingRecord."Entry No.");
        end;
    end;

    local procedure EnsureExistingOperationType(
        WeighbridgeDocument: Record "SI Weighbridge Document";
        ExpectedOperationType: Enum "SI WB Operation Type")
    begin
        if WeighbridgeDocument."Operation Type" =
           ExpectedOperationType
        then
            exit;

        Error(
            'Операційний документ %1 уже має тип операції %2, але зважування %3 визначає тип %4.',
            WeighbridgeDocument."Document No.",
            Format(WeighbridgeDocument."Operation Type"),
            WeighbridgeDocument."Weighing Entry No.",
            Format(ExpectedOperationType));
    end;

    local procedure EnsureBusinessScenario(
        var WeighbridgeDocument: Record "SI Weighbridge Document";
        OperationType: Enum "SI WB Operation Type")
    var
        MustModify: Boolean;
    begin
        case OperationType of
            "SI WB Operation Type"::Receipt:
                if WeighbridgeDocument."Shipment Scenario" <>
                   "SI WB Shipment Scenario"::Supply
                then begin
                    WeighbridgeDocument."Shipment Scenario" :=
                        "SI WB Shipment Scenario"::Supply;
                    Clear(WeighbridgeDocument."Customer No.");
                    Clear(WeighbridgeDocument."Project No.");
                    MustModify := true;
                end;

            "SI WB Operation Type"::Shipment:
                if WeighbridgeDocument."Shipment Scenario" =
                   "SI WB Shipment Scenario"::Supply
                then begin
                    WeighbridgeDocument."Shipment Scenario" :=
                        "SI WB Shipment Scenario"::Undefined;
                    MustModify := true;
                end;
        end;

        if MustModify then
            WeighbridgeDocument.Modify(true);
    end;

    local procedure EnsureDefaultLine(
        WeighbridgeDocument: Record "SI Weighbridge Document")
    var
        WeighbridgeLine: Record "SI Weighbridge Document Line";
    begin
        WeighbridgeLine.Reset();
        WeighbridgeLine.SetRange(
            "Document Entry No.",
            WeighbridgeDocument."Entry No.");

        if not WeighbridgeLine.IsEmpty() then
            exit;

        WeighbridgeLine.Init();
        WeighbridgeLine."Document Entry No." :=
            WeighbridgeDocument."Entry No.";
        WeighbridgeLine."Line No." := 10000;

        WeighbridgeLine.EnsureWeightUoM();
        WeighbridgeLine.Validate(
            "Allocated Weight",
            WeighbridgeDocument."Net Weight");

        WeighbridgeLine.Insert(true);
    end;
}