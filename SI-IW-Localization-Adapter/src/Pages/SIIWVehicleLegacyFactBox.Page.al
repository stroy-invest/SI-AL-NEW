
page 65003 "SI IW Vehicle Legacy FactBox"
{
    PageType = CardPart;
    SourceTable = IWSVehicle;
    Caption = 'Дані IW Foundation';
    Editable = false;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(LegacyDetails)
            {
                ShowCaption = false;

                field("Storage Location"; Rec."Storage Location")
                {
                    ApplicationArea = All;
                    ToolTip = 'Місце зберігання транспортного засобу в IW Foundation.';
                }

                field(Length; Rec.Length)
                {
                    ApplicationArea = All;
                    ToolTip = 'Довжина транспортного засобу в метрах.';
                }

                field(Width; Rec.Width)
                {
                    ApplicationArea = All;
                    ToolTip = 'Ширина транспортного засобу в метрах.';
                }

                field(Height; Rec.Height)
                {
                    ApplicationArea = All;
                    ToolTip = 'Висота транспортного засобу в метрах.';
                }

                field("Gross Weight"; Rec."Gross Weight")
                {
                    ApplicationArea = All;
                    ToolTip = 'Маса брутто транспортного засобу в тоннах.';
                }
            }
        }
    }
}
