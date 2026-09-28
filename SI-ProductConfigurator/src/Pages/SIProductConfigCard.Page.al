page 53007 "SI Product Config. Card"
{
    PageType = Card;
    SourceTable = "SI Product Config.";
    ApplicationArea = All;
    Caption = 'Конфігурація продукту';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає номер конфігурації продукту.';
                }

                field("Family Code"; Rec."Family Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає сімейство продукту.';
                }

                field("Base Item No."; Rec."Base Item No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає наявний базовий товар Business Central, для якого конфігурація описує варіант.';
                }

                field("Include Base Name"; Rec."Include Base Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи потрібно додати перед назвою, сформованою з параметрів, назву категорії товару або назву базового товару.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає поточний статус конфігурації.';
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає, чи заборонено використання конфігурації.';
                }
            }

            group(Presentation)
            {
                Caption = 'Системні представлення';

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Визначає сформовану назву продукту.';
                }

                field("Short Description"; Rec."Short Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає сформовану коротку назву продукту.';
                }

                field("Composite Key"; Rec."Composite Key")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Визначає нормалізований семантичний ключ конфігурації.';
                }

                field("Composite Key Hash"; Rec."Composite Key Hash")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає hash нормалізованого Composite Key.';
                }

                field("Search Text"; Rec."Search Text")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Визначає сформоване пошукове представлення продукту.';
                }
            }

            part(Values; "SI Prod. Config. Values")
            {
                ApplicationArea = All;
                Caption = 'Параметри конфігурації';
                SubPageLink =
                    "Configuration No." = field("No.");
                UpdatePropagation = Both;
            }

            group(Approval)
            {
                Caption = 'Погодження';

                field("Validation Message"; Rec."Validation Message")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Визначає результат останньої системної перевірки.';
                }

                field("Approved By"; Rec."Approved By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає користувача, який затвердив конфігурацію.';
                }

                field("Approved At"; Rec."Approved At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Визначає дату й час затвердження конфігурації.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Maintenance)
            {
                Caption = 'Обслуговування';

                action(SyncMissingParameters)
                {
                    ApplicationArea = All;
                    Caption = 'Синхронізувати параметри';
                    ToolTip = 'Додає до спроєктованої конфігурації активні параметри сімейства, яких у ній ще немає. Існуючі значення, товар, варіант та ERP-проєкція не змінюються.';
                    Image = Refresh;
                    Enabled = SyncParametersAllowed;

                    trigger OnAction()
                    var
                        ConfigurationEngine: Codeunit "SI Configuration Engine";
                        AddedCount: Integer;
                    begin
                        if not Confirm(SyncParametersQst, false, Rec."No.") then
                            exit;

                        AddedCount := ConfigurationEngine.SyncMissingParameters(Rec."No.");
                        CurrPage.Values.Page.RefreshPart();
                        CurrPage.Update(false);

                        if AddedCount = 0 then
                            Message(NoParametersToSyncMsg)
                        else
                            Message(ParametersSyncedMsg, AddedCount);
                    end;
                }

                action(FinalizeMaintenanceParameters)
                {
                    ApplicationArea = All;
                    Caption = 'Завершити редагування';
                    ToolTip = 'Фіксує параметри, додані синхронізацією, та повертає їх у захищений режим спроєктованої конфігурації.';
                    Image = Lock;
                    Enabled = SyncParametersAllowed;

                    trigger OnAction()
                    var
                        ConfigurationEngine: Codeunit "SI Configuration Engine";
                        FinalizedCount: Integer;
                    begin
                        if not Confirm(FinalizeParametersQst, false, Rec."No.") then
                            exit;

                        FinalizedCount := ConfigurationEngine.FinalizeMaintenanceParameters(Rec."No.");
                        CurrPage.Values.Page.RefreshPart();
                        CurrPage.Update(false);

                        if FinalizedCount = 0 then
                            Message(NoParametersToFinalizeMsg)
                        else
                            Message(ParametersFinalizedMsg, FinalizedCount);
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
                        CurrPage.Update(false);
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
                        if ERPProjectionMgt.DeleteProjection(Rec."No.") then
                            CurrPage.Close()
                        else begin
                            UpdatePageState();
                            CurrPage.Update(false);
                        end;
                    end;
                }

                action(ViewERPProjection)
                {
                    ApplicationArea = All;
                    Caption = 'Перегляд ERP-проєкції';
                    ToolTip = 'Формує та відкриває попередній перегляд ERP-проєкції для поточної конфігурації.';
                    Image = View;

                    trigger OnAction()
                    var
                        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
                    begin
                        ERPProjectionMgt.OpenPreview(Rec."No.");
                    end;
                }

                action(SyncDisplayNameFromERP)
                {
                    ApplicationArea = All;
                    Caption = 'Синхронізувати назву з ERP';
                    ToolTip = 'Оновлює лише відображувану назву матеріалізованої конфігурації за актуальною назвою пов’язаного товару або варіанта Business Central. Параметри, семантична ідентичність та ERP-проєкція не змінюються.';
                    Image = Refresh;
                    Enabled = SyncDisplayNameAllowed;

                    trigger OnAction()
                    var
                        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
                        ConfigProjection: Record "SI Config. ERP Projection";
                        Item: Record Item;
                        ItemVariant: Record "Item Variant";
                        NewDisplayName: Text;
                    begin
                        ConfigProjection.Get(Rec."No.");

                        if Rec."Base Item No." = '' then begin
                            Item.Get(ConfigProjection."Item No.");
                            NewDisplayName := Item.Description;
                        end else begin
                            ItemVariant.Get(ConfigProjection."Item No.", ConfigProjection."Variant Code");
                            NewDisplayName := ItemVariant.Description;
                        end;

                        if Rec.Description = NewDisplayName then begin
                            Message(DisplayNameAlreadySyncedMsg, Rec.Description);
                            exit;
                        end;

                        if not Confirm(SyncDisplayNameQst, false, Rec.Description, NewDisplayName) then
                            exit;

                        ERPProjectionMgt.SyncConfigurationDisplayNameFromERP(Rec."No.");
                        Rec.Get(Rec."No.");
                        CurrPage.Update(false);
                        Message(DisplayNameSyncedMsg, Rec.Description);
                    end;
                }

                action(MaterializeERPProjection)
                {
                    ApplicationArea = All;
                    Caption = 'Матеріалізувати ERP-проєкцію';
                    ToolTip = 'Повторно формує, перевіряє та матеріалізує ERP-проєкцію у стандартні товар і варіант Business Central.';
                    Image = Process;

                    trigger OnAction()
                    var
                        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
                    begin
                        ERPProjectionMgt.Materialize(Rec."No.");
                        CurrPage.Update(false);
                    end;
                }
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Процес';

                actionref(SyncMissingParameters_Promoted; SyncMissingParameters)
                {
                }

                actionref(CreateERPProjection_Promoted; CreateERPProjection)
                {
                }

                actionref(DeleteERPProjection_Promoted; DeleteERPProjection)
                {
                }

                actionref(ViewERPProjection_Promoted; ViewERPProjection)
                {
                }

                actionref(SyncDisplayNameFromERP_Promoted; SyncDisplayNameFromERP)
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

    trigger OnAfterGetCurrRecord()
    begin
        UpdatePageState();
    end;

    local procedure UpdatePageState()
    var
        ERPProjectionMgt: Codeunit "SI ERP Projection Mgt.";
    begin
        CreateProjectionAllowed :=
            (Rec."No." <> '') and
            (not ERPProjectionMgt.HasProjection(Rec."No."));

        DeleteProjectionAllowed :=
            (Rec."No." <> '') and
            ERPProjectionMgt.CanDeleteProjection(Rec."No.");

        SyncDisplayNameAllowed :=
            (Rec."No." <> '') and
            ERPProjectionMgt.HasMaterializedERPLinks(Rec."No.");

        SyncParametersAllowed :=
            (Rec."No." <> '') and
            (Rec.Status = Rec.Status::Projected) and
            (not Rec.Blocked);
    end;

    var
        CreateProjectionAllowed: Boolean;
        DeleteProjectionAllowed: Boolean;
        SyncDisplayNameAllowed: Boolean;
        SyncParametersAllowed: Boolean;
        SyncParametersQst: Label 'Синхронізувати відсутні параметри сімейства для конфігурації %1?\Існуючі параметри та ERP-проєкція не змінюватимуться.';
        ParametersSyncedMsg: Label 'Синхронізацію завершено. Додано параметрів: %1.';
        NoParametersToSyncMsg: Label 'У конфігурації вже є всі активні параметри сімейства для її типу ERP-проєкції.';
        FinalizeParametersQst: Label 'Завершити редагування параметрів конфігурації %1?\Параметри, додані синхронізацією, після цього знову стануть захищеними від змін.';
        ParametersFinalizedMsg: Label 'Редагування завершено. Зафіксовано параметрів: %1.';
        NoParametersToFinalizeMsg: Label 'У конфігурації немає параметрів, що очікують завершення редагування.';
        SyncDisplayNameQst: Label 'Поточна назва конфігурації:\%1\\Нова назва з ERP:\%2\\Синхронізувати лише відображувану назву конфігурації?';
        DisplayNameSyncedMsg: Label 'Відображувану назву конфігурації синхронізовано з ERP: %1';
        DisplayNameAlreadySyncedMsg: Label 'Назва конфігурації вже відповідає ERP: %1';
}
