page 54024 "SI BP Address Card"
{
    PageType = Card;
    SourceTable = "SI BP Address";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Адреса контрагента';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальні дані';

                field("Business Partner No."; Rec."Business Partner No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Address Type"; Rec."Address Type")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("Is Primary"; Rec."Is Primary")
                {
                    ApplicationArea = All;
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = All;
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = All;
                }
            }

            group(StructuredAddress)
            {
                Caption = 'Структурована адреса';

                field("Region/State"; Rec."Region/State")
                {
                    ApplicationArea = All;
                }
                field(District; Rec.District)
                {
                    ApplicationArea = All;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = All;
                }
                field(Street; Rec.Street)
                {
                    ApplicationArea = All;
                }
                field("Building No."; Rec."Building No.")
                {
                    ApplicationArea = All;
                }
                field("Office/Apartment"; Rec."Office/Apartment")
                {
                    ApplicationArea = All;
                }
                field("Address Details"; Rec."Address Details")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
                field("Raw Address"; Rec."Raw Address")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
            }

            group(Verification)
            {
                Caption = 'Перевірка';

                field(Verified; Rec.Verified)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Verification Source"; Rec."Verification Source")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Verification Date/Time"; Rec."Verification Date/Time")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetDefaultsFromBusinessPartner();
    end;

    local procedure SetDefaultsFromBusinessPartner()
    var
        BusinessPartner: Record "SI Business Partner";
    begin
        if Rec."Business Partner No." = '' then
            exit;

        if not BusinessPartner.Get(Rec."Business Partner No.") then
            exit;

        if Rec."Country/Region Code" = '' then
            Rec."Country/Region Code" := BusinessPartner."Country/Region Code";

        if Rec."Valid From" = 0D then
            Rec."Valid From" := WorkDate();
    end;
}
