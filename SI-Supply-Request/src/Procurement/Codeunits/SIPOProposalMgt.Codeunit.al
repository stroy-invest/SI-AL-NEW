codeunit 61056 "SI PO Proposal Mgt."
{
    procedure RebuildCurrentRun()
    var
        Run: Record "SI Proc. Plan Run";
    begin
        Run.SetRange(Current, true);
        if not Run.FindLast() then
            Error(NoPlanErr);
        Rebuild(Run."Run No.");
    end;

    procedure Rebuild(RunNo: Integer)
    var
        Allocation: Record "SI Procurement Allocation";
    begin
        DeleteRunProposals(RunNo);

        Allocation.SetRange("Planning Run No.", RunNo);
        Allocation.SetRange(Status, Allocation.Status::Confirmed);
        if Allocation.FindSet() then
            repeat
                AddAllocation(Allocation);
            until Allocation.Next() = 0;
    end;

    local procedure AddAllocation(Allocation: Record "SI Procurement Allocation")
    var
        Snapshot: Record "SI Proc. Plan Snapshot";
        Capability: Record "SI Vendor Supply Capability";
        Vendor: Record Vendor;
        Header: Record "SI PO Proposal Header";
        Line: Record "SI PO Proposal Line";
        Link: Record "SI PO Proposal Alloc. Link";
    begin
        Snapshot.Get(Allocation."Planning Run No.", Allocation."Snapshot Line No.");
        Capability.Get(Allocation."Capability Code");
        Vendor.Get(Allocation."Vendor No.");

        GetOrCreateHeader(Allocation, Snapshot, Capability, Vendor, Header);
        GetOrCreateLine(Header, Allocation, Snapshot, Line);

        Line.Validate(Quantity, Line.Quantity + Allocation."Purchase Quantity");
        Line.Modify(true);

        Link.Init();
        Link.Validate("Proposal Entry No.", Header."Entry No.");
        Link.Validate("Proposal Line No.", Line."Line No.");
        Link.Validate("Allocation Entry No.", Allocation."Entry No.");
        Link.Validate(Quantity, Allocation."Purchase Quantity");
        Link.Insert(true);
    end;

    local procedure GetOrCreateHeader(Allocation: Record "SI Procurement Allocation"; Snapshot: Record "SI Proc. Plan Snapshot"; Capability: Record "SI Vendor Supply Capability"; Vendor: Record Vendor; var Header: Record "SI PO Proposal Header")
    begin
        Header.SetRange("Planning Run No.", Allocation."Planning Run No.");
        Header.SetRange("Vendor No.", Allocation."Vendor No.");
        Header.SetRange("Location Code", Snapshot."Location Code");
        Header.SetRange("Expected Receipt Date", Allocation."Expected Receipt Date");
        Header.SetRange("Shipment Method Code", Capability."Shipment Method Code");
        Header.SetRange("Currency Code", Vendor."Currency Code");
        if Header.FindFirst() then
            exit;

        Header.Init();
        Header.Validate("Planning Run No.", Allocation."Planning Run No.");
        Header.Validate("Vendor No.", Allocation."Vendor No.");
        Header.Validate("Location Code", Snapshot."Location Code");
        Header.Validate("Expected Receipt Date", Allocation."Expected Receipt Date");
        Header.Validate("Shipment Method Code", Capability."Shipment Method Code");
        Header.Validate("Currency Code", Vendor."Currency Code");
        Header.Insert(true);
    end;

    local procedure GetOrCreateLine(Header: Record "SI PO Proposal Header"; Allocation: Record "SI Procurement Allocation"; Snapshot: Record "SI Proc. Plan Snapshot"; var Line: Record "SI PO Proposal Line")
    var
        LastLine: Record "SI PO Proposal Line";
        NextLineNo: Integer;
    begin
        Line.SetRange("Proposal Entry No.", Header."Entry No.");
        Line.SetRange("Item No.", Snapshot."Item No.");
        Line.SetRange("Variant Code", Snapshot."Variant Code");
        Line.SetRange("Unit of Measure Code", Allocation."Unit of Measure Code");
        Line.SetRange("Location Code", Snapshot."Location Code");
        Line.SetRange("Capability Code", Allocation."Capability Code");
        if Line.FindFirst() then
            exit;

        LastLine.SetRange("Proposal Entry No.", Header."Entry No.");
        if LastLine.FindLast() then
            NextLineNo := LastLine."Line No." + 10000
        else
            NextLineNo := 10000;

        Line.Init();
        Line.Validate("Proposal Entry No.", Header."Entry No.");
        Line.Validate("Line No.", NextLineNo);
        Line.Validate("Item No.", Snapshot."Item No.");
        Line.Validate("Variant Code", Snapshot."Variant Code");
        Line.Validate(Description, Snapshot.Description);
        Line.Validate("Unit of Measure Code", Allocation."Unit of Measure Code");
        Line.Validate("Location Code", Snapshot."Location Code");
        Line.Validate("Capability Code", Allocation."Capability Code");
        Line.Validate(Quantity, 0);
        Line.Insert(true);
    end;

    local procedure DeleteRunProposals(RunNo: Integer)
    var
        Header: Record "SI PO Proposal Header";
        Line: Record "SI PO Proposal Line";
        Link: Record "SI PO Proposal Alloc. Link";
    begin
        Header.SetRange("Planning Run No.", RunNo);
        Header.SetRange(Status, Header.Status::Draft);
        if Header.FindSet(true) then
            repeat
                Link.SetRange("Proposal Entry No.", Header."Entry No.");
                Link.DeleteAll(true);
                Line.SetRange("Proposal Entry No.", Header."Entry No.");
                Line.DeleteAll(true);
                Header.Delete(true);
            until Header.Next() = 0;
    end;

    var
        NoPlanErr: Label 'Немає актуального плану закупівель.';
}
