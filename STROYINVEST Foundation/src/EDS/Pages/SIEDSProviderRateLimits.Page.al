page 50468 "SI EDS Provider Rate Limits"
{
    PageType = List;
    SourceTable = "SI EDS Provider Rate Limit";
    Caption = 'EDS: ліміти провайдерів';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Код провайдера. OTHER-PROVIDER є типовим профілем для провайдерів без власних активних правил.';
                }
                field(Sequence; Rec.Sequence) { ApplicationArea = All; }
                field("Window Seconds"; Rec."Window Seconds") { ApplicationArea = All; }
                field("Max Requests"; Rec."Max Requests") { ApplicationArea = All; }
                field("Safety Margin %"; Rec."Safety Margin %") { ApplicationArea = All; }
                field(EffectiveMax; Rec.EffectiveMaxRequests())
                {
                    ApplicationArea = All;
                    Caption = 'Фактичний максимум';
                    Editable = false;
                }
                field(Enabled; Rec.Enabled) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}
