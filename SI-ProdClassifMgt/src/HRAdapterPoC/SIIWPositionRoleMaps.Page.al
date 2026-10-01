page 56204 "SI IW Position Role Maps"
{
    PageType = List;
    SourceTable = "SI IW Position Role Map";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Відповідність посад IW ролям SI';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("IW Position Code"; Rec."IW Position Code")
                {
                    ApplicationArea = All;
                    TableRelation = "IWSP Position".Code;
                }
                field("SI Project Role Code"; Rec."SI Project Role Code")
                {
                    ApplicationArea = All;
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
