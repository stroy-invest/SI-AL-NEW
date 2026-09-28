page 57023 "SI Concrete Prod Req Card"
{
    PageType = Card;
    SourceTable = "SI Concrete Prod Request";
    Caption = 'Заявка на виробництво бетону';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';
                field("Required Date/Time"; Rec."Required Date/Time")
                {
                    ApplicationArea = All;
                }
            }
            group(DemandContext)
            {
                Caption = 'Контекст потреби';

                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = ShowSourceDocument;
                }
                field("Source Line No."; Rec."Source Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = ShowSourceDocument;
                }
                field("Request Type"; Rec."Request Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = ShowSupplyContext;
                }
                field(ProjectDisplay; ProjectDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Проєкт';
                    Editable = false;
                    Visible = ShowSupplyContext;
                    DrillDown = true;
                    ToolTip = 'Людиночитабельна назва будівельного проєкту.';

                    trigger OnDrillDown()
                    var
                        Project: Record Job;
                    begin
                        if (Rec."Project No." <> '') and Project.Get(Rec."Project No.") then
                            Page.RunModal(Page::"Job Card", Project);
                    end;
                }
                field(IntegrationCustomerDisplay; IntegrationCustomerDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Інтеграційний клієнт';
                    Editable = false;
                    Visible = ShowSupplyContext;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        Customer: Record Customer;
                    begin
                        if (Rec."Integration Customer No." <> '') and Customer.Get(Rec."Integration Customer No.") then
                            Page.RunModal(Page::"Customer Card", Customer);
                    end;
                }
            }
            group(SupplyContext)
            {
                Caption = 'Контекст забезпечення';
                Visible = ShowSupplyContext;

                field("Supply Decision No."; Rec."Supply Decision No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        DecisionHeader: Record "SI Supply Decision Header";
                    begin
                        if Rec."Supply Decision No." = '' then
                            exit;

                        if DecisionHeader.Get(Rec."Supply Decision No.") then
                            Page.RunModal(Page::"SI Supply Decision Card", DecisionHeader);
                    end;
                }
                field("Supply Decision Line No."; Rec."Supply Decision Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        DecisionLine: Record "SI Supply Decision Line";
                    begin
                        if (Rec."Supply Decision No." = '') or (Rec."Supply Decision Line No." = 0) then
                            exit;

                        if DecisionLine.Get(Rec."Supply Decision No.", Rec."Supply Decision Line No.") then
                            Page.RunModal(Page::"SI Supply Decision Line Card", DecisionLine);
                    end;
                }
                field("Supply Allocation Line No."; Rec."Supply Allocation Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        Allocation: Record "SI Supply Allocation";
                    begin
                        if (Rec."Supply Decision No." = '') or
                           (Rec."Supply Decision Line No." = 0) or
                           (Rec."Supply Allocation Line No." = 0)
                        then
                            exit;

                        if Allocation.Get(
                            Rec."Supply Decision No.",
                            Rec."Supply Decision Line No.",
                            Rec."Supply Allocation Line No.")
                        then
                            Page.RunModal(Page::"SI Supply Allocation Card", Allocation);
                    end;
                }
                field("Supply Method"; Rec."Supply Method")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(SourceLocationDisplay; SourceLocationDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Склад-джерело';
                    Editable = false;
                    DrillDown = true;
                    ToolTip = 'Тип складу та його людиночитабельна назва.';

                    trigger OnDrillDown()
                    var
                        Location: Record Location;
                    begin
                        if (Rec."Source Location Code" <> '') and Location.Get(Rec."Source Location Code") then
                            Page.RunModal(Page::"Location Card", Location);
                    end;
                }
                field(TargetLocationDisplay; TargetLocationDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Майданчик / склад призначення';
                    Editable = false;
                    DrillDown = true;
                    ToolTip = 'Для будівельного проєкту відображається назва проєкту; для інших сценаріїв — назва Location.';

                    trigger OnDrillDown()
                    var
                        Project: Record Job;
                        Location: Record Location;
                    begin
                        if (Rec."Project No." <> '') and Project.Get(Rec."Project No.") then begin
                            Page.RunModal(Page::"Job Card", Project);
                            exit;
                        end;

                        if (Rec."Location Code" <> '') and Location.Get(Rec."Location Code") then begin
                            Page.RunModal(Page::"Location Card", Location);
                            exit;
                        end;

                        if (Rec."Project Location Code" <> '') and Location.Get(Rec."Project Location Code") then
                            Page.RunModal(Page::"Location Card", Location);
                    end;
                }
            }
            group(OrderData)
            {
                Caption = 'Замовлення';
                Visible = ShowOrderSection;

                field(CustomerName; CustomerName)
                {
                    ApplicationArea = All;
                    Caption = 'Клієнт';
                    Editable = false;
                    Visible = ShowCustomer;
                }
                field(LocationName; LocationName)
                {
                    ApplicationArea = All;
                    Caption = 'Майданчик';
                    Editable = false;
                    Visible = ShowLocation;
                }
            }
            group(Product)
            {
                Caption = 'Виробничий контекст';

                field(ProductName; ProductName)
                {
                    ApplicationArea = All;
                    Caption = 'Товар / Варіант';
                    Editable = false;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        Item: Record Item;
                    begin
                        if (Rec."Item No." <> '') and Item.Get(Rec."Item No.") then
                            Page.RunModal(Page::"Item Card", Item);
                    end;
                }
                field(QuantityDisplay; QuantityDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Кількість';
                    Editable = false;
                }
            }
            group(Recipe)
            {
                Caption = 'Виконувана рецептура';
                field("Recipe Type"; Rec."Recipe Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(RecipeName; RecipeName)
                {
                    ApplicationArea = All;
                    Caption = 'Рецептура';
                    Editable = false;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        Snapshot: Record "SI Prok Recipe Snapshot";
                    begin
                        if Rec."Recipe Snapshot Entry No." = 0 then
                            exit;

                        if Snapshot.Get(Rec."Recipe Snapshot Entry No.") then
                            Page.RunModal(Page::"SI Prok Recipe Snapshot Card", Snapshot);
                    end;
                }
            }
        }

        area(FactBoxes)
        {
            part(CPRTechnicalInfo; "SI Prok CPR FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UseBaseRecipe)
            {
                ApplicationArea = All;
                Caption = 'Використати базову рецептуру';
                Image = Apply;

                trigger OnAction()
                var
                    FormulaProjector: Codeunit "SI Prok Formula Projector";
                    BOMResolver: Codeunit "SI Prok Product BOM Resolver";
                    ProductionBOM: Record "Production BOM Header";
                    BOMNo: Code[20];
                begin
                    Rec.TestField("Item No.");
                    BOMNo := BOMResolver.ResolveProductionBOM(Rec."Item No.", Rec."Variant Code");
                    ProductionBOM.Get(BOMNo);
                    if ProductionBOM.Status <> ProductionBOM.Status::Certified then
                        Error('Виробнича специфікація %1 не має статусу Certified.', BOMNo);
                    Rec."Recipe Type" := Rec."Recipe Type"::Base;
                    Rec."Recipe Snapshot Entry No." := 0;
                    Rec."Formula Code" := CopyStr(FormulaProjector.BuildFormulaIntegrationKey(Rec."Item No.", Rec."Variant Code"), 1, MaxStrLen(Rec."Formula Code"));
                    Rec."Formula Description" := Rec.GetProductDescription();
                    Rec.Status := Rec.Status::"Recipe Resolved";
                    Rec.Modify(true);
                    UpdatePresentation();
                    CurrPage.Update(false);
                end;
            }
            action(UseModifiedRecipe)
            {
                ApplicationArea = All;
                Caption = 'Використати модифіковану рецептуру';
                Image = SelectLineToApply;

                trigger OnAction()
                var
                    Snapshot: Record "SI Prok Recipe Snapshot";
                    SnapshotList: Page "SI Prok Recipe Snapshots";
                begin
                    Rec.TestField("Item No.");

                    Snapshot.SetRange("Item No.", Rec."Item No.");
                    Snapshot.SetRange("Variant Code", Rec."Variant Code");
                    Snapshot.SetRange(Status, Snapshot.Status::Certified);
                    if Snapshot.IsEmpty() then
                        Error('Для товару %1 та вибраного варіанта немає Certified модифікованих рецептур.', Rec.GetProductDescription());

                    SnapshotList.SetTableView(Snapshot);
                    SnapshotList.LookupMode(true);
                    if SnapshotList.RunModal() <> Action::LookupOK then
                        exit;
                    SnapshotList.GetRecord(Snapshot);

                    Rec."Recipe Type" := Rec."Recipe Type"::Modified;
                    Rec."Recipe Snapshot Entry No." := Snapshot."Entry No.";
                    Rec."Formula Code" := Snapshot."Derived Formula Code";
                    Rec."Formula Description" := BuildModifiedRecipeCaption(Snapshot);
                    Rec.Status := Rec.Status::"Recipe Resolved";
                    Rec.Modify(true);
                    UpdatePresentation();
                    CurrPage.Update(false);
                end;
            }

            action(CreateModifiedRecipe)
            {
                ApplicationArea = All;
                Caption = 'Створити модифіковану рецептуру';
                Image = NewDocument;

                trigger OnAction()
                var
                    Snapshot: Record "SI Prok Recipe Snapshot";
                begin
                    Rec.TestField("Item No.");

                    Snapshot.Init();
                    Snapshot."Production Request Entry No." := Rec."Entry No.";
                    Snapshot.Validate("Item No.", Rec."Item No.");
                    if Rec."Variant Code" <> '' then
                        Snapshot.Validate("Variant Code", Rec."Variant Code");
                    Snapshot.Insert(true);
                    Snapshot.RefreshBaseData();
                    Snapshot.Modify(true);

                    Rec."Recipe Type" := Rec."Recipe Type"::Modified;
                    Rec."Recipe Snapshot Entry No." := Snapshot."Entry No.";
                    Rec."Formula Code" := Snapshot."Derived Formula Code";
                    Rec."Formula Description" := BuildModifiedRecipeCaption(Snapshot);
                    Rec.Status := Rec.Status::"Recipe Resolved";
                    Rec.Modify(true);

                    Page.Run(Page::"SI Prok Recipe Snapshot Card", Snapshot);
                    UpdatePresentation();
                    CurrPage.Update(false);
                end;
            }

            action(OpenRecipeSnapshot)
            {
                ApplicationArea = All;
                Caption = 'Відкрити Recipe Snapshot';
                Image = View;
                Enabled = HasSnapshot;

                trigger OnAction()
                var
                    Snapshot: Record "SI Prok Recipe Snapshot";
                begin
                    Rec.TestField("Recipe Snapshot Entry No.");
                    Snapshot.Get(Rec."Recipe Snapshot Entry No.");
                    Page.Run(Page::"SI Prok Recipe Snapshot Card", Snapshot);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdatePresentation();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdatePresentation();
    end;

    local procedure UpdatePresentation()
    begin
        ShowSupplyContext := Rec."Source Type" = Rec."Source Type"::"Supply Request";
        ShowCustomer := Rec."Source Type" = Rec."Source Type"::"External Sale";
        ShowLocation := Rec."Source Type" = Rec."Source Type"::"Internal Project";
        ShowOrderSection := ShowCustomer or ShowLocation;
        ShowSourceDocument := Rec."Source No." <> '';

        CustomerName := Rec.GetCustomerDescription();
        LocationName := Rec.GetLocationDescription();
        ProductName := Rec.GetProductDescription();
        QuantityDisplay := BuildQuantityDisplay();
        ProjectDisplay := GetProjectDisplay();
        IntegrationCustomerDisplay := GetIntegrationCustomerDisplay();
        SourceLocationDisplay := GetSourceLocationDisplay();
        TargetLocationDisplay := GetTargetLocationDisplay();

        RecipeName := Rec."Formula Description";
        if Rec."Recipe Type" = Rec."Recipe Type"::Modified then
            RecipeName := GetModifiedRecipeCaption();
        HasSnapshot := Rec."Recipe Snapshot Entry No." <> 0;
    end;

    local procedure BuildQuantityDisplay(): Text[80]
    begin
        if Rec."Unit of Measure Code" = '' then
            exit(Format(Rec.Quantity));

        exit(CopyStr(StrSubstNo('%1 %2', Format(Rec.Quantity), Rec."Unit of Measure Code"), 1, 80));
    end;

    local procedure GetProjectDisplay(): Text[150]
    var
        Project: Record Job;
    begin
        if (Rec."Project No." <> '') and Project.Get(Rec."Project No.") then begin
            if Project.Description <> '' then
                exit(CopyStr(Project.Description, 1, 150));
            exit(Rec."Project No.");
        end;

        exit(Rec."Project No.");
    end;

    local procedure GetIntegrationCustomerDisplay(): Text[150]
    var
        Customer: Record Customer;
    begin
        if (Rec."Integration Customer No." <> '') and Customer.Get(Rec."Integration Customer No.") then begin
            if Customer.Name <> '' then
                exit(CopyStr(Customer.Name, 1, 150));
            exit(Rec."Integration Customer No.");
        end;

        exit(Rec."Integration Customer No.");
    end;

    local procedure GetSourceLocationDisplay(): Text[250]
    var
        Location: Record Location;
    begin
        if (Rec."Source Location Code" = '') or (not Location.Get(Rec."Source Location Code")) then
            exit(Rec."Source Location Code");

        if (Location."SI Location Type Code" <> '') and (Location.Name <> '') then
            exit(CopyStr(StrSubstNo('%1: %2', Location."SI Location Type Code", Location.Name), 1, 250));

        if Location.Name <> '' then
            exit(CopyStr(Location.Name, 1, 250));

        exit(Location.Code);
    end;

    local procedure GetTargetLocationDisplay(): Text[250]
    var
        Project: Record Job;
        Location: Record Location;
    begin
        if (Rec."Project No." <> '') and Project.Get(Rec."Project No.") and (Project.Description <> '') then
            exit(CopyStr(Project.Description, 1, 250));

        if (Rec."Location Code" <> '') and Location.Get(Rec."Location Code") then begin
            if Location.Name <> '' then
                exit(CopyStr(Location.Name, 1, 250));
            exit(Location.Code);
        end;

        if (Rec."Project Location Code" <> '') and Location.Get(Rec."Project Location Code") then begin
            if Location.Name <> '' then
                exit(CopyStr(Location.Name, 1, 250));
            exit(Location.Code);
        end;

        exit(Rec."Location Code");
    end;

    local procedure GetModifiedRecipeCaption(): Text[150]
    var
        Snapshot: Record "SI Prok Recipe Snapshot";
    begin
        if Rec."Recipe Snapshot Entry No." = 0 then
            exit(Rec."Formula Description");
        if not Snapshot.Get(Rec."Recipe Snapshot Entry No.") then
            exit(Rec."Formula Description");
        exit(BuildModifiedRecipeCaption(Snapshot));
    end;

    local procedure BuildModifiedRecipeCaption(Snapshot: Record "SI Prok Recipe Snapshot"): Text[150]
    var
        BaseCaption: Text[150];
    begin
        BaseCaption := Snapshot.Description;
        if BaseCaption = '' then
            BaseCaption := Rec.GetProductDescription();
        exit(CopyStr(StrSubstNo('%1 | RS-%2', BaseCaption, Snapshot."Entry No."), 1, 150));
    end;

    var
        CustomerName: Text[150];
        LocationName: Text[150];
        ProductName: Text[150];
        QuantityDisplay: Text[80];
        ProjectDisplay: Text[150];
        IntegrationCustomerDisplay: Text[150];
        SourceLocationDisplay: Text[250];
        TargetLocationDisplay: Text[250];
        RecipeName: Text[150];
        ShowCustomer: Boolean;
        ShowLocation: Boolean;
        ShowOrderSection: Boolean;
        ShowSourceDocument: Boolean;
        ShowSupplyContext: Boolean;
        HasSnapshot: Boolean;
}
