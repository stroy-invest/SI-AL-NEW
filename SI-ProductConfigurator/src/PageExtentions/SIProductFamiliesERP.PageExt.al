pageextension 53021 "SI Product Families ERP Ext." extends "SI Product Families"
{
    actions
    {
        addafter(Parameters)
        {
            action(ItemProjections)
            {
                ApplicationArea = All;
                Caption = 'ERP-проєкції товарів';
                Image = Item;
                ToolTip = 'Відкриває ERP-проєкції товарів для вибраного сімейства.';

                trigger OnAction()
                var
                    ItemProjection: Record "SI Item ERP Projection";
                begin
                    Rec.TestField(Code);
                    ItemProjection.SetRange("Family Code", Rec.Code);
                    Page.Run(Page::"SI Item ERP Projections", ItemProjection);
                end;
            }
        }

        addlast(Promoted)
        {
            actionref(ItemProjectionsPromoted; ItemProjections)
            {
            }
        }
    }
}
