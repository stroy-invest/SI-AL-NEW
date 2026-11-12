page 60019 "SI Construction Site Card"
{
    PageType = Card;
    SourceTable = "SI Construction Site";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Будівельний майданчик';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field("Project No."; Rec."Project No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Site Code"; Rec."Site Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Default"; Rec."Default")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(ForemenGroup)
            {
                Caption = 'Виконроби';

                part(Foremen; "SI Site Assignments Part")
                {
                    ApplicationArea = All;
                    SubPageLink = "Project No." = field("Project No."),
                                  "Site Code" = field("Site Code");
                    UpdatePropagation = Both;
                }
            }
            group(TasksGroup)
            {
                Caption = 'Роботи';

                part(Tasks; "SI Site Job Tasks")
                {
                    ApplicationArea = All;
                    SubPageLink = "Job No." = field("Project No."),
                                  "SI Site Code" = field("Site Code");
                    UpdatePropagation = Both;
                }
            }
            group(AddressGroup)
            {
                Caption = 'Адреса доставки';
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Системний код стандартної адреси доставки.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditDeliveryAddress)
            {
                ApplicationArea = All;
                Caption = 'Адреса та географічні точки';
                Image = Addresses;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    SiteMgt: Codeunit "SI Construction Site Mgt.";
                begin
                    SiteMgt.EnsureSiteShipTo(Rec);
                    SiteMgt.OpenSiteShipTo(Rec);
                    CurrPage.Update(false);
                end;
            }

            action(SetDefault)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Caption = 'Зробити основним';

                trigger OnAction()
                var
                    SiteMgt: Codeunit "SI Construction Site Mgt.";
                begin
                    SiteMgt.SetDefaultSite(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Freeze)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Caption = 'Заморозити';

                trigger OnAction()
                begin
                    Rec.Validate(Status, Rec.Status::Freezed);
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
            action(Restore)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Caption = 'Відновити';

                trigger OnAction()
                begin
                    Rec.Validate(Status, Rec.Status::Active);
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
            action(Annulate)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Caption = 'Анулювати';

                trigger OnAction()
                begin
                    if not Confirm('Анулювати будівельний майданчик %1? Цю дію неможливо скасувати.', false, Rec.Name) then
                        exit;
                    Rec.Validate(Status, Rec.Status::Annulated);
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
