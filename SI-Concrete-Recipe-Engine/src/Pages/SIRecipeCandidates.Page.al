namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Manufacturing.ProductionBOM;

page 62107 "SI Recipe Candidates"
{
    PageType = List;
    SourceTable = "SI Recipe Resolver Result";
    SourceTableTemporary = true;
    Caption = 'Актуальні ревізії рецептур';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Candidates)
            {
                field("Recipe Description"; Rec."Recipe Description") { ApplicationArea = All; }
                field("Revision No."; Rec."Revision No.") { ApplicationArea = All; }
                field("Match Type"; Rec."Match Type") { ApplicationArea = All; }
                field("Validity Type"; Rec."Validity Type") { ApplicationArea = All; }
                field("Valid From"; Rec."Valid From") { ApplicationArea = All; }
                field("Valid To"; Rec."Valid To") { ApplicationArea = All; }
                field(Applicability; Rec.Applicability) { ApplicationArea = All; Caption = 'Актуальність'; }
                field("Projection Status"; Rec."Projection Status") { ApplicationArea = All; }
                field("Projection Ready"; Rec."Projection Ready") { ApplicationArea = All; }
                field("Production BOM No."; Rec."Production BOM No.") { ApplicationArea = All; }
                field("Production BOM Version Code"; Rec."Production BOM Version Code") { ApplicationArea = All; }
                field("Recipe No."; Rec."Recipe No.")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenRecipeRevision)
            {
                Caption = 'Відкрити ревізію рецептури';
                ApplicationArea = All;
                Image = EditLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    RecipeRevision: Record "SI Concrete Recipe Revision";
                begin
                    RecipeRevision.Get(Rec."Recipe No.", Rec."Revision No.");
                    Page.Run(Page::"SI Recipe Revision Card", RecipeRevision);
                end;
            }

            action(OpenProductionBOMVersion)
            {
                Caption = 'Відкрити версію виробничої специфікації';
                ApplicationArea = All;
                Image = BOM;
                Enabled = Rec."Projection Ready";

                trigger OnAction()
                var
                    ProdBOMVersion: Record "Production BOM Version";
                begin
                    Rec.TestField("Production BOM No.");
                    Rec.TestField("Production BOM Version Code");

                    ProdBOMVersion.Get(
                        Rec."Production BOM No.",
                        Rec."Production BOM Version Code");
                    Page.Run(Page::"Production BOM Version", ProdBOMVersion);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Resolver: Codeunit "SI Recipe Resolver";
    begin
        if ContextTargetDate = 0D then
            ContextTargetDate := Today();

        Outcome :=
            Resolver.GetApplicableCandidates(
                ContextItemNo,
                ContextVariantCode,
                ContextTargetDate,
                Rec);

        case Outcome of
            Outcome::"No Recipe":
                Message(NoRecipeMsg, ContextItemNo, ContextVariantCode);
            Outcome::"No Applicable Revision":
                Message(NoApplicableMsg, ContextTargetDate);
            Outcome::"Multiple Candidates":
                Message(
                    MultipleCandidatesMsg,
                    Rec.Count(),
                    ContextTargetDate);
        end;
    end;

    procedure SetContext(ItemNo: Code[20]; VariantCode: Code[10]; TargetDate: Date)
    begin
        ContextItemNo := ItemNo;
        ContextVariantCode := VariantCode;
        ContextTargetDate := TargetDate;
    end;

    var
        ContextItemNo: Code[20];
        ContextVariantCode: Code[10];
        ContextTargetDate: Date;
        Outcome: Enum "SI Recipe Resolve Outcome";
        NoRecipeMsg: Label 'Для товару %1, варіанта %2 не знайдено активної логічної рецептури.';
        NoApplicableMsg: Label 'Для %1 не знайдено актуальної сертифікованої активної ревізії рецептури.';
        MultipleCandidatesMsg: Label 'Для %2 знайдено актуальних ревізій рецептури: %1. Жодну ревізію не вибрано автоматично.';
}
