codeunit 53016 "SI Family Template Mgt."
{
    procedure ApplyTemplate(FamilyCode: Code[30])
    var
        ProductFamily: Record "SI Product Family";
        FamilyTemplate: Record "SI Product Family Template";
        TemplateParameter: Record "SI Family Template Parameter";
        FamilyParameter: Record "SI Family Parameter";
        AddedCount: Integer;
        TemplateGroup: Record "SI Template Req. Group";
        FamilyGroup: Record "SI Family Req. Group";
    begin
        ProductFamily.Get(FamilyCode);
        ProductFamily.TestField("Family Template Code");

        FamilyTemplate.Get(ProductFamily."Family Template Code");
        if FamilyTemplate.Blocked then
            Error(BlockedTemplateErr, FamilyTemplate.Code);

        TemplateGroup.SetRange("Template Code", FamilyTemplate.Code);
        if TemplateGroup.FindSet() then
            repeat
                if not FamilyGroup.Get(FamilyCode, TemplateGroup.Code) then begin
                    FamilyGroup.Init();
                    FamilyGroup."Family Code" := FamilyCode;
                    FamilyGroup.Code := TemplateGroup.Code;
                    FamilyGroup.Description := TemplateGroup.Description;
                    FamilyGroup."Min Filled" := TemplateGroup."Min Filled";
                    FamilyGroup."Max Filled" := TemplateGroup."Max Filled";
                    FamilyGroup."ERP Projection Role" := TemplateGroup."ERP Projection Role";
                    FamilyGroup.Insert(true);
                end;
            until TemplateGroup.Next() = 0;

        TemplateParameter.SetRange("Template Code", FamilyTemplate.Code);
        if TemplateParameter.FindSet() then
            repeat
                if not FamilyParameter.Get(ProductFamily.Code, TemplateParameter."Parameter Code") then begin
                    FamilyParameter.Init();
                    FamilyParameter.Validate("Family Code", ProductFamily.Code);
                    FamilyParameter.Validate("Parameter Code", TemplateParameter."Parameter Code");
                    FamilyParameter."Parameter Order" := TemplateParameter."Parameter Order";
                    FamilyParameter.Mandatory := TemplateParameter.Mandatory;
                    FamilyParameter."ERP Projection Role" := TemplateParameter."ERP Projection Role";
                    FamilyParameter."Include in Description" := TemplateParameter."Include in Description";
                    FamilyParameter."Description Order" := TemplateParameter."Description Order";
                    FamilyParameter."Include in Search" := TemplateParameter."Include in Search";
                    FamilyParameter."Recipe Relevant" := TemplateParameter."Recipe Relevant";
                    FamilyParameter."Default Value Code" := TemplateParameter."Default Value Code";
                    FamilyParameter.Blocked := TemplateParameter.Blocked;
                    FamilyParameter.Validate("Requirement Group Code", TemplateParameter."Requirement Group Code");
                    FamilyParameter.Insert(true);
                    AddedCount += 1;
                end;
            until TemplateParameter.Next() = 0;

        Message(ApplyCompletedMsg, FamilyTemplate.Code, ProductFamily.Code, AddedCount);
    end;

    var
        BlockedTemplateErr: Label 'Шаблон сімейства %1 заблоковано й не може бути застосований.';
        ApplyCompletedMsg: Label 'Шаблон %1 застосовано до сімейства %2. Додано параметрів: %3. Наявні параметри не змінювалися.';
}
