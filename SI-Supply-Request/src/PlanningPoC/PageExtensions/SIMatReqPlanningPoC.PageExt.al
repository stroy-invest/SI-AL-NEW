pageextension 61040 "SI Mat Req Planning PoC" extends "SI Supply Material Reqs."
{
    actions
    {
        addafter(OpenProcurementPreview)
        {
            action(ProjectToComponentForecast)
            {
                ApplicationArea = All;
                Caption = 'PoC: Проєктувати потребу';
                Image = CreateDocument;

                trigger OnAction()
                var
                    PlanningPoCMgt: Codeunit "SI Planning PoC Mgt.";
                begin
                    PlanningPoCMgt.ProjectRequirement(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(OpenComponentForecastProjection)
            {
                ApplicationArea = All;
                Caption = 'PoC: Відкрити проєкцію';
                Image = View;

                trigger OnAction()
                var
                    PlanningPoCMgt: Codeunit "SI Planning PoC Mgt.";
                begin
                    PlanningPoCMgt.OpenProjection(Rec);
                end;
            }
            action(DeleteComponentForecastProjection)
            {
                ApplicationArea = All;
                Caption = 'PoC: Видалити проєкцію';
                Image = Delete;

                trigger OnAction()
                var
                    PlanningPoCMgt: Codeunit "SI Planning PoC Mgt.";
                begin
                    PlanningPoCMgt.DeleteProjection(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
