codeunit 61065 "SI Supply Req Clone Mgt"
{
    // SR-CLONE-001: creates a new business request, not a reopened old request.
    // All writes and both audit events are in the caller transaction (no COMMIT).
    Permissions = tabledata "SI Supply Req Header" = rim,
                  tabledata "SI Supply Req Line" = ri,
                  tabledata "SI Supply Req Parameter" = ri,
                  tabledata "SI Supply Request Site" = rim,
                  tabledata "SI Concrete Supply Spec" = ri;

    procedure TestCloneAllowed(var SourceHeader: Record "SI Supply Req Header")
    begin
        SourceHeader.TestField("No.");
        SourceHeader.TestField("Required on Site At");
        if CurrentDateTime() < SourceHeader."Required on Site At" then
            Error('Заявка %1 ще не задавнена. Клонування доступне після настання дати потреби.', SourceHeader."No.");
        if SourceHeader.Status in [SourceHeader.Status::Fulfilled, SourceHeader.Status::Cancelled] then
            Error('Заявку %1 у статусі %2 не можна клонувати.', SourceHeader."No.", SourceHeader.Status);
    end;

    procedure CloneRequest(SourceRequestNo: Code[20]; NewRequiredAt: DateTime; Reason: Text[250]; var NewHeader: Record "SI Supply Req Header")
    var
        SourceHeader: Record "SI Supply Req Header";
        AuditMgt: Codeunit "SI Supply Req Audit Mgt";
        CorrelationId: Guid;
    begin
        // Re-read source and revalidate AFTER the modal dialog.
        SourceHeader.Get(SourceRequestNo);
        SourceHeader.LockTable();
        SourceHeader.Get(SourceRequestNo);
        TestCloneAllowed(SourceHeader);
        if NewRequiredAt <= SourceHeader."Required on Site At" then
            Error('Нова дата потреби має бути пізнішою за дату вихідної заявки.');
        if NewRequiredAt <= CurrentDateTime() then
            Error('Нова дата потреби має бути строго пізнішою за поточний момент.');
        if DT2Time(NewRequiredAt) = 000000T then
            Error('Вкажіть точний час потреби: 00:00 не допускається.');
        if DelChr(Reason, '<>') = '' then
            Error('Заповніть причину повторного створення заявки.');

        NewHeader.Init();
        NewHeader."Request Type" := SourceHeader."Request Type";
        NewHeader."Request Profile" := SourceHeader."Request Profile";
        NewHeader."Project No." := SourceHeader."Project No.";
        NewHeader."Project Location Code" := SourceHeader."Project Location Code";
        NewHeader."Departure Location Code" := SourceHeader."Departure Location Code";
        NewHeader."Departure Point Code" := SourceHeader."Departure Point Code";
        NewHeader."Destination Point Code" := SourceHeader."Destination Point Code";
        NewHeader."Required on Site At" := NewRequiredAt;
        NewHeader.Description := SourceHeader.Description;
        NewHeader."Cloned From Request No." := SourceHeader."No.";
        // Do not copy identity, external integration, approval or audit metadata.
        NewHeader.Insert(true); // New number, new creator/date, initial project-site rows.

        CopySites(SourceHeader."No.", NewHeader."No.");
        CopyLines(SourceHeader."No.", NewHeader."No.", NewRequiredAt);
        CopyParameters(SourceHeader."No.", NewHeader."No.");
        CopyConcreteSpec(SourceHeader."No.", NewHeader."No.");

        CorrelationId := AuditMgt.NewCorrelationId();
        AuditMgt.LogEvent(SourceHeader."No.", Enum::"SI Supply Req Event Type"::"Request Cloned To",
            'Cloned To Request No.', '', NewHeader."No.", Reason,
            StrSubstNo('Створено нову заявку %1 з датою потреби %2.', NewHeader."No.", Format(NewRequiredAt)), CorrelationId);
        AuditMgt.LogEvent(NewHeader."No.", Enum::"SI Supply Req Event Type"::"Request Cloned From",
            'Cloned From Request No.', '', SourceHeader."No.", Reason,
            StrSubstNo('Вихідна заявка %1; попередня дата потреби %2; нова дата %3.',
                SourceHeader."No.", Format(SourceHeader."Required on Site At"), Format(NewRequiredAt)), CorrelationId);
    end;

    local procedure CopySites(SourceNo: Code[20]; TargetNo: Code[20])
    var
        OldSite: Record "SI Supply Request Site";
        NewSite: Record "SI Supply Request Site";
    begin
        // OnInsert of new header initializes current project sites. Preserve only
        // selections that still exist; never create stale/invalid project sites.
        OldSite.SetRange("Request No.", SourceNo);
        if OldSite.FindSet() then
            repeat
                if NewSite.Get(TargetNo, OldSite."Site Code") then begin
                    NewSite.Selected := OldSite.Selected;
                    NewSite.Modify(true);
                end;
            until OldSite.Next() = 0;
    end;

    local procedure CopyLines(SourceNo: Code[20]; TargetNo: Code[20]; RequiredAt: DateTime)
    var
        OldLine: Record "SI Supply Req Line";
        NewLine: Record "SI Supply Req Line";
    begin
        OldLine.SetRange("Request No.", SourceNo);
        if OldLine.FindSet() then
            repeat
                NewLine.Init();
                NewLine."Request No." := TargetNo;
                NewLine."Line No." := OldLine."Line No.";
                NewLine."Construction Site Code" := OldLine."Construction Site Code";
                NewLine."Line Type" := OldLine."Line Type";
                NewLine."Item No." := OldLine."Item No.";
                NewLine."Variant Code" := OldLine."Variant Code";
                NewLine.Description := OldLine.Description;
                NewLine."Requested Quantity" := OldLine."Requested Quantity";
                NewLine."Unit of Measure Code" := OldLine."Unit of Measure Code";
                NewLine."Required on Site At" := RequiredAt;
                NewLine.Comment := OldLine.Comment;
                // Approved Quantity deliberately stays zero.
                NewLine.Insert(true);
            until OldLine.Next() = 0;
    end;

    local procedure CopyParameters(SourceNo: Code[20]; TargetNo: Code[20])
    var
        OldParam: Record "SI Supply Req Parameter";
        NewParam: Record "SI Supply Req Parameter";
    begin
        OldParam.SetRange("Request No.", SourceNo);
        if OldParam.FindSet() then
            repeat
                NewParam.Init();
                NewParam."Request No." := TargetNo;
                NewParam."Request Line No." := OldParam."Request Line No.";
                NewParam."Parameter Code" := OldParam."Parameter Code";
                NewParam."Value Type" := OldParam."Value Type";
                NewParam."Requested Code Value" := OldParam."Requested Code Value";
                NewParam."Requested Decimal Value" := OldParam."Requested Decimal Value";
                NewParam."Requested Text Value" := OldParam."Requested Text Value";
                NewParam."Requested Bool Value" := OldParam."Requested Bool Value";
                NewParam."Requested Date Value" := OldParam."Requested Date Value";
                NewParam."Requested DateTime Value" := OldParam."Requested DateTime Value";
                NewParam."Unit of Measure Code" := OldParam."Unit of Measure Code";
                NewParam.Source := OldParam.Source;
                NewParam.Insert(true); // Fresh Created At / Created By.
            until OldParam.Next() = 0;
    end;

    local procedure CopyConcreteSpec(SourceNo: Code[20]; TargetNo: Code[20])
    var
        OldSpec: Record "SI Concrete Supply Spec";
        NewSpec: Record "SI Concrete Supply Spec";
    begin
        if not OldSpec.Get(SourceNo) then
            exit;
        NewSpec.Init();
        NewSpec."Request No." := TargetNo;
        NewSpec."Truck Interval Minutes" := OldSpec."Truck Interval Minutes";
        NewSpec."Delivery Address" := OldSpec."Delivery Address";
        NewSpec."Entry Restrictions" := OldSpec."Entry Restrictions";
        NewSpec."Access Road Conditions" := OldSpec."Access Road Conditions";
        NewSpec."Unloading Method" := OldSpec."Unloading Method";
        NewSpec."Concrete Pump Required" := OldSpec."Concrete Pump Required";
        NewSpec."Pump Type" := OldSpec."Pump Type";
        NewSpec."Pump Boom Length" := OldSpec."Pump Boom Length";
        NewSpec."Additional Chute Required" := OldSpec."Additional Chute Required";
        NewSpec."Discharge Pipe Required" := OldSpec."Discharge Pipe Required";
        NewSpec."Contact Name" := OldSpec."Contact Name";
        NewSpec."Contact Phone" := OldSpec."Contact Phone";
        NewSpec."Contact E-Mail" := OldSpec."Contact E-Mail";
        NewSpec."Special Instructions" := OldSpec."Special Instructions";
        NewSpec."Payment Method Text" := OldSpec."Payment Method Text";
        NewSpec.Insert(true);
    end;
}
