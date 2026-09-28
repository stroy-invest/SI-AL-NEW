page 61031 "SI Supply Req Line Edit"
{
    PageType = StandardDialog;
    SourceTable = "SI Supply Req Line";
    SourceTableTemporary = true;
    Caption = 'Позиція потреби';

    layout
    {
        area(Content)
        {
            field(SiteName; SiteName)
            {
                ApplicationArea = All;
                Caption = 'Буд. майданчик';
                ShowMandatory = true;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    exit(LookupRequestSite());
                end;
            }
            field("Line Type"; Rec."Line Type") { ApplicationArea = All; }
            field("Item No."; Rec."Item No.") { ApplicationArea = All; }
            field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
            field(Description; Rec.Description) { ApplicationArea = All; }
            field("Requested Quantity"; Rec."Requested Quantity") { ApplicationArea = All; }
            field("Approved Quantity"; Rec."Approved Quantity") { ApplicationArea = All; Editable = false; }
            field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
            field("Required on Site At"; Rec."Required on Site At") { ApplicationArea = All; ShowMandatory = true; }
            field(Comment; Rec.Comment) { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetSiteName();
    end;

    procedure PrepareNew(RequestNo: Code[20])
    var
        Header: Record "SI Supply Req Header";
        RequestSite: Record "SI Supply Request Site";
        Line: Record "SI Supply Req Line";
    begin
        Header.Get(RequestNo);
        Header.TestEditable();

        Rec.Init();
        Rec."Request No." := RequestNo;
        Rec."Line Type" := Rec."Line Type"::Item;
        Rec."Required on Site At" := Header."Required on Site At";

        Line.SetRange("Request No.", RequestNo);
        if Line.FindLast() then
            Rec."Line No." := Line."Line No." + 10000
        else
            Rec."Line No." := 10000;

        // The request-site junction is the authoritative allowed set for a line.
        // If exactly one site was selected for the request, use it immediately.
        RequestSite.SetRange("Request No.", RequestNo);
        RequestSite.SetRange(Selected, true);
        if RequestSite.Count() = 1 then begin
            RequestSite.FindFirst();
            Rec."Construction Site Code" := RequestSite."Site Code";
            SiteName := RequestSite."Site Name";
        end;

        // StandardDialog + temporary source requires a real current temp record.
        Rec.Insert(false);
    end;

    local procedure LookupRequestSite(): Boolean
    var
        RequestSite: Record "SI Supply Request Site";
        RequestSiteList: Page "SI Supply Request Sites";
        RequestNo: Code[20];
    begin
        RequestNo := Rec."Request No.";
        if RequestNo = '' then
            Error('Не визначено заявку для позиції потреби.');

        // Fail explicitly on a broken request invariant instead of opening an empty lookup.
        RequestSite.Reset();
        RequestSite.SetRange("Request No.", RequestNo);
        RequestSite.SetRange(Selected, true);
        if RequestSite.IsEmpty() then
            Error('Для заявки %1 не знайдено вибраних будівельних майданчиків.', RequestNo);

        // Do not rely on SetTableView propagation. The lookup page owns and applies
        // the Request No. filter itself in OnOpenPage.
        RequestSiteList.SetRequestNo(RequestNo);
        RequestSiteList.LookupMode(true);

        if RequestSiteList.RunModal() <> Action::LookupOK then
            exit(false);

        RequestSiteList.GetRecord(RequestSite);

        Rec."Construction Site Code" := RequestSite."Site Code";
        SiteName := RequestSite."Site Name";
        Rec.Modify(false);

        exit(true);
    end;

    local procedure SetSiteName()
    var
        RequestSite: Record "SI Supply Request Site";
    begin
        Clear(SiteName);
        if RequestSite.Get(Rec."Request No.", Rec."Construction Site Code") and RequestSite.Selected then
            SiteName := RequestSite."Site Name";
    end;

    var
        SiteName: Text[100];
}
