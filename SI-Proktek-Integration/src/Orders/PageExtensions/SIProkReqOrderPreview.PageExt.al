pageextension 57028 "SI Prok Req Order Preview" extends "SI Concrete Prod Req Card"
{
    actions
    {
        addlast(Processing)
        {
            action(SIProkPreviewOrderPayload)
            {
                ApplicationArea = All;
                Caption = 'Proktek: переглянути Order payload';
                Image = View;
                ToolTip = 'Формує SAVE-ORDER payload із поточної заявки без відправлення до Proktek.';

                trigger OnAction()
                var
                    Projector: Codeunit "SI Prok Order Projector";
                    Preview: Page "SI Prok Order Payload Preview";
                    Payload: Text;
                begin
                    Payload := Projector.BuildOrderPayload(Rec);
                    Preview.SetPayload(Payload);
                    Preview.RunModal();
                end;
            }
        }
    }
}
