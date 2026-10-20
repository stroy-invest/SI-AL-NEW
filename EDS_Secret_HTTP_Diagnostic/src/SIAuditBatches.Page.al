page 70020 "SI Audit Batches"
{
    PageType = List;
    SourceTable = "SI Audit Batch";
    Caption = 'SI Audit Batches';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = true;
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; Editable = false; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
                field("Provider Code"; Rec."Provider Code") { ApplicationArea = All; }
                field("EDS Service Code"; Rec."EDS Service Code") { ApplicationArea = All; }
                field("EDS Operation Code"; Rec."EDS Operation Code") { ApplicationArea = All; }
                field("EDS Runtime Key"; Rec."EDS Runtime Key") { ApplicationArea = All; }
                field("Batch Size"; Rec."Batch Size") { ApplicationArea = All; }
                field("Request Interval Sec."; Rec."Request Interval Sec.") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ImportShortList)
            {
                Caption = 'Імпортувати ShortList';
                ApplicationArea = All;
                Image = ImportExcel;
                ToolTip = 'Завантажити записи з аркуша ShortList. Жодних HTTP-запитів чи записів у SI BP.';
                trigger OnAction()
                var
                    Importer: Codeunit "SI Audit ShortList Import";
                begin
                    Importer.ImportBatch(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(PrepareBatch)
            {
                Caption = 'Підготувати пакет';
                ApplicationArea = All;
                Image = Approve;
                trigger OnAction()
                begin
                    if Rec.Status in [Rec.Status::Running, Rec.Status::Completed] then
                        Error('Пакет уже виконується або завершений.');
                    Rec.Status := Rec.Status::Ready;
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
            action(RunBatchSlice)
            {
                Caption = 'Виконати порцію GET';
                ApplicationArea = All;
                Image = Start;
                trigger OnAction()
                var Worker: Codeunit "SI Audit Batch Worker";
                begin
                    Worker.RunSlice(Rec."No.");
                    CurrPage.Update(false);
                end;
            }
            action(StopBatch)
            {
                Caption = 'Зупинити пакет';
                ApplicationArea = All;
                Image = Stop;
                trigger OnAction()
                begin
                    Rec.Status := Rec.Status::Stopped;
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
            action(ResumeBatch)
            {
                Caption = 'Відновити пакет';
                ApplicationArea = All;
                Image = Restart;
                trigger OnAction()
                begin
                    if Rec.Status <> Rec.Status::Stopped then
                        Error('Відновити можна лише зупинений пакет.');
                    Rec.Status := Rec.Status::Ready;
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
            action(ResetAuditResults)
            {
                Caption = 'Скинути результати аудиту';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Повний cleanup тестових результатів вибраного пакета зі збереженням імпортованих даних 1С. Job Queue має бути на утриманні.';
                trigger OnAction()
                var
                    Resetter: Codeunit "SI Audit Batch Reset";
                begin
                    Resetter.ResetBatch(Rec."No.");
                    CurrPage.Update(false);
                end;
            }
            action(OpenEntries)
            {
                Caption = 'Записи пакета';
                ApplicationArea = All;
                Image = List;
                RunObject = page "SI Audit Entries";
                RunPageLink = "Batch No." = field("No.");
            }
        }
    }
}
