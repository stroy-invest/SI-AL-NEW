pageextension 57060 "SI Prok Production BOM Ext." extends "Production BOM"
{
    actions
    {
        addlast(Processing)
        {
            action(SIProkTestKgProjection)
            {
                ApplicationArea = All;
                Caption = 'Proktek: тест BOM → KG';
                Image = Calculate;
                ToolTip = 'Перевіряє проєкцію компонентів Production BOM у кілограми через SI Master Data Toolkit без виклику Proktek API.';

                trigger OnAction()
                var
                    FormulaProjector: Codeunit "SI Prok Formula Projector";
                begin
                    Rec.TestField("No.");
                    Message('%1', FormulaProjector.BuildBomKgProjection(Rec."No."));
                end;
            }

            action(SIProkTestMaterialProjection)
            {
                ApplicationArea = All;
                Caption = 'Proktek: тест BOM → KG → Materials';
                Image = Link;
                ToolTip = 'Проєктує BOM у KG, один раз читає GET-MATERIALS і резолвить кожен компонент за malzeme_ent_kod. SAVE-FORMULA не викликається.';

                trigger OnAction()
                var
                    FormulaProjector: Codeunit "SI Prok Formula Projector";
                begin
                    Rec.TestField("No.");
                    Message('%1', FormulaProjector.BuildBomKgMaterialProjection(Rec."No."));
                end;
            }


            action(SIProkFormulaJsonPreview)
            {
                ApplicationArea = All;
                Caption = 'Proktek: JSON preview';
                Image = View;
                ToolTip = 'Будує JSON preview recete_malzeme[] з BOM через MDT та Proktek Material Resolver. SAVE-FORMULA не викликається.';

                trigger OnAction()
                var
                    FormulaProjector: Codeunit "SI Prok Formula Projector";
                begin
                    Rec.TestField("No.");
                    Message('%1', FormulaProjector.BuildFormulaMaterialsJsonPreview(Rec."No."));
                end;
            }
            action(SIProkFormulaSavePayloadPreview)
            {
                ApplicationArea = All;
                Caption = 'Proktek: бойовий Formula JSON';
                Image = View;
                ToolTip = 'Формує точний JSON request body, який буде передано в SAVE-FORMULA для поточного Item + Variant + Production BOM. Запит у Proktek не відправляється.';

                trigger OnAction()
                var
                    PayloadPreview: Page "SI Prok Formula Payload";
                begin
                    Rec.TestField("No.");
                    PayloadPreview.SetContext(Rec."No.");
                    PayloadPreview.RunModal();
                end;
            }

            action(SIProkExportFormula)
            {
                ApplicationArea = All;
                Caption = 'Proktek: експортувати Formula';
                Image = SendTo;
                ToolTip = 'Формує Formula з Item + Variant + Production BOM за master data BC та викликає SAVE-FORMULA.';

                trigger OnAction()
                var
                    ExportDialog: Page "SI Prok Formula Export Dialog";
                begin
                    Rec.TestField("No.");
                    ExportDialog.SetContext(Rec."No.");
                    ExportDialog.RunModal();
                end;
            }
        }
    }
}
