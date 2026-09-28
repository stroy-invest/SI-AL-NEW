page 54005 "SI Business Partners"
{
    PageType = List;
    SourceTable = "SI Business Partner";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Контрагенти';
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
                    Caption = 'Юридична форма країни';
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

            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowTree)
            {
                ApplicationArea = All;
                Caption = 'Показати дерево';
                ToolTip = 'Показує контрагентів у дереві за ролями Постачальники та Клієнти.';
                Image = Hierarchy;

                trigger OnAction()
                begin
                    Page.Run(Page::"SI Business Partners Tree");
                    CurrPage.Close();
                end;
            }
        }

        area(Promoted)
        {
            actionref(ShowTreePromoted; ShowTree) { }
        }
    }
}
