pageextension 60003 "SI Job Card Ext." extends "Job Card"
{
    layout
    {
        modify("Location Code")
        {
            // Preserve the standard BC field and layout. For SI Construction Projects
            // the project location is system-managed and therefore read-only.
            Editable = LocationCodeEditable;
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        RefreshLocationEditability();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        RefreshLocationEditability();
    end;

    local procedure RefreshLocationEditability()
    begin
        LocationCodeEditable := not Rec."SI Construction Project";
    end;

    var
        LocationCodeEditable: Boolean;
}
