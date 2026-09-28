page 57027 "SI Prok Order Payload Preview"
{
    PageType = StandardDialog;
    Caption = 'Proktek Order payload';

    layout
    {
        area(Content)
        {
            group(PayloadGroup)
            {
                Caption = 'SAVE-ORDER request body';
                field(PayloadText; PayloadText)
                {
                    ApplicationArea = All;
                    Caption = 'JSON';
                    MultiLine = true;
                    Editable = false;
                }
            }
        }
    }

    procedure SetPayload(NewPayload: Text)
    begin
        PayloadText := NewPayload;
    end;

    var
        PayloadText: Text;
}
