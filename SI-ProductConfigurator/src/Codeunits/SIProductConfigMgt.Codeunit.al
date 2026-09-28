codeunit 53000 "SI Product Config. Mgt."
{
    procedure RebuildConfiguration(ConfigurationNo: Code[20])
    var
        ConfigurationEngine: Codeunit "SI Configuration Engine";
    begin
        ConfigurationEngine.RebuildConfiguration(ConfigurationNo);
    end;

    procedure ValidateConfiguration(ConfigurationNo: Code[20]): Boolean
    var
        ConfigurationEngine: Codeunit "SI Configuration Engine";
    begin
        exit(ConfigurationEngine.ValidateConfiguration(ConfigurationNo));
    end;

    procedure BuildDescription(ConfigurationNo: Code[20]): Text
    var
        NamingEngine: Codeunit "SI Naming Engine";
    begin
        exit(NamingEngine.BuildDescription(ConfigurationNo));
    end;

    procedure BuildShortDescription(ConfigurationNo: Code[20]): Text
    var
        NamingEngine: Codeunit "SI Naming Engine";
    begin
        exit(NamingEngine.BuildShortDescription(ConfigurationNo));
    end;

    procedure BuildCompositeKey(ConfigurationNo: Code[20]): Text
    var
        NamingEngine: Codeunit "SI Naming Engine";
    begin
        exit(NamingEngine.BuildCompositeKey(ConfigurationNo));
    end;

    procedure BuildSearchText(
        ConfigurationNo: Code[20];
        DescriptionText: Text): Text
    var
        NamingEngine: Codeunit "SI Naming Engine";
    begin
        exit(
            NamingEngine.BuildSearchText(
                ConfigurationNo,
                DescriptionText));
    end;

    procedure CheckDuplicate(ConfigurationNo: Code[20])
    var
        ValidationEngine: Codeunit "SI Validation Engine";
    begin
        ValidationEngine.CheckDuplicate(ConfigurationNo);
    end;

    procedure CreateProductFamily(
        FamilyCode: Code[30];
        Description: Text[100];
        DescriptionEN: Text[100];
        NamePrefix: Text[50];
        SupportsRecipes: Boolean;
        SortOrder: Integer): Code[30]
    var
        ConfigurationEngine: Codeunit "SI Configuration Engine";
    begin
        exit(
            ConfigurationEngine.CreateProductFamily(
                FamilyCode,
                Description,
                DescriptionEN,
                NamePrefix,
                SupportsRecipes,
                SortOrder));
    end;

    procedure CreateProductFamilyInCategory(
        FamilyCode: Code[30];
        Description: Text[100];
        DescriptionEN: Text[100];
        NamePrefix: Text[50];
        SupportsRecipes: Boolean;
        SortOrder: Integer;
        ItemTemplateCode: Code[20];
        ItemCategoryCode: Code[20]): Code[30]
    var
        ConfigurationEngine: Codeunit "SI Configuration Engine";
    begin
        exit(
            ConfigurationEngine.CreateProductFamilyInCategory(
                FamilyCode,
                Description,
                DescriptionEN,
                NamePrefix,
                SupportsRecipes,
                SortOrder,
                ItemTemplateCode,
                ItemCategoryCode));
    end;

    procedure CreateProductFamilyWithChildCategory(
        FamilyCode: Code[30];
        Description: Text[100];
        DescriptionEN: Text[100];
        NamePrefix: Text[50];
        SupportsRecipes: Boolean;
        SortOrder: Integer;
        ItemTemplateCode: Code[20];
        ParentCategoryCode: Code[20];
        NewCategoryCode: Code[20];
        NewCategoryDescription: Text[100]): Code[30]
    var
        ConfigurationEngine: Codeunit "SI Configuration Engine";
    begin
        exit(
            ConfigurationEngine.CreateProductFamilyWithChildCategory(
                FamilyCode,
                Description,
                DescriptionEN,
                NamePrefix,
                SupportsRecipes,
                SortOrder,
                ItemTemplateCode,
                ParentCategoryCode,
                NewCategoryCode,
                NewCategoryDescription));
    end;

    procedure CreateParameterForFamily(
        FamilyCode: Code[30];
        ParameterBuffer: Record "SI Product Parameter";
        FamilyParameterBuffer: Record "SI Family Parameter"): Code[30]
    var
        ConfigurationEngine: Codeunit "SI Configuration Engine";
    begin
        exit(
            ConfigurationEngine.CreateParameterForFamily(
                FamilyCode,
                ParameterBuffer,
                FamilyParameterBuffer));
    end;

    procedure AddExistingParameterToFamily(
        FamilyCode: Code[30];
        ParameterCode: Code[30];
        FamilyParameterBuffer: Record "SI Family Parameter"): Code[30]
    var
        ConfigurationEngine: Codeunit "SI Configuration Engine";
    begin
        exit(
            ConfigurationEngine.AddExistingParameterToFamily(
                FamilyCode,
                ParameterCode,
                FamilyParameterBuffer));
    end;

    procedure PromptAssignExistingItemTemplate(
        FamilyCode: Code[30];
        var ItemTemplateCode: Code[20]): Boolean
    var
        ConfigurationEngine: Codeunit "SI Configuration Engine";
    begin
        exit(
            ConfigurationEngine.PromptAssignExistingItemTemplate(
                FamilyCode,
                ItemTemplateCode));
    end;

    procedure EnsureFamilyItemTemplate(FamilyCode: Code[30]): Boolean
    var
        ConfigurationEngine: Codeunit "SI Configuration Engine";
    begin
        exit(ConfigurationEngine.EnsureFamilyItemTemplate(FamilyCode));
    end;

    procedure CreateDraftConfiguration(FamilyCode: Code[30]): Code[20]
    var
        ConfigurationEngine: Codeunit "SI Configuration Engine";
    begin
        exit(ConfigurationEngine.CreateDraftConfiguration(FamilyCode));
    end;

    procedure CancelDraftConfiguration(ConfigurationNo: Code[20])
    var
        ConfigurationEngine: Codeunit "SI Configuration Engine";
    begin
        ConfigurationEngine.CancelDraftConfiguration(ConfigurationNo);
    end;

    procedure ReinitializeConfigValues(ConfigurationNo: Code[20])
    var
        ConfigurationEngine: Codeunit "SI Configuration Engine";
    begin
        ConfigurationEngine.ReinitializeConfigurationValues(ConfigurationNo);
    end;

}
