namespace STROYINVEST.ConcreteRecipeEngine;

codeunit 62202 "SI Recipe Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        MigrateLegacyClosedCertificationState();
    end;

    local procedure MigrateLegacyClosedCertificationState()
    var
        RecipeRevision: Record "SI Concrete Recipe Revision";
    begin
        RecipeRevision.SetRange(Status, RecipeRevision.Status::Closed);
        if RecipeRevision.FindSet(true) then
            repeat
                RecipeRevision.Status := RecipeRevision.Status::Certified;
                RecipeRevision."Administrative Status" := RecipeRevision."Administrative Status"::Inactive;
                RecipeRevision.Modify(false);
            until RecipeRevision.Next() = 0;
    end;
}
