page 52026 "SI Request Resolution Dialog"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Причина рішення';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Причина';

                field(ResolutionReason; ResolutionReason)
                {
                    ApplicationArea = All;
                    Caption = 'Причина повернення';
                    ToolTip = 'Зазначте, що саме потрібно виправити або уточнити в заявці.';
                    MultiLine = true;
                    ShowMandatory = true;
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            if DelChr(ResolutionReason, '<>', ' ') = '' then
                Error(ResolutionReasonRequiredErr);

        exit(true);
    end;

    procedure GetResolutionReason(): Text[250]
    begin
        exit(CopyStr(ResolutionReason, 1, 250));
    end;

    procedure SetResolutionReason(NewResolutionReason: Text[250])
    begin
        ResolutionReason := NewResolutionReason;
    end;

    var
        ResolutionReason: Text[250];
        ResolutionReasonRequiredErr: Label 'Необхідно зазначити причину повернення заявки на доопрацювання.';
}