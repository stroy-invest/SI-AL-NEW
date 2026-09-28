page 54051 "SI BP Bank Accounts Part"
{
    PageType = ListPart;
    SourceTable = "SI BP Bank Account";

    Caption = 'Банківські рахунки';
    ApplicationArea = All;

    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }

                field(IBAN; Rec.IBAN)
                {
                    ApplicationArea = All;
                }

                field("Bank Name"; Rec."Bank Name")
                {
                    ApplicationArea = All;
                }

                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                }

                field(MFO; Rec.MFO)
                {
                    ApplicationArea = All;
                }

                field("Bank EDRPOU"; Rec."Bank EDRPOU")
                {
                    ApplicationArea = All;
                }

                field("Verification Status"; Rec."Verification Status")
                {
                    ApplicationArea = All;
                }

                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                }

                field(Primary; Rec.Primary)
                {
                    ApplicationArea = All;
                }

                field("Verified At"; Rec."Verified At")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}