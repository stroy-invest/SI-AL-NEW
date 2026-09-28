table 50211 "SI Recipient Group"
{
    Caption = 'Групи отримувачів';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[50])
        {
            Caption = 'Код';
            NotBlank = true;
        }

        field(10; Description; Text[250])
        {
            Caption = 'Опис';
        }

        field(20; "Resolver Type"; Enum "SI Recipient Resolver Type")
        {
            Caption = 'Тип визначення отримувачів';

            trigger OnValidate()
            begin
                if "Resolver Type" <> xRec."Resolver Type" then
                    Clear("Provider Code");
            end;
        }

        field(30; "Provider Code"; Code[50])
        {
            Caption = 'Код провайдера';
        }

        field(40; Active; Boolean)
        {
            Caption = 'Активна';
            InitValue = true;
        }

        field(50; "Include Inactive Users"; Boolean)
        {
            Caption = 'Включати неактивних користувачів';
        }

        field(60; "Remove Duplicates"; Boolean)
        {
            Caption = 'Видаляти дублікати';
            InitValue = true;
        }

        field(70; Notes; Text[2048])
        {
            Caption = 'Примітки';
        }

        field(80; "Last Modified At"; DateTime)
        {
            Caption = 'Змінено';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        field(90; "Last Modified By"; Code[50])
        {
            Caption = 'Змінив';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }

        key(ActiveGroups; Active, "Resolver Type")
        {
        }
    }

    trigger OnInsert()
    begin
        SetModificationData();
    end;

    trigger OnModify()
    begin
        SetModificationData();
    end;

    local procedure SetModificationData()
    begin
        "Last Modified At" := CurrentDateTime();
        "Last Modified By" := CopyStr(UserId(), 1, MaxStrLen("Last Modified By"));
    end;
}