page 60029 "SI Site Delivery Address"
{
    PageType = Card;
    SourceTable = "Ship-to Address";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Адреса доставки майданчика';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Адреса доставки';
                field(Name; Rec.Name) { ApplicationArea = All; Caption = 'Назва майданчика'; }
                field("Country/Region Code"; Rec."Country/Region Code") { ApplicationArea = All; Caption = 'Країна'; }
                field("Post Code"; Rec."Post Code") { ApplicationArea = All; Caption = 'Поштовий індекс'; }
                field(County; Rec.County) { ApplicationArea = All; Caption = 'Область'; }
                field("SI District"; Rec."SI District") { ApplicationArea = All; Caption = 'Район'; }
                field(City; Rec.City) { ApplicationArea = All; Caption = 'Місто'; }
                field(Address; Rec.Address) { ApplicationArea = All; Caption = 'Адреса'; }
            }
            group(ContactGroup)
            {
                Caption = 'Контактна інформація';
                field(EmployeeDisplayName; EmployeeDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Контактна особа';
                    Lookup = true;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Employee: Record Employee;
                    begin
                        if Page.RunModal(Page::"Employee List", Employee) <> Action::LookupOK then
                            exit(false);
                        Rec.Validate("SI Contact Employee No.", Employee."No.");
                        EmployeeDisplayName := Employee.FullName();
                        Text := EmployeeDisplayName;
                        exit(true);
                    end;
                }
                field("Phone No."; Rec."Phone No.") { ApplicationArea = All; Caption = 'Телефон'; }
                field("E-Mail"; Rec."E-Mail") { ApplicationArea = All; Caption = 'Електронна пошта'; }
            }
        }
    }
    var
        EmployeeDisplayName: Text[250];

    trigger OnAfterGetRecord()
    var
        Employee: Record Employee;
    begin
        Clear(EmployeeDisplayName);
        if (Rec."SI Contact Employee No." <> '') and Employee.Get(Rec."SI Contact Employee No.") then
            EmployeeDisplayName := Employee.FullName();
    end;
}
