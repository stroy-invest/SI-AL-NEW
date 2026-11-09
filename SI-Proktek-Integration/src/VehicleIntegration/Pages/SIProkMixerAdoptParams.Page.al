page 57113 "SI Prok Mixer Adopt Params"
{
    PageType = StandardDialog;
    Caption = 'Прив’язка існуючого міксера Proktek';
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            group(Parameters)
            {
                Caption = 'Ідентифікатори Proktek';
                field(MixerId; MixerId)
                {
                    ApplicationArea = All;
                    Caption = 'Mixer ID';
                }
                field(MixerUuidText; MixerUuidText)
                {
                    ApplicationArea = All;
                    Caption = 'Mixer UUID';
                }
            }
        }
    }
    procedure GetValues(var Id: Integer; var Uuid: Guid)
    begin
        if MixerId <= 0 then
            Error('Mixer ID має бути додатним.');
        if not Evaluate(Uuid, MixerUuidText) then
            Error('Некоректний Mixer UUID.');
        if IsNullGuid(Uuid) then
            Error('Mixer UUID не може бути порожнім.');
        Id := MixerId;
    end;
    var
        MixerId: Integer;
        MixerUuidText: Text[50];
}
