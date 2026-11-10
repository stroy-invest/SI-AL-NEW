codeunit 57101 "SI Prok Production Plan Mgt."
{
    // Idempotent immutable snapshot, keyed by production request Entry No.
    procedure EnsurePlan(ProdRequest: Record "SI Concrete Prod Request")
    var
        Plan: Record "SI Prok Production Plan";
        PlanLine: Record "SI Prok Production Plan Line";
        Recipe: Record "SI Concrete Recipe";
        Revision: Record "SI Concrete Recipe Revision";
        BOMVersion: Record "Production BOM Version";
        BOMLine: Record "Production BOM Line";
        RequestUoM: Record "Item Unit of Measure";
        OutputUoM: Record "Item Unit of Measure";
        BOMNo: Code[20];
        VersionCode: Code[20];
        OutputQty: Decimal;
        LinesCreated: Integer;
    begin
        ProdRequest.TestField("Entry No.");
        if Plan.Get(ProdRequest."Entry No.") then
            exit;

        ProdRequest.TestField("Recipe No.");
        ProdRequest.TestField("Recipe Revision No.");
        ProdRequest.TestField("Item No.");
        ProdRequest.TestField("Unit of Measure Code");
        if ProdRequest.Quantity <= 0 then
            Error('Планова кількість виробничої заявки %1 має бути додатною.', ProdRequest."Entry No.");

        Recipe.Get(ProdRequest."Recipe No.");
        Revision.Get(ProdRequest."Recipe No.", ProdRequest."Recipe Revision No.");
        Recipe.TestField("Production BOM No.");
        Revision.TestField("Production BOM Version Code");
        Recipe.TestField("Output UoM Code");
        if (Recipe."Item No." <> ProdRequest."Item No.") or (Recipe."Variant Code" <> ProdRequest."Variant Code") then
            Error('Продукція виробничої заявки %1 не відповідає рецептурі %2.', ProdRequest."Entry No.", Recipe."Recipe No.");

        BOMNo := Recipe."Production BOM No.";
        VersionCode := Revision."Production BOM Version Code";
        BOMVersion.Get(BOMNo, VersionCode);

        // Normalize planned output into the recipe output UoM using standard Item UoM factors.
        RequestUoM.Get(ProdRequest."Item No.", ProdRequest."Unit of Measure Code");
        OutputUoM.Get(ProdRequest."Item No.", Recipe."Output UoM Code");
        if OutputUoM."Qty. per Unit of Measure" <= 0 then
            Error('Некоректний коефіцієнт одиниці випуску %1.', Recipe."Output UoM Code");
        OutputQty := ProdRequest.Quantity * RequestUoM."Qty. per Unit of Measure" / OutputUoM."Qty. per Unit of Measure";

        Plan.Init();
        Plan."Prod. Request Entry No." := ProdRequest."Entry No.";
        Plan."Source No." := ProdRequest."Source No.";
        Plan."Item No." := ProdRequest."Item No.";
        Plan."Variant Code" := ProdRequest."Variant Code";
        Plan."Planned Quantity" := ProdRequest.Quantity;
        Plan."Unit of Measure Code" := ProdRequest."Unit of Measure Code";
        Plan."Recipe No." := ProdRequest."Recipe No.";
        Plan."Recipe Revision No." := ProdRequest."Recipe Revision No.";
        Plan."Production BOM No." := BOMNo;
        Plan."Production BOM Version Code" := VersionCode;
        Plan."Created At" := CurrentDateTime();
        Plan."Created By" := CopyStr(UserId(), 1, MaxStrLen(Plan."Created By"));
        Plan.Insert(false);

        BOMLine.SetRange("Production BOM No.", BOMNo);
        BOMLine.SetRange("Version Code", VersionCode);
        if not BOMLine.FindSet() then
            Error('Специфікація %1 / %2 не має рядків.', BOMNo, VersionCode);
        repeat
            if BOMLine.Type <> BOMLine.Type::Item then
                Error('Непідтримуваний тип рядка %1 у BOM %2 / %3.', BOMLine."Line No.", BOMNo, VersionCode);
            BOMLine.TestField("No.");
            PlanLine.Init();
            PlanLine."Prod. Request Entry No." := Plan."Prod. Request Entry No.";
            PlanLine."Line No." := BOMLine."Line No.";
            PlanLine."Item No." := BOMLine."No.";
            PlanLine.Description := BOMLine.Description;
            PlanLine."Variant Code" := BOMLine."Variant Code";
            PlanLine."Unit of Measure Code" := BOMLine."Unit of Measure Code";
            PlanLine."Quantity per" := BOMLine."Quantity per";
            PlanLine."Planned Quantity" := BOMLine."Quantity per" * OutputQty;
            PlanLine.Insert(false);
            LinesCreated += 1;
        until BOMLine.Next() = 0;
        if LinesCreated = 0 then
            Error('План виробництва не містить матеріалів.');
    end;
}
