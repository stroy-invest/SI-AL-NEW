namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Manufacturing.ProductionBOM;

page 62103 "SI Recipe Revision Card"
{
    PageType = Card;
    SourceTable = "SI Concrete Recipe Revision";
    Caption = 'Ревізія рецептури';
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Recipe No."; Rec."Recipe No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Revision No."; Rec."Revision No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
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
                    Editable = IsDraft;

                    trigger OnValidate()
                    begin
                        UpdateState();
                        CurrPage.Update(false);
                    end;
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = All;
                    Editable = IsDraft;
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = All;
                    Editable = IsTemporaryDraft;
                }
                field("Source Revision No."; Rec."Source Revision No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(ProductionBOMVersionLink; ProductionBOMVersionDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Версія виробничої специфікації';
                    Editable = false;
                    DrillDown = true;
                    Enabled = HasProjection;
                    ToolTip = 'Відкриває стандартну версію виробничої специфікації Business Central, спроєктовану з цієї ревізії рецептури.';

                    trigger OnDrillDown()
                    begin
                        OpenProjectedBOMVersion();
                    end;
                }
            }
            group(Projection)
            {
                field("Production BOM Version Code"; Rec."Production BOM Version Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Projection Status"; Rec."Projection Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Projection Error"; Rec."Projection Error")
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                }
            }
            group(Audit)
            {
                Caption = 'Аудит життєвого циклу';

                field("Certified At"; Rec."Certified At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Certified By"; Rec."Certified By")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Closed At"; Rec."Closed At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Closed By"; Rec."Closed By")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            part(Lines; "SI Recipe Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Recipe No." = field("Recipe No."),
                              "Revision No." = field("Revision No.");
                UpdatePropagation = Both;
                Editable = IsDraft;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Certify)
            {
                Caption = 'Сертифікувати';
                ApplicationArea = All;
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Enabled = IsDraft;
                ToolTip = 'Перевірити цю чернеткову ревізію та сертифікувати її. Сертифіковані ревізії незмінні.';

                trigger OnAction()
                var
                    RecipeLifecycleMgt: Codeunit "SI Recipe Lifecycle Mgt.";
                begin
                    if not Confirm(CertifyQst, false) then
                        exit;

                    RecipeLifecycleMgt.CertifyRevision(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CloneRevision)
            {
                Caption = 'Клонувати ревізію';
                ApplicationArea = All;
                Image = CopyDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Створити наступну чернеткову ревізію та скопіювати до неї всі рядки цієї рецептури.';

                trigger OnAction()
                var
                    RecipeLifecycleMgt: Codeunit "SI Recipe Lifecycle Mgt.";
                    NewRevision: Record "SI Concrete Recipe Revision";
                begin
                    RecipeLifecycleMgt.CloneRevision(Rec, NewRevision);
                    Page.Run(Page::"SI Recipe Revision Card", NewRevision);
                end;
            }
            action(OpenProductionBOMVersion)
            {
                Caption = 'Відкрити версію виробничої специфікації';
                ApplicationArea = All;
                Image = BOM;
                Enabled = HasProjection;
                ToolTip = 'Відкрити стандартну версію виробничої специфікації Business Central, створену з цієї ревізії рецептури.';

                trigger OnAction()
                begin
                    OpenProjectedBOMVersion();
                end;
            }

            action(DeactivateRevision)
            {
                Caption = 'Деактивувати';
                ApplicationArea = All;
                Image = Close;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Enabled = CanDeactivate;
                ToolTip = 'Тимчасово деактивувати цю сертифіковану ревізію. Сертифікація та дати валідності зберігаються.';

                trigger OnAction()
                var
                    RecipeLifecycleMgt: Codeunit "SI Recipe Lifecycle Mgt.";
                    Recipe: Record "SI Concrete Recipe";
                    RecipeDisplayName: Text[100];
                begin
                    RecipeDisplayName := Rec."Recipe No.";
                    if Recipe.Get(Rec."Recipe No.") and (Recipe.Description <> '') then
                        RecipeDisplayName := Recipe.Description;

                    if not Confirm(DeactivateQst, false, Rec."Revision No.", RecipeDisplayName) then
                        exit;

                    RecipeLifecycleMgt.DeactivateRevision(Rec);
                    CurrPage.Update(false);
                end;
            }

            action(ActivateRevision)
            {
                Caption = 'Активувати';
                ApplicationArea = All;
                Image = ReOpen;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Enabled = CanActivate;
                ToolTip = 'Повторно активувати цю сертифіковану ревізію без зміни сертифікації або дат валідності.';

                trigger OnAction()
                var
                    RecipeLifecycleMgt: Codeunit "SI Recipe Lifecycle Mgt.";
                    Recipe: Record "SI Concrete Recipe";
                    RecipeDisplayName: Text[100];
                begin
                    RecipeDisplayName := Rec."Recipe No.";
                    if Recipe.Get(Rec."Recipe No.") and (Recipe.Description <> '') then
                        RecipeDisplayName := Recipe.Description;

                    if not Confirm(ActivateQst, false, Rec."Revision No.", RecipeDisplayName) then
                        exit;

                    RecipeLifecycleMgt.ActivateRevision(Rec);
                    CurrPage.Update(false);
                end;
            }

            action(AdministrativeHistory)
            {
                Caption = 'Історія активності';
                ApplicationArea = All;
                Image = History;
                ToolTip = 'Показує історію активації та деактивації цієї ревізії.';

                trigger OnAction()
                var
                    History: Record "SI Recipe Admin History";
                begin
                    History.SetRange("Recipe No.", Rec."Recipe No.");
                    History.SetRange("Revision No.", Rec."Revision No.");
                    Page.Run(Page::"SI Recipe Admin History", History);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateState();
    end;

    local procedure UpdateState()
    begin
        IsDraft := Rec.Status = Rec.Status::Draft;
        IsCertified := Rec.Status = Rec.Status::Certified;
        IsTemporaryDraft := IsDraft and (Rec."Validity Type" = Rec."Validity Type"::Temporary);
        CanDeactivate := IsCertified and (Rec."Administrative Status" = Rec."Administrative Status"::Active);
        CanActivate := IsCertified and (Rec."Administrative Status" = Rec."Administrative Status"::Inactive);
        HasProjection :=
            (Rec."Projection Status" = Rec."Projection Status"::Projected) and
            (Rec."Production BOM Version Code" <> '');

        UpdateProductionBOMVersionDisplay();

        if IsCertified then
            ApplicabilityDisplay := Format(Rec.GetApplicability(Today()))
        else
            Clear(ApplicabilityDisplay);
    end;

    local procedure UpdateProductionBOMVersionDisplay()
    var
        Recipe: Record "SI Concrete Recipe";
    begin
        Clear(ProductionBOMVersionDisplay);

        if Rec."Production BOM Version Code" = '' then
            exit;

        if Recipe.Get(Rec."Recipe No.") and (Recipe."Production BOM No." <> '') then
            ProductionBOMVersionDisplay :=
                CopyStr(
                    StrSubstNo(
                        '%1 / %2',
                        Recipe."Production BOM No.",
                        Rec."Production BOM Version Code"),
                    1,
                    MaxStrLen(ProductionBOMVersionDisplay))
        else
            ProductionBOMVersionDisplay := Rec."Production BOM Version Code";
    end;

    local procedure OpenProjectedBOMVersion()
    var
        Recipe: Record "SI Concrete Recipe";
        ProdBOMVersion: Record "Production BOM Version";
    begin
        Recipe.Get(Rec."Recipe No.");
        Recipe.TestField("Production BOM No.");
        Rec.TestField("Production BOM Version Code");

        ProdBOMVersion.Get(
            Recipe."Production BOM No.",
            Rec."Production BOM Version Code");

        Page.Run(Page::"Production BOM Version", ProdBOMVersion);
    end;

    var
        IsDraft: Boolean;
        IsCertified: Boolean;
        IsTemporaryDraft: Boolean;
        CanDeactivate: Boolean;
        CanActivate: Boolean;
        HasProjection: Boolean;
        ApplicabilityDisplay: Text[30];
        ProductionBOMVersionDisplay: Text[60];
        CertifyQst: Label 'Рецептуру буде сертифіковано. Також для неї буде створено стандартну виробничу специфікацію. Продовжити дію?';
        DeactivateQst: Label 'Деактивувати ревізію %1 рецептури "%2"? Ревізія залишиться сертифікованою, але не зможе використовуватися до повторної активації.';
        ActivateQst: Label 'Активувати ревізію %1 рецептури "%2"? Якщо поточна дата входить у період її валідності, ревізія одразу стане актуальною.';
}
