page 51002 "SI IW Position Cap. Maps"
{
    PageType = List;
    SourceTable = "SI IW Position Cap. Map";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Відповідність посад IW компетенціям SI';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("IW Position Code"; Rec."IW Position Code") { ApplicationArea = All; }
                field("Capability Code"; Rec."Capability Code") { ApplicationArea = All; }
                field(Active; Rec.Active) { ApplicationArea = All; }
            }
        }
    }
}
