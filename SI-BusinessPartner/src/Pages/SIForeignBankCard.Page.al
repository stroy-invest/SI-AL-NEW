page 54014 "SI Foreign Bank Card"
{
    PageType = Card;
    SourceTable = "SI Foreign Bank";
    ApplicationArea = All;
    Caption = 'Закордонний банк';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("SWIFT"; Rec."SWIFT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the normalized SWIFT/BIC code of the foreign bank.';
                }

                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the foreign bank.';
                }

                field("Country Code"; Rec."Country Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country/region code of the foreign bank.';
                }

                field("City Name"; Rec."City Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the city where the foreign bank is located.';
                }

                field("Is Active"; Rec."Is Active")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the foreign bank is active.';
                }
            }

            group(SourceInformation)
            {
                Caption = 'Source Information';

                field("Id"; Rec."Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the source identifier of the foreign bank.';
                }

                field("K040"; Rec."K040")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the technical country code received from the source.';
                }
            }
        }
    }
}