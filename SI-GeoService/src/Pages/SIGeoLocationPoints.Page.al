page 63001 "SI Geo Location Points"
{
    Caption = 'Географічні точки складів';
    PageType = List;
    SourceTable = "SI Geo Location Point";
    ApplicationArea = All;
    UsageCategory = Lists;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Points)
            {
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }

                field("Point Code"; Rec."Point Code")
                {
                    ApplicationArea = All;
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

                field("Point Type"; Rec."Point Type")
                {
                    ApplicationArea = All;
                }

                field(Latitude; Rec.Latitude)
                {
                    ApplicationArea = All;
                }

                field(Longitude; Rec.Longitude)
                {
                    ApplicationArea = All;
                }

                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                }

                field("Default Point"; Rec."Default Point")
                {
                    ApplicationArea = All;
                }

                field(Verified; Rec.Verified)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}