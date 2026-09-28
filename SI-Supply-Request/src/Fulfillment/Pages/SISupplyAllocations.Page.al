page 61011 "SI Supply Allocations"
{
    PageType = ListPart;
    SourceTable = "SI Supply Allocation";
    ApplicationArea = All;
    Caption = 'Розподіл за способами забезпечення';
    AutoSplitKey = true;
    DelayedInsert = true;
    MultipleNewLines = true;

    layout
    {
        area(Content)
        {
            repeater(Allocations)
            {
                field(ConstructionSiteName; ConstructionSiteName)
                {
                    ApplicationArea = All;
                    Caption = 'Буд. майданчик';
                    Editable = false;
                }
                field("Supply Method"; Rec."Supply Method")
                {
                    ApplicationArea = All;
                    Editable = AllocationEditable;

                    trigger OnValidate()
                    begin
                        // DelayedInsert page: persist readiness before propagating the refresh
                        // so the sibling Decision Lines part recalculates Allocated Quantity immediately.
                        CurrPage.SaveRecord();
                        CurrPage.Update(false);
                    end;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Editable = AllocationEditable;

                    trigger OnValidate()
                    begin
                        // Allocated Quantity is a FlowField on the decision line. Persist the
                        // allocation first, then let UpdatePropagation=Both refresh the parent/sibling part.
                        CurrPage.SaveRecord();
                        CurrPage.Update(false);
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field(SourceLocationName; SourceLocationName)
                {
                    ApplicationArea = All;
                    Caption = 'Склад-джерело';
                    Editable = SourceLocationEditable and AllocationEditable;
                    Lookup = true;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Location: Record Location;
                        SourceLocationLookup: Page "SI Supply Source Locations";
                    begin
                        if Rec."Supply Method" = Rec."Supply Method"::Purchase then
                            exit(true);

                        Rec.SetSourceLocationFilter(Location);
                        SourceLocationLookup.SetTableView(Location);
                        SourceLocationLookup.LookupMode(true);
                        if SourceLocationLookup.RunModal() = Action::LookupOK then begin
                            SourceLocationLookup.GetRecord(Location);
                            Rec.Validate("Source Location Code", Location.Code);
                            SourceLocationName := Location.Name;
                            CurrPage.Update(false);
                        end;
                        exit(true);
                    end;
                }
                field(PurchaseReceivingLocationName; TargetLocationName)
                {
                    ApplicationArea = All;
                    Caption = 'Склад приходу';
                    Editable = PurchaseLocationEditable;
                    Lookup = true;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Location: Record Location;
                        ReceivingLocationLookup: Page "SI Purchase Receiving Locs";
                    begin
                        ReceivingLocationLookup.LookupMode(true);
                        if ReceivingLocationLookup.RunModal() = Action::LookupOK then begin
                            ReceivingLocationLookup.GetRecord(Location);
                            Rec.Validate("Target Location Code", Location.Code);
                            TargetLocationName := Location.Name;
                            CurrPage.SaveRecord();
                            CurrPage.Update(false);
                        end;
                        exit(true);
                    end;
                }
                field(ProjectTargetLocationName; ProjectTargetLocationName)
                {
                    ApplicationArea = All;
                    Caption = 'Склад призначення';
                    Editable = false;
                }
                field("Required on Site At"; Rec."Required on Site At") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field(RecipeResolutionStatusDisplay; RecipeResolutionStatusDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Статус визначення рецептури';
                    Editable = false;
                }
                field("Selected Recipe No."; Rec."Selected Recipe No.") { ApplicationArea = All; }
                field(SelectedRevisionDisplay; SelectedRevisionDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Вибрана ревізія';
                    Editable = false;
                }
                field("Recipe Selection Mode"; Rec."Recipe Selection Mode") { ApplicationArea = All; }
                field("Material Req. Status"; Rec."Material Req. Status")
                {
                    ApplicationArea = All;
                    Visible = Rec."Supply Method" = Rec."Supply Method"::Production;
                }
                field("Material Warehouse Code"; Rec."Material Warehouse Code")
                {
                    ApplicationArea = All;
                    Visible = Rec."Supply Method" = Rec."Supply Method"::Production;
                }
                field("Execution Reference"; Rec."Execution Reference") { ApplicationArea = All; }
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
                Enabled = AllocationEditable and (Rec."Supply Method" = Rec."Supply Method"::Production);

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
                Enabled = AllocationEditable and (Rec."Supply Method" = Rec."Supply Method"::Production);

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
                Enabled = AllocationEditable and (Rec."Supply Method" = Rec."Supply Method"::Production);

                trigger OnAction()
                var
                    MaterialReqMgt: Codeunit "SI Material Req. Mgt.";
                begin
                    CurrPage.SaveRecord();
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
                Enabled = AllocationEditable and (Rec."Supply Method" = Rec."Supply Method"::Production);

                trigger OnAction()
                var
                    MaterialReqMgt: Codeunit "SI Material Req. Mgt.";
                begin
                    MaterialReqMgt.OpenRequirements(Rec);
                end;
            }
            action(CreateExecutionDocument)
            {
                ApplicationArea = All;
                Caption = 'Передати до виконання';
                Image = CreateDocument;

                trigger OnAction()
                var
                    ExecutionMgt: Codeunit "SI Supply Execution Mgt.";
                begin
                    CurrPage.SaveRecord();

                    case Rec."Supply Method" of
                        Rec."Supply Method"::Production:
                            ExecutionMgt.ExecuteProduction(Rec);
                        Rec."Supply Method"::Purchase:
                            ExecutionMgt.ExecutePurchase(Rec);
                        else
                            Error(UnsupportedExecutionMethodErr, Format(Rec."Supply Method"));
                    end;

                    CurrPage.Update(false);
                end;
            }
        }
    }


    trigger OnAfterGetRecord()
    begin
        ConstructionSiteName := Rec.GetConstructionSiteName();
        SourceLocationName := Rec.GetSourceLocationName();
        SetTargetLocationDisplay();
        AllocationEditable := IsAllocationEditable();
        PurchaseLocationEditable := AllocationEditable and (Rec."Supply Method" = Rec."Supply Method"::Purchase);
        SetRecipeDisplayValues();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ConstructionSiteName := Rec.GetConstructionSiteName();
        SourceLocationName := Rec.GetSourceLocationName();
        SetTargetLocationDisplay();
        AllocationEditable := IsAllocationEditable();
        SourceLocationEditable := Rec."Supply Method" <> Rec."Supply Method"::Purchase;
        PurchaseLocationEditable := AllocationEditable and (Rec."Supply Method" = Rec."Supply Method"::Purchase);
        SetRecipeDisplayValues();
    end;

    local procedure IsAllocationEditable(): Boolean
    var
        DecisionHeader: Record "SI Supply Decision Header";
    begin
        if not DecisionHeader.Get(Rec."Decision No.") then
            exit(false);
        exit(DecisionHeader.Status = DecisionHeader.Status::Draft);
    end;

    local procedure SetTargetLocationDisplay()
    begin
        Clear(TargetLocationName);
        Clear(ProjectTargetLocationName);
        if Rec."Supply Method" = Rec."Supply Method"::Purchase then
            TargetLocationName := Rec.GetTargetLocationName()
        else
            ProjectTargetLocationName := Rec.GetTargetLocationName();
    end;

    local procedure SetRecipeDisplayValues()
    begin
        Clear(RecipeResolutionStatusDisplay);
        Clear(SelectedRevisionDisplay);

        if Rec."Supply Method" <> Rec."Supply Method"::Production then
            exit;

        RecipeResolutionStatusDisplay := Format(Rec."Recipe Resolution Status");
        if Rec."Selected Revision No." <> 0 then
            SelectedRevisionDisplay := Format(Rec."Selected Revision No.");
    end;

    var
        ConstructionSiteName: Text[100];
        SourceLocationName: Text[100];
        TargetLocationName: Text[100];
        ProjectTargetLocationName: Text[100];
        SourceLocationEditable: Boolean;
        PurchaseLocationEditable: Boolean;
        AllocationEditable: Boolean;
        RecipeResolutionStatusDisplay: Text[50];
        SelectedRevisionDisplay: Text[20];

        MaterialsAvailableMsg: Label 'Потребу в матеріалах розраховано. Необхідні матеріали на складі %1 наявні в достатній кількості.';

        UnsupportedExecutionMethodErr: Label 'Передача до виконання для способу забезпечення «%1» не підтримується.';
}
