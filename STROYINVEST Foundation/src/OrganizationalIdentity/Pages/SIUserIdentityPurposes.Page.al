page 50602 "SI User Identity Purposes"
{
    PageType = List;
    SourceTable = "SI User Identity Purpose";
    Caption = 'Функції облікових записів';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Стабільний семантичний код бізнесової функції облікового запису.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Зрозуміла бізнесова назва функції облікового запису.';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи можна використовувати цю функцію для нових призначень. Деактивація не змінює історичні призначення.';
                }
            }
        }
    }
}
