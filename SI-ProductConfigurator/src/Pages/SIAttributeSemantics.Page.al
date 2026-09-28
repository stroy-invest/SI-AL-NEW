page 53037 "SI Attribute Semantics"
{
    Caption = 'Семантики атрибутів';
    PageType = List;
    SourceTable = "SI Attribute Semantic";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Semantics)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає стабільний машинний код семантики атрибута.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає зрозумілу користувачу назву семантики атрибута.';
                }
            }
        }
    }
}
