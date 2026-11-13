pageextension 57199 "SI Prok TC01 Facts Ext" extends "SI Prok Production Facts"
{
    actions
    {
        addlast(Processing)
        {
            action(ApplyTC01Output)
            {
                Caption = 'TC-01: Заповнити тестовий випуск';
                ApplicationArea = All;
                Image = Calculate;
                ToolTip = 'Тестове встановлення випуску п’яти партій за введеним Order No. Лише Sandbox.';
                trigger OnAction()
                var
                    Fixture: Codeunit "SI Prok TC01 Output Override";
                begin
                    Fixture.Apply();
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
