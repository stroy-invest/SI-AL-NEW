codeunit 59110 "SI WB Supporting Docs Mgt."
{
    procedure EnsureForDocument(var Header: Record "SI Weighbridge Document")
    begin
        if Header."Entry No." = 0 then
            exit;

        // Receipt/Supply documents are vendor-owned incoming documents.
        // They must be entered by the manager exactly as received and must
        // never be auto-created or auto-numbered by STROYINVEST.
        if Header."Operation Type" = "SI WB Operation Type"::Receipt then begin
            RemoveEmptyLegacyReceiptPlaceholders(Header);
            exit;
        end;

        // Outbound/internal routes contain documents created by STROYINVEST.
        EnsureType(
            Header,
            "SI WB Supporting Doc Type"::TTN,
            Header."TTN No.");

        case Header."Shipment Scenario" of
            "SI WB Shipment Scenario"::Sales:
                EnsureType(
                    Header,
                    "SI WB Supporting Doc Type"::"Delivery Note",
                    Header."Delivery Note No.");

            "SI WB Shipment Scenario"::"Internal Transfer":
                EnsureType(
                    Header,
                    "SI WB Supporting Doc Type"::"Internal Transfer Document",
                    '');
        end;

        EnsureType(
            Header,
            "SI WB Supporting Doc Type"::"Product Passport",
            Header."Product Passport No.");
    end;

    local procedure RemoveEmptyLegacyReceiptPlaceholders(
        Header: Record "SI Weighbridge Document")
    var
        SupportingDoc: Record "SI WB Supporting Document";
    begin
        // 1.1.1.5 and earlier seeded TTN / vendor delivery note / passport
        // placeholders for receipts. Remove only completely empty rows;
        // anything containing user-entered data or an attachment is kept.
        SupportingDoc.Reset();
        SupportingDoc.SetRange("Document Entry No.", Header."Entry No.");

        if SupportingDoc.FindSet(true) then
            repeat
                if IsLegacyReceiptPlaceholderType(SupportingDoc."Document Type") and
                   IsEmptySupportingDocument(SupportingDoc)
                then
                    SupportingDoc.Delete(true);
            until SupportingDoc.Next() = 0;
    end;

    local procedure IsLegacyReceiptPlaceholderType(
        DocumentType: Enum "SI WB Supporting Doc Type"): Boolean
    begin
        exit(
            (DocumentType = "SI WB Supporting Doc Type"::TTN) or
            (DocumentType = "SI WB Supporting Doc Type"::"Vendor Delivery Note") or
            (DocumentType = "SI WB Supporting Doc Type"::"Product Passport"));
    end;

    local procedure IsEmptySupportingDocument(
        var SupportingDoc: Record "SI WB Supporting Document"): Boolean
    begin
        if SupportingDoc."Document No." <> '' then
            exit(false);

        if SupportingDoc."File Name" <> '' then
            exit(false);

        if SupportingDoc.Note <> '' then
            exit(false);

        if SupportingDoc.Generated then
            exit(false);

        exit(not SupportingDoc.HasAttachment());
    end;

    local procedure EnsureType(
        Header: Record "SI Weighbridge Document";
        DocumentType: Enum "SI WB Supporting Doc Type";
        LegacyDocumentNo: Code[50])
    var
        SupportingDoc: Record "SI WB Supporting Document";
    begin
        SupportingDoc.Reset();
        SupportingDoc.SetRange(
            "Document Entry No.",
            Header."Entry No.");
        SupportingDoc.SetRange(
            "Document Type",
            DocumentType);

        if SupportingDoc.FindFirst() then
            exit;

        SupportingDoc.Init();
        SupportingDoc."Document Entry No." := Header."Entry No.";
        SupportingDoc."Line No." := NextLineNo(Header."Entry No.");
        SupportingDoc."Document Type" := DocumentType;
        SupportingDoc."Document No." := LegacyDocumentNo;

        if Header."Weighing Date/Time" <> 0DT then
            SupportingDoc."Document Date" :=
                DT2Date(Header."Weighing Date/Time");

        SupportingDoc.Insert(true);
    end;

    local procedure NextLineNo(
        DocumentEntryNo: BigInteger): Integer
    var
        SupportingDoc: Record "SI WB Supporting Document";
    begin
        SupportingDoc.Reset();
        SupportingDoc.SetRange(
            "Document Entry No.",
            DocumentEntryNo);

        if SupportingDoc.FindLast() then
            exit(SupportingDoc."Line No." + 10000);

        exit(10000);
    end;
}
