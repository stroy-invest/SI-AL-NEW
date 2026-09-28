page 61033 "SI Supply Req Lines Grid"
{
    PageType = CardPart;
    SourceTable = "SI Supply Req Header";
    Caption = 'Позиції потреби';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            usercontrol(LinesGrid; SISupplyReqLinesGrid)
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    ControlIsReady := true;
                    RefreshGrid();
                end;

                trigger AddLine()
                begin
                    AddDemandLine();
                end;

                trigger EditLine(LineNo: Integer)
                begin
                    EditDemandLine(LineNo);
                end;

                trigger DeleteLine(LineNo: Integer)
                begin
                    DeleteDemandLine(LineNo);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if (RequestNoContext = '') and (Rec."No." <> '') then
            RequestNoContext := Rec."No.";

        RefreshGrid();
    end;

    procedure SetRequestContext(RequestNo: Code[20])
    begin
        RequestNoContext := RequestNo;
        RefreshGrid();
    end;

    procedure RefreshFromDatabase()
    begin
        RefreshGrid();
    end;

    procedure RefreshGrid()
    var
        SupplyLine: Record "SI Supply Req Line";
        RequestSite: Record "SI Supply Request Site";
        LinesArray: JsonArray;
        LineObject: JsonObject;
        LinesJson: Text;
        RequestNo: Code[20];
    begin
        if not ControlIsReady then
            exit;

        RequestNo := GetRequestNo();
        if RequestNo = '' then begin
            Clear(LinesArray);
            LinesArray.WriteTo(LinesJson);
            CurrPage.LinesGrid.SetLines(LinesJson, IsRequestEditable(RequestNo));
            exit;
        end;

        Clear(LinesArray);

        SupplyLine.Reset();
        SupplyLine.SetRange("Request No.", RequestNo);

        if SupplyLine.FindSet() then
            repeat
                Clear(LineObject);

                LineObject.Add('lineNo', SupplyLine."Line No.");

                RequestSite.Reset();
                if RequestSite.Get(RequestNo, SupplyLine."Construction Site Code") then
                    LineObject.Add('siteName', RequestSite."Site Name")
                else
                    LineObject.Add('siteName', SupplyLine."Construction Site Code");

                LineObject.Add('lineType', Format(SupplyLine."Line Type"));
                LineObject.Add('itemNo', SupplyLine."Item No.");
                LineObject.Add('variantCode', SupplyLine."Variant Code");
                LineObject.Add('description', SupplyLine.Description);
                LineObject.Add('requestedQty', Format(SupplyLine."Requested Quantity"));
                LineObject.Add('approvedQty', Format(SupplyLine."Approved Quantity"));
                LineObject.Add('uom', SupplyLine."Unit of Measure Code");
                LineObject.Add('requiredAt', Format(SupplyLine."Required on Site At"));
                LineObject.Add('comment', SupplyLine.Comment);

                LinesArray.Add(LineObject);
            until SupplyLine.Next() = 0;

        LinesArray.WriteTo(LinesJson);

        // Command-driven UI: the New Line command is always available.
        // Readiness is validated authoritatively in AddDemandLine() at click time.
        CurrPage.LinesGrid.SetLines(LinesJson, IsRequestEditable(RequestNo));
    end;

    local procedure AddDemandLine()
    var
        SupplyLine: Record "SI Supply Req Line";
        LineEditor: Page "SI Supply Req Line Edit";
        RequestNo: Code[20];
    begin
        RequestNo := GetRequestNo();
        EnsureRequestContext(RequestNo);

        LineEditor.PrepareNew(RequestNo);

        if LineEditor.RunModal() <> Action::OK then
            exit;

        LineEditor.GetRecord(SupplyLine);
        ValidateLineSite(RequestNo, SupplyLine);
        SupplyLine.Insert(true);

        RefreshGrid();
    end;

    local procedure EditDemandLine(LineNo: Integer)
    var
        SupplyLine: Record "SI Supply Req Line";
        LineEditor: Page "SI Supply Req Line Edit";
        RequestNo: Code[20];
    begin
        RequestNo := GetRequestNo();

        if RequestNo = '' then
            Error('Не визначено заявку для позиції потреби.');

        EnsureRequestEditable(RequestNo);
        SupplyLine.Get(RequestNo, LineNo);
        LineEditor.PrepareEdit(SupplyLine);

        if LineEditor.RunModal() <> Action::OK then
            exit;

        LineEditor.GetRecord(SupplyLine);
        ValidateLineSite(RequestNo, SupplyLine);
        SupplyLine.Modify(true);

        RefreshGrid();
    end;

    local procedure DeleteDemandLine(LineNo: Integer)
    var
        SupplyLine: Record "SI Supply Req Line";
        RequestNo: Code[20];
    begin
        RequestNo := GetRequestNo();

        if RequestNo = '' then
            Error('Не визначено заявку для позиції потреби.');

        EnsureRequestEditable(RequestNo);
        SupplyLine.Get(RequestNo, LineNo);

        if not Confirm('Видалити позицію потреби %1?', false, LineNo) then
            exit;

        SupplyLine.Delete(true);
        RefreshGrid();
    end;

    local procedure EnsureRequestContext(RequestNo: Code[20])
    var
        Header: Record "SI Supply Req Header";
    begin
        if RequestNo = '' then
            Error('Спочатку створіть або збережіть заявку.');

        if not Header.Get(RequestNo) then
            Error('Заявку %1 не знайдено.', RequestNo);

        Header.TestEditable();

        if Header."Project No." = '' then
            Error('Виберіть проєкт.');

        if Header."Required on Site At" = 0DT then
            Error('Введіть дату потреби.');

    end;

    local procedure ValidateLineSite(RequestNo: Code[20]; SupplyLine: Record "SI Supply Req Line")
    var
        RequestSite: Record "SI Supply Request Site";
    begin
        if SupplyLine."Construction Site Code" = '' then
            Error('Необхідно вибрати будівельний майданчик.');

        if (not RequestSite.Get(RequestNo, SupplyLine."Construction Site Code")) or (not RequestSite.Selected) then
            Error(
                'Будівельний майданчик %1 не включено до заявки %2.',
                SupplyLine."Construction Site Code",
                RequestNo);
    end;

    local procedure IsRequestEditable(RequestNo: Code[20]): Boolean
    var
        Header: Record "SI Supply Req Header";
    begin
        if RequestNo = '' then
            exit(false);
        if not Header.Get(RequestNo) then
            exit(false);
        exit(Header.Status = Header.Status::Draft);
    end;

    local procedure EnsureRequestEditable(RequestNo: Code[20])
    var
        Header: Record "SI Supply Req Header";
    begin
        if not Header.Get(RequestNo) then
            Error('Заявку %1 не знайдено.', RequestNo);
        Header.TestEditable();
    end;

    local procedure GetRequestNo(): Code[20]
    begin
        if RequestNoContext <> '' then
            exit(RequestNoContext);

        exit(Rec."No.");
    end;

    var
        ControlIsReady: Boolean;
        RequestNoContext: Code[20];
}
