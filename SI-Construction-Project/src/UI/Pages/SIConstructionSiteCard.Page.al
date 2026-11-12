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
                field(DeliveryAddressDisplay; DeliveryAddressDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Адреса';
                    Editable = false;
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
                    Rec.TestField("Ship-to Code");
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
    trigger OnAfterGetRecord()
    var
        Project: Record Job;
        ShipTo: Record "Ship-to Address";
    begin
        Clear(DeliveryAddressDisplay);
        if Project.Get(Rec."Project No.") then
            if (Project."SI Internal Customer No." <> '') and (Rec."Ship-to Code" <> '') then
                if ShipTo.Get(Project."SI Internal Customer No.", Rec."Ship-to Code") then
                    DeliveryAddressDisplay := CopyStr(ShipTo.Address + ', ' + ShipTo.City, 1, MaxStrLen(DeliveryAddressDisplay));
    end;


    var
        DeliveryAddressDisplay: Text[150];

}
