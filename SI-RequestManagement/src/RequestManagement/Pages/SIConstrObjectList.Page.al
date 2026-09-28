page 52016 "SI Constr. Object List"
{
    PageType = List;
    SourceTable = "SI Construction Object";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Об''єкти будівництва';
    // CardPageId = "SI Constr. Object Card";

    layout
    {
        area(Content)
        {
            repeater(Objects)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }

                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                }

                field(City; Rec.City)
                {
                    ApplicationArea = All;
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }

                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
