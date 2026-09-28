page 53008 "SI Prod. Config. Values"
{
    PageType = ListPart;
    SourceTable = "SI Product Config. Value";
    ApplicationArea = All;
    Caption = 'Значення конфігурації';
    DelayedInsert = true;
    PopulateAllFields = true;
    AutoSplitKey = false;
    MultipleNewLines = false;

    SourceTableView =
        sorting(
            "Configuration No.",
            "Parameter Order",
            "Parameter Code");

    layout
    {
        area(Content)
        {
            repeater(Values)
            {
                field("Parameter Code"; Rec."Parameter Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає параметр конфігурації продукту.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ProductConfig: Record "SI Product Config.";
                        FamilyParameter: Record "SI Family Parameter";
                        FamilyParametersPage: Page "SI Family Parameters";
                    begin
                        Rec.TestField("Configuration No.");
                        ProductConfig.Get(Rec."Configuration No.");

                        FamilyParameter.SetRange("Family Code", ProductConfig."Family Code");
                        FamilyParameter.SetRange(Blocked, false);

                        if ProductConfig."Base Item No." <> '' then
                            FamilyParameter.SetRange(
                                "ERP Projection Role",
                                FamilyParameter."ERP Projection Role"::"Variant Identity")
                        else
                            FamilyParameter.SetRange(
                                "ERP Projection Role",
                                FamilyParameter."ERP Projection Role"::"Item Identity");

                        Clear(FamilyParametersPage);
                        FamilyParametersPage.SetTableView(FamilyParameter);
                        FamilyParametersPage.LookupMode(true);

                        if FamilyParametersPage.RunModal() <> Action::LookupOK then
                            exit(false);

                        FamilyParametersPage.GetRecord(FamilyParameter);
                        Text := FamilyParameter."Parameter Code";

                        exit(true);
                    end;
                }

                field("Parameter Value Code"; Rec."Parameter Value Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Контрольоване значення';
                    Editable =
                        Rec."Value Type" =
                        Rec."Value Type"::"Controlled Value";
                    ToolTip = 'Визначає допустиме контрольоване значення параметра.';
                }

                field("Decimal Value"; Rec."Decimal Value")
                {
                    ApplicationArea = All;
                    Caption = 'Десяткове значення';
                    Editable =
                        Rec."Value Type" =
                        Rec."Value Type"::Decimal;
                    ToolTip = 'Визначає десяткове значення параметра.';
                }

                field("Integer Value"; Rec."Integer Value")
                {
                    ApplicationArea = All;
                    Caption = 'Ціле значення';
                    Editable =
                        Rec."Value Type" =
                        Rec."Value Type"::Integer;
                    ToolTip = 'Визначає ціле значення параметра.';
                }

                field("Text Value"; Rec."Text Value")
                {
                    ApplicationArea = All;
                    Caption = 'Текстове значення';
                    Editable =
                        Rec."Value Type" =
                        Rec."Value Type"::Text;
                    ToolTip = 'Визначає текстове значення параметра.';
                }

                field("Boolean Value"; Rec."Boolean Value")
                {
                    ApplicationArea = All;
                    Caption = 'Значення Так/Ні';
                    Editable =
                        Rec."Value Type" =
                        Rec."Value Type"::Boolean;
                    ToolTip = 'Визначає логічне значення параметра.';
                }

                field("Date Value"; Rec."Date Value")
                {
                    ApplicationArea = All;
                    Caption = 'Значення дати';
                    Editable =
                        Rec."Value Type" =
                        Rec."Value Type"::Date;
                    ToolTip = 'Визначає значення параметра типу дата.';
                }

                field(ReferenceValue; Rec."Display Value")
                {
                    ApplicationArea = All;
                    Caption = 'Посилальне значення';
                    Editable = Rec."Value Type" = Rec."Value Type"::Reference;
                    Lookup = true;
                    Visible = Rec."Value Type" = Rec."Value Type"::Reference;
                    ToolTip = 'Визначає кероване посилальне значення з налаштованого зовнішнього довідника.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ProductConfig: Record "SI Product Config.";
                        ProductParameter: Record "SI Product Parameter";
                        FamilyParameter: Record "SI Family Parameter";
                        ReferenceParameterMgt: Codeunit "SI Reference Parameter Mgt.";
                        SelectedSystemId: Guid;
                        SelectedKey: Text[250];
                        SelectedDisplayValue: Text[250];
                    begin
                        if Rec."Value Type" <> Rec."Value Type"::Reference then
                            exit(false);

                        ProductConfig.Get(Rec."Configuration No.");
                        ProductParameter.Get(Rec."Parameter Code");
                        FamilyParameter.Get(ProductConfig."Family Code", Rec."Parameter Code");

                        if not ReferenceParameterMgt.LookupValue(
                            ProductConfig,
                            FamilyParameter,
                            ProductParameter."Reference Type",
                            Rec."Reference SystemId",
                            SelectedSystemId,
                            SelectedKey,
                            SelectedDisplayValue)
                        then
                            exit(false);

                        Rec.SetReferenceValue(SelectedSystemId, SelectedKey, SelectedDisplayValue);
                        Rec.Modify(true);
                        Text := SelectedDisplayValue;
                        CurrPage.Update(false);
                        exit(true);
                    end;
                }

                field("Display Value"; Rec."Display Value")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Відображуване значення';
                    Editable = false;
                    ToolTip = 'Визначає сформоване значення параметра, яке використовується у назві та інших системних представленнях.';
                }
            }
        }
    }

    procedure RefreshPart()
    begin
        CurrPage.Update(false);
    end;
}