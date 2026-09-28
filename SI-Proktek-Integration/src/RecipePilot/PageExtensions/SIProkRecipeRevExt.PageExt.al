using STROYINVEST.ConcreteRecipeEngine;

pageextension 57090 "SI Prok Recipe Rev Ext" extends "SI Recipe Revision Card"
{
    layout
    {
        addafter(Projection)
        {
            group(SIProktek)
            {
                Caption = 'Proktek';

                field(SIProkStatus; ProktekStatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Статус';
                    Editable = false;
                }
                field(SIFormulaIndex; FormulaIndex)
                {
                    ApplicationArea = All;
                    Caption = 'Formula Index';
                    Editable = false;
                    Visible = Published;
                }
                field(SIFormulaUUID; FormulaUUID)
                {
                    ApplicationArea = All;
                    Caption = 'Formula UUID';
                    Editable = false;
                    Visible = Published;
                }
                field(SIProkActive; ProktekActive)
                {
                    ApplicationArea = All;
                    Caption = 'Активна в Proktek';
                    Editable = false;
                    Visible = Published;
                }
                field(SILastSyncAt; LastSyncAt)
                {
                    ApplicationArea = All;
                    Caption = 'Остання синхронізація';
                    Editable = false;
                    Visible = Published;
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            group(SIProktekActions)
            {
                Caption = 'Proktek';
                Image = Web;

                action(SISyncProktekFormula)
                {
                    Caption = 'Передати в Proktek';
                    ApplicationArea = All;
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = CanPublish;
                    ToolTip = 'Передати нову Formula або оновити вже пов''язану Formula в Proktek. Після передачі система запропонує одразу активувати рецептуру.';

                    trigger OnAction()
                    var
                        FormulaMgt: Codeunit "SI Prok Recipe Formula Mgt.";
                    begin
                        FormulaMgt.Publish(Rec);
                        UpdateProktekState();
                        CurrPage.Update(false);
                    end;
                }
                action(SIActivateProktekFormula)
                {
                    Caption = 'Активувати в Proktek';
                    ApplicationArea = All;
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = CanActivateProktek;
                    ToolTip = 'Зробити опубліковану Formula активною та доступною оператору Proktek.';

                    trigger OnAction()
                    var
                        FormulaMgt: Codeunit "SI Prok Recipe Formula Mgt.";
                    begin
                        FormulaMgt.Activate(Rec);
                        UpdateProktekState();
                        CurrPage.Update(false);
                    end;
                }
                action(SIDeactivateProktekFormula)
                {
                    Caption = 'Деактивувати в Proktek';
                    ApplicationArea = All;
                    Image = Close;
                    Enabled = CanDeactivateProktek;
                    ToolTip = 'Зробити Formula неактивною в Proktek. Статус сертифікації та адміністративний статус ревізії BC не змінюються.';

                    trigger OnAction()
                    var
                        FormulaMgt: Codeunit "SI Prok Recipe Formula Mgt.";
                    begin
                        FormulaMgt.Deactivate(Rec);
                        UpdateProktekState();
                        CurrPage.Update(false);
                    end;
                }
                action(SIOpenProktekSyncStatus)
                {
                    Caption = 'Стан синхронізації';
                    ApplicationArea = All;
                    Image = Information;
                    Enabled = Published;
                    ToolTip = 'Відкрити технічний mapping Formula, recete_index, UUID та останню відповідь Proktek.';

                    trigger OnAction()
                    var
                        FormulaMgt: Codeunit "SI Prok Recipe Formula Mgt.";
                    begin
                        FormulaMgt.OpenSyncStatus(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateProktekState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateProktekState();
    end;

    local procedure UpdateProktekState()
    var
        FormulaMgt: Codeunit "SI Prok Recipe Formula Mgt.";
    begin
        FormulaMgt.GetProjectionState(Rec, FormulaIndex, FormulaUUID, Published, ProktekActive, LastSyncAt, ProktekStatusText);
        CanPublish :=
            (Rec.Status = Rec.Status::Certified) and
            (Rec."Administrative Status" = Rec."Administrative Status"::Active) and
            (Rec."Projection Status" = Rec."Projection Status"::Projected) and
            (Rec."Production BOM Version Code" <> '');
        CanActivateProktek := Published and (not ProktekActive) and CanPublish;
        CanDeactivateProktek := Published and ProktekActive;
    end;

    var
        FormulaIndex: BigInteger;
        FormulaUUID: Guid;
        Published: Boolean;
        ProktekActive: Boolean;
        LastSyncAt: DateTime;
        ProktekStatusText: Text[100];
        CanPublish: Boolean;
        CanActivateProktek: Boolean;
        CanDeactivateProktek: Boolean;
}
