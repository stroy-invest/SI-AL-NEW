page 54006 "SI EDRPOU Check Result"
{
    PageType = Card;
    SourceTable = "SI EDRPOU Check Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Перевірка даних ЄДРПОУ';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(ComparisonSummary)
            {
                Caption = 'Результат перевірки';

                field("Comparison Result"; Rec."Comparison Result")
                {
                    ApplicationArea = All;
                    Caption = 'Результат';
                    MultiLine = true;
                    StyleExpr = ResultStyle;
                    ToolTip = 'Показує загальний результат порівняння даних Business Partner з даними державного реєстру.';
                }
            }

            group(Comparison)
            {
                Caption = 'Порівняння значущих реквізитів';

                group(VATComparison)
                {
                    Caption = 'Реєстраційний номер ПДВ';

                    field(BPVATRegistrationNo; Rec."BP Tax Registration No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Наше';
                        StyleExpr = VATStyle;
                        ToolTip = 'Показує VAT Registration No., записаний у картці Business Partner.';
                    }

                    field(RegistryVATRegistrationNo; Rec."Tax Registration No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Реєстр';
                        StyleExpr = VATStyle;
                        ToolTip = 'Показує VAT Registration No., отриманий із державного реєстру.';
                    }
                }

                group(LegalFormComparison)
                {
                    Caption = 'Форма господарювання';

                    field(BPLegalFormName; Rec."BP Legal Form Name")
                    {
                        ApplicationArea = All;
                        Caption = 'Наше';
                        StyleExpr = LegalFormStyle;
                        ToolTip = 'Показує форму господарювання, записану у картці Business Partner.';
                    }

                    field(RegistryLegalFormName; Rec."Registry Legal Form Name")
                    {
                        ApplicationArea = All;
                        Caption = 'Реєстр';
                        StyleExpr = LegalFormStyle;
                        ToolTip = 'Показує форму господарювання, визначену за повною назвою з державного реєстру.';
                    }
                }


                group(NameComparison)
                {
                    Caption = 'Назва (заповнення, якщо порожня)';

                    field(BPName; Rec."BP Name")
                    {
                        ApplicationArea = All;
                        Caption = 'Наше';
                        StyleExpr = NameStyle;
                        ToolTip = 'Показує поточне поле Name у картці Business Partner.';
                    }

                    field(RegistryBusinessName; Rec."Registry Business Name")
                    {
                        ApplicationArea = All;
                        Caption = 'Реєстр';
                        StyleExpr = NameStyle;
                        ToolTip = 'Показує бізнес-назву, виділену з повної назви державного реєстру після вилучення форми господарювання та лапок.';
                    }
                }
            }

            group(RegistryDetails)
            {
                Caption = 'Дані державного реєстру';

                field("Registration No."; Rec."Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'ЄДРПОУ';
                    ToolTip = 'Показує код ЄДРПОУ, повернений сервісом державного реєстру.';
                }

                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = All;
                    Caption = 'Повна назва';
                    MultiLine = true;
                    ToolTip = 'Показує повну назву юридичної особи, повернену сервісом державного реєстру.';
                }

                field("Short Name"; Rec."Short Name")
                {
                    ApplicationArea = All;
                    Caption = 'Скорочена назва';
                    MultiLine = true;
                    ToolTip = 'Показує скорочену назву юридичної особи, повернену сервісом державного реєстру.';
                }

                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                    Caption = 'Юридична адреса';
                    MultiLine = true;
                    ToolTip = 'Показує юридичну адресу, повернену сервісом державного реєстру.';
                }

                field(Director; Rec.Director)
                {
                    ApplicationArea = All;
                    Caption = 'Керівник';
                    ToolTip = 'Показує керівника юридичної особи, поверненого сервісом державного реєстру.';
                }

                field("KVED No."; Rec."KVED No.")
                {
                    ApplicationArea = All;
                    Caption = 'Основний КВЕД';
                    ToolTip = 'Показує код основного виду економічної діяльності.';
                }

                field("KVED Description"; Rec."KVED Description")
                {
                    ApplicationArea = All;
                    Caption = 'Опис основного КВЕД';
                    MultiLine = true;
                    ToolTip = 'Показує опис основного виду економічної діяльності.';
                }

                field("Last Update"; Rec."Last Update")
                {
                    ApplicationArea = All;
                    Caption = 'Оновлення даних реєстру';
                    ToolTip = 'Показує дату останнього оновлення даних у сервісі державного реєстру.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ApplyCorrections)
            {
                ApplicationArea = All;
                Caption = 'Виправити';
                Image = Apply;
                Enabled = CanApplyCorrections;
                ToolTip = 'Оновити VAT Registration No., форму господарювання та заповнити Name, якщо воно порожнє, даними державного реєстру.';

                trigger OnAction()
                begin
                    ApplyRequested := true;
                    CurrPage.Close();
                end;
            }

            action(ClosePage)
            {
                ApplicationArea = All;
                Caption = 'Закрити';
                Image = Close;
                ToolTip = 'Закрити вікно результату перевірки без зміни Business Partner.';

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }

        area(Promoted)
        {
            actionref(ApplyCorrectionsPromoted; ApplyCorrections)
            {
            }

            actionref(ClosePagePromoted; ClosePage)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdatePageState();
    end;

    procedure SetResult(var ResultBuffer: Record "SI EDRPOU Check Buffer" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();
        Rec := ResultBuffer;
        Rec.Insert();
        ApplyRequested := false;
        UpdatePageState();
    end;

    procedure GetApplyRequested(): Boolean
    begin
        exit(ApplyRequested);
    end;

    local procedure UpdatePageState()
    begin
        CanApplyCorrections := Rec."Can Apply Corrections" and Rec."Has Differences";

        if Rec."Has Differences" then
            ResultStyle := 'Unfavorable'
        else
            ResultStyle := 'Favorable';

        if Rec."VAT Matches" then
            VATStyle := 'Favorable'
        else
            VATStyle := 'Unfavorable';

        if Rec."Legal Form Matches" then
            LegalFormStyle := 'Favorable'
        else
            LegalFormStyle := 'Unfavorable';

        if Rec."Name Needs Fill" then
            NameStyle := 'Unfavorable'
        else
            NameStyle := 'Favorable';
    end;

    var
        ApplyRequested: Boolean;
        CanApplyCorrections: Boolean;
        LegalFormStyle: Text;
        NameStyle: Text;
        ResultStyle: Text;
        VATStyle: Text;
}
