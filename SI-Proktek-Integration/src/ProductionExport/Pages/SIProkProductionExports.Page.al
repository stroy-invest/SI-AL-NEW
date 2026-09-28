page 57080 "SI Prok Production Exports"
{
    PageType = List;
    SourceTable = "SI Prok Production Export";
    Caption = 'Експорт виробництва Proktek';
    ApplicationArea = All;
    UsageCategory = Tasks;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Exports)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Date From"; Rec."Date From")
                {
                    ApplicationArea = All;
                }
                field("Date To"; Rec."Date To")
                {
                    ApplicationArea = All;
                }
                field("Connection Code"; Rec."Connection Code")
                {
                    ApplicationArea = All;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                }
                field("Production Count"; Rec."Production Count")
                {
                    ApplicationArea = All;
                }
                field("Total Volume M3"; Rec."Total Volume M3")
                {
                    ApplicationArea = All;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Generate)
            {
                ApplicationArea = All;
                Caption = 'Сформувати';
                Image = ExportFile;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ParamsPage: Page "SI Prok Prod Export Params";
                    ExportMgt: Codeunit "SI Prok Production Export Mgt.";
                    NewExport: Record "SI Prok Production Export";
                    ActiveConnection: Record "SI Prok Connection";
                    ConnectionMgt: Codeunit "SI Prok Connection Mgt.";
                begin
                    ConnectionMgt.GetActive(ActiveConnection);
                    ParamsPage.SetDefaults(Today, Today, ActiveConnection.Code);
                    if ParamsPage.RunModal() <> Action::OK then
                        exit;

                    ExportMgt.GenerateNew(
                        ParamsPage.GetDateFrom(),
                        ParamsPage.GetDateTo(),
                        ParamsPage.GetConnectionCode(),
                        NewExport);

                    CurrPage.Update(false);

                    if NewExport.Status = NewExport.Status::Ready then
                        Message(
                            'Експорт сформовано. Виробництв: %1, обсяг: %2 м³.',
                            NewExport."Production Count",
                            NewExport."Total Volume M3")
                    else
                        Message('Експорт завершився помилкою: %1', NewExport."Error Message");
                end;
            }

            action(Download)
            {
                ApplicationArea = All;
                Caption = 'Завантажити';
                Image = Download;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = CanUseReady;

                trigger OnAction()
                var
                    ExportMgt: Codeunit "SI Prok Production Export Mgt.";
                begin
                    ExportMgt.Download(Rec);
                end;
            }

            action(ViewJson)
            {
                ApplicationArea = All;
                Caption = 'Переглянути JSON';
                Image = View;
                Enabled = CanUseReady;

                trigger OnAction()
                begin
                    Page.RunModal(Page::"SI Prok Export JSON View", Rec);
                end;
            }

            action(Retry)
            {
                ApplicationArea = All;
                Caption = 'Повторити';
                Image = Refresh;
                Enabled = CanRetry;

                trigger OnAction()
                var
                    ExportMgt: Codeunit "SI Prok Production Export Mgt.";
                begin
                    ExportMgt.GenerateExisting(Rec);
                    CurrPage.Update(false);

                    if Rec.Status = Rec.Status::Ready then
                        Message(
                            'Експорт сформовано. Виробництв: %1, обсяг: %2 м³.',
                            Rec."Production Count",
                            Rec."Total Volume M3")
                    else
                        Message('Експорт знову завершився помилкою: %1', Rec."Error Message");
                end;
            }

            action(DeleteExport)
            {
                ApplicationArea = All;
                Caption = 'Видалити';
                Image = Delete;

                trigger OnAction()
                begin
                    if not Confirm('Видалити вибраний експорт?', false) then
                        exit;

                    Rec.Delete(true);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CanUseReady := Rec.Status = Rec.Status::Ready;
        CanRetry := Rec.Status = Rec.Status::Error;
    end;

    var
        CanUseReady: Boolean;
        CanRetry: Boolean;
}
