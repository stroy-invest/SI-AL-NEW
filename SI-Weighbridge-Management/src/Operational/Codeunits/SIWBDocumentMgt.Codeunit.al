codeunit 59100 "SI WB Document Mgt."
{
    procedure CreateFromWeighing(
        WeighingRecord: Record "SI Weighing Record";
        var WeighbridgeDocument: Record "SI Weighbridge Document"): Boolean
    var
        DocumentFactory: Codeunit "SI WB Document Factory";
        ExistingDocument: Record "SI Weighbridge Document";
    begin
        WeighingRecord.TestField("Entry No.");

        ExistingDocument.Reset();
        ExistingDocument.SetRange(
            "Weighing Entry No.",
            WeighingRecord."Entry No.");

        if ExistingDocument.FindFirst() then begin
            DocumentFactory.EnsureDocumentForWeighing(
                WeighingRecord,
                WeighbridgeDocument);

            exit(false);
        end;

        DocumentFactory.EnsureDocumentForWeighing(
            WeighingRecord,
            WeighbridgeDocument);

        exit(true);
    end;

    procedure OpenOrCreateFromWeighing(
        WeighingRecord: Record "SI Weighing Record")
    var
        WeighbridgeDocument: Record "SI Weighbridge Document";
    begin
        CreateFromWeighing(
            WeighingRecord,
            WeighbridgeDocument);

        Page.Run(
            Page::"SI Weighbridge Document Card",
            WeighbridgeDocument);
    end;
    procedure SubmitToManager(
        var WeighbridgeDocument: Record "SI Weighbridge Document")
    var
        UoMConversionMgt: Codeunit "SI WB UoM Conversion Mgt.";
        BasisType: Enum "SI WB Basis Type";
    begin
        if WeighbridgeDocument.Status <>
           "SI WB Document Status"::New
        then
            Error(
                'Передати менеджеру можна тільки документ у статусі "Новий". Поточний статус: %1.',
                Format(WeighbridgeDocument.Status));

        UoMConversionMgt.EnsureCanAdvance(WeighbridgeDocument);

        BasisType := ResolveBasisType(WeighbridgeDocument);

        WeighbridgeDocument."Basis Type" := BasisType;
        Clear(WeighbridgeDocument."Basis No.");
        WeighbridgeDocument."Submitted At" := CurrentDateTime();
        WeighbridgeDocument."Submitted By" := UserSecurityId();
        WeighbridgeDocument.Status :=
            "SI WB Document Status"::Submitted;
        WeighbridgeDocument.Modify(true);
    end;

    procedure ResolveBasisType(
        WeighbridgeDocument: Record "SI Weighbridge Document")
        BasisType: Enum "SI WB Basis Type"
    begin
        case WeighbridgeDocument."Operation Type" of
            "SI WB Operation Type"::Receipt:
                begin
                    if WeighbridgeDocument."Shipment Scenario" <>
                       "SI WB Shipment Scenario"::Supply
                    then
                        Error('Для надходження очікується сценарій "Постачання".');

                    exit("SI WB Basis Type"::"Purchase Order");
                end;

            "SI WB Operation Type"::Shipment:
                case WeighbridgeDocument."Shipment Scenario" of
                    "SI WB Shipment Scenario"::Sales:
                        exit("SI WB Basis Type"::"Sales Order");

                    "SI WB Shipment Scenario"::"Internal Transfer":
                        exit("SI WB Basis Type"::Request);

                    else
                        Error('Для відвантаження не визначено допустимий тип операції.');
                end;
        end;

        Error('Для документа %1 не визначено тип підстави.', WeighbridgeDocument."Document No.");
    end;

    procedure EnsureOperatorEditable(
        WeighbridgeDocument: Record "SI Weighbridge Document")
    begin
        if WeighbridgeDocument.Status <>
           "SI WB Document Status"::New
        then
            Error(
                'Документ %1 уже передано менеджеру і не може редагуватися оператором.',
                WeighbridgeDocument."Document No.");
    end;

}
