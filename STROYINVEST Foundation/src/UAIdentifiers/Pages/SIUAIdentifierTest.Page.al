page 50447 "SI UA Identifier Test"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Перевірка українських ідентифікаторів';

    layout
    {
        area(Content)
        {
            group(RNOKPPGroup)
            {
                Caption = 'РНОКПП (ІПН фізичної особи)';

                field(RNOKPP; RNOKPPValue)
                {
                    ApplicationArea = All;
                    Caption = 'РНОКПП';
                    ToolTip = 'Введіть 10-значний РНОКПП для локальної перевірки контрольної цифри.';
                }

                field(RNOKPPResult; RNOKPPResultText)
                {
                    ApplicationArea = All;
                    Caption = 'Результат';
                    Editable = false;
                    ToolTip = 'Показує результат локальної перевірки РНОКПП.';
                }
            }

            group(EDRPOUGroup)
            {
                Caption = 'Код ЄДРПОУ';

                field(EDRPOU; EDRPOUValue)
                {
                    ApplicationArea = All;
                    Caption = 'ЄДРПОУ';
                    ToolTip = 'Введіть 8-значний код ЄДРПОУ для локальної перевірки контрольної цифри.';
                }

                field(EDRPOUResult; EDRPOUResultText)
                {
                    ApplicationArea = All;
                    Caption = 'Результат';
                    Editable = false;
                    ToolTip = 'Показує результат локальної перевірки коду ЄДРПОУ.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateRNOKPP)
            {
                ApplicationArea = All;
                Caption = 'Перевірити РНОКПП';
                Image = Check;
                ToolTip = 'Перевірити формат і контрольну цифру введеного РНОКПП без зовнішніх запитів.';

                trigger OnAction()
                begin
                    UAIdentifierMgt.ValidateRNOKPP(RNOKPPValue);
                    RNOKPPResultText := 'Коректний';
                end;
            }

            action(ValidateEDRPOU)
            {
                ApplicationArea = All;
                Caption = 'Перевірити ЄДРПОУ';
                Image = Check;
                ToolTip = 'Перевірити формат і контрольну цифру введеного коду ЄДРПОУ без зовнішніх запитів.';

                trigger OnAction()
                begin
                    UAIdentifierMgt.ValidateEDRPOU(EDRPOUValue);
                    EDRPOUResultText := 'Коректний';
                end;
            }

            action(ClearResults)
            {
                ApplicationArea = All;
                Caption = 'Очистити';
                Image = ClearFilter;
                ToolTip = 'Очистити введені значення та результати перевірки.';

                trigger OnAction()
                begin
                    Clear(RNOKPPValue);
                    Clear(EDRPOUValue);
                    Clear(RNOKPPResultText);
                    Clear(EDRPOUResultText);
                end;
            }
        }
    }

    var
        UAIdentifierMgt: Codeunit "SI UA Identifier Mgt.";
        RNOKPPValue: Text[10];
        EDRPOUValue: Text[8];
        RNOKPPResultText: Text[50];
        EDRPOUResultText: Text[50];
}
