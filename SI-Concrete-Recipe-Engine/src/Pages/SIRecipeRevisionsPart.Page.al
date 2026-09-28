namespace STROYINVEST.ConcreteRecipeEngine;

page 62102 "SI Recipe Revisions Part"
{
    PageType = ListPart;
    SourceTable = "SI Concrete Recipe Revision";
    Caption = 'Ревізії рецептури';
    ApplicationArea = All;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Revisions)
            {
                field("Revision No."; Rec."Revision No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Статус сертифікації';
                    Editable = false;
                }
                field("Administrative Status"; Rec."Administrative Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Applicability; ApplicabilityDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Актуальність';
                    Editable = false;
                }
                field("Validity Type"; Rec."Validity Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Source Revision No."; Rec."Source Revision No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Projection Status"; Rec."Projection Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Production BOM Version Code"; Rec."Production BOM Version Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewRevision)
            {
                Caption = 'Нова ревізія';
                ApplicationArea = All;
                Image = NewDocument;
                ToolTip = 'Відкрити наявну чернеткову ревізію або створити наступну чернеткову ревізію цієї рецептури.';

                trigger OnAction()
                var
                    RecipeCreationMgt: Codeunit "SI Recipe Creation Mgt.";
                    RecipeRevision: Record "SI Concrete Recipe Revision";
                    RecipeNo: Code[50];
                begin
                    RecipeNo := GetCurrentRecipeNo();
                    if RecipeNo = '' then
                        Error(RecipeNoMissingErr);

                    RecipeCreationMgt.GetOrCreateDraftRevisionForRecipe(RecipeNo, RecipeRevision);
                    Page.Run(Page::"SI Recipe Revision Card", RecipeRevision);
                    CurrPage.Update(false);
                end;
            }

            action(OpenRevision)
            {
                Caption = 'Відкрити ревізію';
                ApplicationArea = All;
                Image = EditLines;
                ToolTip = 'Відкрити вибрану ревізію рецептури.';

                trigger OnAction()
                begin
                    Rec.TestField("Recipe No.");
                    Rec.TestField("Revision No.");
                    Page.Run(Page::"SI Recipe Revision Card", Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateApplicability();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateApplicability();
    end;

    local procedure UpdateApplicability()
    begin
        if Rec.Status = Rec.Status::Certified then
            ApplicabilityDisplay := Format(Rec.GetApplicability(Today()))
        else
            Clear(ApplicabilityDisplay);
    end;

    local procedure GetCurrentRecipeNo(): Code[50]
    begin
        if Rec."Recipe No." <> '' then
            exit(Rec."Recipe No.");

        if Rec.GetFilter("Recipe No.") <> '' then
            exit(Rec.GetRangeMin("Recipe No."));

        exit('');
    end;

    var
        ApplicabilityDisplay: Text[30];
        RecipeNoMissingErr: Label 'Контекст рецептури відсутній.';
}
