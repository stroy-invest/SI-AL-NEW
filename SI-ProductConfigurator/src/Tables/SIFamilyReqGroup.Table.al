table 53015 "SI Family Req. Group"
{
    Caption = 'Група обов’язковості параметрів';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Family Code"; Code[30]) { Caption = 'Код сімейства або шаблону'; TableRelation = "SI Product Family".Code; NotBlank = true; }
        field(2; Code; Code[30]) { Caption = 'Код групи'; NotBlank = true; }
        field(3; Description; Text[100]) { Caption = 'Назва'; }
        field(10; "Min Filled"; Integer) { Caption = 'Мінімум заповнених'; MinValue = 0; InitValue = 1; }
        field(20; "Max Filled"; Integer) { Caption = 'Максимум заповнених'; MinValue = 0; InitValue = 1; }
        field(30; "ERP Projection Role"; Enum "SI ERP Projection Role") { Caption = 'Роль в ERP-проєкції'; InitValue = "Item Identity"; }
    }
    keys { key(PK; "Family Code", Code) { Clustered = true; } }
    trigger OnInsert()
    begin
        TestField("Family Code");
        TestField(Code);
        CheckSetup();
    end;
    trigger OnModify()
    begin
        CheckSetup();
    end;
    trigger OnDelete()
    begin
        CheckUnused();
    end;
    trigger OnRename()
    begin
        Error('Код групи змінювати не можна.');
    end;
    local procedure CheckUnused()
    var
        Member: Record "SI Family Parameter";
    begin
        Member.SetRange("Family Code", "Family Code");
        Member.SetRange("Requirement Group Code", Code);
        if not Member.IsEmpty() then
            Error('Спочатку вилучіть параметри з групи %1.', Code);
    end;
    procedure CheckSetup()
    begin
        if ("Min Filled" < 0) or ("Max Filled" < "Min Filled") then
            Error('Для групи %1 мінімум має бути невід’ємним і не перевищувати максимум.', Code);
        if not ("ERP Projection Role" in ["ERP Projection Role"::"Item Identity", "ERP Projection Role"::"Variant Identity"]) then
            Error('Для групи %1 виберіть ідентичність товару або варіанта.', Code);
    end;
}
