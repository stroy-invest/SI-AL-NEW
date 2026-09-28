page 61002 "SI Supply Req Card"
{
    PageType = Document;
    SourceTable = "SI Supply Req Header";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Заявка на забезпечення';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальні';
                field("No."; Rec."No.") { ApplicationArea = All; Editable = false; }
                field("Request Type"; Rec."Request Type") { ApplicationArea = All; }
                field("Request Profile"; Rec."Request Profile") { ApplicationArea = All; }
                field(ProjectDisplayName; ProjectDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Проєкт';
                    Editable = false;
                    AssistEdit = true;
                    ToolTip = 'Виберіть будівельний проєкт. Після вибору проєкту система сформує перелік його активних будівельних майданчиків.';

                    trigger OnAssistEdit()
                    begin
                        SelectProject();
                    end;
                }
                field("Project Location Code"; Rec."Project Location Code") { ApplicationArea = All; Caption = 'Склад проєкту'; }
                field("Required on Site At"; Rec."Required on Site At")
                {
                    ApplicationArea = All;
                    Caption = 'Дата потреби';
                    ShowMandatory = true;
                    ToolTip = 'Обов’язкова дата і точний час, на які потреба має бути забезпечена на об’єкті. Для нової позиції це значення використовується як початкове і може бути змінене в рядку.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        CurrPage.Update(false);
                        CurrPage.DemandLines.Page.SetRequestContext(Rec."No.");
                        CurrPage.DemandLines.Page.RefreshFromDatabase();
                    end;
                }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Requested By User ID"; Rec."Requested By User ID") { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; MultiLine = true; }
            }

            part(DemandLines; "SI Supply Req Lines Grid")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
                UpdatePropagation = Both;
            }

            part(Parameters; "SI Supply Req Parameters Part")
            {
                ApplicationArea = All;
                SubPageLink = "Request No." = field("No.");
                UpdatePropagation = Both;
            }
            part(ConcreteSpec; "SI Concrete Supply Spec Part")
            {
                ApplicationArea = All;
                SubPageLink = "Request No." = field("No.");
                UpdatePropagation = Both;
            }
            group(ExternalSource)
            {
                Caption = 'Зовнішнє джерело';
                field("Source Type"; Rec."Source Type") { ApplicationArea = All; }
                field("External System Code"; Rec."External System Code") { ApplicationArea = All; }
                field("Schrift Request"; Rec."Schrift Request") { ApplicationArea = All; Editable = false; }
                field("External Document ID"; Rec."External Document ID") { ApplicationArea = All; }
                field("External Document No."; Rec."External Document No.") { ApplicationArea = All; }
                field("External Registered At"; Rec."External Registered At") { ApplicationArea = All; }
                field("Last External Sync At"; Rec."Last External Sync At") { ApplicationArea = All; }
                field("External Sync Status"; Rec."External Sync Status") { ApplicationArea = All; }
                field("External Sync Message"; Rec."External Sync Message") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectRequestSites)
            {
                ApplicationArea = All;
                Caption = 'Буд. майданчики';
                ToolTip = 'Змінити перелік активних будівельних майданчиків, дозволених для позицій цієї заявки.';
                Image = SelectEntries;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = (Rec."Project No." <> '') and (Rec.Status = Rec.Status::Draft);

                trigger OnAction()
                var
                    RequestSiteMgt: Codeunit "SI Supply Request Site Mgt.";
                begin
                    CurrPage.SaveRecord();
                    Commit();
                    if RequestSiteMgt.OpenSelector(Rec."No.") then begin
                        CurrPage.Update(false);
                        CurrPage.DemandLines.Page.SetRequestContext(Rec."No.");
                        CurrPage.DemandLines.Page.RefreshFromDatabase();
                    end;
                end;
            }
            action(DevMarkAsSchriftRequest)
            {
                ApplicationArea = All;
                Caption = 'DEV: Поставити Schrift = true';
                Image = Setup;
                Enabled = (not Rec."Schrift Request") and (Rec."External System Code" = 'SCHRIFT');
                trigger OnAction()
                begin
                    if not Confirm('Позначити заявку %1 як Schrift-заявку?', false, Rec."No.") then exit;
                    Rec."Schrift Request" := true; Rec.Modify(false); CurrPage.Update(false);
                end;
            }
            action(SynchronizeSchrift)
            {
                ApplicationArea = All; Caption = 'Синхронізувати зі Schrift'; Image = Refresh; Promoted = true; PromotedCategory = Process;
                Enabled = Rec."External System Code" = 'SCHRIFT';
                trigger OnAction()
                var SchriftIntake: Codeunit "SI Schrift Intake Mgt."; WasUpdated: Boolean; HasConflict: Boolean;
                begin
                    CurrPage.SaveRecord(); SchriftIntake.SynchronizeRequest(Rec, WasUpdated, HasConflict); CurrPage.Update(false);
                    if HasConflict then Message('У Schrift виявлено зміни, але заявка вже перебуває в обробці. Автоматичне оновлення заблоковано.')
                    else if WasUpdated then Message('Заявку синхронізовано зі Schrift. Дані оновлено.')
                    else Message('Заявку синхронізовано зі Schrift. Змін не виявлено.');
                end;
            }
            action(ApproveRequest)
            {
                ApplicationArea = All;
                Caption = 'Погодити';
                ToolTip = 'Погодити заявку після перевірки, що всі позиції повністю та коректно розподілені у Плані забезпечення.';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Status = Rec.Status::Draft;

                trigger OnAction()
                var
                    DecisionMgt: Codeunit "SI Supply Decision Mgt.";
                begin
                    CurrPage.SaveRecord();
                    DecisionMgt.ApproveRequest(Rec);
                    CurrPage.Update(false);
                    CurrPage.DemandLines.Page.RefreshFromDatabase();
                    Message('Заявку %1 погоджено. План забезпечення зафіксовано та закрито для редагування.', Rec."No.");
                end;
            }
            action(OpenSupplyDecision)
            {
                ApplicationArea = All; Caption = 'План забезпечення'; Image = Planning; Promoted = true; PromotedCategory = Process;
                trigger OnAction()
                var DecisionMgt: Codeunit "SI Supply Decision Mgt.";
                begin CurrPage.SaveRecord(); DecisionMgt.OpenOrCreateFromRequest(Rec); end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateProjectDisplayName();
        if Rec."No." <> '' then
            CurrPage.DemandLines.Page.SetRequestContext(Rec."No.");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ProjectDisplayName);
    end;

    local procedure SelectProject(): Boolean
    var
        ProjectSelector: Page "SI Project Selection";
        RequestSiteMgt: Codeunit "SI Supply Request Site Mgt.";
        SelectedProjectNo: Code[20];
    begin
        Rec.TestEditable();

        // Use the standard modal lookup UX: the single "Вибрати" action is shown
        // in the bottom-right dialog action area. No duplicate promoted action.
        ProjectSelector.LookupMode(true);
        if ProjectSelector.RunModal() <> Action::LookupOK then
            exit(false);

        SelectedProjectNo := ProjectSelector.GetSelectedProjectNo();
        if SelectedProjectNo = '' then
            exit(false);

        if SelectedProjectNo = Rec."Project No." then begin
            UpdateProjectDisplayName();
            exit(true);
        end;

        Rec.Validate("Project No.", SelectedProjectNo);
        CurrPage.SaveRecord();
        Commit();

        // Project validation creates the physical request-site rows. Do not open
        // the site selector until the persisted default selection is verifiably present.
        RequestSiteMgt.EnsureSelectedSiteExists(Rec."No.");
        RequestSiteMgt.OpenSelector(Rec."No.");

        UpdateProjectDisplayName();
        CurrPage.Update(false);
        CurrPage.DemandLines.Page.SetRequestContext(Rec."No.");
        CurrPage.DemandLines.Page.RefreshFromDatabase();
        exit(true);
    end;

    local procedure UpdateProjectDisplayName()
    var
        Project: Record Job;
    begin
        Clear(ProjectDisplayName);
        if Rec."Project No." = '' then
            exit;

        if Project.Get(Rec."Project No.") then begin
            ProjectDisplayName := Project.Description;
            if ProjectDisplayName = '' then
                ProjectDisplayName := Project."No.";
        end;
    end;

    var
        ProjectDisplayName: Text[100];
}
