pageextension 53023 "SI Product Configs ERP Ext" extends "SI Product Configs."
{
    actions
    {
        addlast(Processing)
        {
            action(PreviewERPProjection)
            {
                ApplicationArea = All;
                Caption = 'Перегляд ERP-проєкції';
                Image = ViewDetails;
                ToolTip = 'Формує та показує майбутній товар і варіант без створення об’єктів Business Central.';

                trigger OnAction()
                var
                    ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
                begin
                    Rec.TestField("No.");
                    ERPProjectionMgt.OpenPreview(Rec."No.");
                end;
            }
        }

        addlast(Promoted)
        {
            actionref(PreviewERPProjectionProm; PreviewERPProjection)
            {
            }
        }
    }
}
