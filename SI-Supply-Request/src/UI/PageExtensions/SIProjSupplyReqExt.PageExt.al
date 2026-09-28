pageextension 61000 "SI Proj Supply Req Ext." extends "Job Card"
{
    actions
    {
        addlast(Processing)
        {
            action(SICreateSupplyRequest)
            {
                ApplicationArea = Jobs;
                Caption = 'Створити заявку на забезпечення';
                Image = NewDocument;
                ToolTip = 'Створює нову заявку на забезпечення для поточного будівельного проєкту.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    RequestMgt: Codeunit "SI Supply Req Mgt.";
                    Header: Record "SI Supply Req Header";
                begin
                    RequestMgt.CreateForProject(Rec, Header);
                    Page.Run(Page::"SI Supply Req Card", Header);
                end;
            }

            action(SIOpenSupplyRequests)
            {
                ApplicationArea = Jobs;
                Caption = 'Заявки на забезпечення';
                Image = List;
                ToolTip = 'Відкриває заявки на забезпечення поточного будівельного проєкту.';

                trigger OnAction()
                var
                    Header: Record "SI Supply Req Header";
                begin
                    Header.SetRange("Project No.", Rec."No.");
                    Page.Run(Page::"SI Supply Req List", Header);
                end;
            }
        }
    }
}
