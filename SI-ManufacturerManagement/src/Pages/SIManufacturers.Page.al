page 55000 "SI Manufacturers"
{
    PageType = List;
    SourceTable = "SI Manufacturer";
    ApplicationArea = All;
    UsageCategory = Lists;

    Caption = 'Виробники';

    CardPageId = "SI Manufacturer Card";

    layout
    {
        area(Content)
        {
            repeater(Manufacturers)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Код виробника.';
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Назва виробника.';
                }

                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Код країни або регіону виробника.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заблоковано виробника для подальшого використання.';
                }
            }
        }
    }
}