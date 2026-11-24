namespace STROYINVEST.ConcreteRecipeEngine;

page 62115 "SI Recipe Proktek No. Dialog"
{
    PageType = StandardDialog;
    Caption = 'Вписати номер Proktek';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(ProktekNumber; ProktekNumber)
            {
                ApplicationArea = All;
                Caption = 'Номер рецептури в Proktek';
                ToolTip = 'Номер для операторського АРМ MES; не використовується для ERP-зв’язування.';
            }
        }
    }

    procedure GetNumber(): Text[20]
    begin
        exit(ProktekNumber);
    end;

    var
        ProktekNumber: Text[20];
}
