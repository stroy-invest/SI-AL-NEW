page 60020 "SI Site Job Tasks"
{
    PageType = ListPart;
    SourceTable = "Job Task";
    ApplicationArea = All;
    Caption = 'Роботи майданчика';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Tasks)
            {
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    Caption = '№ роботи';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Робота';
                }
                field("Job Task Type"; Rec."Job Task Type")
                {
                    ApplicationArea = All;
                    Caption = 'Тип';
                }
                field("SI Lifecycle Status"; Rec."SI Lifecycle Status")
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
            action(Freeze)
            {
                ApplicationArea = All;
                Caption = 'Заморозити';

                trigger OnAction()
                var
                    JobTaskMgt: Codeunit "SI Job Task Mgt.";
                begin
                    JobTaskMgt.Freeze(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Restore)
            {
                ApplicationArea = All;
                Caption = 'Відновити';

                trigger OnAction()
                var
                    JobTaskMgt: Codeunit "SI Job Task Mgt.";
                begin
                    JobTaskMgt.Restore(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Annulate)
            {
                ApplicationArea = All;
                Caption = 'Анулювати';

                trigger OnAction()
                var
                    JobTaskMgt: Codeunit "SI Job Task Mgt.";
                begin
                    if not Confirm('Анулювати роботу %1? Цю дію неможливо скасувати.', false, Rec."Job Task No.") then
                        exit;
                    JobTaskMgt.Annulate(Rec);
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

    local procedure ApplyLifecycleFilter()
    begin
        if ShowingAll then
            Rec.SetRange("SI Lifecycle Status")
        else
            Rec.SetFilter("SI Lifecycle Status", '<>%1', Rec."SI Lifecycle Status"::Annulated);
    end;

    var
        ShowingAll: Boolean;
}
