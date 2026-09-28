pageextension 60002 "SI Job Task Lines Ext." extends "Job Task Lines Subform"
{
    layout
    {
        addafter(Description)
        {
            field("SI Site Code"; Rec."SI Site Code")
            {
                ApplicationArea = All;
                Caption = 'Будівельний майданчик';
                ToolTip = 'Визначає будівельний майданчик SI, до якого належить робота.';
            }
            field("SI Lifecycle Status"; Rec."SI Lifecycle Status")
            {
                ApplicationArea = All;
                Caption = 'Стан SI';
                Editable = false;
            }
        }
    }

    actions
    {
        addfirst(Processing)
        {
            action(SIShowAllTasks)
            {
                ApplicationArea = All;
                Caption = 'Показати всі';
                ToolTip = 'Показати також анульовані роботи SI.';
                Visible = not SIShowingAll;

                trigger OnAction()
                begin
                    SIShowingAll := true;
                    SIApplyLifecycleFilter();
                    CurrPage.Update(false);
                end;
            }
            action(SIHideAnnulatedTasks)
            {
                ApplicationArea = All;
                Caption = 'Приховати анульовані';
                ToolTip = 'Приховати анульовані роботи SI. Активні та заморожені роботи залишаються видимими.';
                Visible = SIShowingAll;

                trigger OnAction()
                begin
                    SIShowingAll := false;
                    SIApplyLifecycleFilter();
                    CurrPage.Update(false);
                end;
            }
        }
        addlast(Processing)
        {
            action(SIFreezeTask)
            {
                ApplicationArea = All;
                Caption = 'Заморозити SI';

                trigger OnAction()
                var
                    JobTaskMgt: Codeunit "SI Job Task Mgt.";
                begin
                    JobTaskMgt.Freeze(Rec);
                    SIApplyLifecycleFilter();
                    CurrPage.Update(false);
                end;
            }
            action(SIRestoreTask)
            {
                ApplicationArea = All;
                Caption = 'Відновити SI';

                trigger OnAction()
                var
                    JobTaskMgt: Codeunit "SI Job Task Mgt.";
                begin
                    JobTaskMgt.Restore(Rec);
                    SIApplyLifecycleFilter();
                    CurrPage.Update(false);
                end;
            }
            action(SIAnnulateTask)
            {
                ApplicationArea = All;
                Caption = 'Анулювати SI';

                trigger OnAction()
                var
                    JobTaskMgt: Codeunit "SI Job Task Mgt.";
                begin
                    if not Confirm('Анулювати роботу %1? Цю дію неможливо скасувати.', false, Rec."Job Task No.") then
                        exit;
                    JobTaskMgt.Annulate(Rec);
                    SIApplyLifecycleFilter();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SIShowingAll := false;
        // Apply the default view immediately. Ordinary BC Job Tasks always have
        // the default SI lifecycle value, so this does not remove any standard
        // BC records; it only guarantees that an SI Annulated task never appears
        // during initial rendering of the subpage.
        SIApplyLifecycleFilter();
    end;

    local procedure SIApplyLifecycleFilter()
    begin
        if SIShowingAll then
            Rec.SetRange("SI Lifecycle Status")
        else
            Rec.SetFilter("SI Lifecycle Status", '<>%1', Rec."SI Lifecycle Status"::Annulated);
    end;

    var
        SIShowingAll: Boolean;
}
