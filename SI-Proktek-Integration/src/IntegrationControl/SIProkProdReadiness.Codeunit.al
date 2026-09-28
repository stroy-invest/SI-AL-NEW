using STROYINVEST.ConcreteRecipeEngine;
using Microsoft.Manufacturing.ProductionBOM;

codeunit 57078 "SI Prok Prod Readiness"
{
    procedure ValidateRecipe(RecipeNo: Code[50]; RevisionNo: Integer)
    var
        Connection: Record "SI Prok Connection";
        ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
    begin
        ConnectionMgt.GetActive(Connection);
        ValidateRecipeForConnection(Connection, RecipeNo, RevisionNo);
    end;

    procedure ValidateRecipeForConnection(
        Connection: Record "SI Prok Connection";
        RecipeNo: Code[50];
        RevisionNo: Integer)
    var
        Recipe: Record "SI Concrete Recipe";
        Revision: Record "SI Concrete Recipe Revision";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        Mapping: Record "SI Prok Entity Mapping";
    begin
        if RecipeNo = '' then
            Error('Для виробничого розподілу не вибрано рецептуру.');
        if RevisionNo <= 0 then
            Error('Для рецептури %1 не вибрано ревізію.', RecipeNo);

        if not Recipe.Get(RecipeNo) then
            Error('Рецептуру %1 не знайдено в BC.', RecipeNo);
        if not Revision.Get(RecipeNo, RevisionNo) then
            Error('Ревізію %1 рецептури %2 не знайдено в BC.', RevisionNo, RecipeNo);

        if Revision.Status <> Revision.Status::Certified then
            Error('Ревізія %1 рецептури %2 не сертифікована. Виробничий розподіл неможливий.', RevisionNo, RecipeNo);
        if Revision."Administrative Status" <> Revision."Administrative Status"::Active then
            Error('Ревізія %1 рецептури %2 неактивна в BC. Виробничий розподіл неможливий.', RevisionNo, RecipeNo);

        if Revision."Projection Status" <> Revision."Projection Status"::Projected then
            Error('Для ревізії %1 рецептури %2 не створено коректну проєкцію у виробничу специфікацію BC. Спочатку виконайте проєкцію Production BOM.', RevisionNo, RecipeNo);
        Revision.TestField("Production BOM Version Code");
        Recipe.TestField("Production BOM No.");

        if not ProdBOMHeader.Get(Recipe."Production BOM No.") then
            Error('Виробничу специфікацію %1 для рецептури %2 фізично не знайдено в BC.', Recipe."Production BOM No.", RecipeNo);
        if not ProdBOMVersion.Get(Recipe."Production BOM No.", Revision."Production BOM Version Code") then
            Error('Версію %1 виробничої специфікації %2 для ревізії %3 рецептури %4 фізично не знайдено в BC.',
                Revision."Production BOM Version Code", Recipe."Production BOM No.", RevisionNo, RecipeNo);
        if ProdBOMVersion.Status <> ProdBOMVersion.Status::Certified then
            Error('Версія %1 виробничої специфікації %2 для ревізії %3 не сертифікована.',
                Revision."Production BOM Version Code", Recipe."Production BOM No.", RevisionNo);

        if not Mapping.Get(Connection.Code, Mapping."Entity Type"::Formula, Revision.SystemId) then
            Error('Ревізію %1 рецептури %2 ще не синхронізовано з Proktek. Спочатку опублікуйте Formula.', RevisionNo, RecipeNo);
        if Mapping."SI Formula Proj. Status" <> Mapping."SI Formula Proj. Status"::Published then
            Error('Formula для ревізії %1 рецептури %2 не має статусу «Опубліковано» в Proktek.', RevisionNo, RecipeNo);
        if (Mapping."Proktek Internal Code" <= 0) or IsNullGuid(Mapping."Proktek UUID") then
            Error('Formula для ревізії %1 рецептури %2 не має валідних recete_index/UUID. Повторно опублікуйте Formula.', RevisionNo, RecipeNo);
        if not Mapping."SI Proktek Active" then
            Error('Formula для ревізії %1 рецептури %2 синхронізована з Proktek, але НЕ АКТИВОВАНА. Спочатку активуйте Formula.', RevisionNo, RecipeNo);
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    var
        EmptyGuid: Guid;
    begin
        exit(Value = EmptyGuid);
    end;
}
