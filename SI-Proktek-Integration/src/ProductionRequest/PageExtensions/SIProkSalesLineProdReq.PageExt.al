pageextension 57025 "SI Prok Sales Line ProdReq" extends "Sales Order Subform"
{
    actions
    {
        addlast("F&unctions")
        {
            action(SICreateConcreteProdReq)
            {
                ApplicationArea = All;
                Caption = 'Створити заявку на виробництво бетону';
                Image = CreateDocument;
                ToolTip = 'Створює або відкриває заявку на виробництво бетону для поточного рядка Sales Order.';

                trigger OnAction()
                var
                    SalesHandler: Codeunit "SI Concrete Sales Handler";
                begin
                    SalesHandler.CreateOrOpenFromLine(Rec);
                end;
            }
        }
    }
}
