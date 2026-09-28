page 54005 "SI Business Partners"
{
    PageType = List;
    SourceTable = "SI Business Partner";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Business Partners';
    CardPageId = "SI Business Partner Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Partners)
            {
                field("Registration No."; Rec."Registration No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the official registration number of the business partner.';
                }

                field("Short Name BK"; Rec."Short Name BK")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the accountant-facing short name of the business partner.';
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the business partner without its legal form.';
                }

                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country or region of the business partner.';
                }

                field("Local Legal Form Code"; Rec."Local Legal Form Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country Legal Form';
                    ToolTip = 'Specifies the legal form used in the selected country or region.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current status of the business partner.';
                }

                field("Tax Registration No."; Rec."Tax Registration No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the business partner tax registration number.';
                }

                field("Is Customer"; Rec."Is Customer")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the business partner has the customer role.';
                }

                field("Is Vendor"; Rec."Is Vendor")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the business partner has the vendor role.';
                }

                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the related Business Central customer number.';
                }

                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the related Business Central vendor number.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(CountryLegalForms)
            {
                ApplicationArea = All;
                Caption = 'Country Legal Forms';
                ToolTip = 'Open the list of country-specific legal forms.';
                Image = List;
                RunObject = page "SI Country Legal Forms";
            }

            action(LegalForms)
            {
                ApplicationArea = All;
                Caption = 'Legal Forms';
                ToolTip = 'Open the list of normalized corporate legal forms.';
                Image = List;
                RunObject = page "SI Legal Forms";
            }
        }

        area(Promoted)
        {
            actionref(CountryLegalFormsPromoted; CountryLegalForms)
            {
            }
        }
    }
}
