namespace STROYINVEST.ConcreteRecipeEngine;

using Microsoft.Manufacturing.ProductionBOM;

table 62021 "SI Concrete Recipe Revision"
{
    Caption = 'Ревізія рецептури бетону';
    DataClassification = CustomerContent;
    DataCaptionFields = "Recipe No.", "Revision No.";

    fields
    {
        field(1; "Recipe No."; Code[50])
        {
            Caption = 'Код рецептури';
            TableRelation = "SI Concrete Recipe"."Recipe No.";
            ToolTip = 'Вказує логічну рецептуру.';
        }
        field(2; "Revision No."; Integer)
        {
            Caption = '№ ревізії';
            MinValue = 1;
            ToolTip = 'Вказує послідовний номер ревізії, присвоєний системою.';
        }
        field(10; Status; Enum "SI Recipe Revision Status")
        {
            Caption = 'Статус сертифікації';
            ToolTip = 'Вказує, чи є ревізія рецептури чернеткою, чи її сертифіковано.';
        }
        field(14; "Administrative Status"; Enum "SI Recipe Admin Status")
        {
            Caption = 'Адміністративний статус';
            ToolTip = 'Вказує, чи є ця сертифікована ревізія адміністративно активною або неактивною. Цей статус не залежить від сертифікації та дат валідності.';
        }
        field(11; "Validity Type"; Enum "SI Recipe Validity Type")
        {
            Caption = 'Тип валідності';
            ToolTip = 'Вказує, чи є ця ревізія постійною або тимчасовою.';

            trigger OnValidate()
            begin
                if "Validity Type" = "Validity Type"::Permanent then
                    SetPermanentEndDate()
                else
                    "Valid To" := 0D;
            end;
        }
        field(12; "Valid From"; Date)
        {
            Caption = 'Чинна з';
            ToolTip = 'Вказує першу дату валідності цієї ревізії.';

            trigger OnValidate()
            begin
                if ("Valid From" <> 0D) and ("Valid To" <> 0D) and ("Valid To" < "Valid From") then
                    Error(InvalidValidityRangeErr);
            end;
        }
        field(13; "Valid To"; Date)
        {
            Caption = 'Чинна до';
            ToolTip = 'Вказує останню дату валідності цієї ревізії.';

            trigger OnValidate()
            begin
                if ("Validity Type" = "Validity Type"::Permanent) and ("Valid To" <> 0D) then
                    Error(PermanentValidToManagedErr);

                if ("Valid From" <> 0D) and ("Valid To" <> 0D) and ("Valid To" < "Valid From") then
                    Error(InvalidValidityRangeErr);
            end;
        }
        field(20; "Source Revision No."; Integer)
        {
            Caption = '№ вихідної ревізії';
            ToolTip = 'Вказує ревізію, з якої було клоновано цю ревізію.';
        }
        field(30; "Production BOM Version Code"; Code[20])
        {
            Caption = 'Код версії виробничої специфікації';
            ToolTip = 'Вказує стандартну версію виробничої специфікації Business Central, створену з цієї ревізії рецептури.';
        }
        field(31; "Projection Status"; Enum "SI Recipe Projection Status")
        {
            Caption = 'Статус проєкції';
            ToolTip = 'Вказує статус проєкції у стандартну виробничу специфікацію Business Central.';
        }
        field(32; "Projection Error"; Text[2048])
        {
            Caption = 'Помилка проєкції';
            ToolTip = 'Вказує останню помилку проєкції виробничої специфікації.';
        }
        field(40; "Certified At"; DateTime)
        {
            Caption = 'Сертифіковано о';
            Editable = false;
            ToolTip = 'Вказує дату й час сертифікації цієї ревізії.';
        }
        field(41; "Certified By"; Guid)
        {
            Caption = 'Сертифікував';
            Editable = false;
            ToolTip = 'Вказує ідентифікатор безпеки користувача, який сертифікував цю ревізію.';
        }
        field(42; "Closed At"; DateTime)
        {
            Caption = 'Деактивовано о';
            Editable = false;
            ToolTip = 'Вказує дату й час останньої деактивації цієї ревізії.';
        }
        field(43; "Closed By"; Guid)
        {
            Caption = 'Деактивував';
            Editable = false;
            ToolTip = 'Вказує ідентифікатор безпеки користувача, який востаннє деактивував цю ревізію.';
        }
    }

    keys
    {
        key(PK; "Recipe No.", "Revision No.")
        {
            Clustered = true;
        }
        key(RecipeStatus; "Recipe No.", Status)
        {
        }
        key(RecipeValidity; "Recipe No.", "Valid From", "Valid To")
        {
        }
        key(RecipeValidityTypeStatus; "Recipe No.", "Validity Type", Status)
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Recipe No.");
        if "Revision No." <= 0 then
            "Revision No." := GetNextRevisionNo();

        Status := Status::Draft;
        "Administrative Status" := "Administrative Status"::Active;
        "Projection Status" := "Projection Status"::"Not Projected";
        Clear("Projection Error");
        Clear("Certified At");
        Clear("Certified By");
        Clear("Closed At");
        Clear("Closed By");

        if "Validity Type" = "Validity Type"::Permanent then
            SetPermanentEndDate();
    end;

    trigger OnModify()
    begin
        if AllowLifecycleModify then
            exit;

        if xRec.Status <> xRec.Status::Draft then
            Error(ControlledRevisionModifyErr, "Recipe No.", "Revision No.");

        if Status <> Status::Draft then
            Error(StatusChangeThroughLifecycleErr);

        if "Administrative Status" <> xRec."Administrative Status" then
            Error(AdminStatusChangeThroughLifecycleErr);
    end;

    trigger OnDelete()
    var
        RecipeLine: Record "SI Concrete Recipe Line";
    begin
        if Status <> Status::Draft then
            Error(ControlledRevisionDeleteErr, "Recipe No.", "Revision No.");

        RecipeLine.SetRange("Recipe No.", "Recipe No.");
        RecipeLine.SetRange("Revision No.", "Revision No.");
        if not RecipeLine.IsEmpty() then
            RecipeLine.DeleteAll(true);
    end;

    local procedure GetNextRevisionNo(): Integer
    var
        RecipeRevision: Record "SI Concrete Recipe Revision";
    begin
        RecipeRevision.LockTable();
        RecipeRevision.SetRange("Recipe No.", "Recipe No.");
        if RecipeRevision.FindLast() then
            exit(RecipeRevision."Revision No." + 1);

        exit(1);
    end;

    procedure ValidateValidity()
    begin
        TestField("Valid From");

        if "Validity Type" = "Validity Type"::Temporary then
            TestField("Valid To")
        else begin
            SetPermanentEndDate();
            TestField("Valid To");
        end;

        if "Valid To" < "Valid From" then
            Error(InvalidValidityRangeErr);
    end;

    procedure SetPermanentEndDate()
    var
        RecipeSetup: Record "SI Concrete Recipe Setup";
    begin
        if RecipeSetup.Get('') and (RecipeSetup."Default Permanent End Date" <> 0D) then
            "Valid To" := RecipeSetup."Default Permanent End Date"
        else
            "Valid To" := DMY2Date(31, 12, 2999);
    end;

    procedure MarkCertified()
    begin
        if Status <> Status::Draft then
            Error(CertifyDraftOnlyErr, "Recipe No.", "Revision No.");

        AllowLifecycleModify := true;
        Status := Status::Certified;
        "Administrative Status" := "Administrative Status"::Active;
        "Certified At" := CurrentDateTime();
        "Certified By" := UserSecurityId();
        "Closed At" := 0DT;
        Clear("Closed By");
        Modify(true);
        AllowLifecycleModify := false;
    end;

    procedure Deactivate()
    begin
        if Status <> Status::Certified then
            Error(DeactivateCertifiedOnlyErr, "Recipe No.", "Revision No.");

        if "Administrative Status" = "Administrative Status"::Inactive then
            exit;

        AllowLifecycleModify := true;
        "Administrative Status" := "Administrative Status"::Inactive;
        "Closed At" := CurrentDateTime();
        "Closed By" := UserSecurityId();
        Modify(true);
        AllowLifecycleModify := false;
    end;

    procedure Activate()
    begin
        if Status <> Status::Certified then
            Error(ActivateCertifiedOnlyErr, "Recipe No.", "Revision No.");

        if "Administrative Status" = "Administrative Status"::Active then
            exit;

        AllowLifecycleModify := true;
        "Administrative Status" := "Administrative Status"::Active;
        "Closed At" := 0DT;
        Clear("Closed By");
        Modify(true);
        AllowLifecycleModify := false;
    end;

    procedure GetApplicability(TargetDate: Date): Enum "SI Recipe Applicability"
    begin
        if "Administrative Status" = "Administrative Status"::Inactive then
            exit("SI Recipe Applicability"::Inactive);

        if ("Valid From" <> 0D) and (TargetDate < "Valid From") then
            exit("SI Recipe Applicability"::Future);

        if ("Valid To" <> 0D) and (TargetDate > "Valid To") then
            exit("SI Recipe Applicability"::Expired);

        exit("SI Recipe Applicability"::Applicable);
    end;

    procedure IsApplicable(TargetDate: Date): Boolean
    begin
        if Status <> Status::Certified then
            exit(false);

        exit(GetApplicability(TargetDate) = "SI Recipe Applicability"::Applicable);
    end;

    procedure SetProjectionState(
        NewStatus: Enum "SI Recipe Projection Status";
        ProductionBOMVersionCode: Code[20];
        ProjectionError: Text)
    begin
        if Status = Status::Draft then
            Error(ProjectionDraftErr, "Recipe No.", "Revision No.");

        AllowLifecycleModify := true;
        "Projection Status" := NewStatus;
        "Production BOM Version Code" := ProductionBOMVersionCode;
        "Projection Error" := CopyStr(ProjectionError, 1, MaxStrLen("Projection Error"));
        Modify(true);
        AllowLifecycleModify := false;
    end;

    var
        AllowLifecycleModify: Boolean;
        ControlledRevisionModifyErr: Label 'Рецептура %1, ревізія %2, сертифікована або неактивна і не може редагуватися безпосередньо. Створіть нову чернеткову ревізію.';
        ControlledRevisionDeleteErr: Label 'Рецептура %1, ревізія %2, сертифікована або неактивна і не може бути видалена.';
        InvalidValidityRangeErr: Label 'Дата «Чинна до» не може бути ранішою за дату «Чинна з».';
        PermanentValidToManagedErr: Label 'Дата «Чинна до» для постійної ревізії визначається автоматично.';
        StatusChangeThroughLifecycleErr: Label 'Статус сертифікації можна змінювати лише через дії життєвого циклу.';
        AdminStatusChangeThroughLifecycleErr: Label 'Адміністративний статус можна змінювати лише через дії життєвого циклу.';
        CertifyDraftOnlyErr: Label 'Сертифікувати можна лише чернеткову ревізію. Рецептура %1, ревізія %2 не є чернеткою.';
        DeactivateCertifiedOnlyErr: Label 'Деактивувати можна лише сертифіковану ревізію. Рецептура %1, ревізія %2 не сертифікована.';
        ActivateCertifiedOnlyErr: Label 'Активувати можна лише сертифіковану ревізію. Рецептура %1, ревізія %2 не сертифікована.';
        ProjectionDraftErr: Label 'Статус проєкції не можна змінювати для чернеткової рецептури %1, ревізії %2.';
}
