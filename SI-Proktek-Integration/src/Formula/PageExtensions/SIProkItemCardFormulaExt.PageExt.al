pageextension 57061 "SI Prok Item Card Formula Ext." extends "Item Card"
{
    actions
    {
        addlast(Processing)
        {
            action(SIProkExportProductFormula)
            {
                ApplicationArea = All;
                Caption = 'Proktek: експортувати Formula';
                Image = SendTo;
                ToolTip = 'Резолвить Production BOM із товару, дозволяє вибрати лише його варіант і синхронізує Formula з Proktek.';

                trigger OnAction()
                var
                    ExportDialog: Page "SI Prok Product Formula Export";
                begin
                    Rec.TestField("No.");
                    ExportDialog.SetItem(Rec."No.");
                    ExportDialog.RunModal();
                end;
            }
        }
    }
}
