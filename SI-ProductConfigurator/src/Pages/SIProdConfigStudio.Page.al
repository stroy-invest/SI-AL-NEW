page 53013 "SI Prod. Config. Studio"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Студія конфігурації продуктів';

    layout
    {
        area(Content)
        {
            group(FamilyContext)
            {
                Caption = 'Модель сімейства';

                part(Families; "SI Prod. Families Part")
                {
                    ApplicationArea = All;
                    Caption = 'Сімейства продуктів';
                }

                part(FamilyParameters; "SI Family Params Part")
                {
                    ApplicationArea = All;
                    Caption = 'Параметри сімейства';

                    Provider = Families;

                    SubPageLink =
                        "Family Code" = field(Code);
                }
            }

            group(ParameterValueContext)
            {
                Caption = 'Допустимі значення параметра';

                part(ParameterValues; "SI Param. Values Part")
                {
                    ApplicationArea = All;
                    Caption = 'Допустимі значення';

                    Provider = FamilyParameters;

                    SubPageLink =
                        "Parameter Code" = field("Parameter Code");
                }
            }

            group(ConfigurationContext)
            {
                Caption = 'Конфігурації продукту';

                part(Configurations; "SI Product Configs Part")
                {
                    ApplicationArea = All;
                    Caption = 'Конфігурації';

                    Provider = Families;

                    SubPageLink =
                        "Family Code" = field(Code);
                }

                part(ConfigurationValues; "SI Prod. Config. Values")
                {
                    ApplicationArea = All;
                    Caption = 'Значення конфігурації';

                    Provider = Configurations;

                    SubPageLink =
                        "Configuration No." = field("No.");

                    UpdatePropagation = Both;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RebuildPresentation)
            {
                ApplicationArea = All;
                Caption = 'Оновити представлення';
                Image = Refresh;
                ToolTip = 'Формує назву, коротку назву, Composite Key, hash і пошукове представлення поточної конфігурації.';

                trigger OnAction()
                var
                    ProductConfigMgt: Codeunit "SI Product Config. Mgt.";
                    ConfigurationNo: Code[20];
                begin
                    ConfigurationNo :=
                        CurrPage.Configurations.Page.GetCurrentConfigurationNo();

                    if ConfigurationNo = '' then
                        Error(NoConfigurationSelectedErr);

                    ProductConfigMgt.RebuildConfiguration(
                        ConfigurationNo);

                    CurrPage.Configurations.Page.RefreshPart();
                    CurrPage.ConfigurationValues.Page.RefreshPart();
                    //CurrPage.ConfigurationValues.Page.Update(false);

                    Message(
                        PresentationUpdatedMsg,
                        ConfigurationNo);
                end;
            }

            action(ValidateConfiguration)
            {
                ApplicationArea = All;
                Caption = 'Перевірити конфігурацію';
                Image = Check;
                ToolTip = 'Перевіряє обов’язкові параметри, коректність значень і відсутність дубля конфігурації.';

                trigger OnAction()
                var
                    ProductConfigMgt: Codeunit "SI Product Config. Mgt.";
                    ProductConfig: Record "SI Product Config.";
                    ConfigurationNo: Code[20];
                    ValidationSucceeded: Boolean;
                begin
                    ConfigurationNo :=
                        CurrPage.Configurations.Page.GetCurrentConfigurationNo();

                    if ConfigurationNo = '' then
                        Error(NoConfigurationSelectedErr);

                    ValidationSucceeded :=
                        ProductConfigMgt.ValidateConfiguration(
                            ConfigurationNo);

                    CurrPage.Configurations.Page.RefreshPart();
                    CurrPage.ConfigurationValues.Page.RefreshPart();
                    //CurrPage.ConfigurationValues.Page.Update(false);

                    ProductConfig.Get(ConfigurationNo);

                    if ValidationSucceeded then
                        Message(
                            ValidationSucceededMsg,
                            ConfigurationNo)
                    else
                        Message(
                            ValidationFailedMsg,
                            ConfigurationNo,
                            ProductConfig."Validation Message");
                end;
            }
        }

        area(Promoted)
        {
            actionref(
                RebuildPresentationPromoted;
            RebuildPresentation)
            {
            }

            actionref(
                ValidateConfigurationPromoted;
            ValidateConfiguration)
            {
            }
        }
    }

    var
        NoConfigurationSelectedErr: Label
            'Спочатку виберіть конфігурацію продукту.';

        PresentationUpdatedMsg: Label
            'Системні представлення конфігурації %1 оновлено.';

        ValidationSucceededMsg: Label
            'Конфігурація %1 успішно пройшла перевірку.';

        ValidationFailedMsg: Label
            'Конфігурація %1 не пройшла перевірку.\Причина: %2';
}