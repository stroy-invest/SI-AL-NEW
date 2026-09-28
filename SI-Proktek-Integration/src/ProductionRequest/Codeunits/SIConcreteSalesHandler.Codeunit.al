codeunit 57066 "SI Concrete Sales Handler"
{
    procedure CreateOrOpenFromLine(SalesLine: Record "Sales Line")
    var
        ProdRequest: Record "SI Concrete Prod Request";
        Customer: Record Customer;
    begin
        ValidateSalesLine(SalesLine);

        ProdRequest.SetRange("Source Type", ProdRequest."Source Type"::"External Sale");
        ProdRequest.SetRange("Source No.", SalesLine."Document No.");
        ProdRequest.SetRange("Source Line No.", SalesLine."Line No.");
        if ProdRequest.FindFirst() then begin
            Page.Run(Page::"SI Concrete Prod Req Card", ProdRequest);
            exit;
        end;

        Customer.Get(SalesLine."Sell-to Customer No.");
        if Customer."SI Customer Type" <> Customer."SI Customer Type"::External then
            Error('Клієнт %1 не має тип External.', Customer."No.");

        ProdRequest.Init();
        ProdRequest."Source Type" := ProdRequest."Source Type"::"External Sale";
        ProdRequest."Source No." := SalesLine."Document No.";
        ProdRequest."Source Line No." := SalesLine."Line No.";
        ProdRequest."Customer No." := SalesLine."Sell-to Customer No.";
        ProdRequest.Validate("Item No.", SalesLine."No.");
        if SalesLine."Variant Code" <> '' then
            ProdRequest.Validate("Variant Code", SalesLine."Variant Code");
        ProdRequest.Validate(Quantity, SalesLine.Quantity);
        if SalesLine."Unit of Measure Code" <> '' then
            ProdRequest.Validate("Unit of Measure Code", SalesLine."Unit of Measure Code");
        ProdRequest.Description := CopyStr(StrSubstNo('Sales Order %1, line %2', SalesLine."Document No.", SalesLine."Line No."), 1, MaxStrLen(ProdRequest.Description));
        ProdRequest.Insert(true);

        Page.Run(Page::"SI Concrete Prod Req Card", ProdRequest);
    end;

    local procedure ValidateSalesLine(SalesLine: Record "Sales Line")
    begin
        if SalesLine."Document Type" <> SalesLine."Document Type"::Order then
            Error('Заявку на виробництво можна створити тільки з Sales Order.');
        if SalesLine.Type <> SalesLine.Type::Item then
            Error('Поточний рядок Sales Order не є товаром.');
        SalesLine.TestField("No.");
        SalesLine.TestField("Sell-to Customer No.");
        if SalesLine.Quantity <= 0 then
            Error('Кількість у рядку Sales Order повинна бути більшою за нуль.');
    end;
}
