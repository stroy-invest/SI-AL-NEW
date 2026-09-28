codeunit 61010 "SI Supply Decision Mgt."
{
    procedure OpenOrCreateFromRequest(var RequestHeader: Record "SI Supply Req Header")
    var
        DecisionHeader: Record "SI Supply Decision Header";
    begin
        RequestHeader.TestField("Project No.");
        RequestHeader.TestField("Project Location Code");
        RequestHeader.TestField("Required on Site At");

        DecisionHeader.SetRange("Request No.", RequestHeader."No.");
        if not DecisionHeader.FindFirst() then
            CreateFromRequest(RequestHeader, DecisionHeader);

        Page.Run(Page::"SI Supply Decision Card", DecisionHeader);
    end;

    procedure CreateFromRequest(var RequestHeader: Record "SI Supply Req Header"; var DecisionHeader: Record "SI Supply Decision Header")
    var
        RequestLine: Record "SI Supply Req Line";
        DecisionLine: Record "SI Supply Decision Line";
        DemandQty: Decimal;
    begin
        RequestHeader.TestField("No.");
        RequestHeader.TestField("Project No.");
        RequestHeader.TestField("Project Location Code");
        RequestHeader.TestField("Required on Site At");
        ValidateRequestDemandLines(RequestHeader);

        DecisionHeader.Init();
        DecisionHeader."No." := RequestHeader."No.";
        DecisionHeader."Request No." := RequestHeader."No.";
        DecisionHeader.Status := DecisionHeader.Status::Draft;
        DecisionHeader."Project No." := RequestHeader."Project No.";
        DecisionHeader."Project Location Code" := RequestHeader."Project Location Code";
        DecisionHeader."Required on Site At" := RequestHeader."Required on Site At";
        DecisionHeader.Insert(true);

        RequestLine.SetRange("Request No.", RequestHeader."No.");
        if not RequestLine.FindSet() then begin
            DecisionHeader.Delete(true);
            Error('Заявка %1 не містить рядків.', RequestHeader."No.");
        end;

        repeat
            DemandQty := RequestLine."Approved Quantity";
            if DemandQty <= 0 then
                DemandQty := RequestLine."Requested Quantity";

            DecisionLine.Init();
            DecisionLine."Decision No." := DecisionHeader."No.";
            DecisionLine."Line No." := RequestLine."Line No.";
            DecisionLine."Request Line No." := RequestLine."Line No.";
            DecisionLine."Line Type" := RequestLine."Line Type";
            DecisionLine."Item No." := RequestLine."Item No.";
            DecisionLine."Variant Code" := RequestLine."Variant Code";
            DecisionLine.Description := RequestLine.Description;
            DecisionLine."Demand Quantity" := DemandQty;
            DecisionLine."Unit of Measure Code" := RequestLine."Unit of Measure Code";
            DecisionLine."Required on Site At" := RequestLine."Required on Site At";
            DecisionLine."Construction Site Code" := RequestLine."Construction Site Code";
            DecisionLine."Target Location Code" := RequestHeader."Project Location Code";
            DecisionLine.Insert(true);
        until RequestLine.Next() = 0;
    end;

    local procedure ValidateRequestDemandLines(var RequestHeader: Record "SI Supply Req Header")
    var
        RequestLine: Record "SI Supply Req Line";
    begin
        RequestLine.SetRange("Request No.", RequestHeader."No.");
        if not RequestLine.FindSet() then
            Error('Заявка %1 не містить рядків.', RequestHeader."No.");

        repeat
            if RequestLine."Line Type" = RequestLine."Line Type"::Item then begin
                if RequestLine."Construction Site Code" = '' then
                    Error('Рядок %1: не вказано будівельний майданчик.', RequestLine."Line No.");
                if RequestLine."Item No." = '' then
                    Error('Рядок %1: не вказано товар.', RequestLine."Line No.");
                if RequestLine."Requested Quantity" <= 0 then
                    Error('Рядок %1: заявлена кількість має бути більшою за нуль.', RequestLine."Line No.");
                if RequestLine."Unit of Measure Code" = '' then
                    Error('Рядок %1: не вказано одиницю виміру.', RequestLine."Line No.");
                if RequestLine."Required on Site At" = 0DT then
                    Error('Рядок %1: не вказано дату та час потреби на об''єкті.', RequestLine."Line No.");
            end;
        until RequestLine.Next() = 0;
    end;

    procedure ApproveRequest(var RequestHeader: Record "SI Supply Req Header")
    var
        DecisionHeader: Record "SI Supply Decision Header";
    begin
        RequestHeader.TestField(Status, RequestHeader.Status::Draft);
        RequestHeader.TestField("Project No.");
        RequestHeader.TestField("Project Location Code");
        RequestHeader.TestField("Required on Site At");
        ValidateRequestDemandLines(RequestHeader);

        DecisionHeader.SetRange("Request No.", RequestHeader."No.");
        if not DecisionHeader.FindFirst() then
            Error('Для заявки %1 ще не сформовано План забезпечення.', RequestHeader."No.");

        ValidateDecisionMatchesRequest(RequestHeader, DecisionHeader);
        ValidateAllocationPlan(DecisionHeader);

        DecisionHeader.MarkReady();
        RequestHeader.MarkApproved();
    end;

    local procedure ValidateDecisionMatchesRequest(RequestHeader: Record "SI Supply Req Header"; DecisionHeader: Record "SI Supply Decision Header")
    var
        RequestLine: Record "SI Supply Req Line";
        DecisionLine: Record "SI Supply Decision Line";
        DemandQty: Decimal;
        RequestLineCount: Integer;
        DecisionLineCount: Integer;
    begin
        RequestLine.SetRange("Request No.", RequestHeader."No.");
        if RequestLine.FindSet() then
            repeat
                RequestLineCount += 1;
                DecisionLine.SetRange("Decision No.", DecisionHeader."No.");
                DecisionLine.SetRange("Request Line No.", RequestLine."Line No.");
                if not DecisionLine.FindFirst() then
                    Error('План забезпечення не містить позицію %1. Оновіть план перед погодженням заявки.', RequestLine.Description);

                DemandQty := RequestLine."Approved Quantity";
                if DemandQty <= 0 then
                    DemandQty := RequestLine."Requested Quantity";

                if (DecisionLine."Item No." <> RequestLine."Item No.") or
                   (DecisionLine."Variant Code" <> RequestLine."Variant Code") or
                   (DecisionLine."Demand Quantity" <> DemandQty) or
                   (DecisionLine."Unit of Measure Code" <> RequestLine."Unit of Measure Code") or
                   (DecisionLine."Required on Site At" <> RequestLine."Required on Site At") or
                   (DecisionLine."Construction Site Code" <> RequestLine."Construction Site Code")
                then
                    Error('План забезпечення не відповідає актуальним даним позиції %1. Оновіть план перед погодженням заявки.', RequestLine.Description);
            until RequestLine.Next() = 0;

        DecisionLine.Reset();
        DecisionLine.SetRange("Decision No.", DecisionHeader."No.");
        DecisionLineCount := DecisionLine.Count();
        if DecisionLineCount <> RequestLineCount then
            Error('План забезпечення не відповідає актуальному складу заявки. Оновіть план перед погодженням.');
    end;

    procedure ValidateAllocationPlan(var DecisionHeader: Record "SI Supply Decision Header")
    var
        DecisionLine: Record "SI Supply Decision Line";
        Allocation: Record "SI Supply Allocation";
    begin
        DecisionHeader.TestField(Status, DecisionHeader.Status::Draft);

        DecisionLine.SetRange("Decision No.", DecisionHeader."No.");
        if not DecisionLine.FindSet() then
            Error('Рішення %1 не містить рядків.', DecisionHeader."No.");

        repeat
            if DecisionLine."Line Type" = DecisionLine."Line Type"::Item then begin
                DecisionLine.TestField("Construction Site Code");
                DecisionLine.TestField("Demand Quantity");
                DecisionLine.TestField("Required on Site At");
                DecisionLine.TestField("Target Location Code");
                DecisionLine.CalcFields("Allocated Quantity");
                if DecisionLine."Allocated Quantity" <> DecisionLine."Demand Quantity" then
                    Error(
                        'Для рядка %1 потрібно забезпечити %2, а розподілено %3.',
                        DecisionLine."Line No.",
                        DecisionLine."Demand Quantity",
                        DecisionLine."Allocated Quantity");

                Allocation.SetRange("Decision No.", DecisionLine."Decision No.");
                Allocation.SetRange("Decision Line No.", DecisionLine."Line No.");
                if not Allocation.FindSet() then
                    Error('Для рядка %1 не визначено жодного способу забезпечення.', DecisionLine."Line No.");

                repeat
                    Allocation.TestField("Supply Method");
                    Allocation.TestField(Quantity);
                    Allocation.TestField("Required on Site At");
                    Allocation.TestField("Construction Site Code");
                    Allocation.TestField("Target Location Code");

                    case Allocation."Supply Method" of
                        Allocation."Supply Method"::Transfer:
                            Allocation.TestField("Source Location Code");
                        Allocation."Supply Method"::Stock:
                            Allocation.TestField("Source Location Code");
                    end;
                until Allocation.Next() = 0;
            end;
        until DecisionLine.Next() = 0;
    end;
}
