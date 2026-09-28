page 53010 "SI Family Params Part"
{
    PageType = ListPart;
    SourceTable = "SI Family Parameter";
    ApplicationArea = All;
    Caption = 'Параметри сімейства';
    DelayedInsert = true;
    PopulateAllFields = true;

    SourceTableView =
        sorting(
            "Family Code",
            "Parameter Order",
            "Parameter Code");

    layout
    {
        area(Content)
        {
            repeater(Parameters)
            {
                field("Parameter Code"; Rec."Parameter Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає параметр, доступний для вибраного сімейства.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ProductParameter: Record "SI Product Parameter";
                        AvailableParameters: Page "SI Wiz. Avail. Params";
                    begin
                        Rec.TestField("Family Code");

                        Clear(AvailableParameters);
                        AvailableParameters.LoadForFamily(
                            Rec."Family Code");
                        AvailableParameters.LookupMode(true);

                        if AvailableParameters.RunModal() <>
                           Action::LookupOK
                        then
                            exit(false);

                        AvailableParameters.GetRecord(
                            ProductParameter);

                        Rec.Validate(
                            "Parameter Code",
                            ProductParameter.Code);

                        exit(true);
                    end;
                }

                field("Parameter Order"; Rec."Parameter Order")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає порядок параметра в конфігураторі.';
                }

                field(Mandatory; Rec.Mandatory)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи є параметр обов’язковим.';
                }

                field("ERP Projection Role"; Rec."ERP Projection Role")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає роль параметра у формуванні Item або Variant.';
                }

                field("Include in Description"; Rec."Include in Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи входить параметр до назви продукту.';
                }

                field("Description Order"; Rec."Description Order")
                {
                    ApplicationArea = All;
                    Editable = Rec."Include in Description";
                    ToolTip = 'Визначає порядок параметра в назві продукту.';
                }

                field("Recipe Relevant"; Rec."Recipe Relevant")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає технологічну значущість параметра.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заблоковано параметр у цьому сімействі.';
                }
            }
        }
    }
    procedure SetFamilyFilter(FamilyCode: Code[30])
    begin
        Rec.Reset();
        Rec.SetRange("Family Code", FamilyCode);

        if Rec.FindFirst() then;

        CurrPage.Update(false);
    end;
}