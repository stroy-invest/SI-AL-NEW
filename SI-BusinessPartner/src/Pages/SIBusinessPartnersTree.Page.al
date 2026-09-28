page 54029 "SI Business Partners Tree"
{
    PageType = List;
    SourceTable = "SI BP Tree Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Контрагенти — дерево';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Tree)
            {
                IndentationColumn = Rec.Indentation;
                ShowAsTree = true;

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Контрагент';
                    ToolTip = 'Показує групу або назву контрагента.';
                    StyleExpr = Rec.Style;
                }

                field("Registration No."; Rec."Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'Реєстраційний номер';
                    ToolTip = 'Показує реєстраційний номер контрагента.';
                }

                field("Tax Registration No."; Rec."Tax Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'Податковий реєстраційний номер';
                    ToolTip = 'Показує податковий реєстраційний номер контрагента.';
                }

                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Код країни/регіону';
                    ToolTip = 'Показує код країни або регіону контрагента.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Статус';
                    ToolTip = 'Показує статус контрагента.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowList)
            {
                ApplicationArea = All;
                Caption = 'Показати список';
                ToolTip = 'Повертає до звичайного списку контрагентів.';
                Image = List;

                trigger OnAction()
                var
                    BusinessPartners: Page "SI Business Partners";
                begin
                    BusinessPartners.Run();
                    CurrPage.Close();
                end;
            }

            action(OpenBusinessPartner)
            {
                ApplicationArea = All;
                Caption = 'Відкрити контрагента';
                ToolTip = 'Відкриває картку вибраного контрагента.';
                Image = Card;

                trigger OnAction()
                var
                    BusinessPartner: Record "SI Business Partner";
                begin
                    if Rec."Business Partner No." = '' then
                        exit;

                    if not BusinessPartner.Get(Rec."Business Partner No.") then
                        exit;

                    Page.Run(Page::"SI Business Partner Card", BusinessPartner);
                end;
            }
        }

        area(Promoted)
        {
            actionref(ShowListPromoted; ShowList)
            {
            }

            actionref(OpenBusinessPartnerPromoted; OpenBusinessPartner)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        BuildTree();
    end;

    local procedure BuildTree()
    begin
        Rec.Reset();
        Rec.DeleteAll();

        AddRoleBranch(
            CustomerBranchLbl,
            Enum::"SI BP Role Type"::Customer);

        AddRoleBranch(
            VendorBranchLbl,
            Enum::"SI BP Role Type"::Vendor);

        Rec.Reset();
        if Rec.FindFirst() then;
    end;

    local procedure AddRoleBranch(
        BranchName: Text;
        RoleType: Enum "SI BP Role Type")
    var
        BPRole: Record "SI BP Role";
        BusinessPartner: Record "SI Business Partner";
        AddedBusinessPartner: Dictionary of [Code[60], Boolean];
        BranchEntryNo: Integer;
    begin
        BranchEntryNo := GetNextEntryNo();

        Rec.Init();
        Rec."Entry No." := BranchEntryNo;
        Rec.Indentation := 0;
        Rec.Name := CopyStr(
            BranchName,
            1,
            MaxStrLen(Rec.Name));
        Rec.Style := 'Strong';
        Rec.Insert();

        BPRole.SetRange("Role Type", RoleType);

        if BPRole.FindSet() then
            repeat
                if not AddedBusinessPartner.ContainsKey(
                    BPRole."Business Partner No.")
                then
                    if BusinessPartner.Get(
                        BPRole."Business Partner No.")
                    then begin
                        AddBusinessPartner(
                            BusinessPartner,
                            BranchEntryNo);

                        AddedBusinessPartner.Add(
                            BPRole."Business Partner No.",
                            true);
                    end;
            until BPRole.Next() = 0;
    end;

    local procedure AddBusinessPartner(
        BusinessPartner: Record "SI Business Partner";
        BranchEntryNo: Integer)
    begin
        Rec.Init();
        Rec."Entry No." := GetNextEntryNo();
        Rec."Parent Entry No." := BranchEntryNo;
        Rec.Indentation := 1;

        Rec."Business Partner No." :=
            BusinessPartner."No.";

        Rec.Name :=
            CopyStr(
                GetBusinessPartnerDisplayName(BusinessPartner),
                1,
                MaxStrLen(Rec.Name));

        Rec."Registration No." :=
            BusinessPartner."Registration No.";

        Rec."Tax Registration No." :=
            BusinessPartner."Tax Registration No.";

        Rec."Country/Region Code" :=
            BusinessPartner."Country/Region Code";

        Rec.Status :=
            Format(BusinessPartner.Status);

        Rec.Insert();
    end;

    local procedure GetBusinessPartnerDisplayName(
        BusinessPartner: Record "SI Business Partner"): Text
    begin
        if BusinessPartner."Short Name BK" <> '' then
            exit(BusinessPartner."Short Name BK");

        if BusinessPartner.Name <> '' then
            exit(BusinessPartner.Name);

        exit(BusinessPartner."No.");
    end;

    local procedure GetNextEntryNo(): Integer
    var
        TreeBuffer: Record "SI BP Tree Buffer" temporary;
    begin
        TreeBuffer.Copy(Rec, true);

        if TreeBuffer.FindLast() then
            exit(TreeBuffer."Entry No." + 1);

        exit(1);
    end;

    var
        CustomerBranchLbl: Label 'Клієнти';
        VendorBranchLbl: Label 'Постачальники';
}