page 61015 "SI Supply Allocation Card"
{
    PageType = Card;
    SourceTable = "SI Supply Allocation";
    Caption = 'Розподіл забезпечення';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(Context)
            {
                Caption = 'Контекст';
                field("Decision No."; Rec."Decision No.") { ApplicationArea = All; }
                field("Decision Line No."; Rec."Decision Line No.") { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Supply Method"; Rec."Supply Method") { ApplicationArea = All; }
                field(ConstructionSiteName; ConstructionSiteName)
                {
                    ApplicationArea = All;
                    Caption = 'Буд. майданчик';
                    Editable = false;
                }
                field(Status; Rec.Status) { ApplicationArea = All; }
            }
            group(Supply)
            {
                Caption = 'Забезпечення';
                field(Description; Rec.Description) { ApplicationArea = All; MultiLine = true; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field(SourceLocationName; SourceLocationName)
                {
                    ApplicationArea = All;
                    Caption = 'Склад-джерело';
                }
                field("Target Location Code"; Rec."Target Location Code") { ApplicationArea = All; }
                field("Required on Site At"; Rec."Required on Site At") { ApplicationArea = All; }
            }
            group(RecipeResolution)
            {
                Caption = 'Рецептура';
                field("Recipe Resolution Status"; Rec."Recipe Resolution Status") { ApplicationArea = All; }
                field("Selected Recipe No."; Rec."Selected Recipe No.") { ApplicationArea = All; }
                field("Selected Revision No."; Rec."Selected Revision No.") { ApplicationArea = All; }
                field("Recipe Selection Mode"; Rec."Recipe Selection Mode") { ApplicationArea = All; }
                field("Recipe Candidate Count"; Rec."Recipe Candidate Count") { ApplicationArea = All; }
                field("Recipe Selected By"; Rec."Recipe Selected By") { ApplicationArea = All; }
                field("Recipe Selected At"; Rec."Recipe Selected At") { ApplicationArea = All; }
                field("Recipe Selection Reason"; Rec."Recipe Selection Reason") { ApplicationArea = All; MultiLine = true; }
                field("Recipe Last Validated At"; Rec."Recipe Last Validated At") { ApplicationArea = All; }
                field("Recipe Resolution Message"; Rec."Recipe Resolution Message") { ApplicationArea = All; MultiLine = true; }
            }
            group(MaterialRequirements)
            {
                Caption = 'Матеріали';
                Visible = Rec."Supply Method" = Rec."Supply Method"::Production;
                field("Material Req. Status"; Rec."Material Req. Status") { ApplicationArea = All; }
                field("Material Warehouse Code"; Rec."Material Warehouse Code") { ApplicationArea = All; }
                field("Material Req. Checked At"; Rec."Material Req. Checked At") { ApplicationArea = All; }
                field("Material Req. Message"; Rec."Material Req. Message") { ApplicationArea = All; MultiLine = true; }
            }
            group(Execution)
            {
                Caption = 'Виконання';
                field("Execution Reference"; Rec."Execution Reference") { ApplicationArea = All; }
                field("Execution System ID"; Rec."Execution System ID") { ApplicationArea = All; }
                field("Created By"; Rec."Created By") { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ResolveRecipe)
            {
                ApplicationArea = All;
                Caption = 'Визначити рецептуру';
                Image = Calculate;
                Enabled = Rec."Supply Method" = Rec."Supply Method"::Production;

                trigger OnAction()
                var
                    RecipeMgt: Codeunit "SI Supply Recipe Mgt.";
                begin
                    RecipeMgt.Resolve(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(SelectRecipeManually)
            {
                ApplicationArea = All;
                Caption = 'Вибрати рецептуру вручну';
                Image = SelectEntries;
                Enabled = Rec."Supply Method" = Rec."Supply Method"::Production;

                trigger OnAction()
                var
                    RecipeMgt: Codeunit "SI Supply Recipe Mgt.";
                begin
                    RecipeMgt.SelectManually(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CalculateMaterialReq)
            {
                ApplicationArea = All;
                Caption = 'Розрахувати потребу в матеріалах';
                Image = Calculate;
                Enabled = Rec."Supply Method" = Rec."Supply Method"::Production;

                trigger OnAction()
                var
                    MaterialReqMgt: Codeunit "SI Material Req. Mgt.";
                begin
                    MaterialReqMgt.Calculate(Rec);
                    CurrPage.Update(false);
                    Commit();
                    if Rec."Material Req. Status" = Rec."Material Req. Status"::Available then
                        Message(MaterialsAvailableMsg, Rec."Material Warehouse Code");
                    MaterialReqMgt.OpenRequirements(Rec);
                end;
            }
            action(ViewMaterialReq)
            {
                ApplicationArea = All;
                Caption = 'Потреба в матеріалах';
                Image = ViewDetails;
                Enabled = Rec."Supply Method" = Rec."Supply Method"::Production;

                trigger OnAction()
                var
                    MaterialReqMgt: Codeunit "SI Material Req. Mgt.";
                begin
                    MaterialReqMgt.OpenRequirements(Rec);
                end;
            }
        }
    }


    trigger OnAfterGetRecord()
    begin
        ConstructionSiteName := Rec.GetConstructionSiteName();
        SourceLocationName := Rec.GetSourceLocationName();
    end;

    var
        ConstructionSiteName: Text[100];
        SourceLocationName: Text[100];
        MaterialsAvailableMsg: Label 'Потребу в матеріалах розраховано. Необхідні матеріали на складі %1 наявні в достатній кількості.';

}
