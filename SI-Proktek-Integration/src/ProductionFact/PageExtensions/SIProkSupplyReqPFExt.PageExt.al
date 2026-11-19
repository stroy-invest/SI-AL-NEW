pageextension 57223 "SI Prok Supply Req PF Ext" extends "SI Supply Req Card"
{
    actions
    {
        addlast(Processing)
        {
            action(SIProkExportPlanFact)
            {
                ApplicationArea = All;
                Caption = 'Звіт план/факт';
                Image = ExportToExcel;
                ToolTip = 'Сформувати Excel план/факт за всіма виробничими заявками та партіями цієї заявки на забезпечення.';
                trigger OnAction()
                var
                    Exporter: Codeunit "SI Prok Plan Fact Excel";
                begin
                    Exporter.ExportForSupplyRequest(Rec."No.");
                end;
            }
        }
    }
}
