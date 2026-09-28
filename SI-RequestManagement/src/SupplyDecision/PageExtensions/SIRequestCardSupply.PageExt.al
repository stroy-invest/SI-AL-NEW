pageextension 52048 "SI Request Card Supply" extends "SI Request Card"
{
    actions
    {
        addfirst(Processing)
        {
            action(OpenSupplyDecision)
            {
                ApplicationArea = All;
                Caption = 'Опрацювання заявки';
                ToolTip = 'Створює або відкриває рішення щодо забезпечення погодженої заявки.';
                Image = Process;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Status = Rec.Status::Approved;

                trigger OnAction()
                var
                    SupplyDecisionMgt: Codeunit "SI Supply Decision Mgt.";
                begin
                    SupplyDecisionMgt.OpenOrCreateFromRequest(Rec);
                end;
            }
        }
    }
}
