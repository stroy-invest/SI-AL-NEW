codeunit 61054 "SI Proc. Plan Snapshot Mgt."
{
    Permissions =
        tabledata "SI Proc. Plan Run" = RIMD,
        tabledata "SI Proc. Plan Snapshot" = RIMD,
        tabledata "SI Proc. Plan Demand Link" = RIMD,
        tabledata "SI Proc. Plan Trace" = RIMD;

    procedure Capture(TemplateName: Code[10]; BatchName: Code[10]; ForecastName: Code[10]; StartDate: Date; EndDate: Date): Integer
    var
        Run: Record "SI Proc. Plan Run";
        OldRun: Record "SI Proc. Plan Run";
        ReqLine: Record "Requisition Line";
        Snapshot: Record "SI Proc. Plan Snapshot";
        LineCount: Integer;
        LinkCount: Integer;
    begin
        OldRun.SetRange(Current, true);
        if OldRun.FindSet(true) then
            repeat
                OldRun.Current := false;
                OldRun.Modify();
            until OldRun.Next() = 0;

        Run.Init();
        Run."Created At" := CurrentDateTime();
        Run."Created By" := CopyStr(UserId(), 1, MaxStrLen(Run."Created By"));
        Run."Planning Start Date" := StartDate;
        Run."Planning End Date" := EndDate;
        Run."Forecast Name" := ForecastName;
        Run."Worksheet Template Name" := TemplateName;
        Run."Worksheet Batch Name" := BatchName;
        Run.Current := true;
        Run.Insert(true);

        ReqLine.SetRange("Worksheet Template Name", TemplateName);
        ReqLine.SetRange("Journal Batch Name", BatchName);
        ReqLine.SetRange(Type, ReqLine.Type::Item);
        ReqLine.SetFilter(Quantity, '<>0');
        if ReqLine.FindSet() then
            repeat
                Snapshot.Init();
                Snapshot."Run No." := Run."Run No.";
                Snapshot."Line No." := ReqLine."Line No.";
                Snapshot."Req. Worksheet Line No." := ReqLine."Line No.";
                Snapshot.Validate("Item No.", ReqLine."No.");
                Snapshot.Validate("Variant Code", ReqLine."Variant Code");
                Snapshot.Description := ReqLine.Description;
                Snapshot.Validate("Location Code", ReqLine."Location Code");
                Snapshot.Quantity := ReqLine.Quantity;
                Snapshot."Quantity (Base)" := ReqLine."Quantity (Base)";
                Snapshot."Unit of Measure Code" := ReqLine."Unit of Measure Code";
                Snapshot."Due Date" := ReqLine."Due Date";
                Snapshot."Order Date" := ReqLine."Order Date";
                Snapshot."Action Message" := ReqLine."Action Message";
                Snapshot."Vendor No." := ReqLine."Vendor No.";
                Snapshot."Demand Quantity" := ReqLine."Demand Quantity";
                Snapshot."Demand Quantity (Base)" := ReqLine."Demand Quantity (Base)";
                Snapshot.Insert(true);
                LineCount += 1;
                LinkCount += CaptureLinks(Run."Run No.", Snapshot, TemplateName, BatchName);
            until ReqLine.Next() = 0;

        Run."Line Count" := LineCount;
        Run."Trace Link Count" := LinkCount;
        Run.Modify();
        exit(Run."Run No.");
    end;

    procedure OpenCurrentSnapshot()
    var
        Run: Record "SI Proc. Plan Run";
        Snapshot: Record "SI Proc. Plan Snapshot";
    begin
        Run.SetRange(Current, true);
        if not Run.FindLast() then
            Error(NoSnapshotErr);
        Snapshot.SetRange("Run No.", Run."Run No.");
        Page.Run(Page::"SI Proc. Plan Snapshot", Snapshot);
    end;

    local procedure CaptureLinks(RunNo: Integer; Snapshot: Record "SI Proc. Plan Snapshot"; TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        Trace: Record "SI Proc. Plan Trace";
        Projection: Record "SI Planning Forecast Proj.";
        Demand: Record "SI Planning Demand";
        Link: Record "SI Proc. Plan Demand Link";
        Count: Integer;
    begin
        Trace.SetRange("Worksheet Template Name", TemplateName);
        Trace.SetRange("Worksheet Batch Name", BatchName);
        Trace.SetRange("Worksheet Line No.", Snapshot."Req. Worksheet Line No.");
        if Trace.FindSet() then
            repeat
                Projection.SetRange("Forecast Entry No.", Trace."Forecast Entry No.");
                if Projection.FindFirst() then begin
                    if Demand.Get(Projection."Planning Demand Entry No.") then begin
                        Link.Init();
                        Link."Run No." := RunNo;
                        Link."Snapshot Line No." := Snapshot."Line No.";
                        Link."Planning Demand Entry No." := Demand."Entry No.";
                        Link."Forecast Entry No." := Trace."Forecast Entry No.";
                        Link.Insert(true);
                        Count += 1;
                    end;
                end;
                Projection.Reset();
            until Trace.Next() = 0;
        exit(Count);
    end;

    var
        NoSnapshotErr: Label 'Ще немає знімка результату планування закупівель.';
}
