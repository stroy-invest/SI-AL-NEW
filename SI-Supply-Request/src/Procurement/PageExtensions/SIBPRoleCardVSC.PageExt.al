pageextension 61044 "SI BP Role Card VSC" extends "SI BP Role Card"
{
    actions
    {
        addlast(Processing)
        {
            action(SIOpenVSC)
            {
                ApplicationArea = All;
                Caption = 'Канали та умови постачання';
                ToolTip = 'Налаштувати категорії товарів, канали та умови постачання для цього постачальника.';
                Image = Setup;
                Visible = IsActiveVendorRole;

                trigger OnAction()
                var
                    BPVSCIntegration: Codeunit "SI BP VSC Integration";
                begin
                    BPVSCIntegration.OpenVSCForRole(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsActiveVendorRole :=
            (Rec."Role Type" = Rec."Role Type"::Vendor) and
            (Rec.Status = Rec.Status::Active) and
            (Rec."Vendor No." <> '');
    end;

    var
        IsActiveVendorRole: Boolean;
}
