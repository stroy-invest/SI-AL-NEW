page 57991 "SI Prok Recovery Reason"
{
    PageType = StandardDialog;
    Caption = 'Причина ручного зіставлення';
    layout { area(Content) { field(Reason; Why) { ApplicationArea = All; Caption = 'Причина'; } } }
    procedure GetReason(): Text[250]
    begin
        exit(Why);
    end;
    var Why: Text[250];
}
