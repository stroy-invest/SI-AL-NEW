page 53006 "SI Product Configs."
{
    PageType = Card;
    SourceTable = "SI Product Config.";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Конфігурації продуктів';
    DataCaptionExpression = '';
    Editable = false;

    layout
    {
        area(Content)
        {
            usercontrol(ConfigurationTree; "SI Product Config Tree")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    TreeReady := true;
                    RenderTree();
                end;

                trigger NodeSelected(NodeType: Text; ConfigurationNo: Text)
                begin
                    SelectedNodeType := CopyStr(NodeType, 1, MaxStrLen(SelectedNodeType));
                    SelectedConfigurationNo := CopyStr(ConfigurationNo, 1, MaxStrLen(SelectedConfigurationNo));
                    if SelectedConfigurationNo <> '' then
                        Rec.Get(SelectedConfigurationNo);
                    UpdatePageState();
                    CurrPage.Update(false);
                end;

                trigger NodeOpen(ConfigurationNo: Text)
                var
                    ProductConfig: Record "SI Product Config.";
                begin
                    if ConfigurationNo = '' then
                        exit;
                    ProductConfig.Get(ConfigurationNo);
                    Page.Run(Page::"SI Product Config. Card", ProductConfig);
                end;


                trigger NodeCommand(CommandName: Text; ConfigurationNo: Text)
                var
                    ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
                begin
                    if ConfigurationNo = '' then
                        exit;

                    case LowerCase(CommandName) of
                        'view':
                            ERPProjectionMgt.OpenPreview(CopyStr(ConfigurationNo, 1, 20));
                        'delete':
                            begin
                                if not ERPProjectionMgt.CanDeleteProjection(CopyStr(ConfigurationNo, 1, 20)) then
                                    exit;

                                if ERPProjectionMgt.DeleteProjection(CopyStr(ConfigurationNo, 1, 20)) then begin
                                    Clear(SelectedConfigurationNo);
                                    Clear(SelectedNodeType);
                                    Clear(Rec);
                                    UpdatePageState();
                                    CurrPage.Update(false);
                                    RenderTree();
                                end;
                            end;
                    end;
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(View)
            {
                Caption = 'Подання';

                action(OpenListView)
                {
                    ApplicationArea = All;
                    Caption = 'Список';
                    ToolTip = 'Відкриває конфігурації продуктів у звичайному списковому поданні.';
                    Image = List;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"SI Product Configs List");
                    end;
                }
            }

            group(Tree)
            {
                Caption = 'Дерево';

                action(ExpandAll)
                {
                    ApplicationArea = All;
                    Caption = 'Розгорнути все';
                    ToolTip = 'Розгортає всі рівні ієрархії конфігурацій продуктів.';
                    Image = ExpandAll;

                    trigger OnAction()
                    begin
                        if TreeReady then
                            CurrPage.ConfigurationTree.ExpandAll();
                    end;
                }

                action(CollapseAll)
                {
                    ApplicationArea = All;
                    Caption = 'Згорнути все';
                    ToolTip = 'Згортає всі рівні ієрархії конфігурацій продуктів.';
                    Image = CollapseAll;

                    trigger OnAction()
                    begin
                        if TreeReady then
                            CurrPage.ConfigurationTree.CollapseAll();
                    end;
                }
            }

            group(ERP)
            {
                Caption = 'ERP';

                action(CreateERPProjection)
                {
                    ApplicationArea = All;
                    Caption = 'Створити проєкцію';
                    ToolTip = 'Формує, перевіряє та зберігає ERP-проєкцію для поточної конфігурації без створення товару або варіанта.';
                    Image = NewDocument;
                    Enabled = CreateProjectionAllowed;

                    trigger OnAction()
                    var
                        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
                    begin
                        ERPProjectionMgt.CreateProjection(Rec."No.");
                        UpdatePageState();
                        RenderTree();
                    end;
                }

                action(DeleteERPProjection)
                {
                    ApplicationArea = All;
                    Caption = 'Видалити проєкцію';
                    ToolTip = 'Примусово видаляє нематеріалізовану ERP-проєкцію поточної конфігурації. Матеріалізовані проєкції видаляти заборонено.';
                    Image = Delete;
                    Enabled = DeleteProjectionAllowed;
                    AccessByPermission = tabledata "SI Config. ERP Projection" = D;

                    trigger OnAction()
                    var
                        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
                    begin
                        if ERPProjectionMgt.DeleteProjection(Rec."No.") then begin
                            Clear(SelectedConfigurationNo);
                            Clear(SelectedNodeType);
                            Clear(Rec);
                            UpdatePageState();
                            CurrPage.Update(false);
                            RenderTree();
                        end;
                    end;
                }

                action(ViewERPProjection)
                {
                    ApplicationArea = All;
                    Caption = 'Перегляд ERP-проєкції';
                    ToolTip = 'Формує та відкриває попередній перегляд ERP-проєкції для поточної конфігурації.';
                    Image = View;
                    Enabled = ConfigurationSelected;

                    trigger OnAction()
                    var
                        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
                    begin
                        ERPProjectionMgt.OpenPreview(Rec."No.");
                    end;
                }

                action(MaterializeERPProjection)
                {
                    ApplicationArea = All;
                    Caption = 'Матеріалізувати ERP-проєкцію';
                    ToolTip = 'Повторно формує, перевіряє та матеріалізує ERP-проєкцію у стандартні товар і варіант Business Central.';
                    Image = Process;
                    Enabled = ConfigurationSelected;

                    trigger OnAction()
                    var
                        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
                    begin
                        ERPProjectionMgt.Materialize(Rec."No.");
                        RenderTree();
                    end;
                }
            }
        }

        area(Promoted)
        {
            group(View_Process)
            {
                Caption = 'Подання';

                actionref(OpenListView_Promoted; OpenListView)
                {
                }
            }

            group(Tree_Process)
            {
                Caption = 'Дерево';

                actionref(ExpandAll_Promoted; ExpandAll)
                {
                }

                actionref(CollapseAll_Promoted; CollapseAll)
                {
                }
            }

            group(Category_Process)
            {
                Caption = 'Процес';

                actionref(CreateERPProjection_Promoted; CreateERPProjection)
                {
                }

                actionref(DeleteERPProjection_Promoted; DeleteERPProjection)
                {
                }

                actionref(ViewERPProjection_Promoted; ViewERPProjection)
                {
                }

                actionref(MaterializeERPProjection_Promoted; MaterializeERPProjection)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdatePageState();
    end;

    local procedure RenderTree()
    begin
        if TreeReady then
            CurrPage.ConfigurationTree.RenderTree(GetTreeJson());
    end;

    procedure RefreshConfigurationTree()
    begin
        // Public refresh hook for page extensions/actions that create or edit
        // configurations outside the tree page (for example, the wizard).
        UpdatePageState();
        CurrPage.Update(false);
        RenderTree();
    end;

    local procedure GetTreeJson(): Text
    var
        ProductFamily: Record "SI Product Family";
        JsonText: Text;
        IsFirst: Boolean;
    begin
        JsonText := '[';
        IsFirst := true;
        ProductFamily.SetCurrentKey(Code);
        if ProductFamily.FindSet() then
            repeat
                if HasFamilyConfigurations(ProductFamily.Code) then begin
                    if not IsFirst then
                        JsonText += ',';
                    JsonText += BuildFamilyNodeJson(ProductFamily);
                    IsFirst := false;
                end;
            until ProductFamily.Next() = 0;
        JsonText += ']';
        exit(JsonText);
    end;

    local procedure HasFamilyConfigurations(FamilyCode: Code[30]): Boolean
    var
        ProductConfig: Record "SI Product Config.";
    begin
        ProductConfig.SetRange("Family Code", FamilyCode);
        exit(not ProductConfig.IsEmpty());
    end;

    local procedure BuildFamilyNodeJson(ProductFamily: Record "SI Product Family"): Text
    var
        NodeName: Text;
    begin
        NodeName := ProductFamily.Description;
        if NodeName = '' then
            NodeName := ProductFamily.Code;
        exit('{"type":"family","configNo":"","name":"' + JsonEscape(ProductFamily.Code + ' — ' + NodeName) + '","children":' + BuildItemConfigurationsJson(ProductFamily.Code) + '}');
    end;

    local procedure BuildItemConfigurationsJson(FamilyCode: Code[30]): Text
    var
        ProductConfig: Record "SI Product Config.";
        JsonText: Text;
        IsFirst: Boolean;
    begin
        JsonText := '[';
        IsFirst := true;
        ProductConfig.SetCurrentKey("Family Code", Status, "No.");
        ProductConfig.SetRange("Family Code", FamilyCode);
        ProductConfig.SetRange("Base Item No.", '');
        if ProductConfig.FindSet() then
            repeat
                if not IsFirst then
                    JsonText += ',';
                JsonText += BuildConfigurationNodeJson(ProductConfig, 'item', BuildVariantConfigurationsJson(ProductConfig));
                IsFirst := false;
            until ProductConfig.Next() = 0;
        JsonText += ']';
        exit(JsonText);
    end;

    local procedure BuildVariantConfigurationsJson(ItemConfig: Record "SI Product Config."): Text
    var
        VariantConfig: Record "SI Product Config.";
        ConfigProjection: Record "SI Config. ERP Projection";
        ItemNo: Code[20];
        JsonText: Text;
        IsFirst: Boolean;
    begin
        ItemNo := GetConfigurationItemNo(ItemConfig."No.");
        JsonText := '[';
        IsFirst := true;
        if ItemNo <> '' then begin
            VariantConfig.SetCurrentKey("Family Code", Status, "No.");
            VariantConfig.SetRange("Family Code", ItemConfig."Family Code");
            VariantConfig.SetRange("Base Item No.", ItemNo);
            if VariantConfig.FindSet() then
                repeat
                    if not IsFirst then
                        JsonText += ',';
                    JsonText += BuildConfigurationNodeJson(VariantConfig, 'variant', '[]');
                    IsFirst := false;
                until VariantConfig.Next() = 0;
        end;
        JsonText += ']';
        exit(JsonText);
    end;

    local procedure GetConfigurationItemNo(ConfigurationNo: Code[20]): Code[20]
    var
        ConfigProjection: Record "SI Config. ERP Projection";
    begin
        if ConfigProjection.Get(ConfigurationNo) then
            exit(ConfigProjection."Item No.");
        exit('');
    end;

    local procedure BuildConfigurationNodeJson(ProductConfig: Record "SI Product Config."; NodeType: Text; ChildrenJson: Text): Text
    var
        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
    begin
        exit(
            '{"type":"' + NodeType +
            '","configNo":"' + JsonEscape(ProductConfig."No.") +
            '","name":"' + JsonEscape(ProductConfig.Description) +
            '","status":"' + JsonEscape(Format(ProductConfig.Status)) +
            '","readinessStatus":"' + JsonEscape(GetProjectionReadinessStatus(ProductConfig."No.")) +
            '","canDeleteProjection":' + BooleanToJson(ERPProjectionMgt.CanDeleteProjection(ProductConfig."No.")) +
            ',"approvedBy":"' + JsonEscape(ProductConfig."Approved By") +
            '","approvedAt":"' + JsonEscape(FormatDateTime(ProductConfig."Approved At")) +
            '","createdAt":"' + JsonEscape(FormatDateTime(ProductConfig.SystemCreatedAt)) +
            '","modifiedAt":"' + JsonEscape(FormatDateTime(ProductConfig.SystemModifiedAt)) +
            '","children":' + ChildrenJson + '}');
    end;

    local procedure GetProjectionReadinessStatus(ConfigurationNo: Code[20]): Text
    var
        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
    begin
        exit(ERPProjectionMgt.GetProjectionLifecycleStatus(ConfigurationNo));
    end;

    local procedure BooleanToJson(Value: Boolean): Text
    begin
        if Value then
            exit('true');
        exit('false');
    end;

    local procedure FormatDateTime(Value: DateTime): Text
    begin
        if Value = 0DT then
            exit('');
        exit(Format(Value, 0, '<Day,2>.<Month,2>.<Year4> <Hours24,2>:<Minutes,2>'));
    end;

    local procedure JsonEscape(Value: Text): Text
    begin
        Value := Value.Replace('\', '\\');
        Value := Value.Replace('"', '\"');
        Value := Value.Replace('/', '\/');
        Value := Value.Replace('<', '\u003C');
        Value := Value.Replace('>', '\u003E');
        Value := Value.Replace('&', '\u0026');
        exit(Value);
    end;

    local procedure UpdatePageState()
    var
        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
    begin
        ConfigurationSelected := SelectedConfigurationNo <> '';

        CreateProjectionAllowed :=
            (SelectedConfigurationNo <> '') and
            (not ERPProjectionMgt.HasProjection(SelectedConfigurationNo));

        DeleteProjectionAllowed :=
            (SelectedConfigurationNo <> '') and
            ERPProjectionMgt.CanDeleteProjection(SelectedConfigurationNo);
    end;

    var
        CreateProjectionAllowed: Boolean;
        DeleteProjectionAllowed: Boolean;
        ConfigurationSelected: Boolean;
        TreeReady: Boolean;
        SelectedConfigurationNo: Code[20];
        SelectedNodeType: Text[20];
}
