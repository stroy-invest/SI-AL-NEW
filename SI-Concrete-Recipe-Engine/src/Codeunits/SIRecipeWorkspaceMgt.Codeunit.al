namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;

codeunit 62206 "SI Recipe Workspace Mgt."
{
    procedure BuildRecipeTreeJson(): Text
    var
        BaseRecipe: Record "SI Concrete Recipe";
        JsonText: Text;
        FirstCategory: Boolean;
        LastCategoryCode: Code[20];
    begin
        JsonText := '[';
        FirstCategory := true;

        BaseRecipe.SetRange("Recipe Type", BaseRecipe."Recipe Type"::Base);
        BaseRecipe.SetCurrentKey("Subcategory Code", "Item No.", "Variant Code");
        if BaseRecipe.FindSet() then
            repeat
                if BaseRecipe."Subcategory Code" <> LastCategoryCode then begin
                    if not FirstCategory then
                        JsonText += ',';
                    JsonText += BuildCategoryNodeJson(BaseRecipe."Subcategory Code");
                    FirstCategory := false;
                    LastCategoryCode := BaseRecipe."Subcategory Code";
                end;
            until BaseRecipe.Next() = 0;

        JsonText += ']';
        exit(JsonText);
    end;

    procedure BuildRevisionGridJson(RecipeNo: Code[50]; EmptyText: Text): Text
    var
        Revision: Record "SI Concrete Recipe Revision";
        JsonText: Text;
        FirstRow: Boolean;
    begin
        JsonText := '{"emptyText":"' + JsonEscape(EmptyText) + '","rows":[';
        FirstRow := true;

        if RecipeNo <> '' then begin
            Revision.SetRange("Recipe No.", RecipeNo);
            Revision.SetCurrentKey("Recipe No.", "Revision No.");
            if Revision.FindSet() then
                repeat
                    if not FirstRow then
                        JsonText += ',';
                    JsonText += BuildRevisionRowJson(Revision);
                    FirstRow := false;
                until Revision.Next() = 0;
        end;

        JsonText += ']}';
        exit(JsonText);
    end;

    procedure OpenRecipe(RecipeNo: Code[50])
    var
        Recipe: Record "SI Concrete Recipe";
    begin
        if RecipeNo = '' then
            exit;
        Recipe.Get(RecipeNo);
        Page.RunModal(Page::"SI Concrete Recipe Card", Recipe);
    end;

    procedure OpenRevision(RecipeNo: Code[50]; RevisionNo: Integer)
    var
        Revision: Record "SI Concrete Recipe Revision";
    begin
        Revision.Get(RecipeNo, RevisionNo);
        Page.RunModal(Page::"SI Recipe Revision Card", Revision);
    end;

    procedure OpenBOMVersion(RecipeNo: Code[50]; RevisionNo: Integer)
    var
        Recipe: Record "SI Concrete Recipe";
        Revision: Record "SI Concrete Recipe Revision";
        ProdBOMVersion: Record "Production BOM Version";
    begin
        Recipe.Get(RecipeNo);
        Revision.Get(RecipeNo, RevisionNo);
        Recipe.TestField("Production BOM No.");
        Revision.TestField("Production BOM Version Code");

        ProdBOMVersion.Get(
            Recipe."Production BOM No.",
            Revision."Production BOM Version Code");
        Page.RunModal(Page::"Production BOM Version", ProdBOMVersion);
    end;

    procedure ResolveSelection(
        RecipeNo: Code[50];
        var BaseRecipeNo: Code[50];
        var VariantRecipeNo: Code[50])
    var
        Recipe: Record "SI Concrete Recipe";
    begin
        Clear(BaseRecipeNo);
        Clear(VariantRecipeNo);

        if RecipeNo = '' then
            exit;
        if not Recipe.Get(RecipeNo) then
            exit;

        case Recipe."Recipe Type" of
            Recipe."Recipe Type"::Base:
                BaseRecipeNo := Recipe."Recipe No.";
            Recipe."Recipe Type"::Variant:
                begin
                    BaseRecipeNo := Recipe."Parent Recipe No.";
                    VariantRecipeNo := Recipe."Recipe No.";
                end;
        end;
    end;

    local procedure BuildCategoryNodeJson(CategoryCode: Code[20]): Text
    var
        Category: Record "Item Category";
        BaseRecipe: Record "SI Concrete Recipe";
        CategoryName: Text;
        ChildrenJson: Text;
        FirstChild: Boolean;
    begin
        CategoryName := CategoryCode;
        if Category.Get(CategoryCode) and (Category.Description <> '') then
            CategoryName := Category.Description;

        ChildrenJson := '[';
        FirstChild := true;

        BaseRecipe.SetRange("Recipe Type", BaseRecipe."Recipe Type"::Base);
        BaseRecipe.SetRange("Subcategory Code", CategoryCode);
        BaseRecipe.SetCurrentKey("Subcategory Code", "Item No.", "Variant Code");
        if BaseRecipe.FindSet() then
            repeat
                if not FirstChild then
                    ChildrenJson += ',';
                ChildrenJson += BuildRecipeNodeJson(BaseRecipe);
                FirstChild := false;
            until BaseRecipe.Next() = 0;

        ChildrenJson += ']';

        exit(
            '{' +
                '"type":"Category",' +
                '"name":"' + JsonEscape(CategoryName) + '",' +
                '"recipeNo":"",' +
                '"children":' + ChildrenJson +
            '}');
    end;

    local procedure BuildRecipeNodeJson(Recipe: Record "SI Concrete Recipe"): Text
    var
        VariantRecipe: Record "SI Concrete Recipe";
        ChildrenJson: Text;
        FirstChild: Boolean;
    begin
        ChildrenJson := '[';
        FirstChild := true;

        if Recipe."Recipe Type" = Recipe."Recipe Type"::Base then begin
            VariantRecipe.SetRange("Parent Recipe No.", Recipe."Recipe No.");
            VariantRecipe.SetRange("Recipe Type", VariantRecipe."Recipe Type"::Variant);
            VariantRecipe.SetCurrentKey("Parent Recipe No.");
            if VariantRecipe.FindSet() then
                repeat
                    if not FirstChild then
                        ChildrenJson += ',';
                    ChildrenJson += BuildLeafRecipeJson(VariantRecipe);
                    FirstChild := false;
                until VariantRecipe.Next() = 0;
        end;

        ChildrenJson += ']';

        exit(
            '{' +
                '"type":"' + GetNodeType(Recipe) + '",' +
                '"name":"' + JsonEscape(Recipe.Description) + '",' +
                '"recipeNo":"' + JsonEscape(Recipe."Recipe No.") + '",' +
                '"recipeType":"' + Format(Recipe."Recipe Type") + '",' +
                '"active":' + BoolJson(Recipe.Active) + ',' +
                '"children":' + ChildrenJson +
            '}');
    end;

    local procedure BuildLeafRecipeJson(Recipe: Record "SI Concrete Recipe"): Text
    begin
        exit(
            '{' +
                '"type":"' + GetNodeType(Recipe) + '",' +
                '"name":"' + JsonEscape(Recipe.Description) + '",' +
                '"recipeNo":"' + JsonEscape(Recipe."Recipe No.") + '",' +
                '"recipeType":"' + Format(Recipe."Recipe Type") + '",' +
                '"active":' + BoolJson(Recipe.Active) + ',' +
                '"children":[]' +
            '}');
    end;

    local procedure BuildRevisionRowJson(Revision: Record "SI Concrete Recipe Revision"): Text
    var
        BOMVersionDisplay: Text;
    begin
        if Revision."Production BOM Version Code" <> '' then
            BOMVersionDisplay := Revision."Production BOM Version Code";

        exit(
            '{' +
                '"recipeNo":"' + JsonEscape(Revision."Recipe No.") + '",' +
                '"revisionNo":' + Format(Revision."Revision No.", 0, 9) + ',' +
                '"certificationStatus":"' + JsonEscape(Format(Revision.Status)) + '",' +
                '"administrativeStatus":"' + JsonEscape(Format(Revision."Administrative Status")) + '",' +
                '"applicability":"' + JsonEscape(Format(Revision.GetApplicability(Today()))) + '",' +
                '"validityType":"' + JsonEscape(Format(Revision."Validity Type")) + '",' +
                '"validFrom":"' + JsonEscape(FormatDate(Revision."Valid From")) + '",' +
                '"validFromIso":"' + JsonEscape(FormatDateIso(Revision."Valid From")) + '",' +
                '"validTo":"' + JsonEscape(FormatDate(Revision."Valid To")) + '",' +
                '"validToIso":"' + JsonEscape(FormatDateIso(Revision."Valid To")) + '",' +
                '"projectionStatus":"' + JsonEscape(Format(Revision."Projection Status")) + '",' +
                '"bomVersion":"' + JsonEscape(BOMVersionDisplay) + '"' +
            '}');
    end;

    local procedure GetNodeType(Recipe: Record "SI Concrete Recipe"): Text
    begin
        if Recipe."Recipe Type" = Recipe."Recipe Type"::Variant then
            exit('Variant');
        exit('Base');
    end;

    local procedure FormatDate(Value: Date): Text
    begin
        if Value = 0D then
            exit('');
        exit(Format(Value, 0, '<Day,2>.<Month,2>.<Year4>'));
    end;

    local procedure FormatDateIso(Value: Date): Text
    begin
        if Value = 0D then
            exit('');
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure BoolJson(Value: Boolean): Text
    begin
        if Value then
            exit('true');
        exit('false');
    end;

    local procedure JsonEscape(Value: Text): Text
    begin
        Value := Value.Replace('\', '\\');
        Value := Value.Replace('"', '\"');
        Value := Value.Replace('/', '\/');
        Value := Value.Replace('<', '\u003C');
        Value := Value.Replace('>', '\u003E');
        Value := Value.Replace('&', '\u0026');
        exit(Value);
    end;
}
