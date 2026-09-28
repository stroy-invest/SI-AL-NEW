page 60018 "SI Construction Sites"
{
    PageType = ListPart;
    SourceTable = "SI Construction Site";
    ApplicationArea = All;
    Caption = 'Будівельні майданчики';
    DelayedInsert = true;
    CardPageId = "SI Construction Site Card";

    layout
    {
        area(Content)
        {
            repeater(Sites)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Майданчик';
                }
                field("Site Code"; Rec."Site Code")
                {
                    ApplicationArea = All;
                    Caption = 'Код';
                    Editable = false;
                    Visible = false;
                }
                field("Default"; Rec."Default")
                {
                    ApplicationArea = All;
                    Caption = 'Основний';
                    Editable = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Стан';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenCard)
            {
                ApplicationArea = All;
                Caption = 'Відкрити картку';

                trigger OnAction()
                begin
                    OpenSiteCard();
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = All;
                Caption = 'Показати всі';
                Visible = not ShowingAll;

                trigger OnAction()
                begin
                    ShowingAll := true;
                    ApplyLifecycleFilter();
                    CurrPage.Update(false);
                end;
            }
            action(HideAnnulated)
            {
                ApplicationArea = All;
                Caption = 'Приховати анульовані';
                Visible = ShowingAll;

                trigger OnAction()
                begin
                    ShowingAll := false;
                    ApplyLifecycleFilter();
                    CurrPage.Update(false);
                end;
            }
            action(SetDefault)
            {
                ApplicationArea = All;
                Caption = 'Зробити основним';

                trigger OnAction()
                var
                    SiteMgt: Codeunit "SI Construction Site Mgt.";
                begin
                    SiteMgt.SetDefaultSite(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Freeze)
            {
                ApplicationArea = All;
                Caption = 'Заморозити';

                trigger OnAction()
                begin
                    Rec.Validate(Status, Rec.Status::Freezed);
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
            action(Restore)
            {
                ApplicationArea = All;
                Caption = 'Відновити';

                trigger OnAction()
                begin
                    Rec.Validate(Status, Rec.Status::Active);
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
            action(Annulate)
            {
                ApplicationArea = All;
                Caption = 'Анулювати';

                trigger OnAction()
                begin
                    if not Confirm('Анулювати будівельний майданчик %1? Цю дію неможливо скасувати.', false, Rec.Name) then
                        exit;
                    Rec.Validate(Status, Rec.Status::Annulated);
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ShowingAll := false;
        ApplyLifecycleFilter();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Status := Rec.Status::Active;
    end;

    procedure OpenCurrentSiteCard()
    begin
        OpenSiteCard();
    end;

    local procedure OpenSiteCard()
    var
        Site: Record "SI Construction Site";
    begin
        if (Rec."Project No." = '') or (Rec."Site Code" = '') then
            exit;

        Site.Get(Rec."Project No.", Rec."Site Code");
        Page.Run(Page::"SI Construction Site Card", Site);
    end;

    local procedure ApplyLifecycleFilter()
    begin
        if ShowingAll then
            Rec.SetRange(Status)
        else
            Rec.SetFilter(Status, '<>%1', Rec.Status::Annulated);
    end;

    var
        ShowingAll: Boolean;
}
