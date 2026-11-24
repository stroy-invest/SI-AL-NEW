codeunit 61064 "SI Supply Req Overdue Mgt"
{
    // This codeunit never COMMITs. The audit entry and flag update share a transaction.
    Permissions = tabledata "SI Supply Req Header" = rm;

    procedure IsOverdue(Request: Record "SI Supply Req Header"): Boolean
    begin
        if not IsEligible(Request) then
            exit(false);
        exit(GetEarliestRequiredAt(Request."No.") <= CurrentDateTime());
    end;

    procedure TestNotOverdue(Request: Record "SI Supply Req Header")
    begin
        if IsOverdue(Request) then
            Error('Заявка %1 задавнена: дата потреби %2 уже настала. Подальшу обробку заблоковано.',
                Request."No.", GetEarliestRequiredAt(Request."No."));
    end;

    // Resolve the owning request from a supply decision; do not trust a cached Is Overdue flag.
    procedure TestDecisionNotOverdue(DecisionNo: Code[20])
    var
        Decision: Record "SI Supply Decision Header";
        Request: Record "SI Supply Req Header";
    begin
        if not Decision.Get(DecisionNo) then
            Error('Не знайдено план забезпечення %1.', DecisionNo);
        if not Request.Get(Decision."Request No.") then
            Error('Не знайдено заявку %1 для плану забезпечення %2.', Decision."Request No.", DecisionNo);
        TestNotOverdue(Request);
    end;

    procedure TestAllocationNotOverdue(Allocation: Record "SI Supply Allocation")
    begin
        TestDecisionNotOverdue(Allocation."Decision No.");
    end;

    // Call for one record, e.g. from Job Queue. Only actual false -> true is logged.
    procedure SynchronizeOne(RequestNo: Code[20])
    var
        Request: Record "SI Supply Req Header";
        AuditMgt: Codeunit "SI Supply Req Audit Mgt";
        NewValue: Boolean;
    begin
        Request.LockTable();
        if not Request.Get(RequestNo) then
            exit;

        NewValue := IsOverdue(Request);
        if Request."Is Overdue" = NewValue then
            exit;

        Request."Is Overdue" := NewValue;
        // Modify(false) is deliberate: the existing OnModify requires Draft,
        // whereas the overdue flag must also update on approved requests.
        Request.Modify(false);
        if NewValue then
            AuditMgt.LogEvent(Request."No.", "SI Supply Req Event Type"::"Marked Overdue",
                'Is Overdue', 'FALSE', 'TRUE', '',
                StrSubstNo('Найраніша дата потреби за рядками: %1', GetEarliestRequiredAt(Request."No.")), CreateGuid());
    end;

    local procedure IsEligible(Request: Record "SI Supply Req Header"): Boolean
    begin
        if GetEarliestRequiredAt(Request."No.") = 0DT then
            exit(false);
        exit(true);
    end;
    local procedure GetEarliestRequiredAt(RequestNo: Code[20]): DateTime
    var
        RequestLine: Record "SI Supply Req Line";
        EarliestAt: DateTime;
    begin
        RequestLine.SetRange("Request No.", RequestNo);
        RequestLine.SetFilter("Required on Site At", '<>%1', 0DT);
        if RequestLine.FindSet() then
            repeat
                if (EarliestAt = 0DT) or (RequestLine."Required on Site At" < EarliestAt) then
                    EarliestAt := RequestLine."Required on Site At";
            until RequestLine.Next() = 0;
        exit(EarliestAt);
    end;

}
