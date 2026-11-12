page 57111 "SI Prok Vehicle Mappings"
{
    PageType = List;
    SourceTable = "SI Prok Vehicle Mapping";
    Caption = 'Відповідності транспортних засобів Proktek';
    ApplicationArea = All;
    UsageCategory = Lists;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Connection Code"; Rec."Connection Code") { ApplicationArea = All; }
                field("Vehicle No."; Rec."Vehicle No.") { ApplicationArea = All; }
                field("External Mixer Code"; Rec."External Mixer Code") { ApplicationArea = All; }
                field("External Mixer ID"; Rec."External Mixer ID") { ApplicationArea = All; }
                field("External Mixer UUID"; Rec."External Mixer UUID") { ApplicationArea = All; }
                field("Sync Status"; Rec."Sync Status") { ApplicationArea = All; }
                field("Last Synced At"; Rec."Last Synced At") { ApplicationArea = All; }
                field("Last Error"; Rec."Last Error") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(SyncAllMixers)
            {
                ApplicationArea = All;
                Caption = 'Синхронізувати всі міксери';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    Manager: Codeunit "SI Prok Mixer Sync Manager";
                begin
                    CurrPage.SaveRecord();
                    Rec.TestField("Connection Code");
                    if not Confirm('Синхронізувати всі міксери BC типу CONCRETE-MIXER з Proktek через підключення %1?', false, Rec."Connection Code") then
                        exit;
                    Manager.SyncAll(Rec."Connection Code");
                    CurrPage.Update(false);
                end;
            }
            action(CreateMixer)
            {
                ApplicationArea = All;
                Caption = 'Створити міксер у Proktek';
                Image = New;
                trigger OnAction()
                var
                    Sync: Codeunit "SI Prok Vehicle Sync";
                begin
                    CurrPage.SaveRecord();
                    if not Confirm('Створити новий міксер Proktek для ТЗ %1? Перед повтором перевіряйте GetMixers.', false, Rec."Vehicle No.") then
                        exit;
                    Sync.CreateMixer(Rec."Connection Code", Rec."Vehicle No.");
                    CurrPage.Update(false);
                    Message('Міксер створено. ID та UUID записано до відповідності.');
                end;
            }
            action(UpdateMixer)
            {
                ApplicationArea = All;
                Caption = 'Оновити міксер у Proktek';
                Image = Edit;
                trigger OnAction()
                var
                    Sync: Codeunit "SI Prok Vehicle Sync";
                begin
                    CurrPage.SaveRecord();
                    if Sync.UpdateMixer(Rec."Connection Code", Rec."Vehicle No.") then
                        Message('Міксер оновлено. ID та UUID залишилися незмінними.')
                    else
                        Message('Змін для передачі немає або оновлення скасовано.');
                    CurrPage.Update(false);
                end;
            }
            action(AdoptExisting)
            {
                ApplicationArea = All;
                Caption = 'Прив’язати існуючий міксер';
                Image = Link;
                trigger OnAction()
                var
                    Sync: Codeunit "SI Prok Vehicle Sync";
                    MixerId: Integer;
                    MixerUuid: Guid;
                    Params: Page "SI Prok Mixer Adopt Params";
                begin
                    CurrPage.SaveRecord();
                    if Params.RunModal() <> Action::OK then
                        exit;
                    Params.GetValues(MixerId, MixerUuid);
                    Sync.AdoptExisting(Rec."Connection Code", Rec."Vehicle No.", MixerId, MixerUuid);
                    CurrPage.Update(false);
                    Message('Міксер прив’язано й перевірено через GetMixers.');
                end;
            }
            action(VerifyExisting)
            {
                ApplicationArea = All;
                Caption = 'Перевірити відповідність';
                Image = Check;
                trigger OnAction()
                var Sync: Codeunit "SI Prok Vehicle Sync";
                begin
                    Sync.VerifyExisting(Rec."Connection Code", Rec."Vehicle No.");
                    CurrPage.Update(false);
                    Message('Відповідність підтверджено через GetMixers.');
                end;
            }
        }
    }
}
